import 'dart:async';

import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/client_agents/domain/events/agent_presence_event.dart';
import 'package:colmeia/features/client_agents/domain/repositories/client_agents_repository.dart';

/// Camada 3 do plano §19 — fallback REST que cobre o cenário
/// "socket caído + tela visível". Liga só quando o
/// `ClientAgentsController` decide (visibilidade da tela + estado do
/// socket); o poller em si é dumb: tick periódico → REST → empurra
/// hints `online: true` no sink.
///
/// Limitações conscientes (alinhadas ao design doc):
///
/// - O REST `loadOnlineAgentIds` só **lista quem está online**.
///   Para `offline` confiável dependemos da Camada 1
///   (`client:agent.profile.updated`) ou da Camada 2 (hints de
///   `agents:command_error_offline`). O poller nunca emite hint
///   `online: false`.
/// - Falhas de rede são logadas e descartadas para não matar o
///   timer. Próximo tick tenta de novo.
///
/// Lifecycle:
///
/// - [start] — idempotente; chamadas extras enquanto o timer já está
///   ativo são no-op.
/// - [stop] — idempotente; cancela o timer.
/// - [dispose] — `stop` + libera o sink (não fechamos o sink aqui
///   porque ele é compartilhado com `SocketAgentPresenceStream`).
class AgentPresencePoller {
  AgentPresencePoller({
    required this._clientAgentsRepository,
    required this._sink,
    this._interval = defaultInterval,
  });

  /// 30 s — same value the design doc proposes for "active screen,
  /// socket disconnected".
  static const Duration defaultInterval = Duration(seconds: 30);

  static const Duration _backoffBase = Duration(seconds: 30);
  static const Duration _backoffStep = Duration(seconds: 30);
  static const Duration _backoffMax = Duration(seconds: 120);

  final ClientAgentsRepository _clientAgentsRepository;
  final Sink<AgentPresenceEvent> _sink;
  final Duration _interval;

  Timer? _timer;
  String? _activeUserId;
  bool _tickInFlight = false;
  bool _isDisposed = false;
  int _epoch = 0;
  int _consecutiveTickFailures = 0;
  Duration _currentBackoff = Duration.zero;

  bool get isRunning => _timer != null;

  /// Liga o polling para [userId]. Se já estiver rodando para o mesmo
  /// `userId` é no-op; para um `userId` diferente reinicia o timer
  /// (cobre logout + login do mesmo controller).
  ///
  /// Dispara um primeiro tick imediatamente para que a UI reflita o
  /// estado em < 1 s quando o usuário abre a tela com o socket caído.
  void start({required String userId}) {
    if (_isDisposed) {
      return;
    }
    if (_timer != null && _activeUserId == userId) {
      return;
    }
    _timer?.cancel();
    _epoch++;
    _activeUserId = userId;
    _consecutiveTickFailures = 0;
    _currentBackoff = Duration.zero;
    _timer = Timer.periodic(_interval, (_) => unawaited(_tick()));
    unawaited(_tick());
  }

  /// Idempotente. Cancela o timer atual e libera o `userId` ativo.
  void stop() {
    _timer?.cancel();
    _timer = null;
    _epoch++;
    _activeUserId = null;
  }

  Future<void> dispose() async {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    stop();
  }

  Future<void> _tick() async {
    if (_isDisposed || _tickInFlight) {
      return;
    }
    _tickInFlight = true;
    try {
      // Loop so that switching `_activeUserId` mid-flight schedules a
      // follow-up REST call without depending on the next periodic
      // tick — important for tests that drive `start()` with two
      // different userIds back-to-back.
      while (!_isDisposed) {
        final userId = _activeUserId;
        final epoch = _epoch;
        if (userId == null) {
          return;
        }
        await _runOneTick(userId, epoch: epoch);
        if (_isDisposed) {
          return;
        }
        if (_activeUserId == userId && _epoch == epoch) {
          return;
        }
        // User changed during the await: continue and tick again.
      }
    } finally {
      _tickInFlight = false;
    }
  }

  Future<void> _runOneTick(String userId, {required int epoch}) async {
    if (_currentBackoff > Duration.zero) {
      await Future<void>.delayed(_currentBackoff);
      if (_isDisposed || _activeUserId != userId || _epoch != epoch) {
        return;
      }
    }
    try {
      final ids = await _clientAgentsRepository.loadOnlineAgentIds(
        userId: userId,
      );
      if (_isDisposed || _activeUserId != userId || _epoch != epoch) {
        return;
      }
      _consecutiveTickFailures = 0;
      _currentBackoff = Duration.zero;
      if (ids == null) {
        // Indeterminate: don't fire hints — we only know "online" when
        // the server tells us, and `null` means it could not resolve.
        return;
      }
      final now = DateTime.now().toUtc();
      for (final id in ids) {
        _sink.add(
          AgentPresenceHint(
            agentId: id,
            observedAt: now,
            online: true,
            source: 'polling_rest',
          ),
        );
      }
    } on Object catch (error, stackTrace) {
      _consecutiveTickFailures += 1;
      final stepIndex = (_consecutiveTickFailures - 1).clamp(0, 2);
      _currentBackoff = _backoffBase + _backoffStep * stepIndex;
      if (_currentBackoff > _backoffMax) {
        _currentBackoff = _backoffMax;
      }
      AppLogger.warning(
        'AgentPresencePoller tick failed',
        context: <String, Object?>{
          'component': 'AgentPresencePoller',
          'operation': 'tick_failed',
          'consecutiveFailures': _consecutiveTickFailures,
          'nextBackoffMs': _currentBackoff.inMilliseconds,
        },
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}

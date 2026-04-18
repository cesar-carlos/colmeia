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
    required ClientAgentsRepository clientAgentsRepository,
    required Sink<AgentPresenceEvent> sink,
    Duration interval = defaultInterval,
  }) : _clientAgentsRepository = clientAgentsRepository,
       _sink = sink,
       _interval = interval;

  /// 30 s — same value the design doc proposes for "active screen,
  /// socket disconnected".
  static const Duration defaultInterval = Duration(seconds: 30);

  final ClientAgentsRepository _clientAgentsRepository;
  final Sink<AgentPresenceEvent> _sink;
  final Duration _interval;

  Timer? _timer;
  String? _activeUserId;
  bool _tickInFlight = false;
  bool _isDisposed = false;

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
    _activeUserId = userId;
    _timer = Timer.periodic(_interval, (_) => unawaited(_tick()));
    unawaited(_tick());
  }

  /// Idempotente. Cancela o timer atual e libera o `userId` ativo.
  void stop() {
    _timer?.cancel();
    _timer = null;
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
        if (userId == null) {
          return;
        }
        await _runOneTick(userId);
        if (_isDisposed) {
          return;
        }
        if (_activeUserId == userId) {
          return;
        }
        // User changed during the await: continue and tick again.
      }
    } finally {
      _tickInFlight = false;
    }
  }

  Future<void> _runOneTick(String userId) async {
    try {
      final ids = await _clientAgentsRepository.loadOnlineAgentIds(
        userId: userId,
      );
      if (_isDisposed) {
        return;
      }
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
      AppLogger.warning(
        'AgentPresencePoller tick failed',
        context: const <String, Object?>{
          'component': 'AgentPresencePoller',
          'operation': 'tick_failed',
        },
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}

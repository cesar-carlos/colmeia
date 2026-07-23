import 'dart:async';

import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/core/network/auth_session_events.dart';
import 'package:colmeia/core/socket/relay/relay_dispatch_exception.dart';
import 'package:colmeia/core/socket/socket_dispatch_exception.dart';
import 'package:colmeia/features/agent_queries/data/datasources/agent_queries_remote_datasource.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_batch_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';

/// Wraps a primary (socket / relay) datasource with REST fallback.
///
/// **Permanent latch** (session-scoped until [resetLatch]):
/// * [SocketDispatchNamespaceForbidden] — hub role policy rejects `/consumers`.
/// * [SocketDispatchUnauthorized] — auth refresh exhausted on the socket.
///
/// **Temporary latch** (per agentId, cooldown then half-open probe):
/// After `transientFailureThreshold` consecutive transport failures
/// for the same agent (`SocketDispatchTimeout`, `SocketDispatchDisconnected`,
/// `RelayRequestTimeout`, `RelayConversationLost`, eligible
/// `RelayConversationStartFailure`), subsequent calls for that agent use REST
/// for `temporaryLatchCooldown`. Other agents keep probing socket.
/// The next call after the cooldown probes socket again; success clears the
/// counter, another transient failure re-opens the temporary latch.
///
/// [SocketDispatchLegacyStreamingUnsupported] and cancel errors are never
/// fallback-eligible.
class SocketWithRestFallbackAgentQueriesRemoteDataSource
    implements AgentQueriesRemoteDataSource {
  SocketWithRestFallbackAgentQueriesRemoteDataSource({
    required AgentQueriesRemoteDataSource socketDelegate,
    required AgentQueriesRemoteDataSource restDelegate,
    void Function(SocketDispatchException trigger)? onFallback,
    void Function({required String reason, required Object trigger})?
    onTemporaryFallback,
    AuthSessionEvents? sessionEvents,
    int transientFailureThreshold = 5,
    Duration temporaryLatchCooldown = const Duration(seconds: 60),
    DateTime Function()? clock,
  }) : _socketDelegate = socketDelegate,
       _restDelegate = restDelegate,
       _onFallback = onFallback,
       _onTemporaryFallback = onTemporaryFallback,
       _transientFailureThreshold = transientFailureThreshold,
       _temporaryLatchCooldown = temporaryLatchCooldown,
       _clock = clock ?? DateTime.now {
    final events = sessionEvents;
    if (events != null) {
      _sessionEventsSub = events.stream.listen(
        (_) => resetLatch(reason: 'auth_session'),
      );
    }
  }

  final AgentQueriesRemoteDataSource _socketDelegate;
  final AgentQueriesRemoteDataSource _restDelegate;
  final void Function(SocketDispatchException trigger)? _onFallback;
  final void Function({required String reason, required Object trigger})?
  _onTemporaryFallback;
  final int _transientFailureThreshold;
  final Duration _temporaryLatchCooldown;
  final DateTime Function() _clock;

  StreamSubscription<AuthSessionEvent>? _sessionEventsSub;

  /// `true` once the latch has caught a permanent failure.
  bool _latched = false;

  final Map<String, _AgentTransientLatchState> _transientByAgent =
      <String, _AgentTransientLatchState>{};

  /// Visible-for-testing accessor for the permanent latch.
  bool get isLatchedToRest => _latched;

  /// Visible-for-testing: any agent is inside a temporary REST window.
  bool get isTemporarilyLatchedToRest {
    final now = _clock();
    for (final state in _transientByAgent.values) {
      final until = state.latchedUntil;
      if (until != null && now.isBefore(until)) {
        return true;
      }
    }
    return false;
  }

  /// Visible-for-testing: temporary REST window for a specific agent.
  bool isTemporarilyLatchedToRestFor(String agentId) {
    return _isAgentTemporarilyLatched(_normalizeAgentId(agentId));
  }

  /// Clears permanent and temporary REST fallback so a new auth session
  /// (or test) can retry the socket transport.
  void resetLatch({required String reason}) {
    final hadPermanent = _latched;
    final hadTemporary = _transientByAgent.isNotEmpty;
    if (!hadPermanent && !hadTemporary) {
      return;
    }
    _latched = false;
    _transientByAgent.clear();
    AppLogger.info(
      'Agent queries REST fallback latch cleared',
      context: <String, Object?>{
        'component': 'SocketWithRestFallbackAgentQueriesRemoteDataSource',
        'reason': reason,
        'clearedPermanent': hadPermanent,
        'clearedTemporary': hadTemporary,
      },
    );
  }

  Future<void> dispose() async {
    await _sessionEventsSub?.cancel();
    _sessionEventsSub = null;
  }

  @override
  Future<Map<String, dynamic>> postSqlExecute(
    AgentSqlExecuteRequest request, {
    AgentQueriesCancelScope? cancelScope,
  }) {
    return _dispatch(
      agentId: request.agentId,
      useRest: () =>
          _restDelegate.postSqlExecute(request, cancelScope: cancelScope),
      useSocket: () =>
          _socketDelegate.postSqlExecute(request, cancelScope: cancelScope),
    );
  }

  @override
  Future<Map<String, dynamic>> postSqlExecuteBatch(
    AgentSqlExecuteBatchRequest request, {
    AgentQueriesCancelScope? cancelScope,
  }) {
    return _dispatch(
      agentId: request.agentId,
      useRest: () =>
          _restDelegate.postSqlExecuteBatch(request, cancelScope: cancelScope),
      useSocket: () => _socketDelegate.postSqlExecuteBatch(
        request,
        cancelScope: cancelScope,
      ),
    );
  }

  Future<Map<String, dynamic>> _dispatch({
    required String agentId,
    required Future<Map<String, dynamic>> Function() useRest,
    required Future<Map<String, dynamic>> Function() useSocket,
  }) async {
    final normalizedAgentId = _normalizeAgentId(agentId);
    if (_latched || _isAgentTemporarilyLatched(normalizedAgentId)) {
      return useRest();
    }
    try {
      final response = await useSocket();
      _onSocketSuccess(normalizedAgentId);
      return response;
    } on SocketDispatchNamespaceForbidden catch (trigger) {
      _latchPermanent(trigger, reason: 'namespace_forbidden');
      return useRest();
    } on SocketDispatchUnauthorized catch (trigger) {
      _latchPermanent(trigger, reason: 'unauthorized_exhausted');
      return useRest();
    } on SocketDispatchException catch (error) {
      if (_isTransientSocketFailure(error)) {
        _noteTransientFailure(
          normalizedAgentId,
          error,
          reason: error.code,
        );
      }
      rethrow;
    } on RelayDispatchException catch (error) {
      if (_isTransientRelayFailure(error)) {
        _noteTransientFailure(
          normalizedAgentId,
          error,
          reason: error.code,
        );
      }
      rethrow;
    }
  }

  bool _isAgentTemporarilyLatched(String agentId) {
    final state = _transientByAgent[agentId];
    if (state == null) {
      return false;
    }
    final until = state.latchedUntil;
    if (until == null) {
      return false;
    }
    return _clock().isBefore(until);
  }

  void _onSocketSuccess(String agentId) {
    _transientByAgent.remove(agentId);
  }

  void _noteTransientFailure(
    String agentId,
    Object trigger, {
    required String reason,
  }) {
    final state = _transientByAgent.putIfAbsent(
      agentId,
      _AgentTransientLatchState.new,
    )..consecutiveFailures += 1;
    if (state.consecutiveFailures < _transientFailureThreshold) {
      return;
    }
    final alreadyOpen = _isAgentTemporarilyLatched(agentId);
    state.latchedUntil = _clock().add(_temporaryLatchCooldown);
    if (alreadyOpen) {
      return;
    }
    AppLogger.warning(
      'Agent queries datasource temporarily latched to REST fallback '
      '(socket/relay transient failures)',
      context: <String, Object?>{
        'component': 'SocketWithRestFallbackAgentQueriesRemoteDataSource',
        'reason': reason,
        'agentId': agentId,
        'consecutiveFailures': state.consecutiveFailures,
        'cooldownMs': _temporaryLatchCooldown.inMilliseconds,
        'trigger': trigger.toString(),
      },
      error: trigger is Exception ? trigger : null,
    );
    final hook = _onTemporaryFallback;
    if (hook == null) {
      return;
    }
    try {
      hook(reason: reason, trigger: trigger);
    } on Object catch (error, stackTrace) {
      AppLogger.warning(
        'Temporary fallback observability hook threw',
        context: const <String, Object?>{
          'component': 'SocketWithRestFallbackAgentQueriesRemoteDataSource',
        },
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  void _latchPermanent(
    SocketDispatchException trigger, {
    required String reason,
  }) {
    if (_latched) {
      return;
    }
    _latched = true;
    _transientByAgent.clear();
    AppLogger.warning(
      'Agent queries datasource latched to REST fallback '
      '(socket permanent failure)',
      context: <String, Object?>{
        'component': 'SocketWithRestFallbackAgentQueriesRemoteDataSource',
        'reason': reason,
        'triggerCode': trigger.code,
        'triggerMessage': trigger.message,
      },
      error: trigger,
    );
    final hook = _onFallback;
    if (hook != null) {
      try {
        hook(trigger);
      } on Object catch (error, stackTrace) {
        AppLogger.warning(
          'Fallback observability hook threw',
          context: const <String, Object?>{
            'component': 'SocketWithRestFallbackAgentQueriesRemoteDataSource',
          },
          error: error,
          stackTrace: stackTrace,
        );
      }
    }
  }

  static String _normalizeAgentId(String agentId) {
    final trimmed = agentId.trim();
    return trimmed.isEmpty ? '_' : trimmed;
  }

  static bool _isTransientSocketFailure(SocketDispatchException error) {
    return error is SocketDispatchTimeout ||
        error is SocketDispatchDisconnected;
  }

  static bool _isTransientRelayFailure(RelayDispatchException error) {
    if (error is RelayRequestTimeout || error is RelayConversationLost) {
      return true;
    }
    if (error is RelayConversationStartFailure) {
      const eligible = <String>{
        'conversation_start_failed',
        'start_timeout',
        'start_error',
        'emit_failed',
        'manager_disposed',
        'obtain_superseded',
      };
      return eligible.contains(error.code) ||
          error.code.toLowerCase().contains('overload') ||
          error.code.toLowerCase().contains('unavailable');
    }
    return false;
  }
}

final class _AgentTransientLatchState {
  int consecutiveFailures = 0;
  DateTime? latchedUntil;
}

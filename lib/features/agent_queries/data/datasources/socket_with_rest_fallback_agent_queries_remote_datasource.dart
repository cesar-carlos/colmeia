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
/// **Temporary latch** (cooldown then half-open probe):
/// After `transientFailureThreshold` consecutive transport failures
/// (`SocketDispatchTimeout`, `SocketDispatchDisconnected`,
/// `RelayRequestTimeout`, `RelayConversationLost`, eligible
/// `RelayConversationStartFailure`), subsequent calls use REST for
/// `temporaryLatchCooldown`. The next call after the cooldown probes
/// socket again; success clears the counter, another transient failure
/// re-opens the temporary latch.
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
    int transientFailureThreshold = 3,
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

  int _consecutiveTransientFailures = 0;
  DateTime? _temporaryLatchedUntil;

  /// Visible-for-testing accessor for the permanent latch.
  bool get isLatchedToRest => _latched;

  /// Visible-for-testing: temporary REST window is still active.
  bool get isTemporarilyLatchedToRest {
    final until = _temporaryLatchedUntil;
    if (until == null) {
      return false;
    }
    return _clock().isBefore(until);
  }

  /// Clears permanent and temporary REST fallback so a new auth session
  /// (or test) can retry the socket transport.
  void resetLatch({required String reason}) {
    final hadPermanent = _latched;
    final hadTemporary =
        _temporaryLatchedUntil != null || _consecutiveTransientFailures > 0;
    if (!hadPermanent && !hadTemporary) {
      return;
    }
    _latched = false;
    _consecutiveTransientFailures = 0;
    _temporaryLatchedUntil = null;
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
      useRest: () =>
          _restDelegate.postSqlExecuteBatch(request, cancelScope: cancelScope),
      useSocket: () => _socketDelegate.postSqlExecuteBatch(
        request,
        cancelScope: cancelScope,
      ),
    );
  }

  Future<Map<String, dynamic>> _dispatch({
    required Future<Map<String, dynamic>> Function() useRest,
    required Future<Map<String, dynamic>> Function() useSocket,
  }) async {
    if (_latched || isTemporarilyLatchedToRest) {
      return useRest();
    }
    try {
      final response = await useSocket();
      _onSocketSuccess();
      return response;
    } on SocketDispatchNamespaceForbidden catch (trigger) {
      _latchPermanent(trigger, reason: 'namespace_forbidden');
      return useRest();
    } on SocketDispatchUnauthorized catch (trigger) {
      _latchPermanent(trigger, reason: 'unauthorized_exhausted');
      return useRest();
    } on SocketDispatchException catch (error) {
      if (_isTransientSocketFailure(error)) {
        _noteTransientFailure(error, reason: error.code);
      }
      rethrow;
    } on RelayDispatchException catch (error) {
      if (_isTransientRelayFailure(error)) {
        _noteTransientFailure(error, reason: error.code);
      }
      rethrow;
    }
  }

  void _onSocketSuccess() {
    _consecutiveTransientFailures = 0;
    _temporaryLatchedUntil = null;
  }

  void _noteTransientFailure(Object trigger, {required String reason}) {
    _consecutiveTransientFailures += 1;
    if (_consecutiveTransientFailures < _transientFailureThreshold) {
      return;
    }
    final alreadyOpen = isTemporarilyLatchedToRest;
    _temporaryLatchedUntil = _clock().add(_temporaryLatchCooldown);
    if (alreadyOpen) {
      return;
    }
    AppLogger.warning(
      'Agent queries datasource temporarily latched to REST fallback '
      '(socket/relay transient failures)',
      context: <String, Object?>{
        'component': 'SocketWithRestFallbackAgentQueriesRemoteDataSource',
        'reason': reason,
        'consecutiveFailures': _consecutiveTransientFailures,
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
    _consecutiveTransientFailures = 0;
    _temporaryLatchedUntil = null;
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

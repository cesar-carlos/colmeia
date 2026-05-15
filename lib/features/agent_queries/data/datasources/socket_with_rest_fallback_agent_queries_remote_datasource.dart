import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/core/socket/socket_dispatch_exception.dart';
import 'package:colmeia/features/agent_queries/data/datasources/agent_queries_remote_datasource.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_batch_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';

/// Wraps a primary (socket) datasource with a permanent REST
/// fallback for the rare classes of failures that no amount of
/// retry will fix:
///
/// * [SocketDispatchNamespaceForbidden] — the hub's
///   `SOCKET_CONSUMER_ROLES` does not include the JWT role. Until
///   the server admin fixes the env + restarts, every dispatch will
///   fail the same way. Pivoting to REST keeps the user productive
///   instead of seeing "Sua sessao expirou" on every chart.
/// * [SocketDispatchUnauthorized] — the connection layer already
///   exhausted retries (5 by default) and a single token refresh
///   attempt. Same conclusion: the socket is dead for this session.
///
/// Once the fallback latches on, **every subsequent dispatch in the
/// same process goes through REST**. This is intentional: the
/// failure modes that trigger the latch are server-side and
/// session-scoped (a hub config edit + restart requires the user to
/// re-launch the app anyway, since the JWT/socket lifecycle is
/// rebuilt on cold start).
///
/// [SocketDispatchLegacyStreamingUnsupported] is deliberately NOT
/// fallback-eligible: progressive socket streaming is relay-only in Colmeia.
/// Callers that need streaming should use `useRelay: true`.
///
/// Transient errors ([SocketDispatchTimeout], plain
/// [SocketDispatchDisconnected] without an auth bind, regular
/// `app:error` overload responses, etc.) are NOT fallback-eligible:
/// the socket layer's own backoff + `RetryAfterGate` already handles
/// those, and pivoting to REST on a momentary blip would mask
/// recoverable problems and break sticky-session affinity.
class SocketWithRestFallbackAgentQueriesRemoteDataSource
    implements AgentQueriesRemoteDataSource {
  SocketWithRestFallbackAgentQueriesRemoteDataSource({
    required AgentQueriesRemoteDataSource socketDelegate,
    required AgentQueriesRemoteDataSource restDelegate,
    void Function(SocketDispatchException trigger)? onFallback,
  }) : _socketDelegate = socketDelegate,
       _restDelegate = restDelegate,
       _onFallback = onFallback;

  final AgentQueriesRemoteDataSource _socketDelegate;
  final AgentQueriesRemoteDataSource _restDelegate;

  /// Optional observability hook. Called exactly once per process,
  /// the first time the latch flips. Useful to bump a Sentry
  /// breadcrumb / metric counter so ops can spot fleet-wide
  /// fallback events.
  final void Function(SocketDispatchException trigger)? _onFallback;

  /// `true` once the latch has caught a permanent failure. Stays
  /// `true` until the process restarts.
  bool _latched = false;

  /// Visible-for-testing accessor. UI code SHOULD NOT depend on
  /// this — the contract is "you get a working datasource"; whether
  /// it is socket or REST is an implementation detail.
  bool get isLatchedToRest => _latched;

  @override
  Future<Map<String, dynamic>> postSqlExecute(
    AgentSqlExecuteRequest request,
  ) async {
    if (_latched) {
      return _restDelegate.postSqlExecute(request);
    }
    try {
      return await _socketDelegate.postSqlExecute(request);
    } on SocketDispatchNamespaceForbidden catch (trigger) {
      _latch(trigger, reason: 'namespace_forbidden');
      return _restDelegate.postSqlExecute(request);
    } on SocketDispatchUnauthorized catch (trigger) {
      _latch(trigger, reason: 'unauthorized_exhausted');
      return _restDelegate.postSqlExecute(request);
    }
    // All other SocketDispatchException variants (timeout,
    // disconnected, app_error, decode_failed, cancelled) propagate
    // verbatim — the socket layer's RetryAfterGate / circuit
    // breaker / user retry handle those better than a permanent
    // pivot would.
  }

  @override
  Future<Map<String, dynamic>> postSqlExecuteBatch(
    AgentSqlExecuteBatchRequest request,
  ) async {
    if (_latched) {
      return _restDelegate.postSqlExecuteBatch(request);
    }
    try {
      return await _socketDelegate.postSqlExecuteBatch(request);
    } on SocketDispatchNamespaceForbidden catch (trigger) {
      _latch(trigger, reason: 'namespace_forbidden');
      return _restDelegate.postSqlExecuteBatch(request);
    } on SocketDispatchUnauthorized catch (trigger) {
      _latch(trigger, reason: 'unauthorized_exhausted');
      return _restDelegate.postSqlExecuteBatch(request);
    }
  }

  void _latch(
    SocketDispatchException trigger, {
    required String reason,
  }) {
    if (_latched) {
      return;
    }
    _latched = true;
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
        // The hook is observability — never let it break the
        // dispatch path that just decided to fall back.
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
}

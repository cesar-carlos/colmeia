import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/agent_queries/data/datasources/agent_queries_remote_datasource.dart';
import 'package:colmeia/features/agent_queries/data/datasources/socket_with_rest_fallback_agent_queries_remote_datasource.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_batch_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';

/// Per-call routing datasource that dispatches each [AgentSqlExecuteRequest]
/// either through the relay channel (`relay:rpc.request`) or through the
/// configured "base" channel (REST or `agents:command`), driven by
/// [AgentSqlExecuteRequest.useRelay].
///
/// PR-L+ part 1: this is the **selector**. The two underlying datasources
/// stay independent — both speak the same `Map<String, dynamic>` bridge
/// envelope, so the repository (`AgentQueriesRepositoryImpl`) keeps using a
/// single parser regardless of the chosen path.
///
/// SRP: this class only chooses a delegate; both delegates own their own
/// timeouts, body building, and error mapping.
///
/// LSP: returns the same response shape for both paths. A query that asks
/// for relay but ends up routed back through the base channel — for example
/// when the relay datasource was not provided — is logged as a `relay_bypass`
/// breadcrumb so observability can quantify how often the selector falls
/// back.
class HybridAgentQueriesRemoteDataSource
    implements AgentQueriesRemoteDataSource {
  HybridAgentQueriesRemoteDataSource({
    required AgentQueriesRemoteDataSource baseDelegate,
    AgentQueriesRemoteDataSource? relayDelegate,
  }) : _baseDelegate = baseDelegate,
       _relayDelegate = relayDelegate;

  final AgentQueriesRemoteDataSource _baseDelegate;
  final AgentQueriesRemoteDataSource? _relayDelegate;

  /// Cancels nested REST-fallback session subscriptions when present.
  Future<void> dispose() async {
    await _disposeNested(_baseDelegate);
    await _disposeNested(_relayDelegate);
  }

  static Future<void> _disposeNested(
    AgentQueriesRemoteDataSource? delegate,
  ) async {
    if (delegate is SocketWithRestFallbackAgentQueriesRemoteDataSource) {
      await delegate.dispose();
    }
  }

  @override
  Future<Map<String, dynamic>> postSqlExecute(
    AgentSqlExecuteRequest request, {
    AgentQueriesCancelScope? cancelScope,
  }) {
    if (!request.useRelay) {
      AppLogger.debug(
        'HybridAgentQueriesRemoteDataSource routing request through base',
        context: <String, Object?>{
          'component': 'HybridAgentQueriesRemoteDataSource',
          'agentId': request.trimmedAgentId,
          'transportRoute': 'base',
          'transportMethod': 'sql.execute',
          'relayRequested': false,
        },
      );
      return _baseDelegate.postSqlExecute(request, cancelScope: cancelScope);
    }
    final relay = _relayDelegate;
    if (relay == null) {
      AppLogger.warning(
        'HybridAgentQueriesRemoteDataSource bypassing relay request '
        '(relay datasource not registered)',
        context: <String, Object?>{
          'component': 'HybridAgentQueriesRemoteDataSource',
          'agentId': request.trimmedAgentId,
          'transportRoute': 'base',
          'transportMethod': 'sql.execute',
          'relayRequested': true,
          'reason': 'relay_datasource_missing',
        },
      );
      return _baseDelegate.postSqlExecute(request, cancelScope: cancelScope);
    }
    AppLogger.debug(
      'HybridAgentQueriesRemoteDataSource routing request through relay',
      context: <String, Object?>{
        'component': 'HybridAgentQueriesRemoteDataSource',
        'agentId': request.trimmedAgentId,
        'transportRoute': 'relay',
        'transportMethod': 'sql.execute',
        'relayRequested': true,
      },
    );
    return relay.postSqlExecute(request, cancelScope: cancelScope);
  }

  @override
  Future<Map<String, dynamic>> postSqlExecuteBatch(
    AgentSqlExecuteBatchRequest request, {
    AgentQueriesCancelScope? cancelScope,
  }) {
    if (!request.useRelay) {
      AppLogger.debug(
        'HybridAgentQueriesRemoteDataSource routing sql.executeBatch through '
        'base',
        context: <String, Object?>{
          'component': 'HybridAgentQueriesRemoteDataSource',
          'agentId': request.trimmedAgentId,
          'transportRoute': 'base',
          'transportMethod': 'sql.executeBatch',
          'relayRequested': false,
        },
      );
      return _baseDelegate.postSqlExecuteBatch(
        request,
        cancelScope: cancelScope,
      );
    }
    final relay = _relayDelegate;
    if (relay == null) {
      AppLogger.warning(
        'HybridAgentQueriesRemoteDataSource bypassing relay batch request '
        '(relay datasource not registered)',
        context: <String, Object?>{
          'component': 'HybridAgentQueriesRemoteDataSource',
          'agentId': request.trimmedAgentId,
          'transportRoute': 'base',
          'transportMethod': 'sql.executeBatch',
          'relayRequested': true,
          'reason': 'relay_datasource_missing',
        },
      );
      return _baseDelegate.postSqlExecuteBatch(
        request,
        cancelScope: cancelScope,
      );
    }
    AppLogger.debug(
      'HybridAgentQueriesRemoteDataSource routing sql.executeBatch through '
      'relay',
      context: <String, Object?>{
        'component': 'HybridAgentQueriesRemoteDataSource',
        'agentId': request.trimmedAgentId,
        'transportRoute': 'relay',
        'transportMethod': 'sql.executeBatch',
        'relayRequested': true,
      },
    );
    return relay.postSqlExecuteBatch(request, cancelScope: cancelScope);
  }
}

import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/agent_queries/data/datasources/agent_queries_remote_datasource.dart';
import 'package:colmeia/features/agent_queries/data/datasources/relay_agent_queries_remote_datasource.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';

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
    RelayAgentQueriesRemoteDataSource? relayDelegate,
  }) : _baseDelegate = baseDelegate,
       _relayDelegate = relayDelegate;

  final AgentQueriesRemoteDataSource _baseDelegate;
  final RelayAgentQueriesRemoteDataSource? _relayDelegate;

  @override
  Future<Map<String, dynamic>> postSqlExecute(
    AgentSqlExecuteRequest request,
  ) {
    if (!request.useRelay) {
      return _baseDelegate.postSqlExecute(request);
    }
    final relay = _relayDelegate;
    if (relay == null) {
      AppLogger.warning(
        'HybridAgentQueriesRemoteDataSource bypassing relay request '
        '(relay datasource not registered)',
        context: <String, Object?>{
          'component': 'HybridAgentQueriesRemoteDataSource',
          'agentId': request.trimmedAgentId,
          'reason': 'relay_datasource_missing',
        },
      );
      return _baseDelegate.postSqlExecute(request);
    }
    return relay.postSqlExecute(request);
  }
}

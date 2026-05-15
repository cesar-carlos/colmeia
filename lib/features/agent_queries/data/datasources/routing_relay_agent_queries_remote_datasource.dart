import 'package:colmeia/features/agent_queries/data/datasources/agent_queries_remote_datasource.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_batch_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';

/// Relay datasource selector that keeps `useRelay` separate from the relay
/// execution mode.
class RoutingRelayAgentQueriesRemoteDataSource
    implements AgentQueriesRemoteDataSource {
  RoutingRelayAgentQueriesRemoteDataSource({
    required AgentQueriesRemoteDataSource unaryDelegate,
    required AgentQueriesRemoteDataSource streamingDelegate,
  }) : _unaryDelegate = unaryDelegate,
       _streamingDelegate = streamingDelegate;

  final AgentQueriesRemoteDataSource _unaryDelegate;
  final AgentQueriesRemoteDataSource _streamingDelegate;

  @override
  Future<Map<String, dynamic>> postSqlExecute(
    AgentSqlExecuteRequest request,
  ) {
    return switch (request.relayMode) {
      AgentSqlRelayMode.unary => _unaryDelegate.postSqlExecute(request),
      AgentSqlRelayMode.streaming => _streamingDelegate.postSqlExecute(request),
    };
  }

  @override
  Future<Map<String, dynamic>> postSqlExecuteBatch(
    AgentSqlExecuteBatchRequest request,
  ) {
    return _unaryDelegate.postSqlExecuteBatch(request);
  }
}

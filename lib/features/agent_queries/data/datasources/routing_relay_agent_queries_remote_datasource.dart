import 'package:colmeia/features/agent_queries/data/datasources/agent_queries_remote_datasource.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_batch_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';

/// Relay datasource selector that keeps `useRelay` separate from the relay
/// execution mode.
class RoutingRelayAgentQueriesRemoteDataSource
    implements AgentQueriesRemoteDataSource {
  RoutingRelayAgentQueriesRemoteDataSource({
    required this._unaryDelegate,
    required this._streamingDelegate,
  });

  final AgentQueriesRemoteDataSource _unaryDelegate;
  final AgentQueriesRemoteDataSource _streamingDelegate;

  @override
  Future<Map<String, dynamic>> postSqlExecute(
    AgentSqlExecuteRequest request, {
    AgentQueriesCancelScope? cancelScope,
  }) {
    return switch (request.relayMode) {
      AgentSqlRelayMode.unary => _unaryDelegate.postSqlExecute(
        request,
        cancelScope: cancelScope,
      ),
      AgentSqlRelayMode.streaming => _streamingDelegate.postSqlExecute(
        request,
        cancelScope: cancelScope,
      ),
    };
  }

  @override
  Future<Map<String, dynamic>> postSqlExecuteBatch(
    AgentSqlExecuteBatchRequest request, {
    AgentQueriesCancelScope? cancelScope,
  }) {
    return _unaryDelegate.postSqlExecuteBatch(
      request,
      cancelScope: cancelScope,
    );
  }
}

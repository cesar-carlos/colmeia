import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_batch_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_batch_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:result_dart/result_dart.dart';

/// Wraps a delegate and counts bridge SQL calls for E2E cache-path assertions.
final class E2eCountingAgentQueriesRepository implements AgentQueriesRepository {
  E2eCountingAgentQueriesRepository(this._delegate);

  final AgentQueriesRepository _delegate;
  int executeSqlCallCount = 0;
  int executeSqlBatchCallCount = 0;
  final List<AgentSqlExecuteBatchRequest> batchRequests =
      <AgentSqlExecuteBatchRequest>[];

  @override
  Future<ResultDart<AgentSqlExecutionResult, AppFailure>> executeSql(
    AgentSqlExecuteRequest request, {
    AgentQueriesCancelScope? cancelScope,
  }) {
    executeSqlCallCount++;
    return _delegate.executeSql(request, cancelScope: cancelScope);
  }

  @override
  Future<ResultDart<AgentSqlBatchExecutionResult, AppFailure>> executeSqlBatch(
    AgentSqlExecuteBatchRequest request, {
    AgentQueriesCancelScope? cancelScope,
  }) {
    executeSqlBatchCallCount++;
    batchRequests.add(request);
    return _delegate.executeSqlBatch(request, cancelScope: cancelScope);
  }
}

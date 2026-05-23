import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/socket/per_agent_concurrency_gate.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_batch_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_batch_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';

/// Limits concurrent REST bridge calls per `agentId` before they reach
/// the concrete REST repository implementation (mirrors hub shared rate-limit
/// pressure).
///
/// Construct with a [PerAgentConcurrencyGate] whose cap matches env; the chain
/// factory omits this decorator when the resolved cap is `0`.
class RestInflightAgentQueriesRepository implements AgentQueriesRepository {
  RestInflightAgentQueriesRepository({
    required AgentQueriesRepository delegate,
    required PerAgentConcurrencyGate gate,
  }) : _delegate = delegate,
       _gate = gate;

  final AgentQueriesRepository _delegate;
  final PerAgentConcurrencyGate _gate;

  @override
  Future<AppResult<AgentSqlExecutionResult>> executeSql(
    AgentSqlExecuteRequest request, {
    AgentQueriesCancelScope? cancelScope,
  }) async {
    final id = request.trimmedAgentId;
    if (id.isEmpty) {
      return _delegate.executeSql(request, cancelScope: cancelScope);
    }
    await _gate.acquire(id);
    try {
      return await _delegate.executeSql(request, cancelScope: cancelScope);
    } finally {
      _gate.release(id);
    }
  }

  @override
  Future<AppResult<AgentSqlBatchExecutionResult>> executeSqlBatch(
    AgentSqlExecuteBatchRequest request, {
    AgentQueriesCancelScope? cancelScope,
  }) async {
    final id = request.trimmedAgentId;
    if (id.isEmpty) {
      return _delegate.executeSqlBatch(request, cancelScope: cancelScope);
    }
    await _gate.acquire(id);
    try {
      return await _delegate.executeSqlBatch(request, cancelScope: cancelScope);
    } finally {
      _gate.release(id);
    }
  }
}

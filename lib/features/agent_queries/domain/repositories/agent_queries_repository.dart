import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_batch_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_batch_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';

abstract interface class AgentQueriesRepository {
  /// Runs a single JSON-RPC `sql.execute` through the configured bridge
  /// channel (REST `POST /agents/commands` or `agents:command` on socket).
  ///
  /// Prefer [AgentSqlExecuteRequest.useRelay] set to `true` for large or
  /// streaming-heavy queries when using socket transport — the unary legacy
  /// socket path does not pull `agents:command_stream_*`.
  Future<AppResult<AgentSqlExecutionResult>> executeSql(
    AgentSqlExecuteRequest request,
  );

  /// Runs a single JSON-RPC `sql.executeBatch` through the configured bridge.
  Future<AppResult<AgentSqlBatchExecutionResult>> executeSqlBatch(
    AgentSqlExecuteBatchRequest request,
  );
}

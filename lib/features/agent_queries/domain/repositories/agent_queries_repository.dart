import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';

// Repository will grow with batch and cancel; single execute entry for now.
// ignore: one_member_abstracts
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
}

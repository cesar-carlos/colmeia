import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';

// Repository will grow with batch and cancel; single execute entry for now.
// ignore: one_member_abstracts
abstract interface class AgentQueriesRepository {
  /// Runs a single JSON-RPC `sql.execute` through `POST /agents/commands`.
  Future<AppResult<AgentSqlExecutionResult>> executeSql(
    AgentSqlExecuteRequest request,
  );
}

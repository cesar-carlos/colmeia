import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';

class ExecuteAgentSqlUseCase {
  ExecuteAgentSqlUseCase(this._repository);

  final AgentQueriesRepository _repository;

  Future<AppResult<AgentSqlExecutionResult>> call(
    AgentSqlExecuteRequest request,
  ) {
    return _repository.executeSql(request);
  }
}

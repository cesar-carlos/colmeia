import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_batch_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_batch_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_sql_execution_eligibility_port.dart';
import 'package:result_dart/result_dart.dart';

/// Runs hub-presence eligibility before delegating to the real bridge repository.
class GatedAgentQueriesRepository implements AgentQueriesRepository {
  GatedAgentQueriesRepository({
    required this._delegate,
    required this._eligibility,
  });

  final AgentQueriesRepository _delegate;
  final AgentSqlExecutionEligibilityPort _eligibility;

  bool _loggedMissingRequestingUserId = false;

  @override
  Future<AppResult<AgentSqlExecutionResult>> executeSql(
    AgentSqlExecuteRequest request, {
    AgentQueriesCancelScope? cancelScope,
  }) async {
    final userId = request.trimmedRequestingUserId;
    if (userId == null || userId.isEmpty) {
      if (!_loggedMissingRequestingUserId) {
        _loggedMissingRequestingUserId = true;
        AppLogger.debug(
          'Agent SQL hub-presence gate skipped once: requestingUserId missing '
          '(further skips not logged this session)',
          context: <String, Object?>{
            'operation': 'executeAgentSql',
            'agentId': request.trimmedAgentId,
          },
        );
      }
      return _delegate.executeSql(request, cancelScope: cancelScope);
    }

    final decision = await _eligibility.evaluate(
      userId: userId,
      agentId: request.trimmedAgentId,
      isHubConnected: request.hubConnectedFromApprovedCatalogRow,
      hubPresenceOnlineAgentIdsSnapshot:
          request.hubPresenceOnlineAgentIdsSnapshot,
    );
    if (!decision.allowed) {
      return Failure<AgentSqlExecutionResult, AppFailure>(
        ValidationFailure(
          message: decision.denialReason ?? 'Agent not eligible for SQL.',
          userMessage:
              'Este agente nao esta disponivel para consultas no momento.',
          context: <String, Object?>{
            'operation': 'executeAgentSql',
            'agentId': request.trimmedAgentId,
            'requestingUserId': userId,
            'field': 'agentHubPresence',
          },
        ),
      );
    }
    return _delegate.executeSql(request, cancelScope: cancelScope);
  }

  @override
  Future<AppResult<AgentSqlBatchExecutionResult>> executeSqlBatch(
    AgentSqlExecuteBatchRequest request, {
    AgentQueriesCancelScope? cancelScope,
  }) async {
    final userId = request.trimmedRequestingUserId;
    if (userId == null || userId.isEmpty) {
      return _delegate.executeSqlBatch(request, cancelScope: cancelScope);
    }

    final decision = await _eligibility.evaluate(
      userId: userId,
      agentId: request.trimmedAgentId,
      isHubConnected: request.hubConnectedFromApprovedCatalogRow,
      hubPresenceOnlineAgentIdsSnapshot:
          request.hubPresenceOnlineAgentIdsSnapshot,
    );
    if (!decision.allowed) {
      return Failure<AgentSqlBatchExecutionResult, AppFailure>(
        ValidationFailure(
          message: decision.denialReason ?? 'Agent not eligible for SQL.',
          userMessage:
              'Este agente nao esta disponivel para consultas no momento.',
          context: <String, Object?>{
            'operation': 'executeAgentSqlBatch',
            'agentId': request.trimmedAgentId,
            'requestingUserId': userId,
            'field': 'agentHubPresence',
          },
        ),
      );
    }
    return _delegate.executeSqlBatch(request, cancelScope: cancelScope);
  }
}

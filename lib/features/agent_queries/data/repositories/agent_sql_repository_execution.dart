import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/agent_queries/domain/agent_sql_rpc_failure_ui_key.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:result_dart/result_dart.dart';

/// Shared helpers for concrete Agent SQL repositories.
///
/// This is intentionally a static helper instead of a base class: each
/// repository keeps its own contract and query-specific mapping while common
/// error/result handling stays consistent.
abstract final class AgentSqlRepositoryExecution {
  static const String invalidFiltersUserMessage =
      'Os filtros da consulta sao invalidos.';
  static const String defaultUnexpectedRowsUserMessage =
      'Resposta do agente estava em formato inesperado. Tente novamente.';

  static AppResult<T> invalidFilters<T extends Object>({
    required String message,
    required String operation,
    required String agentId,
    String userMessage = invalidFiltersUserMessage,
  }) {
    return Failure<T, AppFailure>(
      ValidationFailure(
        message: message,
        userMessage: userMessage,
        context: <String, Object?>{
          'operation': operation,
          'agentId': agentId,
        },
      ),
    );
  }

  static Future<AppResult<T>> execute<T extends Object>({
    required AgentQueriesRepository agentQueriesRepository,
    required AgentSqlExecuteRequest request,
    required String operation,
    required String agentId,
    required T Function(AgentSqlExecutionResult executionResult) mapExecution,
    String? unexpectedRowsLogMessage,
    String unexpectedRowsUserMessage = defaultUnexpectedRowsUserMessage,
    String? unexpectedRowsUiKey,
    AgentQueriesCancelScope? cancelScope,
  }) async {
    final result = await agentQueriesRepository.executeSql(
      request,
      cancelScope: cancelScope,
    );
    return result.fold(
      (executionResult) => mapExecutionResult(
        executionResult,
        operation: operation,
        agentId: agentId,
        mapExecution: mapExecution,
        unexpectedRowsLogMessage: unexpectedRowsLogMessage,
        unexpectedRowsUserMessage: unexpectedRowsUserMessage,
        unexpectedRowsUiKey: unexpectedRowsUiKey,
      ),
      Failure<T, AppFailure>.new,
    );
  }

  static AppResult<T> mapExecutionResult<T extends Object>(
    AgentSqlExecutionResult executionResult, {
    required String operation,
    required String agentId,
    required T Function(AgentSqlExecutionResult executionResult) mapExecution,
    String? unexpectedRowsLogMessage,
    String unexpectedRowsUserMessage = defaultUnexpectedRowsUserMessage,
    String? unexpectedRowsUiKey,
  }) {
    try {
      return Success<T, AppFailure>(mapExecution(executionResult));
    } catch (error, stackTrace) {
      if (error is! FormatException && error is! ArgumentError) {
        Error.throwWithStackTrace(error, stackTrace);
      }
      AppLogger.error(
        unexpectedRowsLogMessage ?? 'Unexpected row shape for $operation',
        context: <String, Object?>{
          'operation': operation,
          'agentId': agentId,
        },
        error: error,
        stackTrace: stackTrace,
      );
      final message = error is FormatException
          ? error.message
          : error.toString();
      return Failure<T, AppFailure>(
        UnknownFailure(
          message: message,
          userMessage: unexpectedRowsUiKey == null
              ? unexpectedRowsUserMessage
              : null,
          cause: error,
          stackTrace: stackTrace,
          context: <String, Object?>{
            'operation': operation,
            'agentId': agentId,
            AgentSqlRpcFailureUiKey.field: ?unexpectedRowsUiKey,
          },
        ),
      );
    }
  }
}

import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/agent_queries/data/datasources/agent_queries_remote_datasource.dart';
import 'package:colmeia/features/agent_queries/data/models/agent_sql_bridge_response.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:dio/dio.dart';
import 'package:result_dart/result_dart.dart';

class AgentQueriesRepositoryImpl implements AgentQueriesRepository {
  AgentQueriesRepositoryImpl(this._remoteDataSource);

  final AgentQueriesRemoteDataSource _remoteDataSource;

  @override
  Future<AppResult<AgentSqlExecutionResult>> executeSql(
    AgentSqlExecuteRequest request,
  ) async {
    final validationError = request.validationError();
    if (validationError != null) {
      return Failure<AgentSqlExecutionResult, AppFailure>(
        ValidationFailure(
          message: validationError,
          userMessage: 'Os parametros da consulta do agente sao invalidos.',
          context: <String, Object?>{
            'operation': 'executeAgentSql',
            'agentId': request.trimmedAgentId,
          },
        ),
      );
    }

    try {
      final payload = await _remoteDataSource.postSqlExecute(request);
      final result = AgentSqlBridgeResponse.parseSuccess(payload);
      AppLogger.info(
        'Agent SQL execute completed',
        context: <String, Object?>{
          'operation': 'executeAgentSql',
          'agentId': request.trimmedAgentId,
          'rowCount': result.rowCount,
        },
      );
      return Success<AgentSqlExecutionResult, AppFailure>(result);
    } on AgentSqlRpcException catch (error, stackTrace) {
      AppLogger.warning(
        'Agent SQL RPC reported failure',
        context: <String, Object?>{
          'operation': 'executeAgentSql',
          'agentId': request.trimmedAgentId,
          'rpcCode': error.details.code,
          'reason': error.details.reason,
          'correlationId': error.details.correlationId,
        },
        error: error,
        stackTrace: stackTrace,
      );
      return Failure<AgentSqlExecutionResult, AppFailure>(
        RpcFailure(
          message: error.details.message,
          userMessage: error.details.userMessage,
          rpcCode: error.details.code,
          retryable: error.details.retryable,
          reason: error.details.reason,
          category: error.details.category,
          technicalMessage: error.details.technicalMessage,
          correlationId: error.details.correlationId,
          timestamp: error.details.timestamp,
          cause: error,
          stackTrace: stackTrace,
          context: <String, Object?>{
            'operation': 'executeAgentSql',
            'agentId': request.trimmedAgentId,
            'rpcCode': error.details.code,
            'reason': error.details.reason,
            'category': error.details.category,
            'correlationId': error.details.correlationId,
          },
        ),
      );
    } on FormatException catch (error, stackTrace) {
      AppLogger.error(
        'Unexpected agent SQL bridge response shape',
        context: <String, Object?>{
          'operation': 'executeAgentSql',
          'agentId': request.trimmedAgentId,
        },
        error: error,
        stackTrace: stackTrace,
      );
      return Failure<AgentSqlExecutionResult, AppFailure>(
        UnknownFailure(
          message: error.message,
          userMessage:
              'Resposta do servidor estava em formato inesperado. '
              'Tente novamente.',
          cause: error,
          stackTrace: stackTrace,
          context: <String, Object?>{
            'operation': 'executeAgentSql',
            'agentId': request.trimmedAgentId,
          },
        ),
      );
    } on DioException catch (error, stackTrace) {
      AppLogger.error(
        'Agent SQL HTTP request failed',
        context: <String, Object?>{
          'operation': 'executeAgentSql',
          'agentId': request.trimmedAgentId,
          'statusCode': error.response?.statusCode,
        },
        error: error,
        stackTrace: stackTrace,
      );
      const sqlHttpUserMessage =
          'Nao foi possivel executar a consulta no agente. Tente novamente.';
      return Failure<AgentSqlExecutionResult, AppFailure>(
        mapToAppFailure(
          error,
          stackTrace: stackTrace,
          fallbackMessage: 'Agent SQL request failed',
          fallbackUserMessage: sqlHttpUserMessage,
          context: <String, Object?>{
            'operation': 'executeAgentSql',
            'agentId': request.trimmedAgentId,
          },
        ),
      );
    } on Object catch (error, stackTrace) {
      AppLogger.error(
        'Unexpected error during agent SQL execute',
        context: <String, Object?>{
          'operation': 'executeAgentSql',
          'agentId': request.trimmedAgentId,
        },
        error: error,
        stackTrace: stackTrace,
      );
      return Failure<AgentSqlExecutionResult, AppFailure>(
        UnknownFailure(
          message: error.toString(),
          userMessage:
              'Ocorreu um erro inesperado ao consultar o agente. '
              'Tente novamente.',
          cause: error,
          stackTrace: stackTrace,
          context: <String, Object?>{
            'operation': 'executeAgentSql',
            'agentId': request.trimmedAgentId,
          },
        ),
      );
    }
  }
}

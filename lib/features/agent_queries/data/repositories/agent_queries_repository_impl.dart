import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/core/socket/socket_dispatch_exception.dart';
import 'package:colmeia/features/agent_queries/data/agent_sql_rpc_user_message_resolver.dart';
import 'package:colmeia/features/agent_queries/data/datasources/agent_queries_remote_datasource.dart';
import 'package:colmeia/features/agent_queries/data/models/agent_sql_bridge_response.dart';
import 'package:colmeia/features/agent_queries/domain/agent_sql_rpc_failure_ui_key.dart';
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
      final resolution = resolveAgentSqlRpcUserMessage(error.details);
      final failureContext = <String, Object?>{
        'operation': 'executeAgentSql',
        'agentId': request.trimmedAgentId,
        'rpcCode': error.details.code,
        'reason': error.details.reason,
        'category': error.details.category,
        'correlationId': error.details.correlationId,
      };
      if (resolution.uiKey != null) {
        failureContext[AgentSqlRpcFailureUiKey.field] = resolution.uiKey;
      }
      if (resolution.preferBridgeUserMessage) {
        failureContext[AgentSqlRpcFailureUiKey.preferBridgeUserMessageField] =
            true;
      }
      final errorData = error.details.errorData;
      if (errorData != null) {
        failureContext[AgentSqlRpcFailureUiKey.errorDataField] = errorData;
      }
      AppLogger.warning(
        'Agent SQL RPC reported failure',
        context: failureContext,
        error: error,
        stackTrace: stackTrace,
      );
      return Failure<AgentSqlExecutionResult, AppFailure>(
        RpcFailure(
          message: error.details.message,
          userMessage: resolution.userMessage,
          rpcCode: error.details.code,
          retryable: error.details.retryable,
          reason: error.details.reason,
          category: error.details.category,
          technicalMessage: error.details.technicalMessage,
          correlationId: error.details.correlationId,
          timestamp: error.details.timestamp,
          cause: error,
          stackTrace: stackTrace,
          context: failureContext,
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
    } on SocketDispatchUnauthorized catch (error, stackTrace) {
      AppLogger.warning(
        'Agent SQL Socket dispatch unauthorized',
        context: <String, Object?>{
          'operation': 'executeAgentSql',
          'agentId': request.trimmedAgentId,
          'transport': 'socket',
        },
        error: error,
        stackTrace: stackTrace,
      );
      return Failure<AgentSqlExecutionResult, AppFailure>(
        SessionFailure(
          message: error.message,
          userMessage:
              'Sua sessao expirou. Faca login novamente para continuar.',
          cause: error,
          stackTrace: stackTrace,
          context: <String, Object?>{
            'operation': 'executeAgentSql',
            'agentId': request.trimmedAgentId,
            'transport': 'socket',
            'socketCode': error.code,
          },
        ),
      );
    } on SocketDispatchAppError catch (error, stackTrace) {
      AppLogger.warning(
        'Agent SQL Socket app:error',
        context: <String, Object?>{
          'operation': 'executeAgentSql',
          'agentId': request.trimmedAgentId,
          'transport': 'socket',
          'socketCode': error.code,
        },
        error: error,
        stackTrace: stackTrace,
      );
      const denied = 'AGENT_ACCESS_DENIED';
      if (error.code == denied) {
        return Failure<AgentSqlExecutionResult, AppFailure>(
          AuthorizationFailure(
            message: error.message,
            userMessage: 'Voce nao tem acesso a este agente.',
            cause: error,
            stackTrace: stackTrace,
            context: <String, Object?>{
              'operation': 'executeAgentSql',
              'agentId': request.trimmedAgentId,
              'transport': 'socket',
              'socketCode': error.code,
            },
          ),
        );
      }
      return Failure<AgentSqlExecutionResult, AppFailure>(
        NetworkFailure(
          message: error.message,
          userMessage:
              'O servidor nao conseguiu processar a consulta agora. Tente novamente.',
          cause: error,
          stackTrace: stackTrace,
          context: <String, Object?>{
            'operation': 'executeAgentSql',
            'agentId': request.trimmedAgentId,
            'transport': 'socket',
            'socketCode': error.code,
          },
        ),
      );
    } on SocketDispatchException catch (error, stackTrace) {
      AppLogger.warning(
        'Agent SQL Socket dispatch failed',
        context: <String, Object?>{
          'operation': 'executeAgentSql',
          'agentId': request.trimmedAgentId,
          'transport': 'socket',
          'socketCode': error.code,
        },
        error: error,
        stackTrace: stackTrace,
      );
      return Failure<AgentSqlExecutionResult, AppFailure>(
        NetworkFailure(
          message: error.message,
          userMessage:
              'Falha de comunicacao com o servidor. Tente novamente.',
          cause: error,
          stackTrace: stackTrace,
          context: <String, Object?>{
            'operation': 'executeAgentSql',
            'agentId': request.trimmedAgentId,
            'transport': 'socket',
            'socketCode': error.code,
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

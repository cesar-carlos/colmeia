import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/core/socket/relay/relay_dispatch_exception.dart';
import 'package:colmeia/core/socket/socket_dispatch_exception.dart';
import 'package:colmeia/features/agent_queries/data/agent_sql_rpc_user_message_resolver.dart';
import 'package:colmeia/features/agent_queries/data/datasources/agent_queries_remote_datasource.dart';
import 'package:colmeia/features/agent_queries/data/models/agent_sql_bridge_response.dart';
import 'package:colmeia/features/agent_queries/data/repositories/agent_queries_failure_codes.dart';
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
    } on SocketDispatchCancelled catch (error, stackTrace) {
      // Cancellation is benign: caller (controller in dispose, navigation
      // away, explicit `SocketCommandCancelToken`) requested it. We still
      // emit a Failure so the result is honestly typed, but mark the
      // context with `cancelled: true` so UI controllers can skip the
      // error banner — the screen is already gone.
      AppLogger.debug(
        'Agent SQL Socket dispatch cancelled by caller',
        context: <String, Object?>{
          'operation': 'executeAgentSql',
          'agentId': request.trimmedAgentId,
          AgentQueriesFailureContext.transportField: 'socket',
          'reason': error.message,
        },
      );
      return Failure<AgentSqlExecutionResult, AppFailure>(
        UnknownFailure(
          message: error.message,
          userMessage: 'A consulta foi cancelada.',
          cause: error,
          stackTrace: stackTrace,
          context: <String, Object?>{
            'operation': 'executeAgentSql',
            'agentId': request.trimmedAgentId,
            AgentQueriesFailureContext.transportField: 'socket',
            AgentQueriesFailureContext.transportCodeField: error.code,
            AgentQueriesFailureContext.cancelledField: true,
          },
        ),
      );
    } on SocketDispatchUnauthorized catch (error, stackTrace) {
      AppLogger.warning(
        'Agent SQL Socket dispatch unauthorized',
        context: <String, Object?>{
          'operation': 'executeAgentSql',
          'agentId': request.trimmedAgentId,
          AgentQueriesFailureContext.transportField: 'socket',
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
            AgentQueriesFailureContext.transportField: 'socket',
            AgentQueriesFailureContext.transportCodeField: error.code,
          },
        ),
      );
    } on SocketDispatchAppError catch (error, stackTrace) {
      AppLogger.warning(
        'Agent SQL Socket app:error',
        context: <String, Object?>{
          'operation': 'executeAgentSql',
          'agentId': request.trimmedAgentId,
          AgentQueriesFailureContext.transportField: 'socket',
          AgentQueriesFailureContext.transportCodeField: error.code,
        },
        error: error,
        stackTrace: stackTrace,
      );
      return Failure<AgentSqlExecutionResult, AppFailure>(
        _appErrorToFailure(
          message: error.message,
          serverCode: error.code,
          cause: error,
          stackTrace: stackTrace,
          baseContext: <String, Object?>{
            'operation': 'executeAgentSql',
            'agentId': request.trimmedAgentId,
            AgentQueriesFailureContext.transportField: 'socket',
            AgentQueriesFailureContext.transportCodeField: error.code,
          },
        ),
      );
    } on SocketDispatchException catch (error, stackTrace) {
      AppLogger.warning(
        'Agent SQL Socket dispatch failed',
        context: <String, Object?>{
          'operation': 'executeAgentSql',
          'agentId': request.trimmedAgentId,
          AgentQueriesFailureContext.transportField: 'socket',
          AgentQueriesFailureContext.transportCodeField: error.code,
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
            AgentQueriesFailureContext.transportField: 'socket',
            AgentQueriesFailureContext.transportCodeField: error.code,
          },
        ),
      );
    } on RelayDispatcherDisposed catch (error, stackTrace) {
      // Same semantics as SocketDispatchCancelled: the caller is gone.
      AppLogger.debug(
        'Agent SQL Relay dispatch cancelled (dispatcher disposed)',
        context: <String, Object?>{
          'operation': 'executeAgentSql',
          'agentId': request.trimmedAgentId,
          AgentQueriesFailureContext.transportField: 'relay',
          'conversationId': error.conversationId,
          'clientRequestId': error.clientRequestId,
        },
      );
      return Failure<AgentSqlExecutionResult, AppFailure>(
        UnknownFailure(
          message: error.message,
          userMessage: 'A consulta foi cancelada.',
          cause: error,
          stackTrace: stackTrace,
          context: <String, Object?>{
            'operation': 'executeAgentSql',
            'agentId': request.trimmedAgentId,
            AgentQueriesFailureContext.transportField: 'relay',
            AgentQueriesFailureContext.transportCodeField: error.code,
            AgentQueriesFailureContext.cancelledField: true,
          },
        ),
      );
    } on RelayRequestRejected catch (error, stackTrace) {
      AppLogger.warning(
        'Agent SQL Relay request rejected by hub',
        context: <String, Object?>{
          'operation': 'executeAgentSql',
          'agentId': request.trimmedAgentId,
          AgentQueriesFailureContext.transportField: 'relay',
          AgentQueriesFailureContext.transportCodeField: error.code,
          'conversationId': error.conversationId,
          'clientRequestId': error.clientRequestId,
        },
        error: error,
        stackTrace: stackTrace,
      );
      return Failure<AgentSqlExecutionResult, AppFailure>(
        _appErrorToFailure(
          message: error.message,
          serverCode: error.code,
          cause: error,
          stackTrace: stackTrace,
          baseContext: <String, Object?>{
            'operation': 'executeAgentSql',
            'agentId': request.trimmedAgentId,
            AgentQueriesFailureContext.transportField: 'relay',
            AgentQueriesFailureContext.transportCodeField: error.code,
            'conversationId': error.conversationId,
            'clientRequestId': error.clientRequestId,
          },
        ),
      );
    } on RelayRequestTimeout catch (error, stackTrace) {
      AppLogger.warning(
        'Agent SQL Relay request timed out',
        context: <String, Object?>{
          'operation': 'executeAgentSql',
          'agentId': request.trimmedAgentId,
          AgentQueriesFailureContext.transportField: 'relay',
          AgentQueriesFailureContext.transportCodeField: error.code,
          'conversationId': error.conversationId,
          'clientRequestId': error.clientRequestId,
        },
        error: error,
        stackTrace: stackTrace,
      );
      return Failure<AgentSqlExecutionResult, AppFailure>(
        NetworkFailure(
          message: error.message,
          userMessage:
              'A consulta demorou mais do que o esperado. Tente novamente.',
          cause: error,
          stackTrace: stackTrace,
          context: <String, Object?>{
            'operation': 'executeAgentSql',
            'agentId': request.trimmedAgentId,
            AgentQueriesFailureContext.transportField: 'relay',
            AgentQueriesFailureContext.transportCodeField: error.code,
            'conversationId': error.conversationId,
            'clientRequestId': error.clientRequestId,
          },
        ),
      );
    } on RelayConversationLost catch (error, stackTrace) {
      AppLogger.warning(
        'Agent SQL Relay conversation dropped while pending',
        context: <String, Object?>{
          'operation': 'executeAgentSql',
          'agentId': request.trimmedAgentId,
          AgentQueriesFailureContext.transportField: 'relay',
          AgentQueriesFailureContext.transportCodeField: error.code,
          'conversationId': error.conversationId,
          'clientRequestId': error.clientRequestId,
        },
        error: error,
        stackTrace: stackTrace,
      );
      return Failure<AgentSqlExecutionResult, AppFailure>(
        NetworkFailure(
          message: error.message,
          userMessage:
              'A conexao com o servidor caiu durante a consulta. '
              'Tente novamente.',
          cause: error,
          stackTrace: stackTrace,
          context: <String, Object?>{
            'operation': 'executeAgentSql',
            'agentId': request.trimmedAgentId,
            AgentQueriesFailureContext.transportField: 'relay',
            AgentQueriesFailureContext.transportCodeField: error.code,
            'conversationId': error.conversationId,
            'clientRequestId': error.clientRequestId,
          },
        ),
      );
    } on RelayConversationStartFailure catch (error, stackTrace) {
      AppLogger.warning(
        'Agent SQL Relay conversation could not be started',
        context: <String, Object?>{
          'operation': 'executeAgentSql',
          'agentId': request.trimmedAgentId,
          AgentQueriesFailureContext.transportField: 'relay',
          AgentQueriesFailureContext.transportCodeField: error.code,
        },
        error: error,
        stackTrace: stackTrace,
      );
      return Failure<AgentSqlExecutionResult, AppFailure>(
        NetworkFailure(
          message: error.message,
          userMessage:
              'Nao foi possivel abrir o canal com o servidor para esta '
              'consulta. Tente novamente.',
          cause: error,
          stackTrace: stackTrace,
          context: <String, Object?>{
            'operation': 'executeAgentSql',
            'agentId': request.trimmedAgentId,
            AgentQueriesFailureContext.transportField: 'relay',
            AgentQueriesFailureContext.transportCodeField: error.code,
          },
        ),
      );
    } on RelayStreamTerminated catch (error, stackTrace) {
      AppLogger.warning(
        'Agent SQL Relay stream terminated abnormally',
        context: <String, Object?>{
          'operation': 'executeAgentSql',
          'agentId': request.trimmedAgentId,
          AgentQueriesFailureContext.transportField: 'relay',
          AgentQueriesFailureContext.transportCodeField: error.code,
          'conversationId': error.conversationId,
          'clientRequestId': error.clientRequestId,
        },
        error: error,
        stackTrace: stackTrace,
      );
      return Failure<AgentSqlExecutionResult, AppFailure>(
        NetworkFailure(
          message: error.message,
          userMessage:
              'A consulta foi interrompida antes de terminar. '
              'Tente novamente.',
          cause: error,
          stackTrace: stackTrace,
          context: <String, Object?>{
            'operation': 'executeAgentSql',
            'agentId': request.trimmedAgentId,
            AgentQueriesFailureContext.transportField: 'relay',
            AgentQueriesFailureContext.transportCodeField: error.code,
            'conversationId': error.conversationId,
            'clientRequestId': error.clientRequestId,
          },
        ),
      );
    } on RelayDecodeFailure catch (error, stackTrace) {
      AppLogger.error(
        'Agent SQL Relay PayloadFrame failed structural validation',
        context: <String, Object?>{
          'operation': 'executeAgentSql',
          'agentId': request.trimmedAgentId,
          AgentQueriesFailureContext.transportField: 'relay',
          AgentQueriesFailureContext.transportCodeField: error.code,
          'conversationId': error.conversationId,
          'clientRequestId': error.clientRequestId,
        },
        error: error,
        stackTrace: stackTrace,
      );
      return Failure<AgentSqlExecutionResult, AppFailure>(
        NetworkFailure(
          message: error.message,
          userMessage:
              'A resposta do servidor chegou em formato invalido. '
              'Tente novamente.',
          cause: error,
          stackTrace: stackTrace,
          context: <String, Object?>{
            'operation': 'executeAgentSql',
            'agentId': request.trimmedAgentId,
            AgentQueriesFailureContext.transportField: 'relay',
            AgentQueriesFailureContext.transportCodeField: error.code,
            'conversationId': error.conversationId,
            'clientRequestId': error.clientRequestId,
          },
        ),
      );
    } on RelayDuplicateRequestId catch (error, stackTrace) {
      // Duplicate request id is a programming bug (caller reused a UUID).
      // Log loud + emit UnknownFailure so it surfaces in monitoring.
      AppLogger.error(
        'Agent SQL Relay duplicate clientRequestId on the same conversation',
        context: <String, Object?>{
          'operation': 'executeAgentSql',
          'agentId': request.trimmedAgentId,
          AgentQueriesFailureContext.transportField: 'relay',
          AgentQueriesFailureContext.transportCodeField: error.code,
          'conversationId': error.conversationId,
          'clientRequestId': error.clientRequestId,
        },
        error: error,
        stackTrace: stackTrace,
      );
      return Failure<AgentSqlExecutionResult, AppFailure>(
        UnknownFailure(
          message: error.message,
          userMessage:
              'Ocorreu um erro inesperado ao consultar o agente. '
              'Tente novamente.',
          cause: error,
          stackTrace: stackTrace,
          context: <String, Object?>{
            'operation': 'executeAgentSql',
            'agentId': request.trimmedAgentId,
            AgentQueriesFailureContext.transportField: 'relay',
            AgentQueriesFailureContext.transportCodeField: error.code,
            'conversationId': error.conversationId,
            'clientRequestId': error.clientRequestId,
          },
        ),
      );
    } on RelayDispatchException catch (error, stackTrace) {
      // Catch-all for any future relay variant we add (the sealed class is
      // not exhaustively pattern-matched here because Dart only enforces
      // exhaustiveness in switch expressions, not in catch chains). Keeps
      // the user out of the generic `on Object` branch.
      AppLogger.warning(
        'Agent SQL Relay dispatch failed (unmapped variant)',
        context: <String, Object?>{
          'operation': 'executeAgentSql',
          'agentId': request.trimmedAgentId,
          AgentQueriesFailureContext.transportField: 'relay',
          AgentQueriesFailureContext.transportCodeField: error.code,
          'conversationId': error.conversationId,
          'clientRequestId': error.clientRequestId,
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
            AgentQueriesFailureContext.transportField: 'relay',
            AgentQueriesFailureContext.transportCodeField: error.code,
            'conversationId': error.conversationId,
            'clientRequestId': error.clientRequestId,
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

  /// Maps a server-emitted error code (from `SocketDispatchAppError` or
  /// `RelayRequestRejected`) to the right [AppFailure] variant. Handles:
  ///
  /// - **Authentication-failed codes** (`UNAUTHORIZED`, `INVALID_TOKEN`, …) ->
  ///   `SessionFailure` so the UX prompts re-login.
  /// - **Authorization-denied codes** (`AGENT_ACCESS_DENIED`, `FORBIDDEN`, …)
  ///   -> `AuthorizationFailure` so the UX shows "no access to this agent".
  /// - **Anything else** -> `NetworkFailure` (generic "server could not
  ///   process now"), preserving the original code in the failure context.
  AppFailure _appErrorToFailure({
    required String message,
    required String serverCode,
    required Object cause,
    required StackTrace stackTrace,
    required Map<String, Object?> baseContext,
  }) {
    if (isSocketAuthenticationFailedCode(serverCode)) {
      return SessionFailure(
        message: message,
        userMessage:
            'Sua sessao expirou. Faca login novamente para continuar.',
        cause: cause,
        stackTrace: stackTrace,
        context: baseContext,
      );
    }
    if (isSocketAuthorizationDeniedCode(serverCode)) {
      return AuthorizationFailure(
        message: message,
        userMessage: 'Voce nao tem acesso a este agente.',
        cause: cause,
        stackTrace: stackTrace,
        context: baseContext,
      );
    }
    return NetworkFailure(
      message: message,
      userMessage:
          'O servidor nao conseguiu processar a consulta agora. '
          'Tente novamente.',
      cause: cause,
      stackTrace: stackTrace,
      context: baseContext,
    );
  }
}

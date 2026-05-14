import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/core/socket/relay/relay_dispatch_exception.dart';
import 'package:colmeia/core/socket/socket_dispatch_exception.dart';
import 'package:colmeia/features/agent_queries/data/agent_sql_rpc_user_message_resolver.dart';
import 'package:colmeia/features/agent_queries/data/datasources/agent_queries_remote_datasource.dart';
import 'package:colmeia/features/agent_queries/data/models/agent_sql_bridge_response.dart';
import 'package:colmeia/features/agent_queries/data/repositories/agent_queries_transport_failure_mapper.dart';
import 'package:colmeia/features/agent_queries/domain/agent_sql_rpc_failure_ui_key.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_batch_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_batch_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:dio/dio.dart';
import 'package:result_dart/result_dart.dart';

class AgentQueriesRepositoryImpl implements AgentQueriesRepository {
  AgentQueriesRepositoryImpl(this._remoteDataSource);

  final AgentQueriesRemoteDataSource _remoteDataSource;
  static const _transportFailureMapper = AgentQueriesTransportFailureMapper();

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
          retryAfter: _readRetryAfterFromErrorData(error.details.errorData),
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
      const sqlHttpUserMessage =
          'Nao foi possivel executar a consulta no agente. Tente novamente.';
      final failure = mapToAppFailure(
        error,
        stackTrace: stackTrace,
        fallbackMessage: 'Agent SQL request failed',
        fallbackUserMessage: sqlHttpUserMessage,
        context: <String, Object?>{
          'operation': 'executeAgentSql',
          'agentId': request.trimmedAgentId,
        },
      );
      AppLogger.error(
        'Agent SQL HTTP request failed',
        context: <String, Object?>{
          'operation': 'executeAgentSql',
          'agentId': request.trimmedAgentId,
          'statusCode': error.response?.statusCode,
          'failureType': failure.runtimeType.toString(),
          ...failure.context,
        },
        error: error,
        stackTrace: stackTrace,
      );
      return Failure<AgentSqlExecutionResult, AppFailure>(failure);
    } on SocketDispatchException catch (error, stackTrace) {
      final failure = _transportFailureMapper.mapSocket(
        error: error,
        stackTrace: stackTrace,
        operation: 'executeAgentSql',
        agentId: request.trimmedAgentId,
      );
      _transportFailureMapper.logDispatchFailure(
        message: 'Agent SQL Socket dispatch failed',
        error: error,
        stackTrace: stackTrace,
        failure: failure,
      );
      return Failure<AgentSqlExecutionResult, AppFailure>(failure);
    } on RelayDispatchException catch (error, stackTrace) {
      final failure = _transportFailureMapper.mapRelay(
        error: error,
        stackTrace: stackTrace,
        operation: 'executeAgentSql',
        agentId: request.trimmedAgentId,
      );
      _transportFailureMapper.logDispatchFailure(
        message: 'Agent SQL Relay dispatch failed',
        error: error,
        stackTrace: stackTrace,
        failure: failure,
      );
      return Failure<AgentSqlExecutionResult, AppFailure>(failure);
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

  @override
  Future<AppResult<AgentSqlBatchExecutionResult>> executeSqlBatch(
    AgentSqlExecuteBatchRequest request,
  ) async {
    final validationError = request.validationError();
    if (validationError != null) {
      return Failure<AgentSqlBatchExecutionResult, AppFailure>(
        ValidationFailure(
          message: validationError,
          userMessage: 'Os parametros do lote do agente sao invalidos.',
          context: <String, Object?>{
            'operation': 'executeAgentSqlBatch',
            'agentId': request.trimmedAgentId,
          },
        ),
      );
    }

    try {
      final payload = await _remoteDataSource.postSqlExecuteBatch(request);
      final result = AgentSqlBridgeResponse.parseBatchSuccess(payload);
      AppLogger.info(
        'Agent SQL batch execute completed',
        context: <String, Object?>{
          'operation': 'executeAgentSqlBatch',
          'agentId': request.trimmedAgentId,
          'totalCommands': result.totalCommands,
          'failedCommands': result.failedCommands,
        },
      );
      return Success<AgentSqlBatchExecutionResult, AppFailure>(result);
    } on AgentSqlRpcException catch (error, stackTrace) {
      final resolution = resolveAgentSqlRpcUserMessage(error.details);
      final failureContext = <String, Object?>{
        'operation': 'executeAgentSqlBatch',
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
      return Failure<AgentSqlBatchExecutionResult, AppFailure>(
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
          retryAfter: _readRetryAfterFromErrorData(error.details.errorData),
          cause: error,
          stackTrace: stackTrace,
          context: failureContext,
        ),
      );
    } on FormatException catch (error, stackTrace) {
      return Failure<AgentSqlBatchExecutionResult, AppFailure>(
        UnknownFailure(
          message: error.message,
          userMessage:
              'Resposta do servidor estava em formato inesperado. '
              'Tente novamente.',
          cause: error,
          stackTrace: stackTrace,
          context: <String, Object?>{
            'operation': 'executeAgentSqlBatch',
            'agentId': request.trimmedAgentId,
          },
        ),
      );
    } on DioException catch (error, stackTrace) {
      final failure = mapToAppFailure(
        error,
        stackTrace: stackTrace,
        fallbackMessage: 'Agent SQL batch request failed',
        fallbackUserMessage:
            'Nao foi possivel executar o lote no agente. Tente novamente.',
        context: <String, Object?>{
          'operation': 'executeAgentSqlBatch',
          'agentId': request.trimmedAgentId,
        },
      );
      return Failure<AgentSqlBatchExecutionResult, AppFailure>(failure);
    } on SocketDispatchException catch (error, stackTrace) {
      final failure = _transportFailureMapper.mapSocket(
        error: error,
        stackTrace: stackTrace,
        operation: 'executeAgentSqlBatch',
        agentId: request.trimmedAgentId,
      );
      _transportFailureMapper.logDispatchFailure(
        message: 'Agent SQL batch Socket dispatch failed',
        error: error,
        stackTrace: stackTrace,
        failure: failure,
      );
      return Failure<AgentSqlBatchExecutionResult, AppFailure>(failure);
    } on RelayDispatchException catch (error, stackTrace) {
      final failure = _transportFailureMapper.mapRelay(
        error: error,
        stackTrace: stackTrace,
        operation: 'executeAgentSqlBatch',
        agentId: request.trimmedAgentId,
      );
      _transportFailureMapper.logDispatchFailure(
        message: 'Agent SQL batch Relay dispatch failed',
        error: error,
        stackTrace: stackTrace,
        failure: failure,
      );
      return Failure<AgentSqlBatchExecutionResult, AppFailure>(failure);
    } on Object catch (error, stackTrace) {
      return Failure<AgentSqlBatchExecutionResult, AppFailure>(
        mapToAppFailure(
          error,
          stackTrace: stackTrace,
          fallbackMessage: 'Unexpected error during agent SQL batch execute',
          fallbackUserMessage:
              'Ocorreu um erro inesperado ao consultar o agente. '
              'Tente novamente.',
          context: <String, Object?>{
            'operation': 'executeAgentSqlBatch',
            'agentId': request.trimmedAgentId,
          },
        ),
      );
    }
  }

  /// Pulls a `Duration` out of the JSON-RPC `error.data` block when the
  /// agent (or hub) propagates the rate-limit hint that ships with
  /// `-32013` and friends. Tolerates both `retry_after_ms` (snake) and
  /// `retryAfterMs` (camel), plus a `reset_at` ISO date as last
  /// resort. Returns `null` when nothing usable is present so the
  /// caller can leave `RpcFailure.retryAfter` unset.
  Duration? _readRetryAfterFromErrorData(Map<String, dynamic>? errorData) {
    if (errorData == null || errorData.isEmpty) {
      return null;
    }
    final ms = errorData['retry_after_ms'] ?? errorData['retryAfterMs'];
    final fromMs = _durationFromMs(ms);
    if (fromMs != null) {
      return fromMs;
    }
    final resetAt = errorData['reset_at'] ?? errorData['resetAt'];
    if (resetAt is String) {
      final parsed = DateTime.tryParse(resetAt);
      if (parsed != null) {
        final delta = parsed.toUtc().difference(DateTime.now().toUtc());
        if (delta.isNegative) {
          return Duration.zero;
        }
        return delta;
      }
    }
    return null;
  }

  Duration? _durationFromMs(Object? raw) {
    if (raw == null) {
      return null;
    }
    if (raw is num) {
      final ms = raw.toInt();
      if (ms < 0) {
        return Duration.zero;
      }
      return Duration(milliseconds: ms);
    }
    if (raw is String) {
      final parsed = int.tryParse(raw.trim());
      if (parsed == null) {
        return null;
      }
      if (parsed < 0) {
        return Duration.zero;
      }
      return Duration(milliseconds: parsed);
    }
    return null;
  }
}

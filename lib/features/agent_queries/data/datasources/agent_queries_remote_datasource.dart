import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/core/network/api_routes.dart';
import 'package:colmeia/core/observability/socket/server_timings.dart';
import 'package:colmeia/features/agent_queries/data/agent_sql_execute_batch_request_to_bridge_body.dart';
import 'package:colmeia/features/agent_queries/data/agent_sql_execute_request_to_bridge_body.dart';
import 'package:colmeia/features/agent_queries/domain/agent_sql_http_receive_timeout.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_bridge_pagination.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_batch_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

// Split into API vs fake implementations for DI; more methods may follow.
abstract interface class AgentQueriesRemoteDataSource {
  Future<Map<String, dynamic>> postSqlExecute(
    AgentSqlExecuteRequest request, {
    AgentQueriesCancelScope? cancelScope,
  });

  Future<Map<String, dynamic>> postSqlExecuteBatch(
    AgentSqlExecuteBatchRequest request, {
    AgentQueriesCancelScope? cancelScope,
  });
}

class ApiAgentQueriesRemoteDataSource implements AgentQueriesRemoteDataSource {
  ApiAgentQueriesRemoteDataSource({
    required Dio dio,
    AgentSqlExecuteRequestToBridgeBody bodyMapper =
        const AgentSqlExecuteRequestToBridgeBody(),
    AgentSqlExecuteBatchRequestToBridgeBody batchBodyMapper =
        const AgentSqlExecuteBatchRequestToBridgeBody(),
    void Function(ServerTimings)? onServerTimings,
  }) : _dio = dio,
       _bodyMapper = bodyMapper,
       _batchBodyMapper = batchBodyMapper,
       _onServerTimings = onServerTimings;

  final Dio _dio;
  final AgentSqlExecuteRequestToBridgeBody _bodyMapper;
  final AgentSqlExecuteBatchRequestToBridgeBody _batchBodyMapper;
  final void Function(ServerTimings)? _onServerTimings;
  static const Uuid _uuid = Uuid();

  Map<String, Object?> _withServerTimingsFlag(Map<String, Object?> body) {
    if (!AppEnvironment.socketRequestServerTimingsEnabled) {
      return body;
    }
    return <String, Object?>{...body, 'requestServerTimings': true};
  }

  void _maybeRecordServerTimings(Map<String, dynamic>? payload) {
    final timings = ServerTimings.tryParseFromEnvelope(payload);
    if (timings != null) {
      _onServerTimings?.call(timings);
    }
  }

  DioException _restRequestCancelled(String operation) {
    return DioException(
      requestOptions: RequestOptions(path: AgentCommandsApiRoutes.commands),
      type: DioExceptionType.cancel,
      message: '$operation skipped: AgentQueriesCancelScope already cancelled',
    );
  }

  Future<Map<String, dynamic>> _postBridgeCommand({
    required Map<String, Object?> body,
    required int? bridgeTimeoutMs,
    required String operation,
    AgentQueriesCancelScope? cancelScope,
  }) async {
    if (cancelScope?.isCancelled ?? false) {
      throw _restRequestCancelled(operation);
    }

    CancelToken? cancelToken;
    void Function()? untrackRest;
    if (cancelScope != null) {
      cancelToken = CancelToken();
      void cancelRequest() {
        if (!cancelToken!.isCancelled) {
          cancelToken.cancel(
            '$operation aborted: AgentQueriesCancelScope cancelled',
          );
        }
      }

      untrackRest = cancelRequest;
      cancelScope.trackRestPending(cancelRequest);
    }

    try {
      final receiveTimeout = agentSqlHttpReceiveTimeout(
        bridgeTimeoutMs: bridgeTimeoutMs,
      );
      final response = await _dio.post<Map<String, dynamic>>(
        AgentCommandsApiRoutes.commands,
        data: body,
        options: Options(
          receiveTimeout: receiveTimeout,
          sendTimeout: receiveTimeout,
        ),
        cancelToken: cancelToken,
      );

      final payload = response.data;
      if (payload == null) {
        AppLogger.warning(
          operation == 'postSqlExecuteBatch'
              ? 'Agent SQL batch bridge returned null JSON body'
              : 'Agent SQL bridge returned null JSON body',
          context: <String, Object?>{
            'operation': operation,
            'path': AgentCommandsApiRoutes.commands,
            'statusCode': response.statusCode,
          },
        );
      } else if (payload.isEmpty && operation == 'postSqlExecute') {
        AppLogger.debug(
          'Agent SQL bridge returned empty JSON object',
          context: <String, Object?>{
            'operation': operation,
            'path': AgentCommandsApiRoutes.commands,
            'statusCode': response.statusCode,
          },
        );
      }

      _maybeRecordServerTimings(payload);
      return payload ?? const <String, dynamic>{};
    } finally {
      if (untrackRest != null) {
        cancelScope?.untrackRestPending(untrackRest);
      }
    }
  }

  @override
  Future<Map<String, dynamic>> postSqlExecute(
    AgentSqlExecuteRequest request, {
    AgentQueriesCancelScope? cancelScope,
  }) {
    final rpcId = request.transportRpcId ?? _uuid.v4();
    final body = _withServerTimingsFlag(
      _bodyMapper.build(request: request, rpcId: rpcId),
    );

    return _postBridgeCommand(
      body: body,
      bridgeTimeoutMs: request.bridgeTimeoutMs,
      operation: 'postSqlExecute',
      cancelScope: cancelScope,
    );
  }

  @override
  Future<Map<String, dynamic>> postSqlExecuteBatch(
    AgentSqlExecuteBatchRequest request, {
    AgentQueriesCancelScope? cancelScope,
  }) {
    final rpcId = request.transportRpcId ?? _uuid.v4();
    final body = _withServerTimingsFlag(
      _batchBodyMapper.build(request: request, rpcId: rpcId),
    );

    return _postBridgeCommand(
      body: body,
      bridgeTimeoutMs: request.bridgeTimeoutMs,
      operation: 'postSqlExecuteBatch',
      cancelScope: cancelScope,
    );
  }
}

/// Deterministic bridge-shaped payloads for local / fake backend runs.
/// RPC error paths are covered by `AgentSqlBridgeResponse` unit tests and e2e
/// runs against the real hub.
class FakeAgentQueriesRemoteDataSource implements AgentQueriesRemoteDataSource {
  @override
  Future<Map<String, dynamic>> postSqlExecute(
    AgentSqlExecuteRequest request, {
    AgentQueriesCancelScope? cancelScope,
  }) async {
    Map<String, dynamic>? paginationResult;
    final pagination = request.pagination;
    if (pagination is AgentSqlPagePagination) {
      paginationResult = <String, dynamic>{
        'page': pagination.page,
        'page_size': pagination.pageSize,
        'returned_rows': 1,
        'has_next_page': false,
        'has_previous_page': pagination.page > 1,
      };
    } else if (pagination is AgentSqlCursorPagination) {
      paginationResult = <String, dynamic>{
        'returned_rows': 1,
        'has_next_page': false,
        'has_previous_page': false,
        'current_cursor': pagination.cursor,
      };
    }

    return <String, dynamic>{
      'mode': 'bridge',
      'agentId': request.trimmedAgentId,
      'requestId': 'fake-request',
      'response': <String, dynamic>{
        'type': 'single',
        'success': true,
        'item': <String, dynamic>{
          'id': 'fake-rpc',
          'success': true,
          'result': <String, dynamic>{
            'execution_id': 'fake-exec',
            'started_at': DateTime.now().toUtc().toIso8601String(),
            'finished_at': DateTime.now().toUtc().toIso8601String(),
            'rows': <Map<String, dynamic>>[
              <String, dynamic>{
                'sql_preview': _normalizeSqlForRpc(request.trimmedSql),
                'fake': true,
                'named_params_empty': request.namedParams.isEmpty,
                'execute_options_empty': request.executeOptions == null,
              },
            ],
            'row_count': 1,
            'affected_rows': 0,
            'pagination': ?paginationResult,
          },
        },
      },
    };
  }

  @override
  Future<Map<String, dynamic>> postSqlExecuteBatch(
    AgentSqlExecuteBatchRequest request, {
    AgentQueriesCancelScope? cancelScope,
  }) async {
    return <String, dynamic>{
      'mode': 'bridge',
      'agentId': request.trimmedAgentId,
      'requestId': 'fake-batch-request',
      'response': <String, dynamic>{
        'type': 'single',
        'success': true,
        'item': <String, dynamic>{
          'id': 'fake-batch-rpc',
          'success': true,
          'result': <String, dynamic>{
            'execution_id': 'fake-batch-exec',
            'started_at': DateTime.now().toUtc().toIso8601String(),
            'finished_at': DateTime.now().toUtc().toIso8601String(),
            'items': <Map<String, dynamic>>[
              for (var i = 0; i < request.commands.length; i++)
                <String, dynamic>{
                  'index': i,
                  'ok': true,
                  'rows': <Map<String, dynamic>>[
                    <String, dynamic>{
                      'sql_preview': normalizeSqlForBatchRpc(
                        request.commands[i].trimmedSql,
                      ),
                      'fake': true,
                      'named_params_empty':
                          request.commands[i].namedParams.isEmpty,
                    },
                  ],
                  'row_count': 1,
                  'affected_rows': 0,
                },
            ],
            'total_commands': request.commands.length,
            'successful_commands': request.commands.length,
            'failed_commands': 0,
          },
        },
      },
    };
  }
}

String _normalizeSqlForRpc(String sql) =>
    sql.replaceAll(RegExp(r'\s*\r?\n\s*'), ' ').trim();

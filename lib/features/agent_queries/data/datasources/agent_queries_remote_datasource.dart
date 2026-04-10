import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/core/network/api_routes.dart';
import 'package:colmeia/features/agent_queries/domain/agent_sql_http_receive_timeout.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_bridge_pagination.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

// Split into API vs fake implementations for DI; more methods may follow.
// ignore: one_member_abstracts
abstract interface class AgentQueriesRemoteDataSource {
  Future<Map<String, dynamic>> postSqlExecute(AgentSqlExecuteRequest request);
}

class ApiAgentQueriesRemoteDataSource implements AgentQueriesRemoteDataSource {
  ApiAgentQueriesRemoteDataSource(this._dio);

  final Dio _dio;
  static const Uuid _uuid = Uuid();

  @override
  Future<Map<String, dynamic>> postSqlExecute(
    AgentSqlExecuteRequest request,
  ) async {
    final rpcId = _uuid.v4();
    final trimmedToken = request.trimmedClientToken;
    final rpcOptions = request.executeOptions?.toRpcOptions();
    final params = <String, Object?>{
      'sql': _normalizeSqlForRpc(request.trimmedSql),
      'params': ?(request.namedParams.isEmpty ? null : request.namedParams),
      'client_token': ?(trimmedToken == null || trimmedToken.isEmpty
          ? null
          : trimmedToken),
      'options': ?rpcOptions,
    };

    final body = <String, Object?>{
      'agentId': request.trimmedAgentId,
      'timeoutMs': ?request.bridgeTimeoutMs,
      'pagination': ?request.pagination?.toHttpBody(),
      'command': <String, Object?>{
        'jsonrpc': '2.0',
        'method': 'sql.execute',
        'id': rpcId,
        'params': params,
      },
    };

    final receiveTimeout = agentSqlHttpReceiveTimeout(
      bridgeTimeoutMs: request.bridgeTimeoutMs,
    );
    final response = await _dio.post<Map<String, dynamic>>(
      AgentCommandsApiRoutes.commands,
      data: body,
      options: Options(
        receiveTimeout: receiveTimeout,
        sendTimeout: receiveTimeout,
      ),
    );

    final payload = response.data;
    if (payload == null) {
      AppLogger.warning(
        'Agent SQL bridge returned null JSON body',
        context: <String, Object?>{
          'operation': 'postSqlExecute',
          'path': AgentCommandsApiRoutes.commands,
          'statusCode': response.statusCode,
        },
      );
    } else if (payload.isEmpty) {
      AppLogger.debug(
        'Agent SQL bridge returned empty JSON object',
        context: <String, Object?>{
          'operation': 'postSqlExecute',
          'path': AgentCommandsApiRoutes.commands,
          'statusCode': response.statusCode,
        },
      );
    }

    return payload ?? const <String, dynamic>{};
  }
}

/// Deterministic bridge-shaped payloads for local / fake backend runs.
/// RPC error paths are covered by `AgentSqlBridgeResponse` unit tests and e2e
/// runs against the real hub.
class FakeAgentQueriesRemoteDataSource implements AgentQueriesRemoteDataSource {
  @override
  Future<Map<String, dynamic>> postSqlExecute(
    AgentSqlExecuteRequest request,
  ) async {
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
}

String _normalizeSqlForRpc(String sql) =>
    sql.replaceAll(RegExp(r'\s*\r?\n\s*'), ' ').trim();

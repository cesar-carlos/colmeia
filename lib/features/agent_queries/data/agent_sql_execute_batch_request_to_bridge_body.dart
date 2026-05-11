import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_batch_request.dart';

class AgentSqlExecuteBatchRequestToBridgeBody {
  const AgentSqlExecuteBatchRequestToBridgeBody();

  Map<String, Object?> build({
    required AgentSqlExecuteBatchRequest request,
    required String rpcId,
  }) {
    final trimmedToken = request.trimmedClientToken;
    final clientToken = trimmedToken == null || trimmedToken.isEmpty
        ? null
        : trimmedToken;
    final payloadFrameCompression = request.payloadFrameCompression?.wireValue;
    final apiVersion = request.apiVersion.trim();

    return <String, Object?>{
      'agentId': request.trimmedAgentId,
      'timeoutMs': ?request.bridgeTimeoutMs,
      'payloadFrameCompression': ?payloadFrameCompression,
      'command': <String, Object?>{
        'jsonrpc': '2.0',
        'method': 'sql.executeBatch',
        'id': rpcId,
        if (apiVersion.isNotEmpty) 'api_version': apiVersion,
        'params': <String, Object?>{
          'commands': <Map<String, Object?>>[
            for (final command in request.commands)
              <String, Object?>{
                'sql': _normalizeSqlForRpc(command.trimmedSql),
                if (command.namedParams.isNotEmpty)
                  'params': command.namedParams,
                'execution_order': ?command.executionOrder,
              },
          ],
          'client_token': ?clientToken,
          'options': ?request.options?.toRpcOptions(),
        },
      },
    };
  }
}

String normalizeSqlForBatchRpc(String sql) => _normalizeSqlForRpc(sql);

String _normalizeSqlForRpc(String sql) =>
    sql.replaceAll(RegExp(r'\s*\r?\n\s*'), ' ').trim();

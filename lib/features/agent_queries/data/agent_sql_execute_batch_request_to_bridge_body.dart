import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_batch_request.dart';
import 'package:uuid/uuid.dart';

class AgentSqlExecuteBatchRequestToBridgeBody {
  const AgentSqlExecuteBatchRequestToBridgeBody();

  /// Builds the REST/`agents:command` bridge body.
  ///
  /// Relay (`relay:rpc.request`) sends only [buildRelayCommand] as the
  /// PayloadFrame logical payload.
  Map<String, Object?> build({
    required AgentSqlExecuteBatchRequest request,
    required String rpcId,
  }) {
    final payloadFrameCompression = request.payloadFrameCompression?.wireValue;

    return <String, Object?>{
      'agentId': request.trimmedAgentId,
      'timeoutMs': ?request.bridgeTimeoutMs,
      'payloadFrameCompression': ?payloadFrameCompression,
      'command': buildRelayCommand(request: request, rpcId: rpcId),
    };
  }

  /// Builds the single JSON-RPC command required by `relay:rpc.request`.
  Map<String, Object?> buildRelayCommand({
    required AgentSqlExecuteBatchRequest request,
    required String rpcId,
    String? traceId,
  }) {
    final trimmedToken = request.trimmedClientToken;
    final clientToken = trimmedToken == null || trimmedToken.isEmpty
        ? null
        : trimmedToken;
    final apiVersion = request.apiVersion.trim();

    return <String, Object?>{
      'jsonrpc': '2.0',
      'method': 'sql.executeBatch',
      'id': rpcId,
      if (apiVersion.isNotEmpty) 'api_version': apiVersion,
      'meta': <String, Object?>{
        'trace_id': traceId ?? const Uuid().v4(),
      },
      'params': <String, Object?>{
        'commands': <Map<String, Object?>>[
          for (final command in request.commands)
            <String, Object?>{
              'sql': _normalizeSqlForRpc(command.trimmedSql),
              if (command.namedParams.isNotEmpty) 'params': command.namedParams,
              'execution_order': ?command.executionOrder,
            },
        ],
        'client_token': ?clientToken,
        'options': ?request.options?.toRpcOptions(),
      },
    };
  }
}

String normalizeSqlForBatchRpc(String sql) => _normalizeSqlForRpc(sql);

String _normalizeSqlForRpc(String sql) =>
    sql.replaceAll(RegExp(r'\s*\r?\n\s*'), ' ').trim();

import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';

/// Maps an [AgentSqlExecuteRequest] into the bridge body shared by both
/// transports:
///
/// - REST: body of `POST /api/v1/agents/commands`.
/// - Socket: payload of the `agents:command` event on the `/consumers`
///   namespace.
///
/// Keeping a single mapper guarantees byte-for-byte parity between channels;
/// any divergence is a bug. Snapshot tests in
/// `test/features/agent_queries/data/agent_sql_execute_request_to_bridge_body_test.dart`
/// pin the wire format.
class AgentSqlExecuteRequestToBridgeBody {
  const AgentSqlExecuteRequestToBridgeBody();

  /// Builds the full body to send. The caller passes the already-generated
  /// JSON-RPC `command.id` ([rpcId]) so the same id can be used to correlate
  /// the response — [rpcId] must NOT be generated inside this helper.
  Map<String, Object?> build({
    required AgentSqlExecuteRequest request,
    required String rpcId,
  }) {
    final trimmedToken = request.trimmedClientToken;
    final rpcOptions = request.executeOptions?.toRpcOptions();
    final namedParams = request.namedParams.isEmpty
        ? null
        : request.namedParams;
    final clientToken = trimmedToken == null || trimmedToken.isEmpty
        ? null
        : trimmedToken;

    final params = <String, Object?>{
      'sql': _normalizeSqlForRpc(request.trimmedSql),
      'params': ?namedParams,
      'client_token': ?clientToken,
      'options': ?rpcOptions,
    };

    return <String, Object?>{
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
  }
}

String _normalizeSqlForRpc(String sql) =>
    sql.replaceAll(RegExp(r'\s*\r?\n\s*'), ' ').trim();

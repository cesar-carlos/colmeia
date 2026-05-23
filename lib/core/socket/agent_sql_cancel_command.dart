/// Builds bridge bodies for hub `sql.cancel` (latency-critical; bypasses batch).
abstract final class AgentSqlCancelCommand {
  static Map<String, Object?> build({
    required String agentId,
    required String rpcId,
    required String streamId,
    String? clientToken,
  }) {
    final trimmedToken = clientToken?.trim();
    return <String, Object?>{
      'agentId': agentId.trim(),
      'command': <String, Object?>{
        'jsonrpc': '2.0',
        'method': 'sql.cancel',
        'id': rpcId,
        'params': <String, Object?>{
          'stream_id': streamId.trim(),
          if (trimmedToken != null && trimmedToken.isNotEmpty)
            'client_token': trimmedToken,
        },
      },
    };
  }
}

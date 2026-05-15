/// Converts relay JSON-RPC responses into the bridge envelope expected by
/// `AgentSqlBridgeResponse`.
Map<String, dynamic> relayJsonRpcToBridgeEnvelope(
  Map<String, dynamic> payload, {
  required String responseType,
}) {
  final response = payload['response'];
  if (response is Map) {
    final responseMap = Map<String, dynamic>.from(response);
    return <String, dynamic>{
      ...payload,
      'response': <String, dynamic>{
        ...responseMap,
        'success': responseMap['success'] ?? true,
      },
    };
  }

  if (!isRelayJsonRpcResponse(payload)) {
    throw const FormatException(
      'Relay SQL response must be bridge-shaped or a JSON-RPC response',
    );
  }

  final id = payload['id']?.toString();
  final error = payload['error'];
  if (payload.containsKey('error') && error is! Map) {
    throw const FormatException('Relay SQL JSON-RPC error must be an object');
  }
  if (error is Map) {
    return <String, dynamic>{
      'response': <String, dynamic>{
        'success': true,
        'type': responseType,
        'item': <String, dynamic>{
          'id': ?id,
          'success': false,
          'error': Map<String, dynamic>.from(error),
        },
      },
    };
  }

  final result = payload['result'];
  if (result is! Map) {
    throw const FormatException('Relay SQL JSON-RPC result must be an object');
  }
  return <String, dynamic>{
    'response': <String, dynamic>{
      'success': true,
      'type': responseType,
      'item': <String, dynamic>{
        'id': ?id,
        'success': true,
        'result': Map<String, dynamic>.from(result),
      },
    },
  };
}

bool isRelayJsonRpcResponse(Map<String, dynamic> payload) {
  return payload['jsonrpc'] == '2.0' &&
      (payload.containsKey('result') || payload.containsKey('error'));
}

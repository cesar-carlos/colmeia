/// Resolves the JSON-RPC body accepted by relay callers.
///
/// Relay sends the command directly, while legacy callers may retain the REST
/// envelope under `command`. Consumers validate the resolved method and
/// parameters according to their own protocol needs.
Map<dynamic, dynamic>? resolveRelayRpcBody(Map<String, Object?> body) {
  final directMethod = body['method'];
  if (directMethod is String && directMethod.isNotEmpty) {
    return body;
  }
  final nested = body['command'];
  if (nested is Map) {
    return nested;
  }
  return null;
}

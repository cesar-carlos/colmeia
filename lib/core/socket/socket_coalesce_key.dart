import 'dart:convert';

/// Pure helper that produces a **stable** identifier for an
/// `agents:command` body so identical concurrent requests can be
/// deduplicated by the dispatcher (review §5.1, P1).
///
/// Two requests are coalesced when:
///
/// - they target the same `agentId`;
/// - they call the same JSON-RPC `method`;
/// - they share the same `params` (deep equality, key-order independent);
/// - they share the same body-level `pagination` and `timeoutMs`.
///
/// The JSON-RPC `command.id` (rpcId) is **not** part of the key — it is
/// unique per call by design.
abstract final class SocketCoalesceKey {
  /// Builds the canonical key for [body]. Returns `null` when [body] does
  /// not contain a recognizable `command.method`; the dispatcher must
  /// then disable coalescing for that call.
  static String? compute({
    required String agentId,
    required Map<String, Object?> body,
  }) {
    final command = body['command'];
    if (command is! Map) {
      return null;
    }
    final method = command['method'];
    if (method is! String || method.isEmpty) {
      return null;
    }
    final params = command['params'];
    final pagination = body['pagination'];
    final timeoutMs = body['timeoutMs'];

    final canonical = <String, Object?>{
      'agentId': agentId,
      'method': method,
      'params': params,
      'pagination': pagination,
      'timeoutMs': timeoutMs,
    };
    return jsonEncode(_sortDeep(canonical));
  }

  /// Recursively sorts every map by key so that `jsonEncode` is
  /// deterministic regardless of insertion order.
  static Object? _sortDeep(Object? value) {
    if (value is Map) {
      final keys = value.keys.map((k) => k.toString()).toList()..sort();
      return <String, Object?>{
        for (final key in keys) key: _sortDeep(value[key]),
      };
    }
    if (value is List) {
      return value.map(_sortDeep).toList(growable: false);
    }
    return value;
  }
}

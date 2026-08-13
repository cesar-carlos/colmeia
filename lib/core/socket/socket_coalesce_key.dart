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
  ///
  /// The key is an FNV-1a 64-bit hex digest of the canonical walk (maps
  /// sorted by key). Hashing during the walk avoids materializing a full
  /// JSON string of SQL + params as a [Map] key.
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

    final hasher = _Fnv1a64()
      ..hashCanonical(<String, Object?>{
        'agentId': agentId,
        'method': method,
        'params': params,
        'pagination': pagination,
        'timeoutMs': timeoutMs,
      });
    return hasher.hexDigest();
  }
}

/// FNV-1a 64-bit hasher over a canonical JSON-like tree.
///
/// Map keys are sorted so insertion order does not change the digest.
/// Leaf numbers/bools/strings use the same encoding as `jsonEncode` so
/// equality matches the previous JSON-string key.
final class _Fnv1a64 {
  // FNV-1a 64-bit offset basis 0xcbf29ce484222325, split so the literal
  // stays inside the JS-safe integer range the linter requires.
  static const int _offsetHi = 0xcbf29ce4;
  static const int _offsetLo = 0x84222325;
  static const int _prime = 0x100000001b3;
  static const int _mask64 = 0xffffffffffffffff;

  static const int _tagNull = 0;
  static const int _tagBool = 1;
  static const int _tagNum = 2;
  static const int _tagString = 3;
  static const int _tagList = 4;
  static const int _tagMap = 5;

  int _hash = (_offsetHi << 32) | _offsetLo;

  void hashCanonical(Object? value) {
    if (value == null) {
      _feedByte(_tagNull);
      return;
    }
    if (value is bool) {
      _feedByte(_tagBool);
      _feedUtf8(jsonEncode(value));
      return;
    }
    if (value is num) {
      _feedByte(_tagNum);
      _feedUtf8(jsonEncode(value));
      return;
    }
    if (value is String) {
      _feedByte(_tagString);
      _feedUtf8(value);
      return;
    }
    if (value is List) {
      _feedByte(_tagList);
      _feedByte(value.length & 0xff);
      _feedByte((value.length >> 8) & 0xff);
      _feedByte((value.length >> 16) & 0xff);
      _feedByte((value.length >> 24) & 0xff);
      value.forEach(hashCanonical);
      return;
    }
    if (value is Map) {
      final keys = value.keys.map((k) => k.toString()).toList()..sort();
      _feedByte(_tagMap);
      _feedByte(keys.length & 0xff);
      _feedByte((keys.length >> 8) & 0xff);
      _feedByte((keys.length >> 16) & 0xff);
      _feedByte((keys.length >> 24) & 0xff);
      for (final key in keys) {
        _feedByte(_tagString);
        _feedUtf8(key);
        hashCanonical(value[key]);
      }
      return;
    }
    _feedByte(_tagString);
    _feedUtf8(jsonEncode(value));
  }

  String hexDigest() => _hash.toRadixString(16).padLeft(16, '0');

  void _feedUtf8(String text) {
    final bytes = utf8.encode(text);
    _feedByte(bytes.length & 0xff);
    _feedByte((bytes.length >> 8) & 0xff);
    _feedByte((bytes.length >> 16) & 0xff);
    _feedByte((bytes.length >> 24) & 0xff);
    bytes.forEach(_feedByte);
  }

  void _feedByte(int b) {
    _hash ^= b & 0xff;
    _hash = (_hash * _prime) & _mask64;
  }
}

/// Pulls a [Duration] hint out of an `app:error` payload emitted by the hub
/// on the `/consumers` namespace.
///
/// The hub propagates the same JSON-RPC `error.data` block over both REST
/// (header `Retry-After` / body `error.data.retry_after_ms`) and Socket
/// (`app:error` envelope). Three shapes are observed in the wild:
///
/// 1. Top-level `retryAfterMs` / `retry_after_ms` — used by overload
///    responses (`SERVICE_UNAVAILABLE` triggered by
///    `SOCKET_RELAY_OUTBOUND_OVERLOAD_BACKLOG`).
/// 2. `error.retryAfterMs` / `error.retry_after_ms` — used when overload
///    shed is returned on `agents:command_response` as
///    `{ success: false, error: { code, retryAfterMs } }`.
/// 3. `data.retry_after_ms` / `data.retryAfterMs` — used when the hub
///    forwards an agent's JSON-RPC error verbatim and the data block is
///    flattened to the envelope root by the bridge.
/// 4. `error.data.retry_after_ms` / `error.data.retryAfterMs` — used by
///    the standard JSON-RPC envelope (e.g. `-32013` `RATE_LIMITED`,
///    `client_token.getPolicy` rate-limit).
///
/// Returns `null` when nothing usable is present so callers can leave the
/// gate / failure unset.
///
/// Hub references: `docs/socket_relay_protocol.md` (sections *Shed load* and
/// *Rate limit por consumer*) and `docs/socket_client_sdk.md`
/// (section *Limites e comportamento do hub*).
Duration? extractRetryAfterFromAppError(Map<String, Object?> map) {
  final candidates = <Object?>[
    map['retryAfterMs'],
    map['retry_after_ms'],
    _readPath(map, const <String>['data', 'retry_after_ms']),
    _readPath(map, const <String>['data', 'retryAfterMs']),
    // Overload shed on agents:command puts retryAfterMs on the error object
    // itself (`error: { code, message, statusCode, retryAfterMs }`).
    _readPath(map, const <String>['error', 'retryAfterMs']),
    _readPath(map, const <String>['error', 'retry_after_ms']),
    _readPath(map, const <String>['error', 'data', 'retry_after_ms']),
    _readPath(map, const <String>['error', 'data', 'retryAfterMs']),
  ];
  for (final candidate in candidates) {
    final ms = _toIntOrNull(candidate);
    if (ms != null) {
      // Defensive: treat negative hints as "retry now". The Socket gate
      // / backoff caller decides whether to use a tiny floor.
      return Duration(milliseconds: ms < 0 ? 0 : ms);
    }
  }
  return null;
}

Object? _readPath(Map<String, Object?> map, List<String> path) {
  Object? current = map;
  for (final key in path) {
    if (current is Map && current.containsKey(key)) {
      current = current[key];
    } else {
      return null;
    }
  }
  return current;
}

int? _toIntOrNull(Object? raw) {
  if (raw == null) {
    return null;
  }
  if (raw is int) {
    return raw;
  }
  if (raw is num) {
    return raw.toInt();
  }
  if (raw is String) {
    return int.tryParse(raw.trim());
  }
  return null;
}

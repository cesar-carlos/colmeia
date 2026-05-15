/// Mode controlling how `connection:ready` is decoded by
/// `ConsumerSocketConnection`. Mirrors the hub-side environment variable
/// `SOCKET_CONNECTION_READY_COMPAT_MODE` documented in
/// `plug_server/docs/socket_client_sdk.md` so both sides can be flipped
/// independently during migration.
enum ConnectionReadyCompatMode {
  /// Try the `PayloadFrame` envelope first, fall back to raw JSON. Explicit
  /// migration override for hubs that still emit raw JSON.
  compat,

  /// Strict - only accept the PayloadFrame envelope. Default for current hub
  /// contracts.
  payloadFrameOnly,

  /// Legacy strict - only accept the raw JSON shape; useful in tests against
  /// older hub forks.
  rawJsonOnly
  ;

  /// Parses the raw env value (`SOCKET_CONNECTION_READY_COMPAT_MODE`).
  /// Unknown values fall back to [fallback].
  static ConnectionReadyCompatMode parse(
    String? raw, {
    ConnectionReadyCompatMode fallback =
        ConnectionReadyCompatMode.payloadFrameOnly,
  }) {
    if (raw == null) {
      return fallback;
    }
    final normalized = raw.trim().toLowerCase().replaceAll('-', '_');
    return switch (normalized) {
      'compat' => ConnectionReadyCompatMode.compat,
      'payload_frame_only' ||
      'payloadframeonly' ||
      'payload_frame' => ConnectionReadyCompatMode.payloadFrameOnly,
      'raw_json_only' ||
      'rawjsononly' ||
      'raw_json' => ConnectionReadyCompatMode.rawJsonOnly,
      _ => fallback,
    };
  }
}

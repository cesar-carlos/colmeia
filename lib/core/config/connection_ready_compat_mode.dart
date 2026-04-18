/// Mode controlling how `connection:ready` is decoded by
/// `ConsumerSocketConnection`. Mirrors the hub-side environment variable
/// `SOCKET_CONNECTION_READY_COMPAT_MODE` documented in
/// `plug_server/docs/socket_client_sdk.md` so both sides can be flipped
/// independently during the migration window.
enum ConnectionReadyCompatMode {
  /// Try the `PayloadFrame` envelope first, fall back to raw JSON. Default
  /// for the migration window declared by the hub (raw_json removal planned
  /// for after 2026-09-30).
  compat,

  /// Strict — only accept the PayloadFrame envelope.
  payloadFrameOnly,

  /// Legacy strict — only accept the raw JSON shape; useful in tests against
  /// older hub forks.
  rawJsonOnly;

  /// Parses the raw env value (`SOCKET_CONNECTION_READY_COMPAT_MODE`).
  /// Unknown values fall back to [fallback].
  static ConnectionReadyCompatMode parse(
    String? raw, {
    ConnectionReadyCompatMode fallback = ConnectionReadyCompatMode.compat,
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

/// Hint serialized as `meta.outbound_compression` in the JSON-RPC `command`.
///
/// Tells the **agent** which `PayloadFrame.cmp` policy to apply when emitting
/// the response (and stream events) back to the hub. The hub forwards the
/// hint verbatim — it does not re-interpret. Per
/// `plug_server/docs/communication_sync_plug_agente.md`, the field is
/// accepted by the hub schema but treated as a **no-op on the runtime today**
/// because current agents do not support a per-request override; we still
/// send it so we are forward-compatible the day agents start honoring it.
///
/// See:
///
/// - `plug_agente/docs/communication/socket_communication_standard.md`
/// - `plug_server/docs/api_rest_bridge.md` (`api_version`/`meta`)
enum AgentOutboundCompression {
  /// `auto` — agent picks based on its own threshold (default).
  auto,

  /// `none` — agent keeps `cmp: none` even when the payload would be a good
  /// gzip candidate. Useful for low-CPU agents.
  none,

  /// `gzip` — agent always gzips the response when above the negotiated
  /// threshold.
  gzip;

  String get wireValue => switch (this) {
    AgentOutboundCompression.auto => 'auto',
    AgentOutboundCompression.none => 'none',
    AgentOutboundCompression.gzip => 'gzip',
  };

  static AgentOutboundCompression? parse(String? raw) {
    final normalized = raw?.trim().toLowerCase();
    return switch (normalized) {
      'auto' => AgentOutboundCompression.auto,
      'none' => AgentOutboundCompression.none,
      'gzip' => AgentOutboundCompression.gzip,
      _ => null,
    };
  }
}

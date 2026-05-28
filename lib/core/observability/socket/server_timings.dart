/// Per-phase latency snapshot the hub returns when the consumer sets
/// `requestServerTimings: true` on the request envelope (relay,
/// `agents:command` or REST). The contract lives in
/// `plug_server/docs/socket_relay_protocol.md` and
/// `plug_server/docs/api_rest_bridge.md`, summarised for the client in
/// `docs/server_adjustments/DELIVERED.md`.
///
/// Stable phase keys for `schemaVersion == 1` are described in
/// [ServerTimingPhaseNames]; consumers MUST tolerate unknown keys because
/// the hub may add new phases on minor bumps.
class ServerTimings {
  const ServerTimings({
    required this.schemaVersion,
    required Map<String, double> phasesMs,
  }) : _phasesMs = phasesMs;

  /// Best-effort parser. Returns `null` when the input is structurally
  /// invalid (not a map, missing or non-numeric `phasesMs`); never throws.
  /// Numeric coercion accepts both `num` and parseable strings so JSON
  /// produced by stricter or looser stacks both round-trip.
  static ServerTimings? tryParse(Object? raw) {
    if (raw is! Map) {
      return null;
    }
    final schemaRaw = raw['schemaVersion'];
    final schemaVersion = switch (schemaRaw) {
      final int v => v,
      final num v => v.toInt(),
      final String v => int.tryParse(v.trim()) ?? 1,
      _ => 1,
    };
    final phasesRaw = raw['phasesMs'];
    if (phasesRaw is! Map) {
      return null;
    }
    final phases = <String, double>{};
    phasesRaw.forEach((key, value) {
      if (key is! String) {
        return;
      }
      final asDouble = switch (value) {
        final num v => v.toDouble(),
        final String v => double.tryParse(v.trim()),
        _ => null,
      };
      if (asDouble != null && asDouble.isFinite) {
        phases[key] = asDouble;
      }
    });
    return ServerTimings(schemaVersion: schemaVersion, phasesMs: phases);
  }

  /// Pulls a `ServerTimings` instance from the relay response envelope.
  /// Relay places the snapshot under `meta.serverTimings` (inside the
  /// JSON-RPC body of `relay:rpc.response`).
  static ServerTimings? tryParseFromRelayBody(Map<String, dynamic>? body) {
    final meta = body?['meta'];
    if (meta is! Map) {
      return null;
    }
    return tryParse(meta['serverTimings']);
  }

  /// Pulls a `ServerTimings` instance from an `agents:command` or REST
  /// response envelope. Those carry the snapshot as a top-level
  /// `serverTimings` field next to `requestId`.
  static ServerTimings? tryParseFromEnvelope(Map<String, dynamic>? envelope) {
    if (envelope == null) {
      return null;
    }
    return tryParse(envelope['serverTimings']);
  }

  final int schemaVersion;
  final Map<String, double> _phasesMs;

  /// Snapshot view of every phase, ordered as the hub returned them.
  /// Unmodifiable so consumers cannot mutate a metrics record.
  Map<String, double> get phasesMs => Map<String, double>.unmodifiable(_phasesMs);

  /// Tolerant accessor for a single phase. Returns `null` on schema
  /// mismatch or unknown key.
  double? phaseMs(String name) {
    if (schemaVersion != 1) {
      return null;
    }
    return _phasesMs[name];
  }

  bool get isEmpty => _phasesMs.isEmpty;
  bool get isNotEmpty => _phasesMs.isNotEmpty;
}

/// Phase keys documented for `schemaVersion == 1` in
/// `plug_server/docs/runbooks/socket_perf_investigation.md`.
///
/// Listed so client-side dashboards and tests can stay aligned with the
/// hub contract; the consumer MUST still tolerate unknown keys to absorb
/// future minor-version additions without redeployment.
abstract final class ServerTimingPhaseNames {
  static const String consumerFrameDecodeMs = 'consumer_frame_decode_ms';
  static const String relayPreflightMs = 'relay_preflight_ms';
  static const String queueWaitMs = 'queue_wait_ms';
  static const String encodeMs = 'encode_ms';
  static const String emitToSocketMs = 'emit_to_socket_ms';
  static const String agentToHubMs = 'agent_to_hub_ms';
  static const String inboundDecodeMs = 'inbound_decode_ms';
  static const String pendingResolveMs = 'pending_resolve_ms';
  static const String relayForwardToConsumerMs =
      'relay_forward_to_consumer_ms';
  static const String responseWriteMs = 'response_write_ms';
}

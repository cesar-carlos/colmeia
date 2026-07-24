/// Transport channel used by `agent_queries` to dispatch JSON-RPC commands
/// to the Plug hub bridge.
///
/// The default is [rest] (battle-tested REST `POST /api/v1/agents/commands`).
/// Switch to [socket] enables the `agents:command` channel on the
/// `/consumers` Socket.IO namespace; planned in
/// `docs/Features/socket_consumer_channel_plan.md`.
enum AgentBridgeTransport {
  rest,
  socket;

  /// Canonical wire/env value for this transport.
  String get wireValue => switch (this) {
    AgentBridgeTransport.rest => 'rest',
    AgentBridgeTransport.socket => 'socket',
  };

  /// Strict parser for `AGENT_BRIDGE_TRANSPORT`.
  ///
  /// Returns `null` for `null`, empty / whitespace and unknown values.
  static AgentBridgeTransport? tryParse(String? raw) {
    if (raw == null) {
      return null;
    }
    final normalized = raw.trim().toLowerCase();
    if (normalized.isEmpty) {
      return null;
    }
    return switch (normalized) {
      'socket' => AgentBridgeTransport.socket,
      'rest' => AgentBridgeTransport.rest,
      _ => null,
    };
  }

  /// Parses the raw env value (`AGENT_BRIDGE_TRANSPORT`). Unknown values
  /// fall back to [fallback].
  static AgentBridgeTransport parse(
    String? raw, {
    AgentBridgeTransport fallback = AgentBridgeTransport.rest,
  }) {
    return tryParse(raw) ?? fallback;
  }
}

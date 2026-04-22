/// Transport channel used by `agent_queries` to dispatch JSON-RPC commands
/// to the Plug hub bridge.
///
/// The default is [rest] (battle-tested REST `POST /api/v1/agents/commands`).
/// Switch to [socket] enables the `agents:command` channel on the
/// `/consumers` Socket.IO namespace; planned in
/// `docs/Features/socket_consumer_channel_plan.md`.
enum AgentBridgeTransport {
  rest,
  socket
  ;

  /// Parses the raw env value (`AGENT_BRIDGE_TRANSPORT`). Unknown values
  /// fall back to [fallback].
  static AgentBridgeTransport parse(
    String? raw, {
    AgentBridgeTransport fallback = AgentBridgeTransport.rest,
  }) {
    if (raw == null) {
      return fallback;
    }
    final normalized = raw.trim().toLowerCase();
    return switch (normalized) {
      'socket' => AgentBridgeTransport.socket,
      'rest' => AgentBridgeTransport.rest,
      _ => fallback,
    };
  }
}

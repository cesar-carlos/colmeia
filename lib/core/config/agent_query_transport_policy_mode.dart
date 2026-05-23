/// Env-driven routing hint for agent SQL transport (`AGENT_QUERY_TRANSPORT_POLICY`).
enum AgentQueryTransportPolicyMode {
  /// Respect caller `useRelay` only (status quo).
  legacy,

  /// Paginated unary SQL stays on the base channel; streaming mode uses relay.
  autoByShape,

  /// Force relay for eligible socket builds (dashboard SQL default today).
  preferRelay,
}

AgentQueryTransportPolicyMode parseAgentQueryTransportPolicyMode(String raw) {
  switch (raw.trim().toLowerCase()) {
    case 'auto':
    case 'auto_by_shape':
      return AgentQueryTransportPolicyMode.autoByShape;
    case 'prefer_relay':
    case 'relay':
      return AgentQueryTransportPolicyMode.preferRelay;
    default:
      return AgentQueryTransportPolicyMode.legacy;
  }
}

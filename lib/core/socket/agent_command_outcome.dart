/// Observable result of a single `agents:command` dispatch.
///
/// Consumed by the agent presence stream (real-time online/offline hints)
/// and by metrics. Sealed so consumers do exhaustive `switch`.
///
/// See `docs/Features/socket_command_dispatcher_design.md` §2.2.
sealed class AgentCommandOutcome {
  const AgentCommandOutcome({
    required this.agentId,
    required this.rpcId,
    required this.observedAt,
    required this.elapsed,
    this.method,
  });

  final String agentId;

  /// Same `command.id` JSON-RPC value the caller sent.
  final String rpcId;

  /// UTC moment when the outcome was observed.
  final DateTime observedAt;

  /// Time from emit to observation (success or error).
  final Duration elapsed;

  /// JSON-RPC `command.method` (e.g. `sql.execute`). Optional because
  /// the dispatcher may not know it for synthesized failure outcomes
  /// (e.g. emit failure before the body was inspected).
  final String? method;
}

/// Successful `agents:command_response` was received and correlated.
final class AgentCommandSuccess extends AgentCommandOutcome {
  const AgentCommandSuccess({
    required super.agentId,
    required super.rpcId,
    required super.observedAt,
    required super.elapsed,
    super.method,
  });
}

/// Server reported the agent is offline / hub has no route. **Signals
/// presence = offline** to the realtime presence layer.
final class AgentCommandFailedOffline extends AgentCommandOutcome {
  const AgentCommandFailedOffline({
    required super.agentId,
    required super.rpcId,
    required super.observedAt,
    required super.elapsed,
    required this.reasonCode,
    super.method,
  });

  /// Server-side classification (e.g. `AGENT_OFFLINE`, `protocol_not_ready`,
  /// `circuit_open`). Useful for diagnosis only.
  final String reasonCode;
}

/// Auth failure (`-32001`/`-32002`, `AGENT_ACCESS_DENIED`,
/// `unauthorized`, etc.). Says nothing about presence. Presence layer
/// ignores this kind.
final class AgentCommandFailedAuth extends AgentCommandOutcome {
  const AgentCommandFailedAuth({
    required super.agentId,
    required super.rpcId,
    required super.observedAt,
    required super.elapsed,
    required this.reasonCode,
    super.method,
  });

  final String reasonCode;
}

/// Timeout, decode failure, socket drop, rate-limit, generic error.
/// Does not interpret presence.
final class AgentCommandFailedTransient extends AgentCommandOutcome {
  const AgentCommandFailedTransient({
    required super.agentId,
    required super.rpcId,
    required super.observedAt,
    required super.elapsed,
    required this.reasonCode,
    super.method,
    this.cause,
  });

  final String reasonCode;
  final Object? cause;
}

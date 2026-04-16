import 'package:colmeia/features/client_agents/domain/entities/client_agent.dart';

/// Result of a network-only probe for `GET /client/me/agents/{agentId}`.
final class ClientApprovedAgentProbeOutcome {
  const ClientApprovedAgentProbeOutcome._({this.agent});

  const ClientApprovedAgentProbeOutcome.linked(ClientAgent agent)
    : this._(agent: agent);

  const ClientApprovedAgentProbeOutcome.notLinked() : this._(agent: null);

  final ClientAgent? agent;

  bool get isLinked => agent != null;
}

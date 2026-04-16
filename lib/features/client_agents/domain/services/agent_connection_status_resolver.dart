import 'package:colmeia/features/client_agents/domain/entities/agent_connection_status.dart';

/// Pure hub / cache presence rule shared by approved-agent profile mapping
/// and agent SQL execution gating.
AgentConnectionStatus resolveAgentConnectionStatus({
  required String agentId,
  required bool? isHubConnected,
  required Set<String>? onlineAgentIds,
}) {
  if (isHubConnected != null) {
    return isHubConnected
        ? AgentConnectionStatus.online
        : AgentConnectionStatus.offline;
  }
  return switch (onlineAgentIds) {
    null => AgentConnectionStatus.unknown,
    final ids when ids.contains(agentId) => AgentConnectionStatus.online,
    _ => AgentConnectionStatus.offline,
  };
}

import 'package:colmeia/features/client_agents/domain/entities/agent_connection_status.dart';

class AgentQueryTarget {
  const AgentQueryTarget({
    required this.agentId,
    required this.displayName,
    required this.connectionStatus,
    this.clientToken,
  });

  final String agentId;
  final String displayName;
  final AgentConnectionStatus connectionStatus;
  final String? clientToken;

  bool get hasClientToken =>
      clientToken != null && clientToken!.trim().isNotEmpty;
}

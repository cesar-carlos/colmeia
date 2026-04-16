import 'package:colmeia/features/client_agents/domain/entities/agent_connection_status.dart';

class AgentQueryTarget {
  const AgentQueryTarget({
    required this.agentId,
    required this.displayName,
    required this.connectionStatus,
    this.clientToken,
    this.hubConnectedFromApprovedCatalogRow,
  });

  final String agentId;
  final String displayName;
  final AgentConnectionStatus connectionStatus;
  final String? clientToken;

  /// Hub flag inferred from the approved-agent row when online status is not
  /// loaded in that query; carried for SQL eligibility / gate alignment.
  final bool? hubConnectedFromApprovedCatalogRow;

  bool get hasClientToken =>
      clientToken != null && clientToken!.trim().isNotEmpty;
}

import 'package:colmeia/features/client_agents/domain/entities/agent_access_request_status.dart';

class ClientAgentAccessRequest {
  const ClientAgentAccessRequest({
    required this.agentId,
    required this.agentName,
    required this.status,
    this.requestId,
    this.requestedAt,
    this.reviewedAt,
    this.rejectionReason,
  });

  final String? requestId;
  final String agentId;
  final String agentName;
  final AgentAccessRequestStatus status;
  final DateTime? requestedAt;
  final DateTime? reviewedAt;
  final String? rejectionReason;
}

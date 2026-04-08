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
    this.statusPollToken,
  });

  final String? requestId;
  final String agentId;
  final String agentName;
  final AgentAccessRequestStatus status;
  final DateTime? requestedAt;
  final DateTime? reviewedAt;
  final String? rejectionReason;

  /// When present, [GET /client-access/status] can be used for accurate polling.
  final String? statusPollToken;
}

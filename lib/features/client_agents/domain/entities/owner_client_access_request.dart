import 'package:colmeia/features/client_agents/domain/entities/agent_access_request_status.dart';

class OwnerClientAccessRequest {
  const OwnerClientAccessRequest({
    required this.requestId,
    required this.agentId,
    required this.agentName,
    required this.clientId,
    required this.clientName,
    required this.status,
    this.clientEmail,
    this.requestedAt,
    this.reviewedAt,
    this.rejectionReason,
    this.isStaleCache = false,
  });

  final String requestId;
  final String agentId;
  final String agentName;
  final String clientId;
  final String clientName;
  final String? clientEmail;
  final AgentAccessRequestStatus status;
  final DateTime? requestedAt;
  final DateTime? reviewedAt;
  final String? rejectionReason;
  final bool isStaleCache;
}

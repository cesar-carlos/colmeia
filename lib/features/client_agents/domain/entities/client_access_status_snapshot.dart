import 'package:colmeia/features/client_agents/domain/entities/agent_access_request_status.dart';

/// Result of [GET /client-access/status] for a review token.
class ClientAccessStatusSnapshot {
  const ClientAccessStatusSnapshot({
    required this.status,
    this.agentId,
    this.message,
    this.decidedAt,
  });

  final AgentAccessRequestStatus status;
  final String? agentId;
  final String? message;
  final DateTime? decidedAt;
}

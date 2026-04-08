import 'package:colmeia/features/client_agents/domain/entities/agent_access_request_status.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent_access_request.dart';

class ClientAgentAccessRequestDto {
  const ClientAgentAccessRequestDto({
    required this.agentId,
    required this.agentName,
    required this.status,
    this.requestId,
    this.requestedAt,
    this.reviewedAt,
    this.rejectionReason,
    this.statusPollToken,
  });

  factory ClientAgentAccessRequestDto.fromJson(Map<String, dynamic> json) {
    final agent = (json['agent'] as Map<String, dynamic>?) ?? json;
    final agentId =
        (json['agentId'] as String?) ??
        (agent['agentId'] as String?) ??
        (json['agent_id'] as String?) ??
        '';
    final name =
        (json['agentName'] as String?) ??
        (agent['name'] as String?) ??
        (json['name'] as String?) ??
        'Agente';
    final statusRaw =
        (json['status'] as String?) ??
        (json['requestStatus'] as String?) ??
        (json['request_status'] as String?);

    return ClientAgentAccessRequestDto(
      requestId: (json['requestId'] as String?) ?? (json['id'] as String?),
      agentId: agentId,
      agentName: name,
      status: AgentAccessRequestStatus.fromWireValue(statusRaw),
      requestedAt: DateTime.tryParse(
        (json['requestedAt'] as String?) ??
            (json['createdAt'] as String?) ??
            '',
      ),
      reviewedAt: DateTime.tryParse(
        (json['reviewedAt'] as String?) ?? (json['updatedAt'] as String?) ?? '',
      ),
      rejectionReason:
          (json['reason'] as String?) ??
          (json['rejectionReason'] as String?) ??
          (json['rejection_reason'] as String?),
      statusPollToken: _readOptionalString(
        json,
        <String>[
          'statusPollToken',
          'status_token',
          'reviewToken',
          'review_token',
          'accessToken',
          'access_token',
          'token',
        ],
      ),
    );
  }

  static String? _readOptionalString(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    for (final key in keys) {
      final raw = json[key];
      if (raw is String) {
        final trimmed = raw.trim();
        if (trimmed.isNotEmpty) {
          return trimmed;
        }
      }
    }
    return null;
  }

  final String? requestId;
  final String agentId;
  final String agentName;
  final AgentAccessRequestStatus status;
  final DateTime? requestedAt;
  final DateTime? reviewedAt;
  final String? rejectionReason;
  final String? statusPollToken;

  ClientAgentAccessRequest toEntity() {
    return ClientAgentAccessRequest(
      requestId: requestId,
      agentId: agentId,
      agentName: agentName,
      status: status,
      requestedAt: requestedAt,
      reviewedAt: reviewedAt,
      rejectionReason: rejectionReason,
      statusPollToken: statusPollToken,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'requestId': requestId,
      'agentId': agentId,
      'agentName': agentName,
      'status': status.name,
      'requestedAt': requestedAt?.toIso8601String(),
      'reviewedAt': reviewedAt?.toIso8601String(),
      'rejectionReason': rejectionReason,
      'statusPollToken': statusPollToken,
    };
  }
}

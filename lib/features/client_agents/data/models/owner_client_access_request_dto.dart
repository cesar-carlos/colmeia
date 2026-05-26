import 'package:colmeia/features/client_agents/domain/entities/agent_access_request_status.dart';
import 'package:colmeia/features/client_agents/domain/entities/owner_client_access_request.dart';

class OwnerClientAccessRequestDto {
  const OwnerClientAccessRequestDto({
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
  });

  factory OwnerClientAccessRequestDto.fromJson(Map<String, dynamic> json) {
    final agent =
        (json['agent'] as Map<String, dynamic>?) ?? const <String, dynamic>{};
    final client =
        (json['client'] as Map<String, dynamic>?) ??
        (json['requester'] as Map<String, dynamic>?) ??
        const <String, dynamic>{};
    final clientName =
        _readOptionalString(json, const <String>[
          'clientName',
          'client_name',
        ]) ??
        _readOptionalString(client, const <String>[
          'name',
          'fullName',
          'full_name',
        ]) ??
        _readOptionalString(client, const <String>[
          'firstName',
          'first_name',
        ]) ??
        _readOptionalString(json, const <String>[
          'email',
          'clientEmail',
          'client_email',
        ]) ??
        _readOptionalString(client, const <String>['email']) ??
        'Cliente';
    final clientEmail =
        _readOptionalString(json, const <String>[
          'clientEmail',
          'client_email',
          'email',
        ]) ??
        _readOptionalString(client, const <String>['email']);
    final statusRaw =
        _readOptionalString(json, const <String>[
          'status',
          'requestStatus',
          'request_status',
        ]) ??
        _readOptionalString(client, const <String>['status']);
    return OwnerClientAccessRequestDto(
      requestId:
          _readOptionalString(json, const <String>['requestId', 'id']) ?? '',
      agentId:
          _readOptionalString(json, const <String>['agentId', 'agent_id']) ??
          _readOptionalString(agent, const <String>['agentId', 'id']) ??
          '',
      agentName:
          _readOptionalString(json, const <String>[
            'agentName',
            'agent_name',
          ]) ??
          _readOptionalString(agent, const <String>['name']) ??
          'Agente',
      clientId:
          _readOptionalString(json, const <String>['clientId', 'client_id']) ??
          _readOptionalString(client, const <String>['id', 'clientId']) ??
          '',
      clientName: clientName,
      clientEmail: clientEmail,
      status: AgentAccessRequestStatus.fromWireValue(statusRaw),
      requestedAt: DateTime.tryParse(
        _readOptionalString(
              json,
              const <String>[
                'requestedAt',
                'createdAt',
                'requested_at',
                'created_at',
              ],
            ) ??
            '',
      ),
      reviewedAt: DateTime.tryParse(
        _readOptionalString(
              json,
              const <String>[
                'reviewedAt',
                'updatedAt',
                'reviewed_at',
                'updated_at',
              ],
            ) ??
            '',
      ),
      rejectionReason: _readOptionalString(
        json,
        const <String>['reason', 'rejectionReason', 'rejection_reason'],
      ),
    );
  }

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

  OwnerClientAccessRequest toEntity({bool isStaleCache = false}) {
    return OwnerClientAccessRequest(
      requestId: requestId,
      agentId: agentId,
      agentName: agentName,
      clientId: clientId,
      clientName: clientName,
      clientEmail: clientEmail,
      status: status,
      requestedAt: requestedAt,
      reviewedAt: reviewedAt,
      rejectionReason: rejectionReason,
      isStaleCache: isStaleCache,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'requestId': requestId,
      'agentId': agentId,
      'agentName': agentName,
      'clientId': clientId,
      'clientName': clientName,
      'clientEmail': clientEmail,
      'status': status.name,
      'requestedAt': requestedAt?.toIso8601String(),
      'reviewedAt': reviewedAt?.toIso8601String(),
      'rejectionReason': rejectionReason,
    };
  }
}

String? _readOptionalString(Map<String, dynamic> json, List<String> keys) {
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

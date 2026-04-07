import 'package:colmeia/features/client_agents/domain/entities/agent_access_request_status.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_access_status_snapshot.dart';

class ClientAccessStatusResponseDto {
  const ClientAccessStatusResponseDto({
    required this.statusWire,
    this.agentId,
    this.message,
    this.decidedAt,
  });

  factory ClientAccessStatusResponseDto.fromJson(Map<String, dynamic> json) {
    final status = (json['status'] as String?)?.trim() ??
        (json['requestStatus'] as String?)?.trim() ??
        (json['state'] as String?)?.trim() ??
        '';
    return ClientAccessStatusResponseDto(
      statusWire: status,
      agentId: json['agentId'] as String? ?? json['agent_id'] as String?,
      message: json['message'] as String?,
      decidedAt: _parseDate(
        json['decidedAt'] as String? ??
            json['updatedAt'] as String? ??
            json['resolvedAt'] as String?,
      ),
    );
  }

  final String statusWire;
  final String? agentId;
  final String? message;
  final DateTime? decidedAt;

  ClientAccessStatusSnapshot toEntity() {
    return ClientAccessStatusSnapshot(
      status: AgentAccessRequestStatus.fromWireValue(
        statusWire.isEmpty ? null : statusWire,
      ),
      agentId: agentId,
      message: message,
      decidedAt: decidedAt,
    );
  }

  static DateTime? _parseDate(String? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return DateTime.tryParse(raw);
  }
}

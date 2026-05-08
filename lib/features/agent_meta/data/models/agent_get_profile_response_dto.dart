import 'package:colmeia/features/agent_meta/domain/entities/agent_profile_snapshot.dart';

/// Wire result of `agent.getProfile` (per
/// `plug_agente/docs/communication/schemas/rpc.result.agent-get-profile.schema.json`).
class AgentGetProfileResponseDto {
  const AgentGetProfileResponseDto({
    required this.agentId,
    required this.name,
    this.profileVersion,
    this.tradeName,
    this.document,
    this.documentType,
    this.phone,
    this.mobile,
    this.email,
    this.notes,
    this.observation,
    this.profileUpdatedAt,
    this.raw = const <String, Object?>{},
  });

  /// Builds from the inner `result` object (already unwrapped from
  /// `response.item.result` by the bridge serializer).
  factory AgentGetProfileResponseDto.fromResult(
    Map<String, Object?> result,
  ) {
    final agentId = (result['agent_id'] ?? result['agentId'])?.toString() ?? '';
    final name = (result['name'] ?? result['displayName'])?.toString() ?? '';
    return AgentGetProfileResponseDto(
      agentId: agentId,
      name: name,
      profileVersion: _asInt(
        result['profile_version'] ?? result['profileVersion'],
      ),
      tradeName:
          result['trade_name']?.toString() ?? result['tradeName']?.toString(),
      document: result['document']?.toString(),
      documentType:
          result['document_type']?.toString() ??
          result['documentType']?.toString(),
      phone: result['phone']?.toString(),
      mobile: result['mobile']?.toString(),
      email: result['email']?.toString(),
      notes: result['notes']?.toString(),
      observation: result['observation']?.toString(),
      profileUpdatedAt: _parseDate(
        result['profile_updated_at'] ?? result['profileUpdatedAt'],
      ),
      raw: result,
    );
  }

  final String agentId;
  final String name;
  final int? profileVersion;
  final String? tradeName;
  final String? document;
  final String? documentType;
  final String? phone;
  final String? mobile;
  final String? email;
  final String? notes;
  final String? observation;
  final DateTime? profileUpdatedAt;
  final Map<String, Object?> raw;

  AgentProfileSnapshot toEntity() {
    return AgentProfileSnapshot(
      agentId: agentId,
      name: name,
      profileVersion: profileVersion,
      tradeName: tradeName,
      document: document,
      documentType: documentType,
      phone: phone,
      mobile: mobile,
      email: email,
      notes: notes,
      observation: observation,
      profileUpdatedAt: profileUpdatedAt,
      raw: raw,
    );
  }

  static int? _asInt(Object? raw) {
    if (raw is int) {
      return raw;
    }
    if (raw is num) {
      return raw.toInt();
    }
    if (raw is String) {
      return int.tryParse(raw.trim());
    }
    return null;
  }

  static DateTime? _parseDate(Object? raw) {
    if (raw is String) {
      return DateTime.tryParse(raw)?.toUtc();
    }
    return null;
  }
}

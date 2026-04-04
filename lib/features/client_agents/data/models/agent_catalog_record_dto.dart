import 'package:colmeia/features/client_agents/data/models/client_agent_profile_dto.dart';

class AgentCatalogRecordDto extends ClientAgentProfileDto {
  const AgentCatalogRecordDto({
    required super.agentId,
    required super.name,
    required super.status,
    required super.createdAt,
    required super.updatedAt,
    this.lastLoginUserId,
    super.tradeName,
    super.document,
    super.cnpjCpf,
    super.documentType,
    super.phone,
    super.mobile,
    super.email,
    super.address,
    super.notes,
    super.observation,
    super.profileUpdatedAt,
  });

  factory AgentCatalogRecordDto.fromJson(Map<String, dynamic> json) {
    final base = ClientAgentProfileDto.fromJson(json);
    return AgentCatalogRecordDto(
      agentId: base.agentId,
      name: base.name,
      status: base.status,
      createdAt: base.createdAt,
      updatedAt: base.updatedAt,
      tradeName: base.tradeName,
      document: base.document,
      cnpjCpf: base.cnpjCpf,
      documentType: base.documentType,
      phone: base.phone,
      mobile: base.mobile,
      email: base.email,
      address: base.address,
      notes: base.notes,
      observation: base.observation,
      profileUpdatedAt: base.profileUpdatedAt,
      lastLoginUserId: json['lastLoginUserId'] as String?,
    );
  }

  final String? lastLoginUserId;

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      ...super.toJson(),
      'lastLoginUserId': lastLoginUserId,
    };
  }
}

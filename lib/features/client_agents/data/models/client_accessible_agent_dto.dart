import 'package:colmeia/features/client_agents/data/models/client_agent_profile_dto.dart';

class ClientAccessibleAgentDto extends ClientAgentProfileDto {
  const ClientAccessibleAgentDto({
    required super.agentId,
    required super.name,
    required super.status,
    required super.createdAt,
    required super.updatedAt,
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

  factory ClientAccessibleAgentDto.fromJson(Map<String, dynamic> json) {
    final base = ClientAgentProfileDto.fromJson(json);
    return ClientAccessibleAgentDto(
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
    );
  }
}

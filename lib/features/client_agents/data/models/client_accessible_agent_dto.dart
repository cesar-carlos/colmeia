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
    super.profileVersion,
    super.isHubConnected,
    super.hasClientToken,
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
      profileVersion: base.profileVersion,
      isHubConnected: base.isHubConnected,
      hasClientToken: base.hasClientToken,
    );
  }

  /// Returns a new DTO with selected fields replaced. Nullable fields
  /// use `Object?` sentinels so `null` arguments are treated as "leave
  /// the original value" (the natural Dart copyWith semantics); callers
  /// that need to explicitly clear a field should rebuild the DTO
  /// directly.
  ClientAccessibleAgentDto copyWith({
    String? name,
    String? tradeName,
    String? document,
    String? cnpjCpf,
    String? documentType,
    String? phone,
    String? mobile,
    String? email,
    String? notes,
    String? observation,
    DateTime? profileUpdatedAt,
    int? profileVersion,
  }) {
    return ClientAccessibleAgentDto(
      agentId: agentId,
      name: name ?? this.name,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
      tradeName: tradeName ?? this.tradeName,
      document: document ?? this.document,
      cnpjCpf: cnpjCpf ?? this.cnpjCpf,
      documentType: documentType ?? this.documentType,
      phone: phone ?? this.phone,
      mobile: mobile ?? this.mobile,
      email: email ?? this.email,
      address: address,
      notes: notes ?? this.notes,
      observation: observation ?? this.observation,
      profileUpdatedAt: profileUpdatedAt ?? this.profileUpdatedAt,
      profileVersion: profileVersion ?? this.profileVersion,
      isHubConnected: isHubConnected,
      hasClientToken: hasClientToken,
    );
  }
}

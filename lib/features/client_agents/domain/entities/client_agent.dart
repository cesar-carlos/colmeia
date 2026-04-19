import 'package:colmeia/features/client_agents/domain/entities/agent_catalog_status.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_connection_status.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_profile_address.dart';

class ClientAgent {
  const ClientAgent({
    required this.agentId,
    required this.name,
    required this.catalogStatus,
    required this.connectionStatus,
    required this.createdAt,
    required this.updatedAt,
    this.tradeName,
    this.document,
    this.cnpjCpf,
    this.registrationDocument,
    this.documentType,
    this.phone,
    this.mobile,
    this.email,
    this.address,
    this.notes,
    this.observation,
    this.profileUpdatedAt,
    this.hasServerClientToken,
  });

  final String agentId;
  final String name;
  final String? tradeName;
  final String? document;
  final String? cnpjCpf;
  final String? registrationDocument;
  final String? documentType;
  final String? phone;
  final String? mobile;
  final String? email;
  final AgentProfileAddress? address;
  final String? notes;
  final String? observation;
  final DateTime? profileUpdatedAt;
  final AgentCatalogStatus catalogStatus;
  final AgentConnectionStatus connectionStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Server-side token presence flag (`hasClientToken` on
  /// `ClientAccessibleAgent`). `null` when the API did not include the field
  /// (older hubs or local cache built before the contract bumped). UI must
  /// treat `null` as "unknown" and decide between local fallback and prompt.
  final bool? hasServerClientToken;

  ClientAgent copyWith({
    AgentConnectionStatus? connectionStatus,
    bool? hasServerClientToken,
    bool resetHasServerClientToken = false,
  }) {
    return ClientAgent(
      agentId: agentId,
      name: name,
      tradeName: tradeName,
      document: document,
      cnpjCpf: cnpjCpf,
      registrationDocument: registrationDocument,
      documentType: documentType,
      phone: phone,
      mobile: mobile,
      email: email,
      address: address,
      notes: notes,
      observation: observation,
      profileUpdatedAt: profileUpdatedAt,
      catalogStatus: catalogStatus,
      connectionStatus: connectionStatus ?? this.connectionStatus,
      createdAt: createdAt,
      updatedAt: updatedAt,
      hasServerClientToken: resetHasServerClientToken
          ? null
          : (hasServerClientToken ?? this.hasServerClientToken),
    );
  }
}

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
    this.registrationDocument,
    this.documentType,
    this.phone,
    this.mobile,
    this.email,
    this.address,
    this.notes,
    this.observation,
    this.profileUpdatedAt,
  });

  final String agentId;
  final String name;
  final String? tradeName;
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

  ClientAgent copyWith({
    AgentConnectionStatus? connectionStatus,
  }) {
    return ClientAgent(
      agentId: agentId,
      name: name,
      tradeName: tradeName,
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
    );
  }
}

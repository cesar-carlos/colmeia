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
    this.profileVersion,
    this.hasServerClientToken,
    this.isStaleCache = false,
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

  /// Monotonic profile revision counter served by the hub
  /// (`profileVersion` on `ClientAccessibleAgent` / `AgentCatalogRecord`).
  /// Used as the CAS token for `PATCH /api/v1/agents/{id}/profile`
  /// (`expectedProfileVersion`) and to compare against the
  /// `profile_version` field carried by `client:agent.profile.updated`
  /// realtime events.
  ///
  /// `null` when the field was not present in the response (older hub
  /// builds) or the entity was rebuilt from a partial payload — callers
  /// must omit `expectedProfileVersion` in that case.
  final int? profileVersion;

  /// Server-side token presence flag (`hasClientToken` on
  /// `ClientAccessibleAgent`). `null` when the API did not include the field
  /// (older hubs or local cache built before the contract bumped). UI must
  /// treat `null` as "unknown" and decide between local fallback and prompt.
  final bool? hasServerClientToken;

  final bool isStaleCache;

  ClientAgent copyWith({
    AgentConnectionStatus? connectionStatus,
    bool? hasServerClientToken,
    bool resetHasServerClientToken = false,
    int? profileVersion,
    bool resetProfileVersion = false,
    bool? isStaleCache,
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
      profileVersion: resetProfileVersion
          ? null
          : (profileVersion ?? this.profileVersion),
      catalogStatus: catalogStatus,
      connectionStatus: connectionStatus ?? this.connectionStatus,
      createdAt: createdAt,
      updatedAt: updatedAt,
      hasServerClientToken: resetHasServerClientToken
          ? null
          : (hasServerClientToken ?? this.hasServerClientToken),
      isStaleCache: isStaleCache ?? this.isStaleCache,
    );
  }
}

import 'package:colmeia/features/client_agents/data/models/client_agent_address_dto.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_catalog_status.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_connection_status.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent.dart';

/// Server-side monotonic profile revision counter (`profileVersion`).
///
/// Required field on `ClientAccessibleAgent` and `AgentCatalogRecord` since
/// the hub started exposing optimistic concurrency for agent profile writes.
/// Older hub builds may still omit it — when missing or non-numeric, this
/// helper returns `null` so the entity can decide to skip CAS rather than
/// send `expectedProfileVersion: 0` (which behaves as "match a fresh
/// profile" and would falsely succeed only on never-edited agents).
int? _parseOptionalProfileVersionFromJson(Map<String, dynamic> json) {
  final raw = json['profileVersion'] ?? json['profile_version'];
  if (raw is int) {
    return raw < 0 ? null : raw;
  }
  if (raw is num) {
    final value = raw.toInt();
    return value < 0 ? null : value;
  }
  if (raw is String) {
    final parsed = int.tryParse(raw.trim());
    if (parsed == null || parsed < 0) {
      return null;
    }
    return parsed;
  }
  return null;
}

/// Server-side token presence flag exposed by `GET /client/me/agents` and
/// `GET /client/me/agents/{id}` (`hasClientToken: boolean`). Returns `null`
/// when the API omits the field — older hubs or list aliases that do not
/// surface it. The actual token value never travels through these payloads.
bool? _parseOptionalHasClientTokenFromJson(Map<String, dynamic> json) {
  const keys = <String>['hasClientToken', 'has_client_token'];
  for (final key in keys) {
    final value = json[key];
    if (value is bool) {
      return value;
    }
    if (value is String) {
      final s = value.trim().toLowerCase();
      if (s == 'true') {
        return true;
      }
      if (s == 'false') {
        return false;
      }
    }
  }
  return null;
}

/// Hub presence fields the API may send on `GET /client/me/agents` rows.
bool? _parseOptionalHubConnectedFromJson(Map<String, dynamic> json) {
  const keys = <String>[
    'isHubConnected',
    'hubConnected',
    'isConnected',
    'online',
  ];
  for (final key in keys) {
    final v = json[key];
    if (v is bool) {
      return v;
    }
    if (v is String) {
      final s = v.trim().toLowerCase();
      if (s == 'true' || s == 'online' || s == 'connected') {
        return true;
      }
      if (s == 'false' || s == 'offline' || s == 'disconnected') {
        return false;
      }
    }
  }
  return null;
}

class ClientAgentProfileDto {
  const ClientAgentProfileDto({
    required this.agentId,
    required this.name,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.tradeName,
    this.document,
    this.cnpjCpf,
    this.documentType,
    this.phone,
    this.mobile,
    this.email,
    this.address,
    this.notes,
    this.observation,
    this.profileUpdatedAt,
    this.profileVersion,
    this.isHubConnected,
    this.hasClientToken,
  });

  factory ClientAgentProfileDto.fromJson(Map<String, dynamic> json) {
    return ClientAgentProfileDto(
      agentId: json['agentId'] as String,
      name: json['name'] as String,
      status: json['status'] as String,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      tradeName: json['tradeName'] as String?,
      document: json['document'] as String?,
      cnpjCpf: json['cnpjCpf'] as String?,
      documentType: json['documentType'] as String?,
      phone: json['phone'] as String?,
      mobile: json['mobile'] as String?,
      email: json['email'] as String?,
      address: (json['address'] as Map<String, dynamic>?) == null
          ? null
          : ClientAgentAddressDto.fromJson(
              json['address'] as Map<String, dynamic>,
            ),
      notes: json['notes'] as String?,
      observation: json['observation'] as String?,
      profileUpdatedAt: DateTime.tryParse(
        json['profileUpdatedAt'] as String? ?? '',
      ),
      profileVersion: _parseOptionalProfileVersionFromJson(json),
      isHubConnected: _parseOptionalHubConnectedFromJson(json),
      hasClientToken: _parseOptionalHasClientTokenFromJson(json),
    );
  }

  final String agentId;
  final String name;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? tradeName;
  final String? document;
  final String? cnpjCpf;
  final String? documentType;
  final String? phone;
  final String? mobile;
  final String? email;
  final ClientAgentAddressDto? address;
  final String? notes;
  final String? observation;
  final DateTime? profileUpdatedAt;

  /// Server-side monotonic profile revision counter — required field on
  /// the current `ClientAccessibleAgent` / `AgentCatalogRecord` schema.
  /// `null` is preserved for older hub builds and partial payloads so we
  /// can omit `expectedProfileVersion` on PATCH instead of sending `0`,
  /// which would behave like an unconditional CAS write.
  final int? profileVersion;

  /// Null: hub did not send per-row presence; UI may fall back to cached ids.
  final bool? isHubConnected;

  /// Null: server did not include the field (older hub or non-listing endpoint).
  /// `true`: a per-(client, agent) bearer token is stored server-side and the
  /// hub will inject it as `params.client_token` on the SQL bridge. The actual
  /// token is only readable via `GET /client/me/agents/{id}/client-token`.
  final bool? hasClientToken;

  ClientAgent toEntity({
    AgentConnectionStatus connectionStatus = AgentConnectionStatus.unknown,
    bool isStaleCache = false,
  }) {
    return ClientAgent(
      agentId: agentId,
      name: name,
      tradeName: tradeName,
      document: document,
      cnpjCpf: cnpjCpf,
      registrationDocument: document ?? cnpjCpf,
      documentType: documentType,
      phone: phone,
      mobile: mobile,
      email: email,
      address: address?.toEntity(),
      notes: notes,
      observation: observation,
      profileUpdatedAt: profileUpdatedAt,
      profileVersion: profileVersion,
      catalogStatus: AgentCatalogStatus.fromWireValue(status),
      connectionStatus: connectionStatus,
      createdAt: createdAt,
      updatedAt: updatedAt,
      hasServerClientToken: hasClientToken,
      isStaleCache: isStaleCache,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'agentId': agentId,
      'name': name,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'tradeName': tradeName,
      'document': document,
      'cnpjCpf': cnpjCpf,
      'documentType': documentType,
      'phone': phone,
      'mobile': mobile,
      'email': email,
      'address': address?.toJson(),
      'notes': notes,
      'observation': observation,
      'profileUpdatedAt': profileUpdatedAt?.toIso8601String(),
      if (profileVersion != null) 'profileVersion': profileVersion,
      if (isHubConnected != null) 'isHubConnected': isHubConnected,
      if (hasClientToken != null) 'hasClientToken': hasClientToken,
    };
  }
}

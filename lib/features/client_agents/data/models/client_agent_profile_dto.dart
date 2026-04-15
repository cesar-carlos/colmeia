import 'package:colmeia/features/client_agents/data/models/client_agent_address_dto.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_catalog_status.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_connection_status.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent.dart';

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
    this.isHubConnected,
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
      isHubConnected: _parseOptionalHubConnectedFromJson(json),
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

  /// Null: hub did not send per-row presence; UI may fall back to cached ids.
  final bool? isHubConnected;

  ClientAgent toEntity({
    AgentConnectionStatus connectionStatus = AgentConnectionStatus.unknown,
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
      catalogStatus: AgentCatalogStatus.fromWireValue(status),
      connectionStatus: connectionStatus,
      createdAt: createdAt,
      updatedAt: updatedAt,
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
      if (isHubConnected != null) 'isHubConnected': isHubConnected,
    };
  }
}

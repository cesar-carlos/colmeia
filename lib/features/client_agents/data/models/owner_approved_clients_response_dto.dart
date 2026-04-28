import 'package:colmeia/features/client_agents/data/models/owner_approved_client_dto.dart';

class OwnerApprovedClientsResponseDto {
  const OwnerApprovedClientsResponseDto({
    required this.clients,
    required this.count,
    required this.total,
  });

  factory OwnerApprovedClientsResponseDto.fromJson(Map<String, dynamic> json) {
    final rawItems =
        (json['clients'] as List<dynamic>?) ??
        (json['items'] as List<dynamic>?) ??
        (json['data'] as List<dynamic>?) ??
        const <dynamic>[];
    final clients = rawItems
        .whereType<Map<String, dynamic>>()
        .map(OwnerApprovedClientDto.fromJson)
        .toList(growable: false);
    return OwnerApprovedClientsResponseDto(
      clients: clients,
      count: (json['count'] as num?)?.toInt() ?? clients.length,
      total:
          (json['total'] as num?)?.toInt() ??
          (json['count'] as num?)?.toInt() ??
          clients.length,
    );
  }

  final List<OwnerApprovedClientDto> clients;
  final int count;
  final int total;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'clients': clients.map((item) => item.toJson()).toList(growable: false),
      'count': count,
      'total': total,
    };
  }
}

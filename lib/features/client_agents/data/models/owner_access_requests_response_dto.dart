import 'package:colmeia/features/client_agents/data/models/owner_client_access_request_dto.dart';

class OwnerAccessRequestsResponseDto {
  const OwnerAccessRequestsResponseDto({
    required this.requests,
    required this.count,
    required this.total,
  });

  factory OwnerAccessRequestsResponseDto.fromJson(Map<String, dynamic> json) {
    final rawItems =
        (json['requests'] as List<dynamic>?) ??
        (json['items'] as List<dynamic>?) ??
        (json['data'] as List<dynamic>?) ??
        const <dynamic>[];
    final requests = rawItems
        .whereType<Map<String, dynamic>>()
        .map(OwnerClientAccessRequestDto.fromJson)
        .toList(growable: false);
    return OwnerAccessRequestsResponseDto(
      requests: requests,
      count: (json['count'] as num?)?.toInt() ?? requests.length,
      total:
          (json['total'] as num?)?.toInt() ??
          (json['count'] as num?)?.toInt() ??
          requests.length,
    );
  }

  final List<OwnerClientAccessRequestDto> requests;
  final int count;
  final int total;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'requests': requests.map((item) => item.toJson()).toList(growable: false),
      'count': count,
      'total': total,
    };
  }
}

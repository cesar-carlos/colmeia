import 'package:colmeia/features/client_agents/data/models/client_agent_access_request_dto.dart';
import 'package:colmeia/features/client_agents/data/models/paginated_response_dto.dart';

class ClientAccessRequestsResponseDto implements PaginatedResponseDto {
  const ClientAccessRequestsResponseDto({
    required this.requests,
    required this.count,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  factory ClientAccessRequestsResponseDto.fromJson(Map<String, dynamic> json) {
    final dynamicItems =
        (json['requests'] as List<dynamic>?) ??
        (json['items'] as List<dynamic>?) ??
        (json['data'] as List<dynamic>?) ??
        const <dynamic>[];
    final mappedItems = dynamicItems
        .whereType<Map<String, dynamic>>()
        .map(ClientAgentAccessRequestDto.fromJson)
        .toList(growable: false);

    return ClientAccessRequestsResponseDto(
      requests: mappedItems,
      count: (json['count'] as num?)?.toInt() ?? mappedItems.length,
      total:
          (json['total'] as num?)?.toInt() ??
          (json['count'] as num?)?.toInt() ??
          mappedItems.length,
      page: (json['page'] as num?)?.toInt() ?? 1,
      pageSize:
          (json['pageSize'] as num?)?.toInt() ??
          (json['page_size'] as num?)?.toInt() ??
          mappedItems.length,
    );
  }

  final List<ClientAgentAccessRequestDto> requests;
  @override
  final int count;
  @override
  final int total;
  @override
  final int page;
  @override
  final int pageSize;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'requests': requests.map((item) => item.toJson()).toList(growable: false),
      'count': count,
      'total': total,
      'page': page,
      'pageSize': pageSize,
    };
  }
}

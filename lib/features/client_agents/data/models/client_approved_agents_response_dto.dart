import 'package:colmeia/features/client_agents/data/models/client_accessible_agent_dto.dart';
import 'package:colmeia/features/client_agents/data/models/paginated_response_dto.dart';

class ClientApprovedAgentsResponseDto implements PaginatedResponseDto {
  const ClientApprovedAgentsResponseDto({
    required this.agents,
    required this.agentIds,
    required this.count,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  factory ClientApprovedAgentsResponseDto.fromJson(Map<String, dynamic> json) {
    final dynamicItems =
        (json['agents'] as List<dynamic>?) ??
        (json['items'] as List<dynamic>?) ??
        (json['data'] as List<dynamic>?) ??
        const <dynamic>[];
    final mappedItems = dynamicItems
        .whereType<Map<String, dynamic>>()
        .map(ClientAccessibleAgentDto.fromJson)
        .toList(growable: false);
    final mappedAgentIds = mappedItems
        .map((agent) => agent.agentId)
        .where((agentId) => agentId.isNotEmpty)
        .toSet();

    return ClientApprovedAgentsResponseDto(
      agents: mappedItems,
      agentIds:
          (json['agentIds'] as List<dynamic>? ?? const <dynamic>[])
              .whereType<String>()
              .toSet()
            ..addAll(mappedAgentIds),
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

  final List<ClientAccessibleAgentDto> agents;
  final Set<String> agentIds;
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
      'agents': agents.map((item) => item.toJson()).toList(growable: false),
      'agentIds': agentIds.toList(growable: false),
      'count': count,
      'total': total,
      'page': page,
      'pageSize': pageSize,
    };
  }
}

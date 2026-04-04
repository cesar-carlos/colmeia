import 'package:colmeia/features/client_agents/data/models/agent_catalog_record_dto.dart';

class PaginatedAgentCatalogResponseDto {
  const PaginatedAgentCatalogResponseDto({
    required this.agents,
    required this.count,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  factory PaginatedAgentCatalogResponseDto.fromJson(Map<String, dynamic> json) {
    return PaginatedAgentCatalogResponseDto(
      agents: (json['agents'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(AgentCatalogRecordDto.fromJson)
          .toList(growable: false),
      count: (json['count'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      pageSize: (json['pageSize'] as num?)?.toInt() ?? 20,
    );
  }

  final List<AgentCatalogRecordDto> agents;
  final int count;
  final int total;
  final int page;
  final int pageSize;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'agents': agents.map((item) => item.toJson()).toList(growable: false),
      'count': count,
      'total': total,
      'page': page,
      'pageSize': pageSize,
    };
  }
}

import 'package:colmeia/features/client_agents/data/models/client_accessible_agent_dto.dart';

class ClientApprovedAgentsResponseDto {
  const ClientApprovedAgentsResponseDto({
    required this.agents,
    required this.agentIds,
    required this.count,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  factory ClientApprovedAgentsResponseDto.fromJson(Map<String, dynamic> json) {
    return ClientApprovedAgentsResponseDto(
      agents: (json['agents'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(ClientAccessibleAgentDto.fromJson)
          .toList(growable: false),
      agentIds: (json['agentIds'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<String>()
          .toSet(),
      count: (json['count'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      pageSize: (json['pageSize'] as num?)?.toInt() ?? 20,
    );
  }

  final List<ClientAccessibleAgentDto> agents;
  final Set<String> agentIds;
  final int count;
  final int total;
  final int page;
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

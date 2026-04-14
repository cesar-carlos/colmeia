import 'package:colmeia/features/client_agents/data/models/online_agent_dto.dart';

class OnlineAgentsResponseDto {
  const OnlineAgentsResponseDto({
    required this.agents,
    required this.count,
    this.malformedAgentRowCount = 0,
  });

  factory OnlineAgentsResponseDto.fromJson(Map<String, dynamic> json) {
    final raw = json['agents'] as List<dynamic>? ?? const <dynamic>[];
    var malformedAgentRowCount = 0;
    final agents = <OnlineAgentDto>[];
    for (final item in raw) {
      if (item is! Map<String, dynamic>) {
        malformedAgentRowCount++;
        continue;
      }
      final dto = OnlineAgentDto.tryFromJson(item);
      if (dto == null) {
        malformedAgentRowCount++;
      } else {
        agents.add(dto);
      }
    }
    return OnlineAgentsResponseDto(
      agents: agents,
      count: (json['count'] as num?)?.toInt() ?? agents.length,
      malformedAgentRowCount: malformedAgentRowCount,
    );
  }

  final List<OnlineAgentDto> agents;
  final int count;

  /// Rows in `agents` that were not object maps or had no valid `agentId`/`id`.
  final int malformedAgentRowCount;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'agents': agents.map((item) => item.toJson()).toList(growable: false),
      'count': count,
      'malformedAgentRowCount': malformedAgentRowCount,
    };
  }
}

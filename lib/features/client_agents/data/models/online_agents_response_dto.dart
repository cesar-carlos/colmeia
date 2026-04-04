import 'package:colmeia/features/client_agents/data/models/online_agent_dto.dart';

class OnlineAgentsResponseDto {
  const OnlineAgentsResponseDto({
    required this.agents,
    required this.count,
  });

  factory OnlineAgentsResponseDto.fromJson(Map<String, dynamic> json) {
    final agents = (json['agents'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(OnlineAgentDto.fromJson)
        .toList(growable: false);
    return OnlineAgentsResponseDto(
      agents: agents,
      count: (json['count'] as num?)?.toInt() ?? agents.length,
    );
  }

  final List<OnlineAgentDto> agents;
  final int count;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'agents': agents.map((item) => item.toJson()).toList(growable: false),
      'count': count,
    };
  }
}

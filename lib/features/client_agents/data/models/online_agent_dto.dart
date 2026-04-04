import 'package:colmeia/features/client_agents/domain/entities/agent_connection_status.dart';

class OnlineAgentDto {
  const OnlineAgentDto({
    required this.agentId,
    this.connectedAt,
    this.lastSeenAt,
  });

  factory OnlineAgentDto.fromJson(Map<String, dynamic> json) {
    return OnlineAgentDto(
      agentId: json['agentId'] as String,
      connectedAt: DateTime.tryParse(json['connectedAt'] as String? ?? ''),
      lastSeenAt: DateTime.tryParse(json['lastSeenAt'] as String? ?? ''),
    );
  }

  final String agentId;
  final DateTime? connectedAt;
  final DateTime? lastSeenAt;

  AgentConnectionStatus get connectionStatus => AgentConnectionStatus.online;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'agentId': agentId,
      'connectedAt': connectedAt?.toIso8601String(),
      'lastSeenAt': lastSeenAt?.toIso8601String(),
    };
  }
}

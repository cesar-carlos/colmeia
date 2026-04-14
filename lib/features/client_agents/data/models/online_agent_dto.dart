import 'package:colmeia/features/client_agents/domain/entities/agent_connection_status.dart';

class OnlineAgentDto {
  const OnlineAgentDto({
    required this.agentId,
    this.connectedAt,
    this.lastSeenAt,
  });

  factory OnlineAgentDto.fromJson(Map<String, dynamic> json) {
    final parsed = tryFromJson(json);
    if (parsed == null) {
      throw FormatException(
        'OnlineAgentDto.fromJson: missing or invalid agent id',
        json,
      );
    }
    return parsed;
  }

  final String agentId;
  final DateTime? connectedAt;
  final DateTime? lastSeenAt;

  AgentConnectionStatus get connectionStatus => AgentConnectionStatus.online;

  /// Parses when [json] contains a non-empty agent id (`agentId` or `id`).
  ///
  /// Returns null if the payload is not a valid online row (avoids failing the
  /// entire [GET /agents] list when one entry is malformed).
  static OnlineAgentDto? tryFromJson(Map<String, dynamic> json) {
    final agentId = _parseAgentId(json);
    if (agentId == null) {
      return null;
    }
    return OnlineAgentDto(
      agentId: agentId,
      connectedAt: DateTime.tryParse(json['connectedAt'] as String? ?? ''),
      lastSeenAt: DateTime.tryParse(json['lastSeenAt'] as String? ?? ''),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'agentId': agentId,
      'connectedAt': connectedAt?.toIso8601String(),
      'lastSeenAt': lastSeenAt?.toIso8601String(),
    };
  }

  static String? _parseAgentId(Map<String, dynamic> json) {
    final raw = json['agentId'] ?? json['id'];
    if (raw == null) {
      return null;
    }
    final trimmed = raw.toString().trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

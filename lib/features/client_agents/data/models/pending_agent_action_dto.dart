import 'package:colmeia/features/client_agents/domain/entities/pending_agent_action.dart';

class PendingAgentActionDto {
  const PendingAgentActionDto({
    required this.id,
    required this.agentId,
    required this.type,
    required this.state,
    required this.createdAt,
    required this.attemptCount,
    this.lastAttemptAt,
    this.errorMessage,
  });

  factory PendingAgentActionDto.fromEntity(PendingAgentAction action) {
    return PendingAgentActionDto(
      id: action.id,
      agentId: action.agentId,
      type: action.type.name,
      state: action.state.name,
      createdAt: action.createdAt,
      lastAttemptAt: action.lastAttemptAt,
      attemptCount: action.attemptCount,
      errorMessage: action.errorMessage,
    );
  }

  factory PendingAgentActionDto.fromJson(Map<String, dynamic> json) {
    return PendingAgentActionDto(
      id: json['id'] as String,
      agentId: json['agentId'] as String,
      type: json['type'] as String,
      state: json['state'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastAttemptAt: DateTime.tryParse(json['lastAttemptAt'] as String? ?? ''),
      attemptCount: (json['attemptCount'] as num?)?.toInt() ?? 0,
      errorMessage: json['errorMessage'] as String?,
    );
  }

  final String id;
  final String agentId;
  final String type;
  final String state;
  final DateTime createdAt;
  final DateTime? lastAttemptAt;
  final int attemptCount;
  final String? errorMessage;

  PendingAgentAction toEntity() {
    return PendingAgentAction(
      id: id,
      agentId: agentId,
      type: _parseType(type),
      state: _parseState(state),
      createdAt: createdAt,
      lastAttemptAt: lastAttemptAt,
      attemptCount: attemptCount,
      errorMessage: errorMessage,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'agentId': agentId,
      'type': type,
      'state': state,
      'createdAt': createdAt.toIso8601String(),
      'lastAttemptAt': lastAttemptAt?.toIso8601String(),
      'attemptCount': attemptCount,
      'errorMessage': errorMessage,
    };
  }

  PendingAgentActionType _parseType(String raw) {
    return switch (raw) {
      'removeAccess' => PendingAgentActionType.removeAccess,
      _ => PendingAgentActionType.requestAccess,
    };
  }

  PendingAgentActionState _parseState(String raw) {
    return switch (raw) {
      'syncing' => PendingAgentActionState.syncing,
      'failed' => PendingAgentActionState.failed,
      'synced' => PendingAgentActionState.synced,
      _ => PendingAgentActionState.queued,
    };
  }
}

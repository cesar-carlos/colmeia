enum PendingAgentActionType { requestAccess, removeAccess }

enum PendingAgentActionState { queued, syncing, failed, synced }

class PendingAgentAction {
  const PendingAgentAction({
    required this.id,
    required this.agentId,
    required this.type,
    required this.state,
    required this.createdAt,
    required this.attemptCount,
    this.lastAttemptAt,
    this.errorMessage,
  });

  final String id;
  final String agentId;
  final PendingAgentActionType type;
  final PendingAgentActionState state;
  final DateTime createdAt;
  final DateTime? lastAttemptAt;
  final int attemptCount;
  final String? errorMessage;

  PendingAgentAction copyWith({
    PendingAgentActionState? state,
    DateTime? lastAttemptAt,
    int? attemptCount,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return PendingAgentAction(
      id: id,
      agentId: agentId,
      type: type,
      state: state ?? this.state,
      createdAt: createdAt,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      attemptCount: attemptCount ?? this.attemptCount,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
    );
  }
}

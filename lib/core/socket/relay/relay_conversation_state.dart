/// Lifecycle state of a single relay conversation, observed by the
/// `RelayConversationManager`. Sealed so adding a new state at the manager
/// is a compile-time event for every observer.
sealed class RelayConversationState {
  const RelayConversationState();
}

final class RelayConversationIdle extends RelayConversationState {
  const RelayConversationIdle();
}

final class RelayConversationStarting extends RelayConversationState {
  const RelayConversationStarting({required this.agentId});
  final String agentId;
}

final class RelayConversationActive extends RelayConversationState {
  const RelayConversationActive({
    required this.agentId,
    required this.conversationId,
    required this.openedAt,
  });
  final String agentId;
  final String conversationId;
  final DateTime openedAt;
}

final class RelayConversationEnding extends RelayConversationState {
  const RelayConversationEnding({
    required this.agentId,
    required this.conversationId,
  });
  final String agentId;
  final String conversationId;
}

final class RelayConversationEnded extends RelayConversationState {
  const RelayConversationEnded({
    required this.agentId,
    this.conversationId,
    this.reason,
  });
  final String agentId;
  final String? conversationId;
  final String? reason;
}

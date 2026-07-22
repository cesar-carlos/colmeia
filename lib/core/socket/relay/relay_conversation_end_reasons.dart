/// Public `relay:conversation.ended.reason` values documented by the hub.
///
/// Source: `docs/plug_server/socket/socket_relay_protocol.md`.
abstract final class RelayConversationEndReasons {
  static const String consumerEnded = 'consumer_ended';
  static const String agentDisconnected = 'agent_disconnected';
  static const String expired = 'expired';

  static const Set<String> publicHubReasons = <String>{
    consumerEnded,
    agentDisconnected,
    expired,
  };

  /// Prefers a hub public reason when present; otherwise [localReason].
  static String? resolve({
    required Object? hubReason,
    String? localReason,
  }) {
    final hub = hubReason?.toString();
    if (hub != null && hub.isNotEmpty) {
      return hub;
    }
    return localReason;
  }
}

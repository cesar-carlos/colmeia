class SyncPendingAgentActionsResult {
  const SyncPendingAgentActionsResult({
    this.successfulRequestAccessAgentIds = const <String>{},
    this.successfulRemoveAccessAgentIds = const <String>{},
    this.failedRequestAccessAgentIds = const <String>{},
    this.failedRemoveAccessAgentIds = const <String>{},
  });

  final Set<String> successfulRequestAccessAgentIds;
  final Set<String> successfulRemoveAccessAgentIds;
  final Set<String> failedRequestAccessAgentIds;
  final Set<String> failedRemoveAccessAgentIds;
}

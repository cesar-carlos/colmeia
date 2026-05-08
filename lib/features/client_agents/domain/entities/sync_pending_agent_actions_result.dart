class SyncPendingAgentActionsResult {
  const SyncPendingAgentActionsResult({
    this.successfulRequestAccessAgentIds = const <String>{},
    this.successfulRemoveAccessAgentIds = const <String>{},
    this.failedRequestAccessAgentIds = const <String>{},
    this.failedRemoveAccessAgentIds = const <String>{},
    this.requestAccessPollAgentIds = const <String>{},
    this.requestAccessAlreadyApprovedAgentIds = const <String>{},
    this.requestAccessDebouncedAgentIds = const <String>{},
    this.requestAccessNewRequestsAgentIds = const <String>{},
  });

  final Set<String> successfulRequestAccessAgentIds;
  final Set<String> successfulRemoveAccessAgentIds;
  final Set<String> failedRequestAccessAgentIds;
  final Set<String> failedRemoveAccessAgentIds;

  /// Subset of [successfulRequestAccessAgentIds] that still need approval
  /// polling (`requested` / `newRequests` / `reopened` / `debounced` from POST,
  /// not `alreadyApproved`).
  final Set<String> requestAccessPollAgentIds;

  /// Agent ids the server reported as already approved in the POST response.
  final Set<String> requestAccessAlreadyApprovedAgentIds;

  /// Agent ids skipped due to debounce (no new email); may still be pending.
  final Set<String> requestAccessDebouncedAgentIds;

  /// Agent ids the server placed in `newRequests` for this POST response.
  final Set<String> requestAccessNewRequestsAgentIds;

  int get successfulActionCount =>
      successfulRequestAccessAgentIds.length +
      successfulRemoveAccessAgentIds.length;

  int get failedActionCount =>
      failedRequestAccessAgentIds.length + failedRemoveAccessAgentIds.length;
}

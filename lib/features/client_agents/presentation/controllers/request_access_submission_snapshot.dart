/// Snapshot passed from `ClientAgentsController.requestAccess` to its
/// optional `onResolved` callback so the caller knows which ids ended up
/// where after preflight + classification + queueing.
class RequestAccessSubmissionSnapshot {
  const RequestAccessSubmissionSnapshot({
    required this.relinkedAgentIds,
    required this.queuedAgentIds,
  });

  /// Ids the server already had linked for this client. Tokens for these
  /// can be PUT to the server immediately.
  final Set<String> relinkedAgentIds;

  /// Ids the controller placed in the local pending queue (POST will fire
  /// on the next sync). Tokens for these are stashed locally and PUT to the
  /// server later, after approval polling sees the link.
  final Set<String> queuedAgentIds;
}

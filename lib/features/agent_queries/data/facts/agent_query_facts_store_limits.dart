/// Persisted agent-query facts store limits enforced on the write path.
abstract final class AgentQueryFactsStoreLimits {
  /// Maximum fact payload entries kept per user before LRU eviction runs.
  ///
  /// Eviction removes the least-recently-written keys first using a per-user
  /// index stored alongside fact payloads in the app cache store.
  static const int maxEntriesPerUser = 512;
}

/// Key-value cache used by feature local datasources (dashboards, reports).
///
/// TTL and per-resource invalidation stay in repositories or use cases that
/// own the cache keys; this type only persists opaque string payloads.
abstract class AppCacheStore {
  Future<String?> getString(String key);

  Future<void> putString({
    required String key,
    required String value,
  });

  /// Removes a single entry when present (e.g. invalidate stale agent detail).
  Future<void> removeString(String key);

  /// Clears all cached entries (e.g. after sign-out so another user never reads
  /// stale dashboard or report snapshots).
  Future<void> clearAll();
}

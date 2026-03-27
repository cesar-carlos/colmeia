/// Key-value cache used by feature local datasources (dashboards, reports).
abstract class AppCacheStore {
  Future<String?> getString(String key);

  Future<void> putString({
    required String key,
    required String value,
  });
}

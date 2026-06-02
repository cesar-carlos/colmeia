import 'package:colmeia/core/cache/app_cache_store.dart';

/// In-memory [AppCacheStore] for agent-queries E2E (no Hive / path_provider).
final class E2eInMemoryAppCacheStore implements AppCacheStore {
  final Map<String, String> _data = <String, String>{};

  @override
  Future<void> clearAll() async {
    _data.clear();
  }

  @override
  Future<String?> getString(String key) async => _data[key];

  @override
  Future<void> putString({
    required String key,
    required String value,
  }) async {
    _data[key] = value;
  }

  @override
  Future<void> removeString(String key) async {
    _data.remove(key);
  }

  @override
  Future<void> removeKeysWithPrefix(String prefix) async {
    _data.removeWhere((key, _) => key.startsWith(prefix));
  }

  @override
  Future<void> removeKeysWhere({
    required String prefix,
    required bool Function(String key) predicate,
  }) async {
    _data.removeWhere(
      (key, _) => key.startsWith(prefix) && predicate(key),
    );
  }
}

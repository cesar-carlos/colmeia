import 'package:colmeia/core/cache/app_cache_store.dart';
import 'package:colmeia/features/agent_queries/data/facts/hive_agent_query_facts_store.dart';
import 'package:colmeia/features/agent_queries/domain/cache/agent_query_facts_store.dart';

/// In-memory [AppCacheStore] for facts-store unit tests.
final class MemoryAppCacheStore implements AppCacheStore {
  final Map<String, String> _entries = <String, String>{};

  @override
  Future<void> clearAll() async => _entries.clear();

  @override
  Future<String?> getString(String key) async => _entries[key];

  @override
  Future<void> putString({required String key, required String value}) async {
    _entries[key] = value;
  }

  @override
  Future<void> removeString(String key) async {
    _entries.remove(key);
  }

  @override
  Future<void> removeKeysWithPrefix(String prefix) async {
    _entries.removeWhere((key, _) => key.startsWith(prefix));
  }

  @override
  Future<void> removeKeysWhere({
    required String prefix,
    required bool Function(String key) predicate,
  }) async {
    _entries.removeWhere(
      (key, _) => key.startsWith(prefix) && predicate(key),
    );
  }
}

AgentQueryFactsStore memoryAgentQueryFactsStore() =>
    HiveAgentQueryFactsStore(MemoryAppCacheStore());

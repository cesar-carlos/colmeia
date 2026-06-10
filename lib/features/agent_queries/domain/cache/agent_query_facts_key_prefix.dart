import 'package:colmeia/core/cache/app_kv_cache_key_prefixes.dart';
import 'package:colmeia/features/agent_queries/domain/cache/agent_query_fact_kind.dart';
import 'package:colmeia/features/agent_queries/domain/cache/agent_query_facts_store.dart'
    show AgentQueryFactsStore;

/// Canonical key prefixes for [AgentQueryFactsStore] invalidation.
abstract final class AgentQueryFactsKeyPrefix {
  static String forUser(String userId) =>
      '${AppKvCacheKeyPrefixes.agentQueryFacts}$userId:';

  static String forAgent({
    required String userId,
    required String agentId,
  }) => '${forUser(userId)}$agentId:';

  static bool matchesFactKind({
    required String storageKey,
    required AgentQueryFactKind factKind,
  }) {
    return storageKey.contains(':${factKind.name}:');
  }
}

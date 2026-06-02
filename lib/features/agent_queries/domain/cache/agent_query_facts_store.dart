import 'package:colmeia/features/agent_queries/domain/cache/agent_query_fact_kind.dart';

/// Opaque persistence for consolidated agent-query fact payloads.
abstract interface class AgentQueryFactsStore {
  Future<List<int>?> readPayload({
    required String storageKey,
    int? expectedSchemaVersion,
  });

  /// Reads multiple keys; missing or stale entries are omitted.
  Future<Map<String, List<int>>> readPayloadsForKeys({
    required List<String> storageKeys,
    int? expectedSchemaVersion,
  });

  Future<void> writePayload({
    required String storageKey,
    required List<int> payload,
    required int schemaVersion,
  });

  Future<void> removeKey(String storageKey);

  /// Removes every key that starts with [keyPrefix].
  Future<void> removeMatching(String keyPrefix);

  /// Removes keys for [userId] whose path includes [factKind].
  Future<void> removeMatchingFactKind({
    required String userId,
    required AgentQueryFactKind factKind,
  });
}

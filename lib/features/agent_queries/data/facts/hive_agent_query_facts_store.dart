import 'dart:convert';

import 'package:colmeia/core/cache/app_cache_store.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/agent_queries/data/facts/agent_query_facts_envelope.dart';
import 'package:colmeia/features/agent_queries/domain/cache/agent_query_fact_kind.dart';
import 'package:colmeia/features/agent_queries/domain/cache/agent_query_facts_key_prefix.dart';
import 'package:colmeia/features/agent_queries/domain/cache/agent_query_facts_store.dart';
import 'package:colmeia/features/agent_queries/domain/cache/agent_query_facts_store_metrics.dart';

/// Persists fact payloads via [AppCacheStore] string values.
final class HiveAgentQueryFactsStore implements AgentQueryFactsStore {
  HiveAgentQueryFactsStore(this._cacheStore);

  final AppCacheStore _cacheStore;

  @override
  Future<List<int>?> readPayload({
    required String storageKey,
    int? expectedSchemaVersion,
  }) async {
    final raw = await _cacheStore.getString(storageKey);
    if (raw == null || raw.isEmpty) {
      AgentQueryFactsStoreMetrics.instance.misses++;
      return null;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        AgentQueryFactsStoreMetrics.instance.misses++;
        await removeKey(storageKey);
        return null;
      }
      final envelope = AgentQueryFactsEnvelope.fromJson(decoded);
      if (expectedSchemaVersion != null &&
          envelope.schemaVersion != expectedSchemaVersion) {
        AgentQueryFactsStoreMetrics.instance.staleSchemaEvictions++;
        AgentQueryFactsStoreMetrics.instance.misses++;
        await removeKey(storageKey);
        return null;
      }
      if (envelope.payloadBase64.isEmpty) {
        AgentQueryFactsStoreMetrics.instance.misses++;
        await removeKey(storageKey);
        return null;
      }
      AgentQueryFactsStoreMetrics.instance.hits++;
      return AgentQueryFactsEnvelope.decodePayloadBase64(envelope.payloadBase64);
    } on Object catch (error, stackTrace) {
      AgentQueryFactsStoreMetrics.instance.misses++;
      await removeKey(storageKey);
      AppLogger.warning(
        'Agent query facts decode failed; treating as miss',
        context: <String, Object?>{
          'operation': 'readPayload',
          'storageKeyHash': storageKey.hashCode,
        },
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  @override
  Future<Map<String, List<int>>> readPayloadsForKeys({
    required List<String> storageKeys,
    int? expectedSchemaVersion,
  }) async {
    final result = <String, List<int>>{};
    for (final key in storageKeys) {
      final payload = await readPayload(
        storageKey: key,
        expectedSchemaVersion: expectedSchemaVersion,
      );
      if (payload != null) {
        result[key] = payload;
      }
    }
    return result;
  }

  @override
  Future<void> writePayload({
    required String storageKey,
    required List<int> payload,
    required int schemaVersion,
  }) async {
    final envelope = AgentQueryFactsEnvelope(
      schemaVersion: schemaVersion,
      payloadBase64: AgentQueryFactsEnvelope.encodePayloadBase64(payload),
    );
    await _cacheStore.putString(
      key: storageKey,
      value: jsonEncode(envelope.toJson()),
    );
    AgentQueryFactsStoreMetrics.instance.writes++;
  }

  @override
  Future<void> removeKey(String storageKey) async {
    await _cacheStore.removeString(storageKey);
  }

  @override
  Future<void> removeMatching(String keyPrefix) async {
    await _cacheStore.removeKeysWithPrefix(keyPrefix);
  }

  @override
  Future<void> removeMatchingFactKind({
    required String userId,
    required AgentQueryFactKind factKind,
  }) async {
    final prefix = AgentQueryFactsKeyPrefix.forUser(userId);
    await _cacheStore.removeKeysWhere(
      prefix: prefix,
      predicate: (key) =>
          AgentQueryFactsKeyPrefix.matchesFactKind(
            storageKey: key,
            factKind: factKind,
          ),
    );
  }
}

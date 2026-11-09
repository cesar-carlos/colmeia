import 'dart:convert';

import 'package:colmeia/core/cache/app_cache_store.dart';
import 'package:colmeia/core/cache/app_kv_cache_key_prefixes.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/agent_queries/data/facts/agent_query_facts_envelope.dart';
import 'package:colmeia/features/agent_queries/data/facts/agent_query_facts_store_limits.dart';
import 'package:colmeia/features/agent_queries/domain/cache/agent_query_fact_kind.dart';
import 'package:colmeia/features/agent_queries/domain/cache/agent_query_facts_key_prefix.dart';
import 'package:colmeia/features/agent_queries/domain/cache/agent_query_facts_store.dart';
import 'package:colmeia/features/agent_queries/domain/cache/agent_query_facts_store_metrics.dart';

/// Persists fact payloads via [AppCacheStore] string values.
final class HiveAgentQueryFactsStore implements AgentQueryFactsStore {
  HiveAgentQueryFactsStore(
    this._cacheStore, {
    int? maxEntriesPerUser,
  }) : _maxEntriesPerUser =
           maxEntriesPerUser ?? AgentQueryFactsStoreLimits.maxEntriesPerUser;

  static const String _lruIndexSuffix = '__lru_v1';

  final AppCacheStore _cacheStore;
  final int _maxEntriesPerUser;
  Future<void> _mutationTail = Future<void>.value();

  Future<void> _mutate(Future<void> Function() operation) {
    final result = _mutationTail.then((_) => operation());
    // A failed operation reaches its caller without blocking later mutations.
    _mutationTail = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return result;
  }

  Future<void> _removeIfUnchanged(String key, String raw) => _mutate(() async {
    if (await _cacheStore.getString(key) == raw) {
      await _removeKey(key);
    }
  });

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
        await _removeIfUnchanged(storageKey, raw);
        return null;
      }
      final envelope = AgentQueryFactsEnvelope.fromJson(decoded);
      if (expectedSchemaVersion != null &&
          envelope.schemaVersion != expectedSchemaVersion) {
        AgentQueryFactsStoreMetrics.instance.staleSchemaEvictions++;
        AgentQueryFactsStoreMetrics.instance.misses++;
        await _removeIfUnchanged(storageKey, raw);
        return null;
      }
      if (envelope.payloadBase64.isEmpty) {
        AgentQueryFactsStoreMetrics.instance.misses++;
        await _removeIfUnchanged(storageKey, raw);
        return null;
      }
      final payload = AgentQueryFactsEnvelope.decodePayloadBase64(
        envelope.payloadBase64,
      );
      AgentQueryFactsStoreMetrics.instance.hits++;
      return payload;
    } on Object catch (error, stackTrace) {
      AgentQueryFactsStoreMetrics.instance.misses++;
      await _removeIfUnchanged(storageKey, raw);
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
    if (storageKeys.isEmpty) {
      return const <String, List<int>>{};
    }
    final payloads = await Future.wait(
      storageKeys.map(
        (key) => readPayload(
          storageKey: key,
          expectedSchemaVersion: expectedSchemaVersion,
        ),
      ),
    );
    final result = <String, List<int>>{};
    for (var i = 0; i < storageKeys.length; i++) {
      final payload = payloads[i];
      if (payload != null) {
        result[storageKeys[i]] = payload;
      }
    }
    return result;
  }

  @override
  Future<void> writePayload({
    required String storageKey,
    required List<int> payload,
    required int schemaVersion,
  }) => _mutate(
    () => _writePayload(
      storageKey: storageKey,
      payload: payload,
      schemaVersion: schemaVersion,
    ),
  );

  Future<void> _writePayload({
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
    await _recordWriteAndEvictIfNeeded(storageKey);
  }

  @override
  Future<void> removeKey(String storageKey) =>
      _mutate(() => _removeKey(storageKey));

  Future<void> _removeKey(String storageKey) async {
    await _cacheStore.removeString(storageKey);
    final userId = _userIdFromStorageKey(storageKey);
    if (userId == null) {
      return;
    }
    await _removeFromLruIndex(
      userId: userId,
      matches: (key) => key == storageKey,
    );
  }

  @override
  Future<void> removeMatching(String keyPrefix) => _mutate(() async {
    await _cacheStore.removeKeysWithPrefix(keyPrefix);
    final userId = _userIdFromStorageKey(keyPrefix);
    if (userId != null) {
      await _removeFromLruIndex(
        userId: userId,
        matches: (key) => key.startsWith(keyPrefix),
      );
    }
  });

  @override
  Future<void> removeMatchingFactKind({
    required String userId,
    required AgentQueryFactKind factKind,
  }) => _mutate(() async {
    bool matches(String key) => AgentQueryFactsKeyPrefix.matchesFactKind(
      storageKey: key,
      factKind: factKind,
    );
    await _cacheStore.removeKeysWhere(
      prefix: AgentQueryFactsKeyPrefix.forUser(userId),
      predicate: matches,
    );
    await _removeFromLruIndex(userId: userId, matches: matches);
  });

  Future<void> _recordWriteAndEvictIfNeeded(String storageKey) async {
    final userId = _userIdFromStorageKey(storageKey);
    if (userId == null) {
      return;
    }
    final lruIndexKey = _lruIndexKey(userId);
    final orderedKeys = await _readLruIndex(userId)
      ..remove(storageKey)
      ..add(storageKey);

    while (orderedKeys.length > _maxEntriesPerUser) {
      final evictedKey = orderedKeys.removeAt(0);
      await _cacheStore.removeString(evictedKey);
      AgentQueryFactsStoreMetrics.instance.evictions++;
    }

    await _cacheStore.putString(
      key: lruIndexKey,
      value: jsonEncode(orderedKeys),
    );
  }

  Future<List<String>> _readLruIndex(String userId) async {
    final raw = await _cacheStore.getString(_lruIndexKey(userId));
    if (raw == null || raw.isEmpty) {
      return <String>[];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List<dynamic>) {
        return <String>[];
      }
      return decoded.whereType<String>().toList(growable: true);
    } on Object {
      return <String>[];
    }
  }

  Future<void> _removeFromLruIndex({
    required String userId,
    required bool Function(String) matches,
  }) async {
    final orderedKeys = await _readLruIndex(userId);
    final previousLength = orderedKeys.length;
    orderedKeys.removeWhere(matches);
    if (previousLength == orderedKeys.length) return;
    await _cacheStore.putString(
      key: _lruIndexKey(userId),
      value: jsonEncode(orderedKeys),
    );
  }

  String _lruIndexKey(String userId) {
    return '${AgentQueryFactsKeyPrefix.forUser(userId)}$_lruIndexSuffix';
  }

  String? _userIdFromStorageKey(String storageKey) {
    const prefix = AppKvCacheKeyPrefixes.agentQueryFacts;
    if (!storageKey.startsWith(prefix)) {
      return null;
    }
    final rest = storageKey.substring(prefix.length);
    final colonIndex = rest.indexOf(':');
    if (colonIndex <= 0) {
      return null;
    }
    return rest.substring(0, colonIndex);
  }
}

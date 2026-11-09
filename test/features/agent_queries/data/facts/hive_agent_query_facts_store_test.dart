import 'dart:convert';

import 'package:colmeia/core/cache/app_cache_store.dart';
import 'package:colmeia/features/agent_queries/data/facts/agent_query_facts_envelope.dart';
import 'package:colmeia/features/agent_queries/data/facts/hive_agent_query_facts_store.dart';
import 'package:colmeia/features/agent_queries/domain/cache/agent_query_fact_kind.dart';
import 'package:colmeia/features/agent_queries/domain/cache/agent_query_facts_key_prefix.dart';
import 'package:flutter_test/flutter_test.dart';

import 'memory_agent_query_facts_store.dart';

void main() {
  group('HiveAgentQueryFactsStore', () {
    test('should enforce per-user capacity during concurrent writes', () async {
      final memory = MemoryAppCacheStore();
      final store = HiveAgentQueryFactsStore(memory, maxEntriesPerUser: 2);
      final prefix = AgentQueryFactsKeyPrefix.forUser('concurrent');
      await Future.wait(<Future<void>>[
        for (var index = 0; index < 6; index++)
          store.writePayload(
            storageKey: '${prefix}agent:dailySales:$index',
            payload: <int>[index],
            schemaVersion: 1,
          ),
      ]);
      for (var index = 0; index < 6; index++) {
        expect(
          await store.readPayload(
            storageKey: '${prefix}agent:dailySales:$index',
          ),
          index < 4 ? isNull : <int>[index],
        );
      }
    });

    test('should prune an agent prefix from the user eviction index', () async {
      final memory = MemoryAppCacheStore();
      final store = HiveAgentQueryFactsStore(memory);
      final prefix = AgentQueryFactsKeyPrefix.forUser('user');
      final first = '${prefix}a:dailySales:1';
      final second = '${prefix}b:dailySales:1';
      await store.writePayload(
        storageKey: first,
        payload: <int>[1],
        schemaVersion: 1,
      );
      await store.writePayload(
        storageKey: second,
        payload: <int>[2],
        schemaVersion: 1,
      );
      await store.removeMatching(
        AgentQueryFactsKeyPrefix.forAgent(userId: 'user', agentId: 'a'),
      );
      expect(
        jsonDecode((await memory.getString('${prefix}__lru_v1'))!),
        <String>[second],
      );
      expect(await store.readPayload(storageKey: second), <int>[2]);
    });

    test(
      'should update the index only once when removing a fact kind',
      () async {
        final memory = _TrackedCacheStore();
        final store = HiveAgentQueryFactsStore(memory);
        final prefix = AgentQueryFactsKeyPrefix.forUser('bulk');
        for (var i = 0; i < 20; i++) {
          await store.writePayload(
            storageKey: '${prefix}a:dailySales:$i',
            payload: <int>[i],
            schemaVersion: 1,
          );
        }
        await store.writePayload(
          storageKey: '${prefix}a:monthlyParcels:1',
          payload: <int>[1],
          schemaVersion: 1,
        );
        memory
          ..reads = 0
          ..writes = 0;
        await store.removeMatchingFactKind(
          userId: 'bulk',
          factKind: AgentQueryFactKind.dailySales,
        );
        expect(memory.reads, 1);
        expect(memory.writes, 1);
        expect(
          await store.readPayload(storageKey: '${prefix}a:monthlyParcels:1'),
          <int>[1],
        );
      },
    );

    test('should continue queued writes after a storage failure', () async {
      final memory = _TrackedCacheStore()..failNextWrite = true;
      final store = HiveAgentQueryFactsStore(memory);
      final prefix = AgentQueryFactsKeyPrefix.forUser('failure');
      final failed = expectLater(
        store.writePayload(
          storageKey: '${prefix}a:dailySales:1',
          payload: <int>[1],
          schemaVersion: 1,
        ),
        throwsStateError,
      );
      final next = store.writePayload(
        storageKey: '${prefix}a:dailySales:2',
        payload: <int>[2],
        schemaVersion: 1,
      );
      await failed;
      await next;
      expect(
        await store.readPayload(storageKey: '${prefix}a:dailySales:2'),
        <int>[2],
      );
    });

    test(
      'should not recreate the index after a queued user invalidation',
      () async {
        final memory = MemoryAppCacheStore();
        final store = HiveAgentQueryFactsStore(memory);
        final prefix = AgentQueryFactsKeyPrefix.forUser('cleared');
        await Future.wait(<Future<void>>[
          store.writePayload(
            storageKey: '${prefix}a:dailySales:1',
            payload: <int>[1],
            schemaVersion: 1,
          ),
          store.removeMatching(prefix),
        ]);
        expect(await memory.getString('${prefix}__lru_v1'), isNull);
        expect(
          await store.readPayload(storageKey: '${prefix}a:dailySales:1'),
          isNull,
        );
      },
    );

    test(
      'should preserve a replacement written during corrupt-data cleanup',
      () async {
        final memory = _TrackedCacheStore();
        final store = HiveAgentQueryFactsStore(memory);
        final key =
            '${AgentQueryFactsKeyPrefix.forUser('replace')}a:dailySales:1';
        await memory.putString(key: key, value: 'invalid-json');
        late Future<void> replacement;
        memory.afterRead = (readKey) {
          if (readKey == key) {
            memory.afterRead = null;
            replacement = store.writePayload(
              storageKey: key,
              payload: <int>[7],
              schemaVersion: 1,
            );
          }
        };
        expect(await store.readPayload(storageKey: key), isNull);
        await replacement;
        expect(await store.readPayload(storageKey: key), <int>[7]);
      },
    );

    test('writePayload then readPayload round-trips bytes', () async {
      final store = memoryAgentQueryFactsStore();
      const key = 'agent_query_facts_test';
      const payload = <int>[1, 2, 3];

      await store.writePayload(
        storageKey: key,
        payload: payload,
        schemaVersion: 1,
      );

      final read = await store.readPayload(
        storageKey: key,
        expectedSchemaVersion: 1,
      );
      expect(read, payload);
    });

    test('stale schema version is treated as miss and key removed', () async {
      final memory = MemoryAppCacheStore();
      final store = HiveAgentQueryFactsStore(memory);
      const key = 'agent_query_facts_stale';

      await memory.putString(
        key: key,
        value: jsonEncode(
          AgentQueryFactsEnvelope(
            schemaVersion: 0,
            payloadBase64: AgentQueryFactsEnvelope.encodePayloadBase64(
              const <int>[1],
            ),
          ).toJson(),
        ),
      );

      final read = await store.readPayload(
        storageKey: key,
        expectedSchemaVersion: 1,
      );
      expect(read, isNull);
      expect(await memory.getString(key), isNull);
    });

    test('removeMatching deletes all keys under user prefix', () async {
      final memory = MemoryAppCacheStore();
      final store = HiveAgentQueryFactsStore(memory);
      const userId = 'user-a';

      await memory.putString(
        key:
            '${AgentQueryFactsKeyPrefix.forUser(userId)}agent1:dailySales:2026-01-01',
        value: 'a',
      );
      await memory.putString(
        key:
            '${AgentQueryFactsKeyPrefix.forUser(userId)}agent2:monthlyParcels:2026-01',
        value: 'b',
      );
      await memory.putString(
        key:
            '${AgentQueryFactsKeyPrefix.forUser('other')}agent1:dailySales:2026-01-01',
        value: 'c',
      );

      await store.removeMatching(AgentQueryFactsKeyPrefix.forUser(userId));

      expect(
        await memory.getString(
          '${AgentQueryFactsKeyPrefix.forUser(userId)}agent1:dailySales:2026-01-01',
        ),
        isNull,
      );
      expect(
        await memory.getString(
          '${AgentQueryFactsKeyPrefix.forUser('other')}agent1:dailySales:2026-01-01',
        ),
        isNotNull,
      );
    });

    test('invalid JSON evicts key on read', () async {
      final memory = MemoryAppCacheStore();
      final store = HiveAgentQueryFactsStore(memory);
      const key = 'agent_query_facts_corrupt';

      await memory.putString(key: key, value: 'not-json');

      final first = await store.readPayload(
        storageKey: key,
        expectedSchemaVersion: 1,
      );
      expect(first, isNull);
      expect(await memory.getString(key), isNull);

      final second = await store.readPayload(
        storageKey: key,
        expectedSchemaVersion: 1,
      );
      expect(second, isNull);
    });

    test('evicts oldest entries when per-user cap is exceeded', () async {
      final memory = MemoryAppCacheStore();
      final store = HiveAgentQueryFactsStore(memory, maxEntriesPerUser: 4);
      const userId = 'user-cap';
      final prefix = AgentQueryFactsKeyPrefix.forUser(userId);

      for (var index = 0; index < 6; index++) {
        await store.writePayload(
          storageKey: '${prefix}agent1:dailySales:2026-01-0$index',
          payload: <int>[index],
          schemaVersion: 1,
        );
      }

      expect(
        await memory.getString('${prefix}agent1:dailySales:2026-01-00'),
        isNull,
      );
      expect(
        await memory.getString('${prefix}agent1:dailySales:2026-01-01'),
        isNull,
      );
      expect(
        await memory.getString('${prefix}agent1:dailySales:2026-01-05'),
        isNotNull,
      );
    });

    test('removeMatchingFactKind deletes only matching fact kind', () async {
      final memory = MemoryAppCacheStore();
      final store = HiveAgentQueryFactsStore(memory);
      const userId = 'user-b';

      await memory.putString(
        key:
            '${AgentQueryFactsKeyPrefix.forUser(userId)}a1:dailySales:2026-01-01',
        value: 'd',
      );
      await memory.putString(
        key:
            '${AgentQueryFactsKeyPrefix.forUser(userId)}a1:monthlyParcels:2026-01',
        value: 'm',
      );

      await store.removeMatchingFactKind(
        userId: userId,
        factKind: AgentQueryFactKind.dailySales,
      );

      expect(
        await memory.getString(
          '${AgentQueryFactsKeyPrefix.forUser(userId)}a1:dailySales:2026-01-01',
        ),
        isNull,
      );
      expect(
        await memory.getString(
          '${AgentQueryFactsKeyPrefix.forUser(userId)}a1:monthlyParcels:2026-01',
        ),
        isNotNull,
      );
    });
  });
}

class _TrackedCacheStore implements AppCacheStore {
  final _delegate = MemoryAppCacheStore();
  int reads = 0;
  int writes = 0;
  bool failNextWrite = false;
  void Function(String)? afterRead;
  @override
  Future<String?> getString(String key) async {
    reads++;
    final value = await _delegate.getString(key);
    afterRead?.call(key);
    return value;
  }

  @override
  Future<void> putString({required String key, required String value}) async {
    writes++;
    if (failNextWrite) {
      failNextWrite = false;
      throw StateError('storage unavailable');
    }
    await _delegate.putString(key: key, value: value);
  }

  @override
  Future<void> removeString(String key) => _delegate.removeString(key);
  @override
  Future<void> removeKeysWithPrefix(String prefix) =>
      _delegate.removeKeysWithPrefix(prefix);
  @override
  Future<void> removeKeysWhere({
    required String prefix,
    required bool Function(String key) predicate,
  }) => _delegate.removeKeysWhere(prefix: prefix, predicate: predicate);
  @override
  Future<void> clearAll() => _delegate.clearAll();
}

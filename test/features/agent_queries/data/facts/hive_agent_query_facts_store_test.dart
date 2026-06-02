import 'dart:convert';

import 'package:colmeia/features/agent_queries/data/facts/agent_query_facts_envelope.dart';
import 'package:colmeia/features/agent_queries/data/facts/hive_agent_query_facts_store.dart';
import 'package:colmeia/features/agent_queries/domain/cache/agent_query_fact_kind.dart';
import 'package:colmeia/features/agent_queries/domain/cache/agent_query_facts_key_prefix.dart';
import 'package:flutter_test/flutter_test.dart';

import 'memory_agent_query_facts_store.dart';

void main() {
  group('HiveAgentQueryFactsStore', () {
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
        key: '${AgentQueryFactsKeyPrefix.forUser(userId)}agent1:dailySales:2026-01-01',
        value: 'a',
      );
      await memory.putString(
        key: '${AgentQueryFactsKeyPrefix.forUser(userId)}agent2:monthlyParcels:2026-01',
        value: 'b',
      );
      await memory.putString(
        key: '${AgentQueryFactsKeyPrefix.forUser('other')}agent1:dailySales:2026-01-01',
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

    test('removeMatchingFactKind deletes only matching fact kind', () async {
      final memory = MemoryAppCacheStore();
      final store = HiveAgentQueryFactsStore(memory);
      const userId = 'user-b';

      await memory.putString(
        key: '${AgentQueryFactsKeyPrefix.forUser(userId)}a1:dailySales:2026-01-01',
        value: 'd',
      );
      await memory.putString(
        key: '${AgentQueryFactsKeyPrefix.forUser(userId)}a1:monthlyParcels:2026-01',
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

import 'package:colmeia/core/cache/indexed_db_app_cache_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:idb_shim/idb_client_memory.dart';
import 'package:mocktail/mocktail.dart';

class _UnavailableFactory extends Mock implements IdbFactory {}

void main() {
  late IdbFactory factory;
  late IndexedDbAppCacheStore first;
  late IndexedDbAppCacheStore second;

  setUp(() {
    factory = newIdbFactoryMemory();
    first = IndexedDbAppCacheStore(factory);
    second = IndexedDbAppCacheStore(factory);
  });
  tearDown(() async {
    await first.close();
    await second.close();
  });

  test(
    'reads committed updates and deletions from another connection',
    () async {
      await first.putString(key: 'user:report', value: 'old');
      expect(await second.getString('user:report'), 'old');
      await first.putString(key: 'user:report', value: 'new');
      expect(await second.getString('user:report'), 'new');
      await first.removeString('user:report');
      expect(await second.getString('user:report'), isNull);
    },
  );

  test(
    'clears values in all connections without deleting the database',
    () async {
      await first.putString(key: 'user:a', value: 'a');
      expect(await second.getString('user:a'), 'a');
      await first.clearAll();
      expect(await second.getString('user:a'), isNull);
      await second.putString(key: 'user:b', value: 'b');
      expect(await first.getString('user:b'), 'b');
    },
  );

  test('prefix and predicate removals preserve unrelated users', () async {
    for (final key in ['a:keep', 'a:drop', 'b:drop']) {
      await first.putString(key: key, value: key);
    }
    await second.removeKeysWhere(
      prefix: 'a:',
      predicate: (key) => key.endsWith('drop'),
    );
    expect(await first.getString('a:drop'), isNull);
    expect(await first.getString('a:keep'), 'a:keep');
    await second.removeKeysWithPrefix('');
    expect(await first.getString('b:drop'), 'b:drop');
    await second.removeKeysWithPrefix('a:');
    expect(await first.getString('a:keep'), isNull);
    expect(await first.getString('b:drop'), 'b:drop');
  });

  test(
    'prefix range includes Unicode boundaries and excludes neighbors',
    () async {
      for (final key in [
        'a',
        'a\uffff',
        'a\ufffftail',
        'b',
        '\uffff',
        '\ufffftail',
      ]) {
        await first.putString(key: key, value: key);
      }
      await first.removeKeysWithPrefix('a');
      expect(await second.getString('a'), isNull);
      expect(await second.getString('a\uffff'), isNull);
      expect(await second.getString('a\ufffftail'), isNull);
      expect(await second.getString('b'), 'b');
      await first.removeKeysWithPrefix('\uffff');
      expect(await second.getString('\uffff'), isNull);
      expect(await second.getString('\ufffftail'), isNull);
      expect(await second.getString('b'), 'b');
    },
  );

  test('opens the existing Hive Web string-box schema', () async {
    final database = await factory.open(
      'app_kv_cache',
      version: 1,
      onUpgradeNeeded: (event) => event.database.createObjectStore('box'),
    );
    final transaction = database.transaction('box', idbModeReadWrite);
    await transaction.objectStore('box').put('legacy payload', 'legacy');
    await transaction.completed;
    database.close();
    expect(await first.getString('legacy'), 'legacy payload');
  });

  test(
    'blocked IndexedDB getter does not prevent cache construction',
    () async {
      final cache = IndexedDbAppCacheStore.lazy(
        () =>
            throw StateError('SecurityError while accessing window.indexedDB'),
      );
      addTearDown(cache.close);
      expect(await cache.getString('key'), isNull);
      await cache.putString(key: 'key', value: 'value');
    },
  );

  test('unavailable browser storage does not fail a cache operation', () async {
    final unavailable = _UnavailableFactory();
    when(
      () => unavailable.open(
        any(),
        onUpgradeNeeded: any(named: 'onUpgradeNeeded'),
      ),
    ).thenAnswer((_) async => throw StateError('IndexedDB blocked'));
    final cache = IndexedDbAppCacheStore(unavailable);
    addTearDown(cache.close);
    expect(await cache.getString('key'), isNull);
    await cache.putString(key: 'key', value: 'value');
    await cache.clearAll();
  });
}

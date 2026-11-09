import 'dart:async';
import 'dart:convert';

import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/application/sync/cache_refresh_coordinator.dart';
import 'package:colmeia/features/agent_queries/data/scheduling/cache_refresh_lock_native.dart';
import 'package:colmeia/features/agent_queries/data/scheduling/local_cache_refresh_schedule_repository.dart';
import 'package:colmeia/features/agent_queries/domain/scheduling/cache_refresh_schedule.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../application/sync/cache_refresh_coordinator_test.dart'
    show Executor, MemoryCache, Presence, until;

void main() {
  late MemoryCache cache;
  late LocalCacheRefreshLock lock;
  late LocalCacheRefreshScheduleRepository store;
  CacheRefreshSchedule schedule(
    String id, {
    String report = 'productSales',
    Map<String, Object?> filters = const {},
  }) => CacheRefreshSchedule(
    id: id,
    userId: 'user',
    agentId: id,
    reportId: report,
    filters: filters,
  );
  setUp(() {
    cache = MemoryCache();
    lock = LocalCacheRefreshLock();
    store = LocalCacheRefreshScheduleRepository(cache, lock);
  });
  test(
    'quota failure is visible even when diagnostic metadata cannot be saved',
    () async {
      await store.save(schedule('A'));
      await store.commit(
        (await store.read('user', 'A'))!,
        const CacheRefreshState(),
        snapshot: {'old': true},
      );
      final executor = Executor();
      final coordinator = CacheRefreshCoordinator(
        repository: store,
        executor: executor,
        presence: Presence(),
        lock: lock,
        online: () => true,
      );
      addTearDown(coordinator.dispose);
      cache.failWrites = true;
      coordinator.start('user');
      await until(
        () => executor.calls.isNotEmpty && coordinator.runningIds.isEmpty,
      );
      expect(coordinator.unpersistedState('A')!.reason, 'storage_unavailable');
      expect(
        coordinator.unpersistedState('A')!.status,
        CacheRefreshStatus.deferred,
      );
      expect((await store.read('user', 'A'))!.snapshot, {'old': true});
    },
  );
  test('metadata listing does not read a large financial snapshot', () async {
    await store.save(schedule('A'));
    await store.commit(
      (await store.read('user', 'A'))!,
      const CacheRefreshState(),
      snapshot: {'rows': List.filled(10000, 'large row')},
    );
    cache.reads.clear();
    final list = await store.list('user');
    expect(list.single.snapshot, isNull);
    expect(list.single.snapshotBytes, greaterThan(100000));
    expect(cache.reads.any((key) => key.contains('/snapshots/')), isFalse);
    final bytesRead = cache.reads.fold<int>(
      0,
      (sum, key) => sum + utf8.encode(cache.values[key] ?? '').length,
    );
    expect(bytesRead, lessThan(2000));
    expect(
      (await store.read('user', 'A'))!.snapshot!['rows'],
      hasLength(10000),
    );
  });
  test('v1 migrates once and preserves the snapshot without rewriting raw results during listing', () async {
    await store.save(schedule('A'));
    final key = cache.values.keys.firstWhere((key) => key.contains('/job/'));
    final old = (await store.read('user', 'A'))!.toJson();
    old['version'] = 1;
    old['snapshot'] = {
      'data': {
        'queries': {
          'hash': {
            'rows': [1],
          },
        },
      },
      'currentDayPartial': true,
    };
    cache.values[key] = jsonEncode(old);
    final migrated = (await store.list('user')).single;
    expect(migrated.snapshot, isNull);
    expect(migrated.queryKeys, ['hash']);
    expect(migrated.currentDayPartial, isTrue);
    expect((jsonDecode(cache.values[key]!) as Map)['version'], 2);
    cache.reads.clear();
    await store.list('user');
    expect(cache.reads.any((key) => key.contains('/snapshots/')), isFalse);
    expect((await store.read('user', 'A'))!.snapshot, old['snapshot']);
  });
  test('failed metadata publication retains the previous generation', () async {
    await store.save(schedule('A'));
    await store.commit(
      (await store.read('user', 'A'))!,
      const CacheRefreshState(),
      snapshot: {'old': true},
    );
    final before = (await store.read('user', 'A'))!;
    cache.failWriteContaining = '/job/';
    await expectLater(
      store.commit(before, const CacheRefreshState(), snapshot: {'new': true}),
      throwsA(isA<StorageFailure>()),
    );
    expect((await store.read('user', 'A'))!.snapshot, {'old': true});
    expect((await store.read('user', 'A'))!.revision, before.revision);
  });
  test('failed migration leaves the v1 record intact', () async {
    await store.save(schedule('A'));
    final key = cache.values.keys.firstWhere((key) => key.contains('/job/'));
    final old = (await store.read('user', 'A'))!.toJson()
      ..['version'] = 1
      ..['snapshot'] = {'old': true};
    cache.values[key] = jsonEncode(old);
    cache.failWriteContaining = '/snapshots/';
    await expectLater(store.list('user'), throwsA(isA<StorageFailure>()));
    expect(jsonDecode(cache.values[key]!), old);
  });
  test('invalid records are quarantined and do not block valid jobs', () async {
    await store.save(schedule('A'));
    await store.save(schedule('B'));
    final key = cache.values.keys.firstWhere((key) => key.endsWith('/job/A'));
    cache.values[key] = '{invalid';
    final executor = Executor();
    final coordinator = CacheRefreshCoordinator(
      repository: store,
      executor: executor,
      presence: Presence(),
      lock: lock,
      online: () => true,
    );
    addTearDown(coordinator.dispose);
    coordinator.start('user');
    await until(
      () => executor.calls.contains('B') && coordinator.runningIds.isEmpty,
    );
    expect(executor.calls, ['B']);
    expect((await store.read('user', 'A'))!.isQuarantined, isTrue);
    expect(cache.values[key], '{invalid');
    await store.remove('user', 'A');
    expect((await store.list('user')).single.schedule.id, 'B');
  });
  test('normalization deduplicates defaults even when saving outside the controller', () async {
    final first = schedule('A');
    await store.save(first);
    final duplicate = CacheRefreshSchedule(
      id: 'other',
      userId: 'user',
      agentId: 'A',
      reportId: 'productSales',
      filters: {'origem': ' FrenteLoja ', 'page': 1, 'pageSize': 20},
    );
    expect(duplicate.identity, first.identity);
    await expectLater(store.save(duplicate), throwsA(isA<ValidationFailure>()));
    expect(
      schedule(
        'A',
        report: 'purchaseNotes',
        filters: {
          'codEmpresa': 1,
          'codFilial': 1,
          'pageSize': 50,
          'searchTerm': ' ',
        },
      ).filters,
      isEmpty,
    );
    expect(
      schedule('A', report: 'movingAverage', filters: {'codFilial': 1}).filters,
      {'codFilial': 1},
    );
  });
  test(
    'two occupied global slots defer a third coordinator without executing SQL',
    () async {
      await store.save(schedule('C'));
      final occupied = Completer<void>();
      final a = lock.run('capacity-user-0', () => occupied.future);
      final b = lock.run('capacity-user-1', () => occupied.future);
      final executor = Executor();
      var now = DateTime.now();
      final coordinator = CacheRefreshCoordinator(
        repository: store,
        executor: executor,
        presence: Presence(),
        lock: lock,
        online: () => true,
        clock: () => now,
      );
      addTearDown(coordinator.dispose);
      coordinator.start('user');
      for (var attempt = 0; attempt < 100; attempt++) {
        if ((await store.read('user', 'C'))!.state.reason == 'capacity_busy') {
          break;
        }
        await Future<void>.delayed(const Duration(milliseconds: 2));
      }
      expect(executor.calls, isEmpty);
      expect((await store.read('user', 'C'))!.state.reason, 'capacity_busy');
      occupied.complete();
      await Future.wait([a, b]);
      now = now.add(const Duration(seconds: 6));
      coordinator.resume();
      await until(
        () => executor.calls.isNotEmpty && coordinator.runningIds.isEmpty,
      );
      expect(executor.calls, ['C']);
    },
  );
}

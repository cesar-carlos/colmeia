import 'dart:async';
import 'dart:convert';

import 'package:colmeia/core/cache/app_cache_store.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/application/sync/cache_refresh_coordinator.dart';
import 'package:colmeia/features/agent_queries/data/scheduling/cache_refresh_lock_native.dart';
import 'package:colmeia/features/agent_queries/data/scheduling/local_cache_refresh_schedule_repository.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/domain/scheduling/cache_refresh_ports.dart';
import 'package:colmeia/features/agent_queries/domain/scheduling/cache_refresh_schedule.dart';
import 'package:flutter_test/flutter_test.dart';

class MemoryCache extends AppCacheStore {
  final values = <String, String>{};
  final reads = <String>[];
  String? failWriteContaining;
  bool failWrites = false;
  @override
  Future<String?> getString(String key) async {
    reads.add(key);
    return values[key];
  }

  @override
  Future<void> putString({required String key, required String value}) async {
    if (!failWrites &&
        !(failWriteContaining != null && key.contains(failWriteContaining!))) {
      values[key] = value;
    }
  }

  @override
  Future<void> clearAll() async => values.clear();
  @override
  Future<void> removeString(String key) async => values.remove(key);
  @override
  Future<void> removeKeysWithPrefix(String prefix) async =>
      values.removeWhere((key, _) => key.startsWith(prefix));
  @override
  Future<void> removeKeysWhere({
    required String prefix,
    required bool Function(String) predicate,
  }) async =>
      values.removeWhere((key, _) => key.startsWith(prefix) && predicate(key));
}

class Presence implements CacheRefreshPresence {
  final states = <String, RefreshAgentAvailability>{};
  final calls = <String>[];
  @override
  Future<RefreshAgentAvailability> reconcile(String user, String agent) async {
    calls.add(agent);
    return states[agent] ?? RefreshAgentAvailability.online;
  }
}

class Executor implements ScheduledReportRefreshExecutor {
  final calls = <String>[];
  final waiting = <String, Completer<void>>{};
  final errors = <String, AppFailure>{};
  @override
  Future<Map<String, dynamic>> execute(
    CacheRefreshSchedule s,
    ({DateTime start, DateTime end}) period,
    AgentQueriesCancelScope scope,
  ) async {
    calls.add(s.id);
    await waiting[s.id]?.future;
    if (errors[s.id] case final error?) throw error;
    return {'value': s.id};
  }
}

Future<void> until(bool Function() condition) async {
  for (var i = 0; i < 100; i++) {
    if (condition()) return;
    await Future<void>.delayed(const Duration(milliseconds: 2));
  }
  fail('Condition did not complete');
}

void main() {
  test(
    'new schedules default to two hours and retain persisted custom intervals',
    () {
      final schedule = CacheRefreshSchedule(
        id: 'job',
        userId: 'user',
        agentId: 'A',
        reportId: 'report',
      );
      expect(schedule.interval, const Duration(hours: 2));
      expect(
        CacheRefreshSchedule.fromJson(schedule.toJson()).interval,
        const Duration(hours: 2),
      );
      final legacy = schedule.toJson()..['intervalMinutes'] = 15;
      expect(
        CacheRefreshSchedule.fromJson(legacy).interval,
        const Duration(minutes: 15),
      );
      schedule.validate(DateTime.now());
    },
  );
  late MemoryCache cache;
  late LocalCacheRefreshLock lock;
  late LocalCacheRefreshScheduleRepository store;
  late Presence presence;
  late Executor executor;
  late CacheRefreshCoordinator coordinator;
  late DateTime now;
  CacheRefreshSchedule schedule(
    String id,
    String agent, {
    String user = 'user',
    bool enabled = true,
  }) => CacheRefreshSchedule(
    id: id,
    userId: user,
    agentId: agent,
    reportId: id,
    enabled: enabled,
  );
  setUp(() {
    now = DateTime(2026, 11, 8);
    cache = MemoryCache();
    lock = LocalCacheRefreshLock();
    store = LocalCacheRefreshScheduleRepository(cache, lock);
    presence = Presence();
    executor = Executor();
    coordinator = CacheRefreshCoordinator(
      repository: store,
      executor: executor,
      presence: presence,
      lock: lock,
      online: () => true,
      clock: () => now,
      random: () => 0.5,
    );
  });
  tearDown(() => coordinator.dispose());
  test(
    'offline agent does not block other agents and resumes once on recovery',
    () async {
      await store.save(schedule('a', 'A'));
      await store.save(schedule('b', 'B'));
      presence.states['A'] = RefreshAgentAvailability.offline;
      coordinator.start('user');
      await until(
        () => executor.calls.contains('b') && coordinator.runningIds.isEmpty,
      );
      expect(executor.calls, ['b']);
      expect(
        (await store.read('user', 'a'))!.state.status,
        CacheRefreshStatus.waitingAgent,
      );
      presence.states['A'] = RefreshAgentAvailability.online;
      coordinator
        ..presenceChanged('A', now.toUtc())
        ..presenceChanged('A', now.toUtc());
      await until(
        () => executor.calls.contains('a') && coordinator.runningIds.isEmpty,
      );
      expect(executor.calls.where((id) => id == 'a'), hasLength(1));
      expect((await store.read('user', 'a'))!.state.lastSuccess, now.toUtc());
    },
  );
  test(
    'slow agent releases no global worker and one work per agent runs',
    () async {
      await store.save(schedule('a', 'A'));
      await store.save(schedule('a2', 'A'));
      await store.save(schedule('b', 'B'));
      executor.waiting['a'] = Completer<void>();
      coordinator.start('user');
      await until(() => executor.calls.contains('b'));
      expect(executor.calls, isNot(contains('a2')));
      executor.waiting['a']!.complete();
      await until(
        () => executor.calls.contains('a2') && coordinator.runningIds.isEmpty,
      );
    },
  );
  test('query timeout defers only that job and respects Retry-After', () async {
    await store.save(schedule('a', 'A'));
    await store.save(schedule('b', 'B'));
    executor.errors['a'] = const NetworkFailure(
      message: 'timeout',
      retryAfter: Duration(minutes: 5),
    );
    coordinator.start('user');
    await until(
      () => executor.calls.length == 2 && coordinator.runningIds.isEmpty,
    );
    final record = (await store.read('user', 'a'))!;
    expect(
      record.state.nextAttempt,
      now.toUtc().add(const Duration(minutes: 5)),
    );
    expect((await store.read('user', 'b'))!.snapshot, isNotNull);
  });
  test('logout and edit fence a late result', () async {
    await store.save(schedule('a', 'A'));
    executor.waiting['a'] = Completer<void>();
    coordinator.start('user');
    await until(() => executor.calls.isNotEmpty);
    await coordinator.logout();
    executor.waiting['a']!.complete();
    await until(() => coordinator.runningIds.isEmpty);
    expect(await store.list('user'), isEmpty);
  });
  test('editing during an execution rejects its old generation', () async {
    await store.save(schedule('a', 'A'));
    executor.waiting['a'] = Completer<void>();
    coordinator.start('user');
    await until(() => executor.calls.isNotEmpty);
    coordinator.cancel('a');
    await store.save(schedule('a', 'A', enabled: false));
    executor.waiting['a']!.complete();
    await until(() => coordinator.runningIds.isEmpty);
    final record = (await store.read('user', 'a'))!;
    expect(record.snapshot, isNull);
    expect(record.state.status, CacheRefreshStatus.paused);
  });
  test('two coordinators share a lock and re-read committed state', () async {
    await store.save(schedule('a', 'A'));
    final second = CacheRefreshCoordinator(
      repository: store,
      executor: executor,
      presence: presence,
      lock: lock,
      online: () => true,
      clock: () => now,
    );
    addTearDown(second.dispose);
    coordinator.start('user');
    second.start('user');
    await until(
      () =>
          executor.calls.isNotEmpty &&
          coordinator.runningIds.isEmpty &&
          second.runningIds.isEmpty,
    );
    expect(executor.calls, ['a']);
  });
  test('quota failure retains the previous snapshot', () async {
    await store.save(schedule('a', 'A'));
    final original = (await store.read('user', 'a'))!;
    await store.commit(
      original,
      const CacheRefreshState(),
      snapshot: {'old': true},
    );
    final previous = (await store.read('user', 'a'))!;
    cache.failWrites = true;
    await expectLater(
      store.commit(
        previous,
        const CacheRefreshState(),
        snapshot: {'new': true},
      ),
      throwsA(isA<StorageFailure>()),
    );
    expect((await store.read('user', 'a'))!.snapshot, {'old': true});
  });
  test(
    'authorization rejection removes snapshots and prevents retry',
    () async {
      await store.save(schedule('a', 'A'));
      presence.states['A'] = RefreshAgentAvailability.denied;
      coordinator.start('user');
      await until(
        () => presence.calls.isNotEmpty && coordinator.runningIds.isEmpty,
      );
      await coordinator.tick();
      await until(() => coordinator.runningIds.isEmpty);
      expect(executor.calls, isEmpty);
      expect(
        (await store.read('user', 'a'))!.state.status,
        CacheRefreshStatus.accessUnavailable,
      );
    },
  );
  test('relative dates roll over while fixed dates stay unchanged', () {
    final rolling = schedule('a', 'A');
    final fixed = CacheRefreshSchedule(
      id: 'f',
      userId: 'user',
      agentId: 'A',
      reportId: 'r',
      period: CacheRefreshPeriod.fixed,
      start: now.subtract(const Duration(days: 2)),
      end: now,
    );
    expect(
      rolling.resolvePeriod(now.add(const Duration(days: 1))).end,
      DateTime(2026, 11, 9),
    );
    expect(fixed.resolvePeriod(now.add(const Duration(days: 1))).end, now);
  });
  test('users and normalized filters remain isolated after restart', () async {
    await store.save(schedule('a', 'A'));
    await store.save(schedule('a', 'A', user: 'another'));
    final reopened = LocalCacheRefreshScheduleRepository(cache, lock);
    expect((await reopened.list('another')).single.schedule.userId, 'another');
    await store.clearUser('user');
    expect(await reopened.list('user'), isEmpty);
    expect(await reopened.list('another'), hasLength(1));
  });
  test('pausing retains the last completed snapshot and timestamp', () async {
    await store.save(schedule('a', 'A'));
    await store.commit(
      (await store.read('user', 'a'))!,
      CacheRefreshState(lastSuccess: now),
      snapshot: {'old': true},
    );
    await store.save(schedule('a', 'A', enabled: false));
    final paused = (await store.read('user', 'a'))!;
    expect(paused.snapshot, {'old': true});
    expect(paused.state.lastSuccess, now);
    expect(paused.state.status, CacheRefreshStatus.paused);
  });
  test('session rejection stops all jobs and removes schedules', () async {
    await store.save(schedule('a', 'A'));
    await store.save(schedule('b', 'B'));
    executor.errors['a'] = const SessionFailure(message: 'expired');
    executor.waiting['b'] = Completer<void>();
    coordinator.start('user');
    await until(
      () => executor.calls.contains('a') && coordinator.userId == null,
    );
    executor.waiting['b']!.complete();
    await until(() => coordinator.runningIds.isEmpty);
    expect(await store.list('user'), isEmpty);
  });
  test(
    'resume executes one overdue interval instead of replaying missed ticks',
    () async {
      await store.save(schedule('a', 'A'));
      coordinator.start('user');
      await until(
        () => executor.calls.isNotEmpty && coordinator.runningIds.isEmpty,
      );
      now = now.add(const Duration(days: 2));
      coordinator.resume();
      await until(
        () => executor.calls.length == 2 && coordinator.runningIds.isEmpty,
      );
      await coordinator.tick();
      expect(executor.calls, ['a', 'a']);
      expect(
        (await store.read('user', 'a'))!.state.nextAttempt,
        now.toUtc().add(const Duration(hours: 2)),
      );
    },
  );
  test('writes started after logout are rejected', () async {
    final protected = LocalCacheRefreshScheduleRepository(
      cache,
      lock,
      isAuthorized: (_) => false,
    );
    await expectLater(
      protected.save(schedule('a', 'A')),
      throwsA(isA<SessionFailure>()),
    );
    expect(await protected.list('user'), isEmpty);
  });
  test('calendar dates reject silently truncated time components', () {
    final fixed = CacheRefreshSchedule(
      id: 'a',
      userId: 'user',
      agentId: 'A',
      reportId: 'r',
      period: CacheRefreshPeriod.fixed,
      start: DateTime(2026, 11, 1, 12),
      end: now,
    );
    expect(() => fixed.validate(now), throwsA(isA<ValidationFailure>()));
  });
  test(
    'revocation during execution discards all snapshots for only that agent',
    () async {
      await store.save(schedule('a', 'A'));
      await store.save(schedule('a2', 'A', enabled: false));
      await store.save(schedule('b', 'B'));
      await store.commit(
        (await store.read('user', 'a2'))!,
        const CacheRefreshState(status: CacheRefreshStatus.paused),
        snapshot: {'old': true},
      );
      executor.waiting['a'] = Completer<void>();
      coordinator.start('user');
      await until(
        () => executor.calls.contains('a') && executor.calls.contains('b'),
      );
      presence.states['A'] = RefreshAgentAvailability.denied;
      executor.waiting['a']!.complete();
      await until(() => coordinator.runningIds.isEmpty);
      expect((await store.read('user', 'a'))!.snapshot, isNull);
      expect((await store.read('user', 'a2'))!.snapshot, isNull);
      expect((await store.read('user', 'b'))!.snapshot, isNotNull);
    },
  );
  test('query failure retains previous data and collection time', () async {
    await store.save(schedule('a', 'A'));
    await store.commit(
      (await store.read('user', 'a'))!,
      CacheRefreshState(lastSuccess: now),
      snapshot: {'old': true},
    );
    executor.errors['a'] = const NetworkFailure(message: 'timeout');
    coordinator.start('user');
    await until(
      () => executor.calls.isNotEmpty && coordinator.runningIds.isEmpty,
    );
    final record = (await store.read('user', 'a'))!;
    expect(record.snapshot, {'old': true});
    expect(record.state.lastSuccess, now);
    expect(record.state.status, CacheRefreshStatus.deferred);
  });
  test(
    'unknown format is rejected without deleting the saved generation',
    () async {
      await store.save(schedule('a', 'A'));
      final key = cache.values.keys.firstWhere((key) => key.contains('/job/'));
      final saved = jsonDecode(cache.values[key]!) as Map<String, dynamic>;
      saved['version'] = 99;
      cache.values[key] = jsonEncode(saved);
      expect((await store.read('user', 'a'))!.isQuarantined, isTrue);
      expect(
        (jsonDecode(cache.values[key]!) as Map<String, dynamic>)['version'],
        99,
      );
    },
  );
}

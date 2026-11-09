import 'dart:async';

import 'package:colmeia/core/cache/app_cache_store.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/pwa/pwa_platform.dart';
import 'package:colmeia/features/agent_queries/data/scheduling/cache_refresh_lock_native.dart';
import 'package:colmeia/features/pwa/application/pwa_package_service.dart';
import 'package:colmeia/features/pwa/data/offline_package_store.dart';
import 'package:colmeia/features/pwa/domain/offline_authorization.dart';
import 'package:colmeia/features/pwa/domain/offline_download_stage.dart';
import 'package:colmeia/features/pwa/domain/offline_package_exception.dart';
import 'package:colmeia/features/pwa/domain/offline_package_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Platform extends Mock implements PwaPlatform {}

class _Authorization extends Mock implements OfflineAuthorizationGateway {}

class _Cache implements AppCacheStore {
  final data = <String, String>{};
  bool quota = false;
  bool discardWrites = false;
  void Function(String key)? afterWrite;
  @override
  Future<String?> getString(String key) async => data[key];
  @override
  Future<void> putString({required String key, required String value}) async {
    if (quota) throw StateError('QuotaExceededError');
    if (discardWrites) return;
    data[key] = value;
    afterWrite?.call(key);
  }

  @override
  Future<void> removeString(String key) async {
    data.remove(key);
  }

  @override
  Future<void> clearAll() async {
    data.clear();
  }

  @override
  Future<void> removeKeysWithPrefix(String prefix) async {
    data.removeWhere((k, _) => k.startsWith(prefix));
  }

  @override
  Future<void> removeKeysWhere({
    required String prefix,
    required bool Function(String key) predicate,
  }) async {
    data.removeWhere((k, _) => k.startsWith(prefix) && predicate(k));
  }
}

void main() {
  final now = DateTime.utc(2026, 10, 26, 12);
  OfflineAuthorization grant({int hours = 24}) => OfflineAuthorization(
    userId: 'user',
    agentIds: {'agent'},
    issuedAt: now,
    expiresAt: now.add(Duration(hours: hours)),
  );
  test(
    'authorization expires at the absolute boundary and isolates identities',
    () {
      final lease = grant();
      expect(lease.permits('user', 'agent', now), isTrue);
      expect(lease.permits('other', 'agent', now), isFalse);
      expect(lease.permits('user', 'other', now), isFalse);
      expect(
        lease.permits(
          'user',
          'agent',
          now.subtract(const Duration(seconds: 1)),
        ),
        isFalse,
      );
      expect(
        lease.permits('user', 'agent', now.add(const Duration(hours: 24))),
        isFalse,
      );
      expect(grant(hours: 25).permits('user', 'agent', now), isFalse);
    },
  );
  late _Cache cache;
  late _Platform platform;
  late _Authorization authorization;
  late OfflinePackageStore store;
  late PwaPackageService service;
  late Future<Map<String, dynamic>> Function() load;
  setUp(() {
    cache = _Cache();
    platform = _Platform();
    authorization = _Authorization();
    store = OfflinePackageStore(cache);
    when(() => platform.online).thenReturn(true);
    when(() => platform.withLock(any(), any())).thenAnswer(
      (call) => (call.positionalArguments[1] as Future<void> Function())(),
    );
    when(() => authorization.authorize('agent'))
        .thenAnswer((_) async => grant());
    load = () async => {
      'rows': [1],
    };
    service = PwaPackageService(
      platform: platform,
      store: store,
      cache: cache,
      authorization: authorization,
      loader: (_, _, _, _, _) => load(),
      clock: () => now,
    );
  });
  test(
    'cancellation during publication restores the previous generation',
    () async {
      await service.synchronize('user', 'agent');
      load = () async => {
        'rows': [2],
      };
      cache.afterWrite = (key) {
        if (!key.startsWith('pwa/package/')) return;
        cache.afterWrite = null;
        service.cancel();
      };
      await expectLater(
        service.synchronize('user', 'agent'),
        throwsA(isA<OfflinePackageException>()),
      );
      expect((await service.read('user', 'agent'))?.datasets['rows'], [1]);
    },
  );
  test(
    'logout in another tab cannot restore a previous private generation',
    () async {
      await service.synchronize('user', 'agent');
      load = () async => {
        'rows': [2],
      };
      cache.afterWrite = (key) {
        if (!key.startsWith('pwa/package/')) return;
        cache.afterWrite = null;
        service.invalidateSession();
      };
      await expectLater(
        service.synchronize('user', 'agent'),
        throwsA(isA<OfflinePackageException>()),
      );
      expect(await service.read('user', 'agent'), isNull);
    },
  );
  test(
    'best-effort cache write failures cannot masquerade as saved packages',
    () async {
      await service.synchronize('user', 'agent');
      cache.discardWrites = true;
      load = () async => {
        'rows': [2],
      };
      await expectLater(
        service.synchronize('user', 'agent'),
        throwsA(isA<OfflinePackageException>()),
      );
      expect((await service.read('user', 'agent'))?.datasets['rows'], [1]);
    },
  );
  test('invalid or future formats remain stored but cannot be read', () async {
    for (final raw in ['[]', '{"version":999}', 'invalid']) {
      cache.data['pwa/package/user/agent'] = raw;
      expect(await service.read('user', 'agent'), isNull);
      expect(cache.data['pwa/package/user/agent'], raw);
    }
  });
  test(
    'cancelled downloads preserve the previously published generation',
    () async {
      await service.synchronize('user', 'agent');
      final gate = Completer<Map<String, dynamic>>();
      load = () => gate.future;
      final failure = expectLater(
        service.synchronize('user', 'agent'),
        throwsA(isA<OfflinePackageException>()),
      );
      await Future<void>.delayed(Duration.zero);
      service.cancel();
      gate.complete({
        'rows': [2],
      });
      await failure;
      expect((await service.read('user', 'agent'))?.datasets['rows'], [1]);
    },
  );
  test('reports download stages in order before publication', () async {
    final stages = <OfflineDownloadStage>[];
    await service.synchronize('user', 'agent', onProgress: stages.add);
    expect(stages, OfflineDownloadStage.values);
    expect(await service.read('user', 'agent'), isNotNull);
  });
  test(
    'cancellation before lock acquisition never contacts authorization',
    () async {
      when(() => platform.withLock(any(), any())).thenAnswer((call) async {
        service.cancel();
        await (call.positionalArguments[1] as Future<void> Function())();
      });
      await expectLater(
        service.synchronize('user', 'agent'),
        throwsA(isA<OfflinePackageException>()),
      );
      verifyNever(() => authorization.authorize(any()));
      expect(await service.read('user', 'agent'), isNull);
    },
  );
  test('publishes all data together and refuses another user', () async {
    await service.synchronize('user', 'agent');
    expect((await service.read('user', 'agent'))?.datasets['rows'], [1]);
    expect(await service.read('other', 'agent'), isNull);
    expect(await service.selectedAgents('user'), ['agent']);
  });
  test(
    'quota and interrupted download preserve the previous generation',
    () async {
      await service.synchronize('user', 'agent');
      cache.quota = true;
      load = () async => {
        'rows': [2],
      };
      await expectLater(service.synchronize('user', 'agent'), throwsStateError);
      expect((await service.read('user', 'agent'))?.datasets['rows'], [1]);
      cache.quota = false;
      load = () => Future.error(StateError('disconnected'));
      await expectLater(service.synchronize('user', 'agent'), throwsStateError);
      expect((await service.read('user', 'agent'))?.datasets['rows'], [1]);
    },
  );
  test(
    'logout cancels an in-flight generation and removes private data',
    () async {
      await service.synchronize('user', 'agent');
      final gate = Completer<Map<String, dynamic>>();
      load = () => gate.future;
      final operation = service.synchronize('user', 'agent');
      final failure = expectLater(
        operation,
        throwsA(isA<OfflinePackageException>()),
      );
      await Future<void>.delayed(Duration.zero);
      await service.clearUser('user');
      gate.complete({
        'rows': [2],
      });
      await failure;
      expect(await service.read('user', 'agent'), isNull);
      expect(await service.selectedAgents('user'), isEmpty);
    },
  );
  test('confirmed revocation removes a prior package', () async {
    await service.synchronize('user', 'agent');
    when(() => authorization.authorize('agent')).thenThrow(
      const AuthorizationFailure(message: 'revoked', userMessage: 'revoked'),
    );
    await expectLater(
      service.synchronize('user', 'agent'),
      throwsA(isA<AuthorizationFailure>()),
    );
    expect(await service.read('user', 'agent'), isNull);
  });
  test(
    'should not query after cancellation while authorization is pending',
    () async {
      final entered = Completer<void>();
      final pending = Completer<OfflineAuthorization>();
      when(() => authorization.authorize('agent')).thenAnswer((_) {
        entered.complete();
        return pending.future;
      });
      var queries = 0;
      load = () async {
        queries++;
        return {
          'rows': [1],
        };
      };
      final operation = service.synchronize('user', 'agent');
      final failure = expectLater(
        operation,
        throwsA(
          isA<OfflinePackageException>().having(
            (e) => e.issue,
            'issue',
            OfflinePackageIssue.cancelled,
          ),
        ),
      );
      await entered.future;
      service.cancel();
      pending.complete(grant());
      await failure;
      expect(queries, 0);
      expect(await service.selectedAgents('user'), isEmpty);
      expect(await service.read('user', 'agent'), isNull);
    },
  );
  test('offline reads never authorize or query remote sources', () async {
    await service.synchronize('user', 'agent');
    clearInteractions(authorization);
    when(() => platform.online).thenReturn(false);
    expect(await service.canRestoreOffline('user'), isTrue);
    await expectLater(
      service.synchronize('user', 'agent'),
      throwsA(isA<OfflinePackageException>()),
    );
    verifyNever(() => authorization.authorize(any()));
  });
  test(
    'cancelling agent A preserves independent agent B publication',
    () async {
      final waiting = Completer<void>();
      final entered = Completer<void>();
      when(() => authorization.authorize(any())).thenAnswer(
        (_) async => OfflineAuthorization(
          userId: 'user',
          agentIds: {'A', 'B'},
          issuedAt: now,
          expiresAt: now.add(const Duration(hours: 24)),
        ),
      );
      final concurrent = PwaPackageService(
        platform: platform,
        store: store,
        cache: cache,
        authorization: authorization,
        clock: () => now,
        selectionLock: LocalCacheRefreshLock(),
        loader: (_, agent, _, _, _) async {
          if (agent == 'A') {
            entered.complete();
            await waiting.future;
          }
          return {
            'rows': [agent],
          };
        },
      );
      final first = concurrent.synchronize('user', 'A');
      final cancelled = expectLater(
        first,
        throwsA(isA<OfflinePackageException>()),
      );
      await entered.future;
      await concurrent.synchronize('user', 'B');
      concurrent.cancel(agentId: 'A');
      waiting.complete();
      await cancelled;
      expect(await concurrent.read('user', 'A'), isNull);
      expect((await concurrent.read('user', 'B'))!.datasets['rows'], ['B']);
      expect(await concurrent.selectedAgents('user'), ['B']);
    },
  );
}

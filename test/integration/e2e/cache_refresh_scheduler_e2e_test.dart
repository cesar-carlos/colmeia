import 'package:colmeia/core/cache/app_cache_store.dart';
import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/di/injector.dart';
import 'package:colmeia/core/di/injector_cache_refresh_reports.dart';
import 'package:colmeia/features/agent_queries/application/sync/cache_refresh_coordinator.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_produto_venda_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/scheduling/cache_refresh_lock_native.dart';
import 'package:colmeia/features/agent_queries/data/scheduling/catalog_cache_refresh_presence.dart';
import 'package:colmeia/features/agent_queries/data/scheduling/local_cache_refresh_schedule_repository.dart';
import 'package:colmeia/features/agent_queries/data/scheduling/scheduled_query_snapshots.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_produto_venda_repository.dart';
import 'package:colmeia/features/agent_queries/domain/scheduling/cache_refresh_ports.dart';
import 'package:colmeia/features/agent_queries/domain/scheduling/cache_refresh_schedule.dart';
import 'package:colmeia/features/client_agents/data/datasources/client_agents_local_datasource.dart';
import 'package:colmeia/features/client_agents/data/datasources/client_agents_remote_datasource.dart';
import 'package:colmeia/features/client_agents/data/repositories/client_agents_repository_cache_support.dart';
import 'package:colmeia/features/client_agents/data/repositories/client_approved_agents_repository_impl.dart';
import 'package:colmeia/features/client_agents/domain/repositories/agent_client_token_reader.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart' hide group;
import 'package:get_it/get_it.dart';
import 'package:test_api/scaffolding.dart' show group;

import 'support/e2e_dependency_bootstrap.dart';

/// Only presence loss is injected; the hub catalog, permissions and SQL remain live.
class _InterruptiblePresence implements CacheRefreshPresence {
  _InterruptiblePresence(this.delegate);
  final CacheRefreshPresence delegate;
  bool disconnected = false;
  @override
  Future<RefreshAgentAvailability> reconcile(String user, String agent) =>
      disconnected
      ? Future.value(RefreshAgentAvailability.offline)
      : delegate.reconcile(user, agent);
}

Future<CacheRefreshRecord> _waitFor(
  LocalCacheRefreshScheduleRepository store,
  bool Function(CacheRefreshRecord) completed,
) async {
  final deadline = DateTime.now().add(const Duration(minutes: 3));
  while (DateTime.now().isBefore(deadline)) {
    final record = (await store.read(
      'scheduler-e2e',
      'live',
      includeSnapshot: false,
    ))!;
    if (completed(record)) return record;
    if (record.state.status == CacheRefreshStatus.accessUnavailable ||
        record.state.status == CacheRefreshStatus.paused ||
        record.state.status == CacheRefreshStatus.deferred) {
      fail(
        'Live scheduler did not publish: ${record.state.status.name}/${record.state.reason}. External failures are not accepted as successful data publication.',
      );
    }
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  fail('Live scheduler did not reach the expected state within three minutes.');
}

void main() {
  group('Local cache refresh with live hub and SQL', () {
    registerE2eAgentQueriesSuiteHooks();
    test('creates, publishes, preserves data during presence loss and resumes once', () async {
      final missing = missingE2eRepositoryKeys();
      if (missing.isNotEmpty) {
        markTestSkipped(
          'Live scheduler requires configured E2E credentials: ${missing.join(', ')}',
        );
        return;
      }
      final cache = getIt<AppCacheStore>();
      final local = ClientAgentsLocalDataSource(cache);
      final presence = _InterruptiblePresence(
        CatalogCacheRefreshPresence(
          ClientApprovedAgentsRepositoryImpl(
            remoteDataSource: ApiClientAgentsRemoteDataSource(getIt<Dio>()),
            localDataSource: local,
            cacheSupport: ClientAgentsRepositoryCacheSupport(local),
          ),
        ),
      );
      final lock = LocalCacheRefreshLock();
      final store = LocalCacheRefreshScheduleRepository(cache, lock);
      final queries = ScheduledQuerySnapshots(
        getIt<AgentQueriesRepository>(),
        store,
        presence,
        () => true,
      );
      final adapters = GetIt.asNewInstance();
      addTearDown(adapters.reset);
      adapters
        ..registerSingleton<AgentClientTokenReader>(
          getIt<AgentClientTokenReader>(),
        )
        ..registerSingleton<ResumoProdutoVendaRepository>(
          ResumoProdutoVendaRepositoryImpl(queries),
        );
      final coordinator = CacheRefreshCoordinator(
        repository: store,
        executor: createReportRefreshExecutor(adapters),
        presence: presence,
        lock: lock,
        online: () => true,
      );
      addTearDown(coordinator.dispose);
      final today = DateTime.now();
      await store.save(
        CacheRefreshSchedule(
          id: 'live',
          userId: 'scheduler-e2e',
          agentId: AppEnvironment.e2eAgentId,
          reportId: 'productSales',
          period: CacheRefreshPeriod.fixed,
          start: DateTime(today.year, today.month, today.day - 2),
          end: DateTime(today.year, today.month, today.day - 1),
        ),
      );
      coordinator.start('scheduler-e2e');
      final first = await _waitFor(store, (r) => r.state.lastSuccess != null);
      expect(first.snapshotBytes, greaterThan(0));
      expect(first.queryKeys, isNotEmpty);
      presence.disconnected = true;
      coordinator.requestNow('live');
      final offline = await _waitFor(
        store,
        (r) => r.state.status == CacheRefreshStatus.waitingAgent,
      );
      expect(offline.snapshotId, first.snapshotId);
      expect(offline.state.lastSuccess, first.state.lastSuccess);
      presence.disconnected = false;
      final observed = DateTime.now().toUtc();
      coordinator
        ..presenceChanged(AppEnvironment.e2eAgentId, observed)
        ..presenceChanged(AppEnvironment.e2eAgentId, observed);
      final recovered = await _waitFor(
        store,
        (r) => r.snapshotId != first.snapshotId && r.state.lastSuccess != null,
      );
      expect(recovered.state.failures, 0);
      final reopened = LocalCacheRefreshScheduleRepository(cache, lock);
      final saved = (await reopened.read('scheduler-e2e', 'live'))!;
      expect(saved.snapshot!['complete'], isTrue);
      expect(saved.snapshotId, recovered.snapshotId);
    }, timeout: const Timeout(Duration(minutes: 8)));
  }, tags: ['e2e']);
}

import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_cadastro_filial_across_agents_use_case.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_participant.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_report.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_key.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target_resolution.dart';
import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_across_agents_page_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_row.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_connection_status.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_catalog_lookup.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_in_memory_catalog_cache.dart';
import 'package:colmeia/features/sales/application/ports/sales_live_map_catalog_cache.dart';
import 'package:colmeia/features/sales/application/sales_live_map_catalog_scope.dart';
import 'package:colmeia/features/sales/application/sales_live_map_refresh_metrics.dart'
    show SalesLiveMapCatalogSource;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

class _MockSalesLiveMapCatalogCache extends Mock
    implements SalesLiveMapCatalogCache {}

class _MockLoadCadastroFilialAcrossAgentsUseCase extends Mock
    implements LoadCadastroFilialAcrossAgentsUseCase {}

void main() {
  const userId = 'user-1';
  final now = DateTime(2026, 5, 27, 12);

  late SalesLiveMapInMemoryCatalogCache memoryCache;
  late _MockSalesLiveMapCatalogCache diskCache;
  late _MockLoadCadastroFilialAcrossAgentsUseCase loadCadastroAcrossAgents;
  late SalesLiveMapCatalogLookup lookup;

  setUpAll(() {
    registerFallbackValue(const CadastroFilialFilter());
    registerFallbackValue(AgentQueryExecutionStrategy.mergeAll);
    registerFallbackValue(
      const AgentQueryTargetResolution(
        consideredApprovedTargets: <AgentQueryTarget>[],
        missingClientTokenTargets: <AgentQueryTarget>[],
        consideredApprovedAgentCount: 0,
        sqlEligibleConsideredTargetCount: 0,
      ),
    );
    registerFallbackValue(SalesLiveMapCatalogScope.fullAgent());
    registerFallbackValue(_emptyPageResult());
  });

  setUp(() {
    memoryCache = SalesLiveMapInMemoryCatalogCache(
      maxEntries: 50,
      ttl: const Duration(minutes: 5),
    );
    diskCache = _MockSalesLiveMapCatalogCache();
    when(
      () => diskCache.readIfFresh(
        userId: any(named: 'userId'),
        scope: any(named: 'scope'),
        now: any(named: 'now'),
      ),
    ).thenReturn(null);
    when(
      () => diskCache.write(
        userId: any(named: 'userId'),
        scope: any(named: 'scope'),
        now: any(named: 'now'),
        result: any(named: 'result'),
      ),
    ).thenAnswer((_) async {});

    loadCadastroAcrossAgents = _MockLoadCadastroFilialAcrossAgentsUseCase();
    lookup = SalesLiveMapCatalogLookup(
      memoryCache: memoryCache,
      diskCache: diskCache,
      loadCadastroAcrossAgents: loadCadastroAcrossAgents,
    );
  });

  group('lookupCached', () {
    test('returns null when nothing is cached', () {
      final outcome = lookup.lookupCached(
        userId: userId,
        scope: SalesLiveMapCatalogScope.fullAgent(agentIds: const ['agent-a']),
        now: now,
      );
      expect(outcome, isNull);
    });

    test('returns memory hit with source=memory when in memory cache', () {
      final scope = SalesLiveMapCatalogScope.fullAgent(
        agentIds: const ['agent-a'],
      );
      final page = _pageForAgents(<String>['agent-a']);
      memoryCache.write(userId: userId, scope: scope, now: now, result: page);

      final outcome = lookup.lookupCached(
        userId: userId,
        scope: scope,
        now: now,
      );

      expect(outcome, isNotNull);
      expect(outcome!.source, SalesLiveMapCatalogSource.memory);
      expect(outcome.page, same(page));
    });

    test(
      'returns disk hit with source=disk AND hydrates the memory cache',
      () {
        final scope = SalesLiveMapCatalogScope.fullAgent(
          agentIds: const ['agent-a'],
        );
        final page = _pageForAgents(<String>['agent-a']);
        when(
          () => diskCache.readIfFresh(
            userId: any(named: 'userId'),
            scope: any(named: 'scope'),
            now: any(named: 'now'),
          ),
        ).thenReturn(page);

        final first = lookup.lookupCached(
          userId: userId,
          scope: scope,
          now: now,
        );
        expect(first, isNotNull);
        expect(first!.source, SalesLiveMapCatalogSource.disk);

        // Disk lookup hydrated memory; a second call now hits memory
        // without touching disk again.
        when(
          () => diskCache.readIfFresh(
            userId: any(named: 'userId'),
            scope: any(named: 'scope'),
            now: any(named: 'now'),
          ),
        ).thenReturn(null);
        final second = lookup.lookupCached(
          userId: userId,
          scope: scope,
          now: now,
        );
        expect(second!.source, SalesLiveMapCatalogSource.memory);
      },
    );

    test(
      'broaderCacheFiltered narrows agents and branches when only the '
      'fullAgent scope is cached',
      () {
        // Cache a broader fullAgent scope for {agent-a} with rows for
        // both codFilial 1 and 2.
        final broaderScope = SalesLiveMapCatalogScope.fullAgent(
          agentIds: const ['agent-a'],
        );
        final broaderPage = _pageWithRows(
          plannedAgentIds: const <String>['agent-a'],
          missingClientTokenAgentIds: const <String>['agent-x'],
          skippedDueToHubPresenceAgentIds: const <String>['agent-y'],
          participants: <String, List<int>>{
            'agent-a': const <int>[1, 2],
          },
        );
        memoryCache.write(
          userId: userId,
          scope: broaderScope,
          now: now,
          result: broaderPage,
        );

        // Request a branchSubset that overlaps only with codFilial=1.
        final narrowScope = SalesLiveMapCatalogScope.branchSubset(
          selectedBranches: const <CadastroFilialBranchRef>[
            CadastroFilialBranchRef(
              agentId: 'agent-a',
              codEmpresa: 1,
              codFilial: 1,
            ),
          ],
        );

        final outcome = lookup.lookupCached(
          userId: userId,
          scope: narrowScope,
          now: now,
        );

        expect(outcome, isNotNull);
        expect(
          outcome!.source,
          SalesLiveMapCatalogSource.broaderCacheFiltered,
        );

        final filteredReport = outcome.page.report;
        // Participant is kept but rows are filtered to codFilial=1 only.
        expect(filteredReport.participants, hasLength(1));
        expect(filteredReport.participants.single.rows, hasLength(1));
        expect(filteredReport.participants.single.rows.single.codFilial, 1);

        // Cross-scope metadata is filtered to the narrow agent set so
        // downstream metrics don't inherit the broader counters.
        expect(
          filteredReport.plannedTargets.map((target) => target.agentId),
          <String>['agent-a'],
        );
        expect(
          filteredReport.missingClientTokenTargets,
          isEmpty,
          reason: 'agent-x must not leak through the broader cache filter',
        );
        expect(
          filteredReport.skippedDueToHubPresenceTargets,
          isEmpty,
          reason: 'agent-y must not leak through the broader cache filter',
        );
      },
    );

    test(
      'returns null when nothing matches the exact scope and the scope '
      'is not a branchSubset (no broader narrowing possible)',
      () {
        final scope = SalesLiveMapCatalogScope.fullAgent(
          agentIds: const ['agent-a'],
        );

        final outcome = lookup.lookupCached(
          userId: userId,
          scope: scope,
          now: now,
        );

        expect(outcome, isNull);
      },
    );
  });

  group('loadRemote', () {
    test('hydrates both memory and disk caches on success', () async {
      final scope = SalesLiveMapCatalogScope.fullAgent(
        agentIds: const ['agent-a'],
      );
      final page = _pageForAgents(<String>['agent-a']);
      when(
        () => loadCadastroAcrossAgents.loadAll(
          userId: any(named: 'userId'),
          filter: any(named: 'filter'),
          selectedAgentIds: any(named: 'selectedAgentIds'),
          strategy: any(named: 'strategy'),
          bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
          raceMaxSources: any(named: 'raceMaxSources'),
          preResolvedResolution: any(named: 'preResolvedResolution'),
          cancelScope: any(named: 'cancelScope'),
          orderTargetsOnlineFirst: any(named: 'orderTargetsOnlineFirst'),
          dedupeTargetsByAgentId: any(named: 'dedupeTargetsByAgentId'),
          mergeAllConcurrencyOverride: any(
            named: 'mergeAllConcurrencyOverride',
          ),
        ),
      ).thenAnswer(
        (_) async => Success<CadastroFilialAcrossAgentsPageResult, AppFailure>(
          page,
        ),
      );

      final result = await lookup.loadRemote(
        userId: userId,
        scope: scope,
        now: now,
        preResolvedResolution: _emptyResolution(),
        bridgeTimeoutMs: 60000,
        mergeAllConcurrencyOverride: 8,
      );

      expect(result.getOrNull(), same(page));
      expect(
        memoryCache.read(userId: userId, scope: scope, now: now),
        same(page),
      );
      // wait one microtask for the unawaited disk write
      await Future<void>.delayed(Duration.zero);
      verify(
        () => diskCache.write(
          userId: userId,
          scope: scope,
          now: now,
          result: page,
        ),
      ).called(1);
    });

    test('does not hydrate caches on remote failure', () async {
      final scope = SalesLiveMapCatalogScope.fullAgent(
        agentIds: const ['agent-a'],
      );
      when(
        () => loadCadastroAcrossAgents.loadAll(
          userId: any(named: 'userId'),
          filter: any(named: 'filter'),
          selectedAgentIds: any(named: 'selectedAgentIds'),
          strategy: any(named: 'strategy'),
          bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
          raceMaxSources: any(named: 'raceMaxSources'),
          preResolvedResolution: any(named: 'preResolvedResolution'),
          cancelScope: any(named: 'cancelScope'),
          orderTargetsOnlineFirst: any(named: 'orderTargetsOnlineFirst'),
          dedupeTargetsByAgentId: any(named: 'dedupeTargetsByAgentId'),
          mergeAllConcurrencyOverride: any(
            named: 'mergeAllConcurrencyOverride',
          ),
        ),
      ).thenAnswer(
        (_) async =>
            const Failure<CadastroFilialAcrossAgentsPageResult, AppFailure>(
              UnknownFailure(message: 'boom'),
            ),
      );

      final result = await lookup.loadRemote(
        userId: userId,
        scope: scope,
        now: now,
        preResolvedResolution: _emptyResolution(),
        bridgeTimeoutMs: 60000,
        mergeAllConcurrencyOverride: 8,
      );

      expect(result.exceptionOrNull(), isA<UnknownFailure>());
      expect(
        memoryCache.read(userId: userId, scope: scope, now: now),
        isNull,
      );
      await Future<void>.delayed(Duration.zero);
      verifyNever(
        () => diskCache.write(
          userId: any(named: 'userId'),
          scope: any(named: 'scope'),
          now: any(named: 'now'),
          result: any(named: 'result'),
        ),
      );
    });
  });
}

CadastroFilialAcrossAgentsPageResult _emptyPageResult() {
  return CadastroFilialAcrossAgentsPageResult.fromReport(
    const AgentQueryExecutionReport<CadastroFilialRow>(
      queryKey: AgentQueryKey.cadastroFilial,
      strategy: AgentQueryExecutionStrategy.mergeAll,
      consideredApprovedAgentCount: 0,
      plannedTargets: <AgentQueryTarget>[],
      missingClientTokenTargets: <AgentQueryTarget>[],
      participants: <AgentQueryExecutionParticipant<CadastroFilialRow>>[],
      totalElapsedMs: 0,
    ),
  );
}

CadastroFilialAcrossAgentsPageResult _pageForAgents(List<String> agentIds) {
  return _pageWithRows(
    plannedAgentIds: agentIds,
    participants: <String, List<int>>{
      for (final id in agentIds) id: const <int>[1],
    },
  );
}

CadastroFilialAcrossAgentsPageResult _pageWithRows({
  required List<String> plannedAgentIds,
  required Map<String, List<int>> participants,
  List<String> missingClientTokenAgentIds = const <String>[],
  List<String> skippedDueToHubPresenceAgentIds = const <String>[],
}) {
  final plannedTargets = plannedAgentIds.map(_target).toList(growable: false);
  final missingTargets = missingClientTokenAgentIds
      .map((id) => _target(id, clientToken: null))
      .toList(growable: false);
  final skippedTargets = skippedDueToHubPresenceAgentIds
      .map(_target)
      .toList(growable: false);
  final participantList = participants.entries
      .map((entry) {
        final rows = entry.value
            .map(
              (codFilial) => CadastroFilialRow(
                codEmpresa: 1,
                codFilial: codFilial,
                nomeFilial: 'Loja $codFilial',
              ),
            )
            .toList(growable: false);
        return AgentQueryExecutionParticipant<CadastroFilialRow>(
          agentId: entry.key,
          displayName: 'Agente ${entry.key}',
          rows: rows,
          elapsedMs: 10,
        );
      })
      .toList(growable: false);

  return CadastroFilialAcrossAgentsPageResult.fromReport(
    AgentQueryExecutionReport<CadastroFilialRow>(
      queryKey: AgentQueryKey.cadastroFilial,
      strategy: AgentQueryExecutionStrategy.mergeAll,
      consideredApprovedAgentCount:
          plannedTargets.length + missingTargets.length,
      plannedTargets: plannedTargets,
      missingClientTokenTargets: missingTargets,
      participants: participantList,
      totalElapsedMs: 12,
      skippedDueToHubPresenceTargets: skippedTargets,
    ),
  );
}

AgentQueryTarget _target(String agentId, {String? clientToken = 'token'}) {
  return AgentQueryTarget(
    agentId: agentId,
    displayName: 'Agente $agentId',
    connectionStatus: AgentConnectionStatus.online,
    clientToken: clientToken,
  );
}

AgentQueryTargetResolution _emptyResolution() {
  return const AgentQueryTargetResolution(
    consideredApprovedTargets: <AgentQueryTarget>[],
    missingClientTokenTargets: <AgentQueryTarget>[],
    consideredApprovedAgentCount: 0,
    sqlEligibleConsideredTargetCount: 0,
  );
}

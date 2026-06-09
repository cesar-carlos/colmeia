import 'dart:async';

import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart' show AppResult;
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_total_vendas_municipio_filial_periodo_across_agents_use_case.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_participant.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_report.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_key.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target_resolution.dart';
import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_across_agents_page_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_vendas_municipio_filial_periodo_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_vendas_municipio_filial_periodo_row.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_catalog_lookup.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_diagnostics_logger.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_load_cancel_token.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_load_result.dart'
    show SalesLiveMapLoadResult;
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_mapped_result.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_parallel_load_orchestrator.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_progressive_emit_policy.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_refresh_metrics_recorder.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_report_mapper.dart';
import 'package:colmeia/features/sales/application/sales_live_map_catalog_scope.dart';
import 'package:colmeia/features/sales/application/sales_live_map_refresh_metrics.dart';
import 'package:colmeia/features/sales/application/sales_live_map_reload_reason.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_filter.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_point.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

class _MockLoadSalesAcrossAgents extends Mock
    implements
        LoadResumoTotalVendasMunicipioFilialPeriodoAcrossAgentsUseCase {}

class _MockSalesLiveMapCatalogLookup extends Mock
    implements SalesLiveMapCatalogLookup {}

class _MockSalesLiveMapReportMapper extends Mock
    implements SalesLiveMapReportMapper {}

void main() {
  late _MockLoadSalesAcrossAgents loadSalesAcrossAgents;
  late _MockSalesLiveMapCatalogLookup catalogLookup;
  late _MockSalesLiveMapReportMapper reportMapper;
  late SalesLiveMapParallelLoadOrchestrator orchestrator;

  final now = DateTime(2026, 5, 27, 18);
  const userId = 'user-1';
  const filter = SalesLiveMapFilter();
  final catalogScope = SalesLiveMapCatalogScope.fullAgent();
  final queryFilter = ResumoTotalVendasMunicipioFilialPeriodoFilter(
    dataVendaInicio: DateTime.utc(2026),
    dataVendaFim: DateTime.utc(2026, 12, 31),
  );
  const resolution = AgentQueryTargetResolution(
    consideredApprovedTargets: <AgentQueryTarget>[],
    missingClientTokenTargets: <AgentQueryTarget>[],
    consideredApprovedAgentCount: 0,
    sqlEligibleConsideredTargetCount: 0,
  );
  final catalogPage = _catalogPage();

  setUpAll(() {
    registerFallbackValue(filter);
    registerFallbackValue(catalogScope);
    registerFallbackValue(queryFilter);
    registerFallbackValue(resolution);
    registerFallbackValue(SalesLiveMapLoadCancelToken());
    registerFallbackValue(SalesLiveMapReloadReason.manual);
    registerFallbackValue(catalogPage);
  });

  setUp(() {
    loadSalesAcrossAgents = _MockLoadSalesAcrossAgents();
    catalogLookup = _MockSalesLiveMapCatalogLookup();
    reportMapper = _MockSalesLiveMapReportMapper();
    orchestrator = SalesLiveMapParallelLoadOrchestrator(
      loadSalesAcrossAgents: loadSalesAcrossAgents,
      catalogLookup: catalogLookup,
      reportMapper: reportMapper,
      diagnosticsLogger: const SalesLiveMapDiagnosticsLogger(),
      metricsRecorder: SalesLiveMapRefreshMetricsRecorder(
        metrics: SalesLiveMapRefreshMetrics(),
        diagnosticsLogger: const SalesLiveMapDiagnosticsLogger(),
      ),
      emitPolicy: const SalesLiveMapProgressiveEmitPolicy(
        diagnosticsLogger: SalesLiveMapDiagnosticsLogger(),
      ),
      bridgeTimeoutMs: 1000,
    );
  });

  test('emits catalog-only mapped results before sales report completes', () async {
    final catalogCompleter =
        Completer<AppResult<CadastroFilialAcrossAgentsPageResult>>();
    final salesCompleter =
        Completer<
          AppResult<
            AgentQueryExecutionReport<
              ResumoTotalVendasMunicipioFilialPeriodoRow
            >
          >
        >();
    final catalogPending = _mappedResult(totalRevenue: 10, salesDataPending: true);
    final finalMapped = _mappedResult(totalRevenue: 99);

    when(
      () => catalogLookup.loadRemote(
        userId: any(named: 'userId'),
        scope: any(named: 'scope'),
        now: any(named: 'now'),
        preResolvedResolution: any(named: 'preResolvedResolution'),
        cancelToken: any(named: 'cancelToken'),
        bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
        mergeAllConcurrencyOverride: any(
          named: 'mergeAllConcurrencyOverride',
        ),
      ),
    ).thenAnswer((_) => catalogCompleter.future);
    when(
      () => loadSalesAcrossAgents(
        userId: any(named: 'userId'),
        filter: any(named: 'filter'),
        selectedAgentIds: any(named: 'selectedAgentIds'),
        bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
        preResolvedResolution: any(named: 'preResolvedResolution'),
        cancelScope: any(named: 'cancelScope'),
        orderTargetsOnlineFirst: any(named: 'orderTargetsOnlineFirst'),
        dedupeTargetsByAgentId: any(named: 'dedupeTargetsByAgentId'),
        mergeAllConcurrencyOverride: any(
          named: 'mergeAllConcurrencyOverride',
        ),
      ),
    ).thenAnswer((_) => salesCompleter.future);
    when(
      () => reportMapper.emitMappedReports(
        any(),
        catalogResult: any(named: 'catalogResult'),
        catalogFailure: any(named: 'catalogFailure'),
        filter: any(named: 'filter'),
        refreshedAt: any(named: 'refreshedAt'),
        cancelToken: any(named: 'cancelToken'),
        salesDataPending: any(named: 'salesDataPending'),
        allowPartialGeoReuse: any(named: 'allowPartialGeoReuse'),
        hubPresenceOnlineAgentIdsSnapshot:
            any(named: 'hubPresenceOnlineAgentIdsSnapshot'),
      ),
    ).thenAnswer((invocation) async* {
      final pending = invocation.namedArguments[#salesDataPending] as bool?;
      if (pending ?? false) {
        yield catalogPending;
        return;
      }
      yield finalMapped;
    });

    final stream = orchestrator.loadProgressive(
      userId: userId,
      filter: filter,
      reason: SalesLiveMapReloadReason.manual,
      now: now,
      catalogScope: catalogScope,
      queryFilter: queryFilter,
      selectedAgentIds: null,
      resolution: resolution,
      cancelToken: null,
      mergeWaveSize: 2,
      resolveSw: null,
      totalStopwatch: null,
      cachedCatalog: null,
      cachedCatalogPage: null,
      loadedViaMergedSqlBatch: false,
    );

    catalogCompleter.complete(
      Success<CadastroFilialAcrossAgentsPageResult, AppFailure>(catalogPage),
    );
    salesCompleter.complete(
      Success<
        AgentQueryExecutionReport<ResumoTotalVendasMunicipioFilialPeriodoRow>,
        AppFailure
      >(_salesReport()),
    );

    final emissions = await stream.toList();
    expect(emissions.first.salesDataPending, isTrue);
    expect(emissions[1].totalRevenue, 10);
    expect(emissions.last.totalRevenue, 99);
  });

  test('yields failed result when both catalog and sales fail', () async {
    const failure = NetworkFailure(message: 'down');

    when(
      () => catalogLookup.loadRemote(
        userId: any(named: 'userId'),
        scope: any(named: 'scope'),
        now: any(named: 'now'),
        preResolvedResolution: any(named: 'preResolvedResolution'),
        cancelToken: any(named: 'cancelToken'),
        bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
        mergeAllConcurrencyOverride: any(
          named: 'mergeAllConcurrencyOverride',
        ),
      ),
    ).thenAnswer(
      (_) async => const Failure<CadastroFilialAcrossAgentsPageResult, AppFailure>(
        failure,
      ),
    );
    when(
      () => loadSalesAcrossAgents(
        userId: any(named: 'userId'),
        filter: any(named: 'filter'),
        selectedAgentIds: any(named: 'selectedAgentIds'),
        bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
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
          const Failure<
            AgentQueryExecutionReport<
              ResumoTotalVendasMunicipioFilialPeriodoRow
            >,
            AppFailure
          >(failure),
    );

    final emissions = await orchestrator
        .loadProgressive(
          userId: userId,
          filter: filter,
          reason: SalesLiveMapReloadReason.manual,
          now: now,
          catalogScope: catalogScope,
          queryFilter: queryFilter,
          selectedAgentIds: null,
          resolution: resolution,
          cancelToken: null,
          mergeWaveSize: 1,
          resolveSw: null,
          totalStopwatch: null,
          cachedCatalog: null,
          cachedCatalogPage: null,
          loadedViaMergedSqlBatch: false,
        )
        .toList();

    expect(emissions.last.loadFailed, isTrue);
  });

  test('skips pending base when cached catalog page is provided', () async {
    when(
      () => loadSalesAcrossAgents(
        userId: any(named: 'userId'),
        filter: any(named: 'filter'),
        selectedAgentIds: any(named: 'selectedAgentIds'),
        bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
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
          Success<
            AgentQueryExecutionReport<
              ResumoTotalVendasMunicipioFilialPeriodoRow
            >,
            AppFailure
          >(_salesReport()),
    );
    when(
      () => reportMapper.emitMappedReports(
        any(),
        catalogResult: any(named: 'catalogResult'),
        salesFailure: any(named: 'salesFailure'),
        catalogFailure: any(named: 'catalogFailure'),
        filter: any(named: 'filter'),
        refreshedAt: any(named: 'refreshedAt'),
        cancelToken: any(named: 'cancelToken'),
        allowPartialGeoReuse: any(named: 'allowPartialGeoReuse'),
        hubPresenceOnlineAgentIdsSnapshot:
            any(named: 'hubPresenceOnlineAgentIdsSnapshot'),
      ),
    ).thenAnswer((_) async* {
      yield _mappedResult(totalRevenue: 50);
    });

    final emissions = await orchestrator
        .loadProgressive(
          userId: userId,
          filter: filter,
          reason: SalesLiveMapReloadReason.autoRefresh,
          now: now,
          catalogScope: catalogScope,
          queryFilter: queryFilter,
          selectedAgentIds: null,
          resolution: resolution,
          cancelToken: null,
          mergeWaveSize: 1,
          resolveSw: null,
          totalStopwatch: null,
          cachedCatalog: null,
          cachedCatalogPage: catalogPage,
          loadedViaMergedSqlBatch: false,
        )
        .toList();

    expect(emissions, isNot(contains(predicate<SalesLiveMapLoadResult>(
      (result) => result.totalBranchCount == 0 && result.salesDataPending,
    ))));
    expect(emissions.last.totalRevenue, 50);
  });
}

CadastroFilialAcrossAgentsPageResult _catalogPage() {
  return CadastroFilialAcrossAgentsPageResult.fromReport(
    const AgentQueryExecutionReport<CadastroFilialRow>(
      queryKey: AgentQueryKey.cadastroFilial,
      strategy: AgentQueryExecutionStrategy.mergeAll,
      consideredApprovedAgentCount: 0,
      plannedTargets: <AgentQueryTarget>[],
      missingClientTokenTargets: <AgentQueryTarget>[],
      participants: <AgentQueryExecutionParticipant<CadastroFilialRow>>[],
      totalElapsedMs: 1,
    ),
  );
}

AgentQueryExecutionReport<ResumoTotalVendasMunicipioFilialPeriodoRow>
_salesReport() {
  return const AgentQueryExecutionReport<
    ResumoTotalVendasMunicipioFilialPeriodoRow
  >(
    queryKey: AgentQueryKey.resumoTotalVendasMunicipioFilialPeriodo,
    strategy: AgentQueryExecutionStrategy.mergeAll,
    consideredApprovedAgentCount: 0,
    plannedTargets: <AgentQueryTarget>[],
    missingClientTokenTargets: <AgentQueryTarget>[],
    participants: <AgentQueryExecutionParticipant<
      ResumoTotalVendasMunicipioFilialPeriodoRow
    >>[],
    totalElapsedMs: 1,
  );
}

SalesLiveMapMappedResult _mappedResult({
  required double totalRevenue,
  bool salesDataPending = false,
}) {
  return SalesLiveMapMappedResult(
    result: SalesLiveMapLoadResult(
      points: const <SalesLiveMapPoint>[],
      branchOptions: const <SalesLiveMapBranchOption>[],
      totalRevenue: totalRevenue,
      totalSalesCount: 1,
      totalBranchCount: 1,
      mappedBranchCount: 0,
      mappedMunicipalityCount: 0,
      queriedAgentCount: 1,
      plannedAgentCount: 1,
      failedAgentCount: 0,
      missingClientTokenAgentCount: 0,
      skippedOfflineAgentCount: 0,
      rowCapReachedAgentCount: 0,
      salesDataPending: salesDataPending,
      refreshedAt: DateTime(2026, 5, 27),
    ),
  );
}

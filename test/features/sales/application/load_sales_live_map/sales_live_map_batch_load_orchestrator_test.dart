import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart' show AppResult;
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_participant.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_report.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_key.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target_resolution.dart';
import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_across_agents_page_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_vendas_municipio_filial_periodo_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_vendas_municipio_filial_periodo_row.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_batch_load_orchestrator.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_catalog_persister.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_diagnostics_logger.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_load_cancel_token.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_load_result.dart'
    show SalesLiveMapLoadResult;
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_mapped_result.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_progressive_emit_policy.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_refresh_metrics_recorder.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_report_mapper.dart';
import 'package:colmeia/features/sales/application/ports/sales_live_map_batch_loader.dart';
import 'package:colmeia/features/sales/application/sales_live_map_catalog_scope.dart';
import 'package:colmeia/features/sales/application/sales_live_map_refresh_metrics.dart';
import 'package:colmeia/features/sales/application/sales_live_map_reload_reason.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_filter.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_point.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

class _MockSalesLiveMapBatchLoader extends Mock
    implements SalesLiveMapBatchLoader {}

class _MockSalesLiveMapReportMapper extends Mock
    implements SalesLiveMapReportMapper {}

class _MockSalesLiveMapCatalogPersister extends Mock
    implements SalesLiveMapCatalogPersister {}

void main() {
  late _MockSalesLiveMapBatchLoader batchLoader;
  late _MockSalesLiveMapReportMapper reportMapper;
  late _MockSalesLiveMapCatalogPersister catalogPersister;
  late SalesLiveMapRefreshMetricsRecorder metricsRecorder;
  late SalesLiveMapBatchLoadOrchestrator orchestrator;

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

  setUpAll(() {
    registerFallbackValue(const CadastroFilialFilter());
    registerFallbackValue(filter);
    registerFallbackValue(catalogScope);
    registerFallbackValue(queryFilter);
    registerFallbackValue(resolution);
    registerFallbackValue(SalesLiveMapLoadCancelToken());
    registerFallbackValue(SalesLiveMapReloadReason.manual);
    registerFallbackValue(_batchResult(isFinal: false));
    registerFallbackValue(_catalogPage());
  });

  setUp(() {
    batchLoader = _MockSalesLiveMapBatchLoader();
    reportMapper = _MockSalesLiveMapReportMapper();
    catalogPersister = _MockSalesLiveMapCatalogPersister();
    metricsRecorder = SalesLiveMapRefreshMetricsRecorder(
      metrics: SalesLiveMapRefreshMetrics(),
      diagnosticsLogger: const SalesLiveMapDiagnosticsLogger(),
    );
    orchestrator = SalesLiveMapBatchLoadOrchestrator(
      batchLoader: batchLoader,
      reportMapper: reportMapper,
      catalogPersister: catalogPersister,
      diagnosticsLogger: const SalesLiveMapDiagnosticsLogger(),
      metricsRecorder: metricsRecorder,
      emitPolicy: const SalesLiveMapProgressiveEmitPolicy(
        diagnosticsLogger: SalesLiveMapDiagnosticsLogger(),
      ),
      bridgeTimeoutMs: 1000,
    );
  });

  test('yields pending base then mapped emissions and persists final batch', () async {
    final partialBatch = _batchResult(isFinal: false, salesLoadingComplete: false);
    final finalBatch = _batchResult(isFinal: true);
    final partialMapped = _mappedResult(totalRevenue: 10, salesDataPending: true);
    final finalMapped = _mappedResult(totalRevenue: 99);

    when(
      () => batchLoader.loadProgressively(
        userId: any(named: 'userId'),
        catalogFilter: any(named: 'catalogFilter'),
        salesFilter: any(named: 'salesFilter'),
        preResolvedResolution: any(named: 'preResolvedResolution'),
        cancelScope: any(named: 'cancelScope'),
        bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
        targetWaveConcurrency: any(named: 'targetWaveConcurrency'),
      ),
    ).thenAnswer(
      (_) => Stream<AppResult<SalesLiveMapBatchLoadResult>>.fromIterable(
        <AppResult<SalesLiveMapBatchLoadResult>>[
          Success<SalesLiveMapBatchLoadResult, AppFailure>(partialBatch),
          Success<SalesLiveMapBatchLoadResult, AppFailure>(finalBatch),
        ],
      ),
    );
    when(
      () => reportMapper.emitMappedReports(
        any(),
        catalogResult: any(named: 'catalogResult'),
        filter: any(named: 'filter'),
        refreshedAt: any(named: 'refreshedAt'),
        cancelToken: any(named: 'cancelToken'),
        salesDataPending: any(named: 'salesDataPending'),
        allowPartialGeoReuse: any(named: 'allowPartialGeoReuse'),
        hubPresenceOnlineAgentIdsSnapshot:
            any(named: 'hubPresenceOnlineAgentIdsSnapshot'),
      ),
    ).thenAnswer((invocation) async* {
      final pending = invocation.namedArguments[#salesDataPending] as bool;
      final reuse = invocation.namedArguments[#allowPartialGeoReuse] as bool;
      if (pending && !reuse) {
        yield partialMapped;
        return;
      }
      yield finalMapped;
    });

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
          mergeWaveSize: 2,
          resolveSw: null,
          totalStopwatch: null,
          cachedCatalog: null,
          loadedViaMergedSqlBatch: true,
        )
        .toList();

    expect(emissions.first.salesDataPending, isTrue);
    expect(emissions, contains(finalMapped.result));
    verify(
      () => catalogPersister.persist(
        userId: userId,
        scope: catalogScope,
        now: now,
        page: finalBatch.catalogPage,
      ),
    ).called(1);
  });

  test('yields cancelled result when cancel token is set during batch stream', () async {
    final cancelToken = SalesLiveMapLoadCancelToken()..cancel();
    final batch = _batchResult(isFinal: false);

    when(
      () => batchLoader.loadProgressively(
        userId: any(named: 'userId'),
        catalogFilter: any(named: 'catalogFilter'),
        salesFilter: any(named: 'salesFilter'),
        preResolvedResolution: any(named: 'preResolvedResolution'),
        cancelScope: any(named: 'cancelScope'),
        bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
        targetWaveConcurrency: any(named: 'targetWaveConcurrency'),
      ),
    ).thenAnswer(
      (_) => Stream<AppResult<SalesLiveMapBatchLoadResult>>.value(
        Success<SalesLiveMapBatchLoadResult, AppFailure>(batch),
      ),
    );

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
          cancelToken: cancelToken,
          mergeWaveSize: 1,
          resolveSw: null,
          totalStopwatch: null,
          cachedCatalog: null,
          loadedViaMergedSqlBatch: false,
        )
        .toList();

    expect(emissions.last.cancelled, isTrue);
    verifyNever(() => catalogPersister.persist(
      userId: any(named: 'userId'),
      scope: any(named: 'scope'),
      now: any(named: 'now'),
      page: any(named: 'page'),
    ));
  });

  test('yields failed result when first batch emission fails', () async {
    const failure = NetworkFailure(message: 'batch down');

    when(
      () => batchLoader.loadProgressively(
        userId: any(named: 'userId'),
        catalogFilter: any(named: 'catalogFilter'),
        salesFilter: any(named: 'salesFilter'),
        preResolvedResolution: any(named: 'preResolvedResolution'),
        cancelScope: any(named: 'cancelScope'),
        bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
        targetWaveConcurrency: any(named: 'targetWaveConcurrency'),
      ),
    ).thenAnswer(
      (_) => Stream<AppResult<SalesLiveMapBatchLoadResult>>.value(
        const Failure<SalesLiveMapBatchLoadResult, AppFailure>(failure),
      ),
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
          loadedViaMergedSqlBatch: false,
        )
        .toList();

    expect(emissions.last.loadFailed, isTrue);
  });
}

SalesLiveMapBatchLoadResult _batchResult({
  required bool isFinal,
  bool salesLoadingComplete = true,
}) {
  final catalogPage = _catalogPage();
  const salesReport =
      AgentQueryExecutionReport<ResumoTotalVendasMunicipioFilialPeriodoRow>(
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
  return SalesLiveMapBatchLoadResult(
    catalogPage: catalogPage,
    salesReport: salesReport,
    totalElapsedMs: 1,
    isFinal: isFinal,
    salesLoadingComplete: salesLoadingComplete,
  );
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

import 'dart:async';

import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_cadastro_filial_across_agents_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_total_vendas_municipio_filial_periodo_across_agents_use_case.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_report.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_query_target_resolver.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_batch_load_orchestrator.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_branch_aggregator.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_branch_location_cache.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_catalog_lookup.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_catalog_persister.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_catalog_scope_resolver.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_diagnostics_logger.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_geolocator.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_in_memory_catalog_cache.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_load_cancel_token.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_load_result.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_parallel_load_orchestrator.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_progressive_emit_policy.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_refresh_metrics_recorder.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_report_mapper.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_result_builder.dart';
import 'package:colmeia/features/sales/application/ports/sales_live_map_batch_loader.dart';
import 'package:colmeia/features/sales/application/ports/sales_live_map_catalog_cache.dart';
import 'package:colmeia/features/sales/application/sales_live_map_catalog_scope.dart';
import 'package:colmeia/features/sales/application/sales_live_map_point_factory.dart';
import 'package:colmeia/features/sales/application/sales_live_map_policies.dart';
import 'package:colmeia/features/sales/application/sales_live_map_refresh_metrics.dart';
import 'package:colmeia/features/sales/application/sales_live_map_reload_reason.dart';
import 'package:colmeia/features/sales/domain/contracts/sales_live_map_point_resolver.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_filter.dart';

// Re-export the public types the use case API surface depends on so legacy
// call sites that import only this file keep compiling after the types
// moved to dedicated files under `load_sales_live_map/`.
export 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_load_cancel_token.dart';
export 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_load_failure_reason.dart';
export 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_load_result.dart';
export 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_location_diagnostics.dart';

class LoadSalesLiveMapUseCase {
  LoadSalesLiveMapUseCase(
    this._targetResolver,
    this._catalogDiskCache,
    this._loadResumoTotalVendasMunicipioFilialPeriodoAcrossAgents,
    this._loadCadastroFilialAcrossAgents,
    this._pointResolver, {
    SalesLiveMapPointFactory? pointFactory,
    SalesLiveMapRefreshMetrics? refreshMetrics,
    SalesLiveMapBranchAggregator? branchAggregator,
    SalesLiveMapDiagnosticsLogger? diagnosticsLogger,
    SalesLiveMapInMemoryCatalogCache? branchCatalogCache,
    SalesLiveMapBranchLocationCache? branchLocationCache,
    SalesLiveMapBatchLoader? batchLoader,
    DateTime Function()? now,
    SalesLiveMapCatalogScopeResolver? catalogScopeResolver,
    SalesLiveMapProgressiveEmitPolicy? emitPolicy,
    SalesLiveMapReportMapper? reportMapper,
    SalesLiveMapBatchLoadOrchestrator? batchLoadOrchestrator,
    SalesLiveMapParallelLoadOrchestrator? parallelLoadOrchestrator,
  }) : _refreshMetrics = refreshMetrics ?? SalesLiveMapRefreshMetrics(),
       _batchLoader = batchLoader,
       _pointFactory = pointFactory ?? const SalesLiveMapPointFactory(),
       _branchAggregator =
           branchAggregator ?? const SalesLiveMapBranchAggregator(),
       _diagnosticsLogger =
           diagnosticsLogger ?? const SalesLiveMapDiagnosticsLogger(),
       _now = now,
       _branchCatalogCache =
           branchCatalogCache ??
           SalesLiveMapInMemoryCatalogCache(
             maxEntries: SalesLiveMapPolicies.branchCatalogCacheMaxEntries,
             ttl: SalesLiveMapPolicies.branchCatalogCacheTtl,
           ),
       _branchLocationCache =
           branchLocationCache ??
           SalesLiveMapBranchLocationCache(
             maxEntries: SalesLiveMapPolicies.branchLocationCacheMaxEntries,
             ttl: SalesLiveMapPolicies.branchLocationCacheTtl,
           ),
       _catalogScopeResolver =
           catalogScopeResolver ?? const SalesLiveMapCatalogScopeResolver(),
       _emitPolicy =
           emitPolicy ??
           SalesLiveMapProgressiveEmitPolicy(
             diagnosticsLogger:
                 diagnosticsLogger ?? const SalesLiveMapDiagnosticsLogger(),
           ),
       _batchLoadOrchestrator = batchLoadOrchestrator,
       _parallelLoadOrchestrator = parallelLoadOrchestrator {
    _metricsRecorder = SalesLiveMapRefreshMetricsRecorder(
      metrics: _refreshMetrics,
      diagnosticsLogger: _diagnosticsLogger,
    );
    _catalogLookup = SalesLiveMapCatalogLookup(
      memoryCache: _branchCatalogCache,
      diskCache: _catalogDiskCache,
      loadCadastroAcrossAgents: _loadCadastroFilialAcrossAgents,
    );
    _geolocator = SalesLiveMapGeolocator(
      locationCache: _branchLocationCache,
      pointResolver: _pointResolver,
      pointFactory: _pointFactory,
      diagnosticsLogger: _diagnosticsLogger,
      maxConcurrency: geolocationMaxConcurrency,
    );
    _catalogPersister = SalesLiveMapCatalogPersister(
      memoryCache: _branchCatalogCache,
      diskCache: _catalogDiskCache,
    );
    _reportMapper =
        reportMapper ??
        SalesLiveMapReportMapper(
          branchAggregator: _branchAggregator,
          diagnosticsLogger: _diagnosticsLogger,
          geolocator: _geolocator,
          emitPolicy: _emitPolicy,
        );
    _resolvedBatchLoadOrchestrator =
        _batchLoadOrchestrator ??
        (_batchLoader == null
            ? null
            : SalesLiveMapBatchLoadOrchestrator(
                batchLoader: _batchLoader,
                reportMapper: _reportMapper,
                catalogPersister: _catalogPersister,
                diagnosticsLogger: _diagnosticsLogger,
                metricsRecorder: _metricsRecorder,
                emitPolicy: _emitPolicy,
                bridgeTimeoutMs: bridgeTimeoutMs,
              ));
    _resolvedParallelLoadOrchestrator =
        _parallelLoadOrchestrator ??
        SalesLiveMapParallelLoadOrchestrator(
          loadSalesAcrossAgents:
              _loadResumoTotalVendasMunicipioFilialPeriodoAcrossAgents,
          catalogLookup: _catalogLookup,
          reportMapper: _reportMapper,
          diagnosticsLogger: _diagnosticsLogger,
          metricsRecorder: _metricsRecorder,
          emitPolicy: _emitPolicy,
          bridgeTimeoutMs: bridgeTimeoutMs,
        );
  }

  static int get bridgeTimeoutMs => SalesLiveMapPolicies.bridgeTimeoutMs;
  static int get geolocationMaxConcurrency =>
      SalesLiveMapPolicies.geolocationMaxConcurrency;
  static int get primaryCompanyCode => SalesLiveMapPolicies.primaryCompanyCode;
  static int get primaryBranchCode => SalesLiveMapPolicies.primaryBranchCode;

  final AgentQueryTargetResolver _targetResolver;
  final SalesLiveMapCatalogCache _catalogDiskCache;
  final LoadResumoTotalVendasMunicipioFilialPeriodoAcrossAgentsUseCase
  _loadResumoTotalVendasMunicipioFilialPeriodoAcrossAgents;
  final LoadCadastroFilialAcrossAgentsUseCase _loadCadastroFilialAcrossAgents;
  final SalesLiveMapPointResolver _pointResolver;
  final SalesLiveMapPointFactory _pointFactory;
  final SalesLiveMapRefreshMetrics _refreshMetrics;
  final SalesLiveMapBranchAggregator _branchAggregator;
  final SalesLiveMapDiagnosticsLogger _diagnosticsLogger;
  final DateTime Function()? _now;
  final SalesLiveMapBranchLocationCache _branchLocationCache;
  final SalesLiveMapInMemoryCatalogCache _branchCatalogCache;
  final SalesLiveMapBatchLoader? _batchLoader;
  final SalesLiveMapCatalogScopeResolver _catalogScopeResolver;
  final SalesLiveMapProgressiveEmitPolicy _emitPolicy;
  final SalesLiveMapBatchLoadOrchestrator? _batchLoadOrchestrator;
  final SalesLiveMapParallelLoadOrchestrator? _parallelLoadOrchestrator;

  late final SalesLiveMapRefreshMetricsRecorder _metricsRecorder;
  late final SalesLiveMapCatalogLookup _catalogLookup;
  late final SalesLiveMapGeolocator _geolocator;
  late final SalesLiveMapCatalogPersister _catalogPersister;
  late final SalesLiveMapReportMapper _reportMapper;
  late final SalesLiveMapBatchLoadOrchestrator? _resolvedBatchLoadOrchestrator;
  late final SalesLiveMapParallelLoadOrchestrator
  _resolvedParallelLoadOrchestrator;

  Future<SalesLiveMapLoadResult> call({
    required String userId,
    required SalesLiveMapFilter filter,
    SalesLiveMapReloadReason reason = SalesLiveMapReloadReason.manual,
    SalesLiveMapLoadCancelToken? cancelToken,
  }) async {
    SalesLiveMapLoadResult? lastResult;
    await for (final result in loadProgressive(
      userId: userId,
      filter: filter,
      reason: reason,
      cancelToken: cancelToken,
    )) {
      lastResult = result;
    }
    return lastResult ?? _emitPolicy.cancelledResult(refreshedAt: _resolveNow());
  }

  Stream<SalesLiveMapLoadResult> loadProgressive({
    required String userId,
    required SalesLiveMapFilter filter,
    SalesLiveMapReloadReason reason = SalesLiveMapReloadReason.manual,
    SalesLiveMapLoadCancelToken? cancelToken,
    bool bypassCatalogCache = false,
  }) async* {
    final totalStopwatch = _diagnosticsLogger.startTraceStopwatch();
    final now = _resolveNow();
    final mergeWaveSize = AppEnvironment.salesLiveMapMergeWaveSize;
    if (cancelToken?.isCancelled ?? false) {
      yield _emitPolicy.cancelledResult(refreshedAt: now);
      return;
    }
    _geolocator.resetPartialGeoSnapshot();

    final queryFilter = filter.toAgentQueryFilter(
      now: now,
      codEmpresa: primaryCompanyCode,
      codFilial: primaryBranchCode,
    );
    final selectedAgentIds =
        filter.selectedAgentIds ?? queryFilter.selectedAgentIds;
    final catalogScope = _catalogScopeResolver.resolve(
      queryFilter: queryFilter,
      fallbackSelectedAgentIds: selectedAgentIds,
    );
    final cachedCatalog = bypassCatalogCache
        ? null
        : _catalogLookup.lookupCached(
            userId: userId,
            scope: catalogScope,
            now: now,
          );
    final cachedCatalogPage = cachedCatalog?.page;
    final loadedViaMergedSqlBatch = _emitPolicy.useMergedSqlBatchPerTarget(
      envFlag: AppEnvironment.agentSqlSalesLiveMapMergeSqlBatchesPerTarget,
      batchLoader: _batchLoader,
      catalogCacheMiss: cachedCatalogPage == null,
    );

    if (cachedCatalogPage != null && !(cancelToken?.isCancelled ?? false)) {
      _diagnosticsLogger.trace(
        'Sales live map catalog cache hit',
        <String, Object?>{
          'catalogSource': cachedCatalog!.source.name,
          'catalogScopeKind': catalogScope.kind.name,
          'catalogParticipantCount':
              cachedCatalogPage.report.participants.length,
          'catalogReturnedRowCount': _returnedRowCount(
            cachedCatalogPage.report,
          ),
        },
      );
      await for (final diskPartial in _reportMapper.emitMappedReports(
        null,
        catalogResult: cachedCatalogPage,
        filter: filter,
        refreshedAt: now,
        cancelToken: cancelToken,
        salesDataPending: true,
      )) {
        if (diskPartial.result.cancelled) {
          yield diskPartial.result;
          return;
        }
        yield diskPartial.result;
      }
      if (cancelToken?.isCancelled ?? false) {
        yield _emitPolicy.cancelledResult(refreshedAt: now);
        return;
      }
    }

    final resolveSw = _diagnosticsLogger.startTraceStopwatch();
    final resolutionResult = await _targetResolver.resolve(
      userId: userId,
      selectedAgentIds: selectedAgentIds,
    );
    final resolution = resolutionResult.getOrNull();
    _diagnosticsLogger.trace(
      'Sales live map agent targets resolved',
      <String, Object?>{
        'elapsedMs': resolveSw?.elapsedMilliseconds,
        'resolveSuccess': resolution != null,
        'consideredApprovedAgentCount':
            resolution?.consideredApprovedAgentCount,
      },
    );
    if (resolution == null) {
      _recordResolveFailure(
        now: now,
        reason: reason,
        catalogScope: catalogScope,
        cachedCatalog: cachedCatalog,
        selectedAgentIds: selectedAgentIds,
        selectedBranchCount: queryFilter.selectedBranches.length,
        resolveSw: resolveSw,
        mergeWaveSize: mergeWaveSize,
        loadedViaMergedSqlBatch: loadedViaMergedSqlBatch,
      );
      yield SalesLiveMapResultBuilder.failed(
        resolutionResult.exceptionOrNull()!,
        refreshedAt: now,
      );
      return;
    }
    if (cancelToken?.isCancelled ?? false) {
      yield _emitPolicy.cancelledResult(refreshedAt: now);
      return;
    }

    if (loadedViaMergedSqlBatch) {
      yield* _resolvedBatchLoadOrchestrator!.loadProgressive(
        userId: userId,
        filter: filter,
        reason: reason,
        now: now,
        catalogScope: catalogScope,
        queryFilter: queryFilter,
        selectedAgentIds: selectedAgentIds,
        resolution: resolution,
        cancelToken: cancelToken,
        mergeWaveSize: mergeWaveSize,
        resolveSw: resolveSw,
        totalStopwatch: totalStopwatch,
        cachedCatalog: cachedCatalog,
        loadedViaMergedSqlBatch: loadedViaMergedSqlBatch,
      );
      return;
    }

    yield* _resolvedParallelLoadOrchestrator.loadProgressive(
      userId: userId,
      filter: filter,
      reason: reason,
      now: now,
      catalogScope: catalogScope,
      queryFilter: queryFilter,
      selectedAgentIds: selectedAgentIds,
      resolution: resolution,
      cancelToken: cancelToken,
      mergeWaveSize: mergeWaveSize,
      resolveSw: resolveSw,
      totalStopwatch: totalStopwatch,
      cachedCatalog: cachedCatalog,
      cachedCatalogPage: cachedCatalogPage,
      loadedViaMergedSqlBatch: loadedViaMergedSqlBatch,
    );
  }

  void _recordResolveFailure({
    required DateTime now,
    required SalesLiveMapReloadReason reason,
    required SalesLiveMapCatalogScope catalogScope,
    required SalesLiveMapCatalogLookupResult? cachedCatalog,
    required Set<String>? selectedAgentIds,
    required int selectedBranchCount,
    required Stopwatch? resolveSw,
    required int mergeWaveSize,
    required bool loadedViaMergedSqlBatch,
  }) {
    _metricsRecorder.record(
      SalesLiveMapRefreshMetricEvent(
        recordedAt: now,
        reloadReason: reason,
        catalogScopeKind: catalogScope.kind,
        catalogSource:
            cachedCatalog?.source ?? SalesLiveMapCatalogSource.remote,
        selectedAgentCount: selectedAgentIds?.length ?? 0,
        selectedBranchCount: selectedBranchCount,
        resolveDurationMs: resolveSw?.elapsedMilliseconds ?? 0,
        catalogDurationMs: 0,
        salesDurationMs: 0,
        mapDurationMs: 0,
        geoDurationMs: 0,
        plannedAgentCount: 0,
        queriedAgentCount: 0,
        rowCapReachedAgentCount: 0,
        paginationStalledAgentIds: const <String>{},
        partialFailure: false,
        loadFailed: true,
        mergeWaveSize: mergeWaveSize,
        catalogSalesBatchMerged: loadedViaMergedSqlBatch,
      ),
    );
  }

  DateTime _resolveNow() => (_now ?? DateTime.now)();

  int _returnedRowCount<Row>(
    AgentQueryExecutionReport<Row> report,
  ) {
    return report.participants.fold<int>(
      0,
      (total, participant) => total + participant.rows.length,
    );
  }
}

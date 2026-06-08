import 'dart:async';

import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_cadastro_filial_across_agents_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_total_vendas_municipio_filial_periodo_across_agents_use_case.dart';
import 'package:colmeia/features/agent_queries/data/orchestration/agent_query_target_resolver.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_report.dart';
import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_across_agents_page_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_filter.dart'
    show CadastroFilialBranchRef;
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_vendas_municipio_filial_periodo_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_vendas_municipio_filial_periodo_row.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_branch_aggregate.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_branch_aggregator.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_branch_location_cache.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_catalog_lookup.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_diagnostics_logger.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_geolocator.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_in_memory_catalog_cache.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_load_cancel_token.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_load_failure_reason.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_load_result.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_location_diagnostics.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_refresh_metrics_recorder.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_result_builder.dart';
import 'package:colmeia/features/sales/application/ports/sales_live_map_catalog_cache.dart';
import 'package:colmeia/features/sales/application/sales_live_map_catalog_scope.dart';
import 'package:colmeia/features/sales/application/sales_live_map_point_factory.dart';
import 'package:colmeia/features/sales/application/sales_live_map_policies.dart';
import 'package:colmeia/features/sales/application/sales_live_map_refresh_metrics.dart';
import 'package:colmeia/features/sales/application/sales_live_map_reload_reason.dart';
import 'package:colmeia/features/sales/data/sales_live_map_batch_loader.dart';
import 'package:colmeia/features/sales/domain/contracts/sales_live_map_point_resolver.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_filter.dart';
import 'package:result_dart/result_dart.dart';

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
           );

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
  late final SalesLiveMapRefreshMetricsRecorder _metricsRecorder =
      SalesLiveMapRefreshMetricsRecorder(
        metrics: _refreshMetrics,
        diagnosticsLogger: _diagnosticsLogger,
      );
  late final SalesLiveMapCatalogLookup _catalogLookup =
      SalesLiveMapCatalogLookup(
        memoryCache: _branchCatalogCache,
        diskCache: _catalogDiskCache,
        loadCadastroAcrossAgents: _loadCadastroFilialAcrossAgents,
      );
  late final SalesLiveMapGeolocator _geolocator = SalesLiveMapGeolocator(
    locationCache: _branchLocationCache,
    pointResolver: _pointResolver,
    pointFactory: _pointFactory,
    diagnosticsLogger: _diagnosticsLogger,
    maxConcurrency: geolocationMaxConcurrency,
  );

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
    return lastResult ?? _cancelledResult(refreshedAt: _resolveNow());
  }

  Stream<SalesLiveMapLoadResult> loadProgressive({
    required String userId,
    required SalesLiveMapFilter filter,
    SalesLiveMapReloadReason reason = SalesLiveMapReloadReason.manual,
    SalesLiveMapLoadCancelToken? cancelToken,
  }) async* {
    final totalStopwatch = _diagnosticsLogger.startTraceStopwatch();
    final now = _resolveNow();
    final mergeWaveSize = AppEnvironment.salesLiveMapMergeWaveSize;
    final useMergedSqlBatchPerTarget =
        AppEnvironment.agentSqlSalesLiveMapMergeSqlBatchesPerTarget &&
        _batchLoader != null;
    if (cancelToken?.isCancelled ?? false) {
      yield _cancelledResult(refreshedAt: now);
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
    final catalogScope = _catalogScope(
      queryFilter: queryFilter,
      fallbackSelectedAgentIds: selectedAgentIds,
    );
    final cachedCatalog = _catalogLookup.lookupCached(
      userId: userId,
      scope: catalogScope,
      now: now,
    );
    final cachedCatalogPage = cachedCatalog?.page;
    final loadedViaMergedSqlBatch =
        useMergedSqlBatchPerTarget && cachedCatalogPage == null;

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
      await for (final diskPartial in _mapReportEmissions(
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
        yield _cancelledResult(refreshedAt: now);
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
      _metricsRecorder.record(
        SalesLiveMapRefreshMetricEvent(
          recordedAt: now,
          reloadReason: reason,
          catalogScopeKind: catalogScope.kind,
          catalogSource:
              cachedCatalog?.source ?? SalesLiveMapCatalogSource.remote,
          selectedAgentCount: selectedAgentIds?.length ?? 0,
          selectedBranchCount: queryFilter.selectedBranches.length,
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
      yield SalesLiveMapResultBuilder.failed(
        resolutionResult.exceptionOrNull()!,
        refreshedAt: now,
      );
      return;
    }
    if (cancelToken?.isCancelled ?? false) {
      yield _cancelledResult(refreshedAt: now);
      return;
    }

    final salesStopwatch = _diagnosticsLogger.startTraceStopwatch();
    final catalogStopwatch = cachedCatalogPage == null
        ? _diagnosticsLogger.startTraceStopwatch()
        : null;
    late final Future<AppResult<CadastroFilialAcrossAgentsPageResult>>
    catalogFuture;
    late final Future<
      AppResult<
        AgentQueryExecutionReport<ResumoTotalVendasMunicipioFilialPeriodoRow>
      >
    >
    salesFuture;
    if (useMergedSqlBatchPerTarget && cachedCatalogPage == null) {
      final batchLoader = _batchLoader;
      final batchFuture = _trackStopwatch(
        batchLoader.load(
          userId: userId,
          catalogFilter: catalogScope.toCatalogFilter(),
          salesFilter: queryFilter,
          preResolvedResolution: resolution,
          cancelScope: cancelToken?.sqlCancelScope,
          bridgeTimeoutMs: bridgeTimeoutMs,
          targetWaveConcurrency: mergeWaveSize,
        ),
        catalogStopwatch,
      );
      catalogFuture = batchFuture.then((result) {
        final batch = result.getOrNull();
        if (batch == null) {
          return Failure<CadastroFilialAcrossAgentsPageResult, AppFailure>(
            result.exceptionOrNull()!,
          );
        }
        final page = batch.catalogPage;
        _persistCatalogPage(
          userId: userId,
          scope: catalogScope,
          now: now,
          page: page,
        );
        return Success<CadastroFilialAcrossAgentsPageResult, AppFailure>(page);
      });
      salesFuture = _trackStopwatch(
        batchFuture.then((result) {
          final batch = result.getOrNull();
          if (batch == null) {
            return Failure<
              AgentQueryExecutionReport<
                ResumoTotalVendasMunicipioFilialPeriodoRow
              >,
              AppFailure
            >(result.exceptionOrNull()!);
          }
          return Success<
            AgentQueryExecutionReport<
              ResumoTotalVendasMunicipioFilialPeriodoRow
            >,
            AppFailure
          >(batch.salesReport);
        }),
        salesStopwatch,
      );
    } else {
      salesFuture = _trackStopwatch(
        _loadResumoTotalVendasMunicipioFilialPeriodoAcrossAgents(
          userId: userId,
          filter: queryFilter,
          selectedAgentIds: selectedAgentIds,
          bridgeTimeoutMs: bridgeTimeoutMs,
          preResolvedResolution: resolution,
          cancelScope: cancelToken?.sqlCancelScope,
          orderTargetsOnlineFirst: true,
          dedupeTargetsByAgentId: true,
          mergeAllConcurrencyOverride: mergeWaveSize,
        ),
        salesStopwatch,
      );
      catalogFuture = cachedCatalogPage != null
          ? Future<AppResult<CadastroFilialAcrossAgentsPageResult>>.value(
              Success<CadastroFilialAcrossAgentsPageResult, AppFailure>(
                cachedCatalogPage,
              ),
            )
          : _trackStopwatch(
              _catalogLookup.loadRemote(
                userId: userId,
                scope: catalogScope,
                now: now,
                preResolvedResolution: resolution,
                cancelToken: cancelToken,
                bridgeTimeoutMs: bridgeTimeoutMs,
                mergeAllConcurrencyOverride: mergeWaveSize,
              ),
              catalogStopwatch,
            );
    }

    if (cachedCatalogPage == null) {
      yield SalesLiveMapResultBuilder.pendingBase(refreshedAt: now);
    }

    final catalogResult = await catalogFuture;
    final catalogPage = catalogResult.getOrNull();
    if (cancelToken?.isCancelled ?? false) {
      yield _cancelledResult(refreshedAt: now);
      return;
    }

    if (catalogPage != null && cachedCatalogPage == null) {
      await for (final partialMapped in _mapReportEmissions(
        null,
        catalogResult: catalogPage,
        catalogFailure: catalogResult.exceptionOrNull(),
        filter: filter,
        refreshedAt: now,
        cancelToken: cancelToken,
        salesDataPending: true,
        hubPresenceOnlineAgentIdsSnapshot:
            resolution.hubPresenceOnlineAgentIdsSnapshot,
      )) {
        if (partialMapped.result.cancelled) {
          yield partialMapped.result;
          return;
        }
        yield partialMapped.result;
      }
    }

    final salesResult = await salesFuture;
    final salesReport = salesResult.getOrNull();
    _diagnosticsLogger.trace(
      'Sales live map SQL reports loaded',
      <String, Object?>{
        'reloadReason': reason.name,
        'catalogScopeKind': catalogScope.kind.name,
        'catalogSource':
            (cachedCatalog?.source ?? SalesLiveMapCatalogSource.remote).name,
        'resolveDurationMs': resolveSw?.elapsedMilliseconds,
        'salesDurationMs': salesStopwatch?.elapsedMilliseconds,
        'catalogDurationMs': catalogStopwatch?.elapsedMilliseconds ?? 0,
        'selectedAgentCount': selectedAgentIds?.length ?? 0,
        'selectedBranchCount': queryFilter.selectedBranches.length,
        'salesReportElapsedMs': salesReport?.totalElapsedMs,
        'catalogReportElapsedMs': catalogPage?.report.totalElapsedMs,
        'salesLoadSuccess': salesReport != null,
        'catalogLoadSuccess': catalogPage != null,
      },
    );
    if (cancelToken?.isCancelled ?? false) {
      yield _cancelledResult(refreshedAt: now);
      return;
    }

    if (salesReport != null) {
      _diagnosticsLogger.logParticipantMetrics(salesReport);
    }
    if (cancelToken?.isCancelled ?? false) {
      yield _cancelledResult(refreshedAt: now);
      return;
    }
    if (catalogPage == null && salesReport == null) {
      final failure =
          salesResult.exceptionOrNull() ?? catalogResult.exceptionOrNull()!;
      AppLogger.warning(
        'Sales live map queries failed',
        context: <String, Object?>{
          'operation': 'LoadSalesLiveMapUseCase',
          'failureType': failure.runtimeType.toString(),
        },
        error: failure,
      );
      _metricsRecorder.record(
        SalesLiveMapRefreshMetricEvent(
          recordedAt: now,
          reloadReason: reason,
          catalogScopeKind: catalogScope.kind,
          catalogSource:
              cachedCatalog?.source ?? SalesLiveMapCatalogSource.remote,
          selectedAgentCount: selectedAgentIds?.length ?? 0,
          selectedBranchCount: queryFilter.selectedBranches.length,
          resolveDurationMs: resolveSw?.elapsedMilliseconds ?? 0,
          catalogDurationMs: catalogStopwatch?.elapsedMilliseconds ?? 0,
          salesDurationMs: salesStopwatch?.elapsedMilliseconds ?? 0,
          mapDurationMs: 0,
          geoDurationMs: 0,
          plannedAgentCount: resolution.consideredApprovedTargets.length,
          queriedAgentCount: 0,
          rowCapReachedAgentCount: 0,
          paginationStalledAgentIds:
              catalogPage?.paginationStalledAgentIds ?? const <String>{},
          partialFailure: false,
          loadFailed: true,
          mergeWaveSize: mergeWaveSize,
          catalogSalesBatchMerged: loadedViaMergedSqlBatch,
        ),
      );
      yield SalesLiveMapResultBuilder.failed(failure, refreshedAt: now);
      return;
    }

    _SalesLiveMapMappedResult? mapped;
    await for (final emission in _mapReportEmissions(
      salesReport,
      catalogResult: catalogPage,
      salesFailure: salesResult.exceptionOrNull(),
      catalogFailure: catalogResult.exceptionOrNull(),
      filter: filter,
      refreshedAt: now,
      cancelToken: cancelToken,
      allowPartialGeoReuse: true,
      hubPresenceOnlineAgentIdsSnapshot:
          resolution.hubPresenceOnlineAgentIdsSnapshot,
    )) {
      mapped = emission;
      if (emission.result.cancelled) {
        yield emission.result;
        return;
      }
      yield emission.result;
    }
    mapped ??= _SalesLiveMapMappedResult(
      result: _cancelledResult(refreshedAt: now),
    );
    if (mapped.result.cancelled) {
      return;
    }
    final metricEvent = SalesLiveMapRefreshMetricEvent(
      recordedAt: now,
      reloadReason: reason,
      catalogScopeKind: catalogScope.kind,
      catalogSource: cachedCatalog?.source ?? SalesLiveMapCatalogSource.remote,
      selectedAgentCount: selectedAgentIds?.length ?? 0,
      selectedBranchCount: queryFilter.selectedBranches.length,
      resolveDurationMs: resolveSw?.elapsedMilliseconds ?? 0,
      catalogDurationMs: catalogStopwatch?.elapsedMilliseconds ?? 0,
      salesDurationMs: salesStopwatch?.elapsedMilliseconds ?? 0,
      mapDurationMs: mapped.mapDurationMs,
      geoDurationMs: mapped.geoDurationMs,
      plannedAgentCount: mapped.result.plannedAgentCount,
      queriedAgentCount: mapped.result.queriedAgentCount,
      rowCapReachedAgentCount: mapped.result.rowCapReachedAgentCount,
      paginationStalledAgentIds:
          catalogPage?.paginationStalledAgentIds ?? const <String>{},
      partialFailure: mapped.result.hasPartialIssue,
      loadFailed: mapped.result.loadFailed,
      mergeWaveSize: mergeWaveSize,
      catalogSalesBatchMerged: loadedViaMergedSqlBatch,
      partialIssueBreakdown: mapped.result.hasPartialIssue
          ? mapped.result.partialIssueActiveKeys
          : null,
    );
    _metricsRecorder.record(metricEvent);
    _diagnosticsLogger.trace(
      'Sales live map load completed',
      <String, Object?>{
        'elapsedMs': totalStopwatch?.elapsedMilliseconds,
        ...metricEvent.toLogContext(),
        'pointCount': mapped.result.points.length,
        'branchOptionCount': mapped.result.branchOptions.length,
        'totalBranchCount': mapped.result.totalBranchCount,
        'plannedAgentCount': mapped.result.plannedAgentCount,
        'queriedAgentCount': mapped.result.queriedAgentCount,
      },
    );
  }

  void _persistCatalogPage({
    required String userId,
    required SalesLiveMapCatalogScope scope,
    required DateTime now,
    required CadastroFilialAcrossAgentsPageResult page,
  }) {
    _branchCatalogCache.write(
      userId: userId,
      scope: scope,
      now: now,
      result: page,
    );
    unawaited(
      _catalogDiskCache.write(
        userId: userId,
        scope: scope,
        now: now,
        result: page,
      ),
    );
  }

  SalesLiveMapCatalogScope _catalogScope({
    required ResumoTotalVendasMunicipioFilialPeriodoFilter queryFilter,
    required Set<String>? fallbackSelectedAgentIds,
  }) {
    final selectedBranches = queryFilter.selectedBranches
        .map(
          (branch) => CadastroFilialBranchRef(
            agentId: branch.normalizedAgentId,
            codEmpresa: branch.codEmpresa,
            codFilial: branch.codFilial,
          ),
        )
        .toList(growable: false);
    if (selectedBranches.isNotEmpty) {
      return SalesLiveMapCatalogScope.branchSubset(
        selectedBranches: selectedBranches,
      );
    }
    return SalesLiveMapCatalogScope.fullAgent(
      agentIds: fallbackSelectedAgentIds,
    );
  }

  Stream<_SalesLiveMapMappedResult> _mapReportEmissions(
    AgentQueryExecutionReport<ResumoTotalVendasMunicipioFilialPeriodoRow>?
    salesReport, {
    required SalesLiveMapFilter filter,
    required DateTime refreshedAt,
    CadastroFilialAcrossAgentsPageResult? catalogResult,
    AppFailure? salesFailure,
    AppFailure? catalogFailure,
    SalesLiveMapLoadCancelToken? cancelToken,
    bool salesDataPending = false,
    bool allowPartialGeoReuse = false,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
  }) async* {
    final mapStopwatch = _diagnosticsLogger.startTraceStopwatch();
    if (cancelToken?.isCancelled ?? false) {
      yield _SalesLiveMapMappedResult(
        result: _cancelledResult(refreshedAt: refreshedAt),
      );
      return;
    }
    final aggregateStopwatch = _diagnosticsLogger.startTraceStopwatch();
    final catalogReport = catalogResult?.report;
    final AgentQueryExecutionReport<dynamic>? baseReport =
        catalogReport ?? salesReport;
    if (baseReport == null) {
      yield _SalesLiveMapMappedResult(
        result: SalesLiveMapResultBuilder.empty(refreshedAt: refreshedAt),
      );
      return;
    }
    final successfulParticipants = baseReport.participants
        .where((participant) => participant.isSuccess)
        .length;
    final returnedRowCount = _returnedRowCount(baseReport);
    final sourceRowCount = _sourceRowCount(baseReport);
    final agentDiagnostics = salesReport == null
        ? (
            salesAgentCount: 0,
            noSalesAgentOptions: const <SalesLiveMapAgentOption>[],
          )
        : _agentDiagnostics(salesReport);
    final salesUnavailableLabelsByAgentId = _branchAggregator
        .salesUnavailableLabelsByAgentId(
          catalogReport: catalogReport,
          salesReport: salesReport,
          salesFailure: salesFailure,
        );
    final aggregates = catalogReport == null
        ? _branchAggregator.aggregateFromSalesReport(salesReport!.participants)
        : _branchAggregator.aggregateFromCatalog(
            catalogReport: catalogReport,
            salesReport: salesReport,
            salesUnavailableLabelsByAgentId: salesUnavailableLabelsByAgentId,
            salesDataPending: salesDataPending,
          );
    final branchOptions = aggregates
        .map((aggregate) => aggregate.toBranchOption())
        .toList(growable: false);
    final visibleAggregates = _branchAggregator.filterByBranchSelection(
      aggregates,
      filter,
    );
    final failedCatalogAgentCount = catalogReport?.failedAgentIds.length ?? 0;
    final failedSalesAgentCount =
        salesReport?.failedAgentIds.length ??
        (salesFailure == null ? 0 : baseReport.plannedTargets.length);
    final failedAgentCount = _branchAggregator.combinedFailedAgentCount(
      catalogReport: catalogReport,
      salesReport: salesReport,
      catalogFailure: catalogFailure,
      salesFailure: salesFailure,
      plannedTargets: baseReport.plannedTargets.length,
    );
    final salesBranchCount = visibleAggregates
        .where((aggregate) => aggregate.qtdVendas > 0)
        .length;
    final salesPendingBranchCount = salesDataPending
        ? visibleAggregates.length
        : 0;
    final salesUnavailableBranchCount = salesDataPending
        ? 0
        : visibleAggregates
              .where((aggregate) => aggregate.salesDataUnavailable)
              .length;
    final noSalesBranchCount = salesDataPending
        ? 0
        : visibleAggregates
              .where(
                (aggregate) =>
                    !aggregate.salesDataUnavailable && aggregate.qtdVendas == 0,
              )
              .length;
    final zeroedBranchCount = noSalesBranchCount + salesUnavailableBranchCount;
    _diagnosticsLogger.trace(
      'Sales live map rows aggregated',
      <String, Object?>{
        'elapsedMs': aggregateStopwatch?.elapsedMilliseconds,
        'reportElapsedMs': baseReport.totalElapsedMs,
        'plannedAgentCount': baseReport.plannedTargets.length,
        'participantCount': baseReport.participants.length,
        'successfulParticipantCount': successfulParticipants,
        'failedAgentCount': failedAgentCount,
        'failedCatalogAgentCount': failedCatalogAgentCount,
        'failedSalesAgentCount': failedSalesAgentCount,
        'missingClientTokenAgentCount':
            baseReport.missingClientTokenTargets.length,
        'skippedOfflineAgentCount':
            baseReport.skippedDueToHubPresenceTargets.length,
        'returnedRowCount': returnedRowCount,
        'sourceRowCount': sourceRowCount,
        'rowCapReachedAgentCount': salesReport == null
            ? 0
            : _branchAggregator.rowCapReachedAgentCount(salesReport),
        'aggregateCount': aggregates.length,
        'visibleAggregateCount': visibleAggregates.length,
        'salesBranchCount': salesBranchCount,
        'salesPendingBranchCount': salesPendingBranchCount,
        'noSalesBranchCount': noSalesBranchCount,
        'salesUnavailableBranchCount': salesUnavailableBranchCount,
        'zeroedBranchCount': zeroedBranchCount,
      },
    );
    if (cancelToken?.isCancelled ?? false) {
      yield _SalesLiveMapMappedResult(
        result: _cancelledResult(refreshedAt: refreshedAt),
      );
      return;
    }

    var geoDurationMs = 0;
    final sqlGeolocationStopwatch = _diagnosticsLogger.startTraceStopwatch();
    final sqlGeolocation = await _geolocator.resolveSqlMunicipalityPoints(
      visibleAggregates,
      refreshedAt: refreshedAt,
      cancelToken: cancelToken,
    );
    geoDurationMs += sqlGeolocationStopwatch?.elapsedMilliseconds ?? 0;
    if (sqlGeolocation.cancelled) {
      yield _SalesLiveMapMappedResult(
        result: _cancelledResult(refreshedAt: refreshedAt),
      );
      return;
    }
    _diagnosticsLogger.trace(
      'Sales live map SQL municipality geolocation completed',
      <String, Object?>{
        'elapsedMs': sqlGeolocationStopwatch?.elapsedMilliseconds,
        'inputBranchCount': visibleAggregates.length,
        'pointCount': sqlGeolocation.points.length,
        'cacheHitCount': sqlGeolocation.cacheHitCount,
        'cacheMissCount': sqlGeolocation.cacheMissCount,
      },
    );
    yield _mappedResultFromGeolocation(
      geolocation: sqlGeolocation,
      mapStopwatch: mapStopwatch,
      geoDurationMs: geoDurationMs,
      branchOptions: branchOptions,
      visibleAggregates: visibleAggregates,
      baseReport: baseReport,
      salesReport: salesReport,
      agentDiagnostics: agentDiagnostics,
      failedAgentCount: failedAgentCount,
      salesBranchCount: salesBranchCount,
      salesPendingBranchCount: salesPendingBranchCount,
      salesUnavailableBranchCount: salesUnavailableBranchCount,
      noSalesBranchCount: noSalesBranchCount,
      zeroedBranchCount: zeroedBranchCount,
      salesDataPending: salesDataPending,
      failedCatalogAgentCount: failedCatalogAgentCount,
      failedSalesAgentCount: failedSalesAgentCount,
      refreshedAt: refreshedAt,
    );

    final fullGeolocationStopwatch = _diagnosticsLogger.startTraceStopwatch();
    final geolocation = await _geolocator.resolveBranchPoints(
      visibleAggregates,
      refreshedAt: refreshedAt,
      cancelToken: cancelToken,
      allowPartialGeoReuse: allowPartialGeoReuse,
    );
    geoDurationMs += fullGeolocationStopwatch?.elapsedMilliseconds ?? 0;
    final points = geolocation.points;
    if (geolocation.cancelled) {
      yield _SalesLiveMapMappedResult(
        result: _cancelledResult(refreshedAt: refreshedAt),
      );
      return;
    }
    if (salesDataPending) {
      _geolocator.recordPartialGeoSnapshot(
        aggregates: visibleAggregates,
        points: points,
      );
    }
    _diagnosticsLogger.trace(
      'Sales live map branch geolocation completed',
      <String, Object?>{
        'elapsedMs': fullGeolocationStopwatch?.elapsedMilliseconds,
        'inputBranchCount': visibleAggregates.length,
        'pointCount': points.length,
        'cacheHitCount': geolocation.cacheHitCount,
        'cacheMissCount': geolocation.cacheMissCount,
        'cacheUnresolvedHitCount': geolocation.cacheUnresolvedHitCount,
        'resolvedAndCachedCount': geolocation.resolvedAndCachedCount,
        'unresolvedAndCachedCount': geolocation.unresolvedAndCachedCount,
        'partialGeoReuseCount': geolocation.partialGeoReuseCount,
      },
    );
    yield _mappedResultFromGeolocation(
      geolocation: geolocation,
      mapStopwatch: mapStopwatch,
      geoDurationMs: geoDurationMs,
      branchOptions: branchOptions,
      visibleAggregates: visibleAggregates,
      baseReport: baseReport,
      salesReport: salesReport,
      agentDiagnostics: agentDiagnostics,
      failedAgentCount: failedAgentCount,
      salesBranchCount: salesBranchCount,
      salesPendingBranchCount: salesPendingBranchCount,
      salesUnavailableBranchCount: salesUnavailableBranchCount,
      noSalesBranchCount: noSalesBranchCount,
      zeroedBranchCount: zeroedBranchCount,
      salesDataPending: salesDataPending,
      failedCatalogAgentCount: failedCatalogAgentCount,
      failedSalesAgentCount: failedSalesAgentCount,
      refreshedAt: refreshedAt,
      hubPresenceOnlineAgentIdsSnapshot: hubPresenceOnlineAgentIdsSnapshot,
    );
  }

  static List<AppFailure> _collectAgentQueryFailures({
    required AgentQueryExecutionReport<dynamic> baseReport,
    AgentQueryExecutionReport<
      ResumoTotalVendasMunicipioFilialPeriodoRow
    >?
    salesReport,
  }) {
    final failures = <AppFailure>[];
    for (final participant in baseReport.participants) {
      final failure = participant.failure;
      if (failure != null) {
        failures.add(failure);
      }
    }
    if (salesReport != null) {
      for (final participant in salesReport.participants) {
        final failure = participant.failure;
        if (failure != null) {
          failures.add(failure);
        }
      }
    }
    return List<AppFailure>.unmodifiable(failures);
  }

  _SalesLiveMapMappedResult _mappedResultFromGeolocation({
    required SalesLiveMapGeolocationResult geolocation,
    required Stopwatch? mapStopwatch,
    required int geoDurationMs,
    required List<SalesLiveMapBranchOption> branchOptions,
    required List<SalesLiveMapBranchAggregate> visibleAggregates,
    required AgentQueryExecutionReport<dynamic> baseReport,
    required AgentQueryExecutionReport<
      ResumoTotalVendasMunicipioFilialPeriodoRow
    >?
    salesReport,
    required ({
      int salesAgentCount,
      List<SalesLiveMapAgentOption> noSalesAgentOptions,
    })
    agentDiagnostics,
    required int failedAgentCount,
    required int salesBranchCount,
    required int salesPendingBranchCount,
    required int salesUnavailableBranchCount,
    required int noSalesBranchCount,
    required int zeroedBranchCount,
    required bool salesDataPending,
    required int failedCatalogAgentCount,
    required int failedSalesAgentCount,
    required DateTime refreshedAt,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
  }) {
    final points = geolocation.points;
    final locationDiagnostics = SalesLiveMapLocationDiagnostics.fromPoints(
      points: points,
      totalBranchCount: visibleAggregates.length,
    );
    _diagnosticsLogger.logLocationSummary(locationDiagnostics);
    final mappedMunicipalityCount =
        SalesLiveMapResultBuilder.mappedMunicipalityCount(points);
    final unmappedBranchOptions =
        SalesLiveMapResultBuilder.unmappedBranchOptions(
          visibleAggregates: visibleAggregates,
          points: points,
        );
    final loadFailed = baseReport.requiresClientTokenSetup;
    return _SalesLiveMapMappedResult(
      result: SalesLiveMapLoadResult(
        points: points,
        branchOptions: branchOptions,
        unmappedBranchOptions: unmappedBranchOptions,
        totalRevenue: visibleAggregates.fold<double>(
          0,
          (total, aggregate) => total + aggregate.totalVenda,
        ),
        totalSalesCount: visibleAggregates.fold<int>(
          0,
          (total, aggregate) => total + aggregate.qtdVendas,
        ),
        totalBranchCount: visibleAggregates.length,
        mappedBranchCount: points.length,
        mappedMunicipalityCount: mappedMunicipalityCount,
        queriedAgentCount: baseReport.participants.length,
        plannedAgentCount: baseReport.plannedTargets.length,
        failedAgentCount: failedAgentCount,
        missingClientTokenAgentCount:
            baseReport.missingClientTokenTargets.length,
        skippedOfflineAgentCount:
            baseReport.skippedDueToHubPresenceTargets.length,
        rowCapReachedAgentCount: salesReport == null
            ? 0
            : _branchAggregator.rowCapReachedAgentCount(salesReport),
        salesAgentCount: agentDiagnostics.salesAgentCount,
        catalogBranchCount: visibleAggregates.length,
        salesBranchCount: salesBranchCount,
        zeroedBranchCount: zeroedBranchCount,
        noSalesBranchCount: noSalesBranchCount,
        salesUnavailableBranchCount: salesUnavailableBranchCount,
        salesDataPending: salesDataPending,
        salesPendingBranchCount: salesPendingBranchCount,
        failedCatalogAgentCount: failedCatalogAgentCount,
        failedSalesAgentCount: failedSalesAgentCount,
        noSalesAgentOptions: agentDiagnostics.noSalesAgentOptions,
        failedAgentOptions: SalesLiveMapResultBuilder.failedAgentOptionsFromReports(
          baseReport: baseReport,
          salesReport: salesReport,
        ),
        missingClientTokenAgentOptions:
            SalesLiveMapResultBuilder.agentOptionsFromTargets(
              baseReport.missingClientTokenTargets,
            ),
        skippedOfflineAgentOptions:
            SalesLiveMapResultBuilder.agentOptionsFromTargets(
              baseReport.skippedDueToHubPresenceTargets,
            ),
        locationDiagnostics: locationDiagnostics,
        loadFailed: loadFailed,
        loadFailureReason: loadFailed
            ? SalesLiveMapLoadFailureReason.missingClientTokenSetup
            : null,
        refreshedAt: refreshedAt,
        partialGeoReuseCount: geolocation.partialGeoReuseCount,
        hubPresenceOnlineAgentIdsSnapshot: hubPresenceOnlineAgentIdsSnapshot,
        agentQueryFailures: _collectAgentQueryFailures(
          baseReport: baseReport,
          salesReport: salesReport,
        ),
      ),
      mapDurationMs: mapStopwatch?.elapsedMilliseconds ?? 0,
      geoDurationMs: geoDurationMs,
    );
  }

  Future<T> _trackStopwatch<T>(Future<T> future, Stopwatch? stopwatch) {
    if (stopwatch == null) {
      return future;
    }
    return future.whenComplete(() {
      if (stopwatch.isRunning) {
        stopwatch.stop();
      }
    });
  }


  ({
    int salesAgentCount,
    List<SalesLiveMapAgentOption> noSalesAgentOptions,
  })
  _agentDiagnostics(
    AgentQueryExecutionReport<ResumoTotalVendasMunicipioFilialPeriodoRow>
    report,
  ) {
    final plannedAgentIds = report.plannedTargets
        .map((target) => target.agentId)
        .toSet();
    var salesAgentCount = 0;
    final noSalesAgentOptions = <SalesLiveMapAgentOption>[];

    for (final participant in report.participants) {
      if (!plannedAgentIds.contains(participant.agentId) ||
          !participant.isSuccess) {
        continue;
      }
      if (participant.rows.isEmpty) {
        noSalesAgentOptions.add(
          SalesLiveMapAgentOption(
            id: participant.agentId,
            name: participant.displayName,
          ),
        );
      } else {
        salesAgentCount += 1;
      }
    }

    noSalesAgentOptions.sort((left, right) => left.name.compareTo(right.name));
    return (
      salesAgentCount: salesAgentCount,
      noSalesAgentOptions: List<SalesLiveMapAgentOption>.unmodifiable(
        noSalesAgentOptions,
      ),
    );
  }

  SalesLiveMapLoadResult _cancelledResult({required DateTime refreshedAt}) {
    _diagnosticsLogger.trace(
      'Sales live map load cancelled before local processing completed',
      <String, Object?>{'refreshedAt': refreshedAt.toIso8601String()},
    );
    return SalesLiveMapResultBuilder.cancelled(refreshedAt: refreshedAt);
  }

  DateTime _resolveNow() => (_now ?? DateTime.now)();

  int _returnedRowCount<Row>(AgentQueryExecutionReport<Row> report) {
    return report.participants.fold<int>(
      0,
      (total, participant) => total + participant.rows.length,
    );
  }

  int _sourceRowCount<Row>(AgentQueryExecutionReport<Row> report) {
    return report.participants.fold<int>(
      0,
      (total, participant) => total + participant.sourceRowCount,
    );
  }

}

class _SalesLiveMapMappedResult {
  const _SalesLiveMapMappedResult({
    required this.result,
    this.mapDurationMs = 0,
    this.geoDurationMs = 0,
  });

  final SalesLiveMapLoadResult result;
  final int mapDurationMs;
  final int geoDurationMs;
}

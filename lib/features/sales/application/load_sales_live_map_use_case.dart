import 'dart:async';

import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_cadastro_filial_across_agents_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_total_vendas_municipio_filial_periodo_across_agents_use_case.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_bounded_result_max_rows.dart';
import 'package:colmeia/features/agent_queries/data/orchestration/agent_query_target_resolver.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_participant.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_report.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target_resolution.dart';
import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_across_agents_page_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_filter.dart'
    show CadastroFilialBranchRef;
import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_vendas_municipio_filial_periodo_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_vendas_municipio_filial_periodo_row.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_load_cancel_token.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_load_failure_reason.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_load_result.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_location_diagnostics.dart';
import 'package:colmeia/features/sales/application/sales_live_map_point_factory.dart';
import 'package:colmeia/features/sales/application/sales_live_map_refresh_metrics.dart';
import 'package:colmeia/features/sales/application/sales_live_map_reload_reason.dart';
import 'package:colmeia/features/sales/data/sales_live_map_catalog_disk_cache.dart';
import 'package:colmeia/features/sales/data/sales_live_map_catalog_scope.dart';
import 'package:colmeia/features/sales/domain/contracts/sales_live_map_point_resolver.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_branch_ref.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_filter.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_point.dart';
import 'package:flutter/foundation.dart';
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
    DateTime Function()? now,
  }) : _refreshMetrics = refreshMetrics ?? SalesLiveMapRefreshMetrics(),
       _pointFactory = pointFactory ?? const SalesLiveMapPointFactory(),
       _now = now;

  static const int bridgeTimeoutMs = 120000;
  static const int geolocationMaxConcurrency = 6;
  static const int primaryCompanyCode = 1;
  static const int primaryBranchCode = 1;
  static const int _branchLocationCacheMaxEntries = 5000;
  static const int _branchCatalogCacheMaxEntries = 200;
  static const Duration _branchLocationCacheTtl = Duration(minutes: 10);
  static const Duration _branchCatalogCacheTtl =
      SalesLiveMapCatalogDiskCache.ttl;

  final AgentQueryTargetResolver _targetResolver;
  final SalesLiveMapCatalogDiskCache _catalogDiskCache;
  final LoadResumoTotalVendasMunicipioFilialPeriodoAcrossAgentsUseCase
  _loadResumoTotalVendasMunicipioFilialPeriodoAcrossAgents;
  final LoadCadastroFilialAcrossAgentsUseCase _loadCadastroFilialAcrossAgents;
  final SalesLiveMapPointResolver _pointResolver;
  final SalesLiveMapPointFactory _pointFactory;
  final SalesLiveMapRefreshMetrics _refreshMetrics;
  final DateTime Function()? _now;
  final Map<String, _SalesLiveMapCachedBranchLocation> _branchLocationCache =
      <String, _SalesLiveMapCachedBranchLocation>{};
  final Map<String, _SalesLiveMapCachedCatalogResult> _branchCatalogCache =
      <String, _SalesLiveMapCachedCatalogResult>{};
  final Map<String, String> _partialLocationSignatureByBranchId =
      <String, String>{};
  final Map<String, SalesLiveMapPoint> _partialGeoPointsByBranchId =
      <String, SalesLiveMapPoint>{};

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
    final totalStopwatch = _startTraceStopwatch();
    final now = _resolveNow();
    final mergeWaveSize = AppEnvironment.salesLiveMapMergeWaveSize;
    if (cancelToken?.isCancelled ?? false) {
      yield _cancelledResult(refreshedAt: now);
      return;
    }
    _partialLocationSignatureByBranchId.clear();
    _partialGeoPointsByBranchId.clear();
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
    final cachedCatalog = _lookupCachedCatalog(
      userId: userId,
      scope: catalogScope,
      now: now,
    );
    final cachedCatalogPage = cachedCatalog?.result;

    if (cachedCatalogPage != null && !(cancelToken?.isCancelled ?? false)) {
      _logTrace(
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
      final diskPartial = await _mapReport(
        null,
        catalogResult: cachedCatalogPage,
        filter: filter,
        refreshedAt: now,
        cancelToken: cancelToken,
        salesDataPending: true,
      );
      if (diskPartial.result.cancelled) {
        yield diskPartial.result;
        return;
      }
      yield diskPartial.result;
      if (cancelToken?.isCancelled ?? false) {
        yield _cancelledResult(refreshedAt: now);
        return;
      }
    }

    final resolveSw = _startTraceStopwatch();
    final resolutionResult = await _targetResolver.resolve(
      userId: userId,
      selectedAgentIds: selectedAgentIds,
    );
    final resolution = resolutionResult.getOrNull();
    _logTrace(
      'Sales live map agent targets resolved',
      <String, Object?>{
        'elapsedMs': resolveSw?.elapsedMilliseconds,
        'resolveSuccess': resolution != null,
        'consideredApprovedAgentCount':
            resolution?.consideredApprovedAgentCount,
      },
    );
    if (resolution == null) {
      _recordRefreshMetric(
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
        ),
      );
      yield _failedResult(
        resolutionResult.exceptionOrNull()!,
        refreshedAt: now,
      );
      return;
    }
    if (cancelToken?.isCancelled ?? false) {
      yield _cancelledResult(refreshedAt: now);
      return;
    }

    final salesStopwatch = _startTraceStopwatch();
    final salesFuture = _trackStopwatch(
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
    final catalogStopwatch = cachedCatalogPage == null
        ? _startTraceStopwatch()
        : null;
    final catalogFuture = cachedCatalogPage != null
        ? Future<AppResult<CadastroFilialAcrossAgentsPageResult>>.value(
            Success<CadastroFilialAcrossAgentsPageResult, AppFailure>(
              cachedCatalogPage,
            ),
          )
        : _trackStopwatch(
            _loadCatalogRemote(
              userId: userId,
              scope: catalogScope,
              now: now,
              preResolvedResolution: resolution,
              cancelToken: cancelToken,
            ),
            catalogStopwatch,
          );

    if (cachedCatalogPage == null) {
      yield _pendingBaseResult(refreshedAt: now);
    }

    final catalogResult = await catalogFuture;
    final catalogPage = catalogResult.getOrNull();
    if (cancelToken?.isCancelled ?? false) {
      yield _cancelledResult(refreshedAt: now);
      return;
    }

    if (catalogPage != null && cachedCatalogPage == null) {
      final partialMapped = await _mapReport(
        null,
        catalogResult: catalogPage,
        catalogFailure: catalogResult.exceptionOrNull(),
        filter: filter,
        refreshedAt: now,
        cancelToken: cancelToken,
        salesDataPending: true,
      );
      if (partialMapped.result.cancelled) {
        yield partialMapped.result;
        return;
      }
      yield partialMapped.result;
    }

    final salesResult = await salesFuture;
    final salesReport = salesResult.getOrNull();
    _logTrace(
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
      _logParticipantMetrics(salesReport);
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
      _recordRefreshMetric(
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
        ),
      );
      yield _failedResult(failure, refreshedAt: now);
      return;
    }

    final mapped = await _mapReport(
      salesReport,
      catalogResult: catalogPage,
      salesFailure: salesResult.exceptionOrNull(),
      catalogFailure: catalogResult.exceptionOrNull(),
      filter: filter,
      refreshedAt: now,
      cancelToken: cancelToken,
      allowPartialGeoReuse: true,
    );
    if (mapped.result.cancelled) {
      yield mapped.result;
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
      partialIssueBreakdown: mapped.result.hasPartialIssue
          ? mapped.result.partialIssueActiveKeys
          : null,
    );
    _recordRefreshMetric(metricEvent);
    _logTrace(
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
    yield mapped.result;
  }

  Future<AppResult<CadastroFilialAcrossAgentsPageResult>> _loadCatalogRemote({
    required String userId,
    required SalesLiveMapCatalogScope scope,
    required DateTime now,
    required AgentQueryTargetResolution preResolvedResolution,
    SalesLiveMapLoadCancelToken? cancelToken,
  }) async {
    final result = await _loadCadastroFilialAcrossAgents.loadAll(
      userId: userId,
      filter: scope.toCatalogFilter(),
      selectedAgentIds: scope.selectedAgentIds,
      bridgeTimeoutMs: bridgeTimeoutMs,
      preResolvedResolution: preResolvedResolution,
      cancelScope: cancelToken?.sqlCancelScope,
      orderTargetsOnlineFirst: true,
      dedupeTargetsByAgentId: true,
      mergeAllConcurrencyOverride: AppEnvironment.salesLiveMapMergeWaveSize,
    );
    final page = result.getOrNull();
    if (page != null) {
      _writeCachedCatalog(
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
    return result;
  }

  _SalesLiveMapCatalogLookup? _lookupCachedCatalog({
    required String userId,
    required SalesLiveMapCatalogScope scope,
    required DateTime now,
  }) {
    final exactMemory = _readCachedCatalog(
      userId: userId,
      scope: scope,
      now: now,
    );
    if (exactMemory != null) {
      return _SalesLiveMapCatalogLookup(
        result: exactMemory.result,
        source: SalesLiveMapCatalogSource.memory,
      );
    }

    final exactDisk = _catalogDiskCache.readIfFresh(
      userId: userId,
      scope: scope,
      now: now,
    );
    if (exactDisk != null) {
      _writeCachedCatalog(
        userId: userId,
        scope: scope,
        now: now,
        result: exactDisk,
      );
      return _SalesLiveMapCatalogLookup(
        result: exactDisk,
        source: SalesLiveMapCatalogSource.disk,
      );
    }

    if (!scope.isBranchSubset) {
      return null;
    }

    final broaderScope = scope.compatibleFullAgentScope;
    final broaderMemory = _readCachedCatalog(
      userId: userId,
      scope: broaderScope,
      now: now,
    );
    if (broaderMemory != null) {
      final filtered = _filterCatalogBySelectedBranches(
        broaderMemory.result,
        scope.selectedBranches,
      );
      _writeCachedCatalog(
        userId: userId,
        scope: scope,
        now: now,
        result: filtered,
      );
      return _SalesLiveMapCatalogLookup(
        result: filtered,
        source: SalesLiveMapCatalogSource.broaderCacheFiltered,
      );
    }

    final broaderDisk = _catalogDiskCache.readIfFresh(
      userId: userId,
      scope: broaderScope,
      now: now,
    );
    if (broaderDisk == null) {
      return null;
    }
    _writeCachedCatalog(
      userId: userId,
      scope: broaderScope,
      now: now,
      result: broaderDisk,
    );
    final filtered = _filterCatalogBySelectedBranches(
      broaderDisk,
      scope.selectedBranches,
    );
    _writeCachedCatalog(
      userId: userId,
      scope: scope,
      now: now,
      result: filtered,
    );
    return _SalesLiveMapCatalogLookup(
      result: filtered,
      source: SalesLiveMapCatalogSource.broaderCacheFiltered,
    );
  }

  _SalesLiveMapCachedCatalogResult? _readCachedCatalog({
    required String userId,
    required SalesLiveMapCatalogScope scope,
    required DateTime now,
  }) {
    final key = _catalogCacheKey(userId: userId, scope: scope);
    final cached = _branchCatalogCache[key];
    if (cached == null) {
      return null;
    }
    if (cached.isExpired(now, ttl: _branchCatalogCacheTtl)) {
      _branchCatalogCache.remove(key);
      return null;
    }
    return cached;
  }

  void _writeCachedCatalog({
    required String userId,
    required SalesLiveMapCatalogScope scope,
    required DateTime now,
    required CadastroFilialAcrossAgentsPageResult result,
  }) {
    final key = _catalogCacheKey(userId: userId, scope: scope);
    _branchCatalogCache.remove(key);
    _branchCatalogCache[key] = _SalesLiveMapCachedCatalogResult(
      result: result,
      cachedAt: now,
    );
    while (_branchCatalogCache.length > _branchCatalogCacheMaxEntries) {
      _branchCatalogCache.remove(_branchCatalogCache.keys.first);
    }
  }

  String _catalogCacheKey({
    required String userId,
    required SalesLiveMapCatalogScope scope,
  }) {
    return '${userId.trim()}|${scope.storageKey}';
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

  CadastroFilialAcrossAgentsPageResult _filterCatalogBySelectedBranches(
    CadastroFilialAcrossAgentsPageResult result,
    Iterable<CadastroFilialBranchRef> selectedBranches,
  ) {
    if (selectedBranches.isEmpty) {
      return result;
    }

    final allowedBranchKeys = selectedBranches
        .map(
          (branch) => _branchKey(
            branch.normalizedAgentId,
            branch.codEmpresa,
            branch.codFilial,
          ),
        )
        .toSet();
    final participants = result.report.participants
        .map((participant) {
          if (!participant.isSuccess) {
            return participant;
          }
          final filteredRows = participant.rows
              .where(
                (row) => allowedBranchKeys.contains(
                  _branchKey(
                    participant.agentId,
                    row.codEmpresa,
                    row.codFilial,
                  ),
                ),
              )
              .toList(growable: false);
          if (filteredRows.length == participant.rows.length &&
              participant.sourceRowCount == filteredRows.length) {
            return participant;
          }
          return AgentQueryExecutionParticipant<CadastroFilialRow>(
            agentId: participant.agentId,
            displayName: participant.displayName,
            rows: filteredRows,
            elapsedMs: participant.elapsedMs,
            sourceRowCount: filteredRows.length,
            failure: participant.failure,
            wasDiscardedByRace: participant.wasDiscardedByRace,
          );
        })
        .toList(growable: false);
    final report = AgentQueryExecutionReport<CadastroFilialRow>(
      queryKey: result.report.queryKey,
      strategy: result.report.strategy,
      consideredApprovedAgentCount: result.report.consideredApprovedAgentCount,
      plannedTargets: result.report.plannedTargets,
      missingClientTokenTargets: result.report.missingClientTokenTargets,
      participants: participants,
      winnerAgentId: result.report.winnerAgentId,
      totalElapsedMs: result.report.totalElapsedMs,
      skippedDueToHubPresenceTargets:
          result.report.skippedDueToHubPresenceTargets,
    );
    return CadastroFilialAcrossAgentsPageResult.fromReport(
      report,
      paginationStalledAgentIds: result.paginationStalledAgentIds
          .where(
            (agentId) => participants.any(
              (participant) => participant.agentId == agentId,
            ),
          )
          .toSet(),
    );
  }

  Future<_SalesLiveMapMappedResult> _mapReport(
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
  }) async {
    final mapStopwatch = _startTraceStopwatch();
    if (cancelToken?.isCancelled ?? false) {
      return _SalesLiveMapMappedResult(
        result: _cancelledResult(refreshedAt: refreshedAt),
      );
    }
    final aggregateStopwatch = _startTraceStopwatch();
    final catalogReport = catalogResult?.report;
    final AgentQueryExecutionReport<dynamic>? baseReport =
        catalogReport ?? salesReport;
    if (baseReport == null) {
      return _SalesLiveMapMappedResult(
        result: SalesLiveMapLoadResult(
          points: const <SalesLiveMapPoint>[],
          branchOptions: const <SalesLiveMapBranchOption>[],
          totalRevenue: 0,
          totalSalesCount: 0,
          totalBranchCount: 0,
          mappedBranchCount: 0,
          mappedMunicipalityCount: 0,
          queriedAgentCount: 0,
          plannedAgentCount: 0,
          failedAgentCount: 0,
          missingClientTokenAgentCount: 0,
          skippedOfflineAgentCount: 0,
          rowCapReachedAgentCount: 0,
          refreshedAt: refreshedAt,
        ),
      );
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
    final salesUnavailableLabelsByAgentId = _salesUnavailableLabelsByAgentId(
      catalogReport: catalogReport,
      salesReport: salesReport,
      salesFailure: salesFailure,
    );
    final aggregates = catalogReport == null
        ? _aggregateRows(salesReport!.participants)
        : _aggregateCatalogRows(
            catalogReport: catalogReport,
            salesReport: salesReport,
            salesUnavailableLabelsByAgentId: salesUnavailableLabelsByAgentId,
            salesDataPending: salesDataPending,
          );
    final branchOptions = aggregates
        .map((aggregate) => aggregate.toBranchOption())
        .toList(growable: false);
    final visibleAggregates = _filterAggregatesByBranch(aggregates, filter);
    final failedCatalogAgentCount = catalogReport?.failedAgentIds.length ?? 0;
    final failedSalesAgentCount =
        salesReport?.failedAgentIds.length ??
        (salesFailure == null ? 0 : baseReport.plannedTargets.length);
    final failedAgentCount = _combinedFailedAgentCount(
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
    _logTrace(
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
            : _rowCapReachedAgentCount(salesReport),
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
      return _SalesLiveMapMappedResult(
        result: _cancelledResult(refreshedAt: refreshedAt),
      );
    }
    final geolocationStopwatch = _startTraceStopwatch();
    final geolocation = await _resolveBranchPoints(
      visibleAggregates,
      refreshedAt: refreshedAt,
      cancelToken: cancelToken,
      allowPartialGeoReuse: allowPartialGeoReuse,
    );
    final points = geolocation.points;
    if (geolocation.cancelled) {
      return _SalesLiveMapMappedResult(
        result: _cancelledResult(refreshedAt: refreshedAt),
      );
    }
    if (salesDataPending) {
      _partialLocationSignatureByBranchId
        ..clear()
        ..addEntries(
          visibleAggregates.map(
            (a) => MapEntry(a.id, a.locationSourceSignature),
          ),
        );
      _partialGeoPointsByBranchId
        ..clear()
        ..addEntries(points.map((p) => MapEntry(p.id, p)));
    }
    _logTrace(
      'Sales live map branch geolocation completed',
      <String, Object?>{
        'elapsedMs': geolocationStopwatch?.elapsedMilliseconds,
        'inputBranchCount': visibleAggregates.length,
        'pointCount': points.length,
        'maxConcurrency': _geolocationConcurrencyFor(
          visibleAggregates.length,
        ),
        'cacheHitCount': geolocation.cacheHitCount,
        'cacheMissCount': geolocation.cacheMissCount,
        'cacheUnresolvedHitCount': geolocation.cacheUnresolvedHitCount,
        'resolvedAndCachedCount': geolocation.resolvedAndCachedCount,
        'unresolvedAndCachedCount': geolocation.unresolvedAndCachedCount,
        'partialGeoReuseCount': geolocation.partialGeoReuseCount,
      },
    );
    final locationDiagnostics = SalesLiveMapLocationDiagnostics.fromPoints(
      points: points,
      totalBranchCount: visibleAggregates.length,
    );
    _logLocationSummary(locationDiagnostics);
    final mappedMunicipalityCount = _mappedMunicipalityCount(points);
    final unmappedBranchOptions = _unmappedBranchOptions(
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
            : _rowCapReachedAgentCount(salesReport),
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
        locationDiagnostics: locationDiagnostics,
        loadFailed: loadFailed,
        loadFailureReason: loadFailed
            ? SalesLiveMapLoadFailureReason.missingClientTokenSetup
            : null,
        refreshedAt: refreshedAt,
        partialGeoReuseCount: geolocation.partialGeoReuseCount,
      ),
      mapDurationMs: mapStopwatch?.elapsedMilliseconds ?? 0,
      geoDurationMs: geolocationStopwatch?.elapsedMilliseconds ?? 0,
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

  void _recordRefreshMetric(SalesLiveMapRefreshMetricEvent event) {
    _refreshMetrics.record(event);
    AppLogger.info(
      'Sales live map refresh completed',
      context: <String, Object?>{
        'operation': 'LoadSalesLiveMapUseCase',
        ...event.toLogContext(),
      },
    );
    if (!event.partialFailure &&
        !event.loadFailed &&
        event.paginationStalledAgentIds.isEmpty &&
        event.rowCapReachedAgentCount == 0) {
      return;
    }
    AppLogger.warning(
      'Sales live map refresh completed with anomalies',
      context: <String, Object?>{
        'operation': 'LoadSalesLiveMapUseCase',
        ...event.toLogContext(),
      },
    );
  }

  Future<_SalesLiveMapGeolocationResult> _resolveBranchPoints(
    List<_SalesLiveMapBranchAggregate> aggregates, {
    required DateTime refreshedAt,
    SalesLiveMapLoadCancelToken? cancelToken,
    bool allowPartialGeoReuse = false,
  }) async {
    if (aggregates.isEmpty) {
      return const _SalesLiveMapGeolocationResult();
    }

    final pointsByIndex = List<SalesLiveMapPoint?>.filled(
      aggregates.length,
      null,
    );
    final pending = <({int index, _SalesLiveMapBranchAggregate aggregate})>[];
    var cacheHitCount = 0;
    var cacheUnresolvedHitCount = 0;
    var partialGeoReuseCount = 0;

    for (var i = 0; i < aggregates.length; i++) {
      if (cancelToken?.isCancelled ?? false) {
        return const _SalesLiveMapGeolocationResult(cancelled: true);
      }

      final aggregate = aggregates[i];
      if (allowPartialGeoReuse) {
        final prev = _partialGeoPointsByBranchId[aggregate.id];
        final prevSig = _partialLocationSignatureByBranchId[aggregate.id];
        if (prev != null &&
            prevSig != null &&
            prevSig == aggregate.locationSourceSignature) {
          pointsByIndex[i] = _mergePartialGeoIntoAggregate(prev, aggregate);
          partialGeoReuseCount += 1;
          continue;
        }
      }

      final cached = _readCachedBranchLocation(
        aggregate,
        now: refreshedAt,
      );
      if (cached == null) {
        pending.add((index: i, aggregate: aggregate));
        continue;
      }

      if (cached.resolved) {
        cacheHitCount += 1;
        pointsByIndex[i] = cached.toPoint(
          aggregate,
          pointFactory: _pointFactory,
        );
      } else {
        cacheUnresolvedHitCount += 1;
      }
    }

    var resolvedAndCachedCount = 0;
    var unresolvedAndCachedCount = 0;
    if (pending.isNotEmpty) {
      final resolved = await _pointResolver.resolveAllWithDetails(
        pending.map((item) => item.aggregate.toPointSource(_pointFactory)),
        maxConcurrent: _geolocationConcurrencyFor(pending.length),
      );
      if (cancelToken?.isCancelled ?? false) {
        return const _SalesLiveMapGeolocationResult(cancelled: true);
      }

      final resolvedById = <String, SalesLiveMapResolvedPoint>{
        for (final item in resolved) item.point.id: item,
      };
      for (final item in pending) {
        final resolvedPoint = resolvedById[item.aggregate.id];
        if (resolvedPoint == null) {
          unresolvedAndCachedCount += 1;
          _writeCachedBranchLocation(
            item.aggregate,
            _SalesLiveMapCachedBranchLocation.unresolved(
              sourceSignature: item.aggregate.locationSourceSignature,
              cachedAt: refreshedAt,
            ),
          );
          _logBranchGeolocation(item.aggregate, null);
          continue;
        }

        resolvedAndCachedCount += 1;
        final cachedLocation = _SalesLiveMapCachedBranchLocation.fromResolved(
          sourceSignature: item.aggregate.locationSourceSignature,
          cachedAt: refreshedAt,
          resolved: resolvedPoint,
        );
        _writeCachedBranchLocation(item.aggregate, cachedLocation);
        pointsByIndex[item.index] = cachedLocation.toPoint(
          item.aggregate,
          pointFactory: _pointFactory,
        );
      }
    }

    return _SalesLiveMapGeolocationResult(
      points: pointsByIndex.whereType<SalesLiveMapPoint>().toList(
        growable: false,
      ),
      cacheHitCount: cacheHitCount,
      cacheMissCount: pending.length,
      cacheUnresolvedHitCount: cacheUnresolvedHitCount,
      resolvedAndCachedCount: resolvedAndCachedCount,
      unresolvedAndCachedCount: unresolvedAndCachedCount,
      partialGeoReuseCount: partialGeoReuseCount,
    );
  }

  _SalesLiveMapCachedBranchLocation? _readCachedBranchLocation(
    _SalesLiveMapBranchAggregate aggregate, {
    required DateTime now,
  }) {
    final cached = _branchLocationCache[aggregate.id];
    if (cached == null) {
      return null;
    }
    if (cached.isExpired(now, ttl: _branchLocationCacheTtl) ||
        cached.sourceSignature != aggregate.locationSourceSignature) {
      _branchLocationCache.remove(aggregate.id);
      return null;
    }
    return cached;
  }

  void _writeCachedBranchLocation(
    _SalesLiveMapBranchAggregate aggregate,
    _SalesLiveMapCachedBranchLocation location,
  ) {
    _branchLocationCache.remove(aggregate.id);
    _branchLocationCache[aggregate.id] = location;
    while (_branchLocationCache.length > _branchLocationCacheMaxEntries) {
      _branchLocationCache.remove(_branchLocationCache.keys.first);
    }
  }

  void _logParticipantMetrics(
    AgentQueryExecutionReport<ResumoTotalVendasMunicipioFilialPeriodoRow>
    report,
  ) {
    if (!_shouldTracePerformance) {
      return;
    }

    AppLogger.info(
      'Sales live map agent SQL participants',
      context: <String, Object?>{
        'operation': 'LoadSalesLiveMapUseCase',
        'participantCount': report.participants.length,
        'participants': report.participants
            .map(
              (participant) => <String, Object?>{
                'agentId': participant.agentId,
                'displayName': participant.displayName,
                'elapsedMs': participant.elapsedMs,
                'rowCount': participant.rows.length,
                'sourceRowCount': participant.sourceRowCount,
                'success': participant.isSuccess,
                'failureType': participant.failure?.runtimeType.toString(),
                'rowCapReached': participant.reachedSourceRowLimit(
                  AgentQueriesBoundedResultMaxRows
                      .resumoTotalVendasMunicipioFilialPeriodo,
                ),
              },
            )
            .toList(growable: false),
      },
    );
  }

  void _logBranchGeolocation(
    _SalesLiveMapBranchAggregate aggregate,
    SalesLiveMapResolvedPoint? resolved,
  ) {
    final point = resolved?.point;
    AppLogger.debug(
      'Sales live map branch geolocation resolved',
      context: <String, Object?>{
        'operation': 'LoadSalesLiveMapUseCase',
        'branchId': aggregate.id,
        'agentId': aggregate.agentId,
        'codEmpresa': aggregate.codEmpresa,
        'codFilial': aggregate.codFilial,
        'uf': aggregate.ufMunicipioFilial,
        'city': aggregate.nomeMunicipioFilial,
        'ibgeMunicipalityCode': aggregate.codigoIbgeMunicipioFilial,
        'hasCep': aggregate.cepFilial?.trim().isNotEmpty ?? false,
        'resolved': point != null,
        'resolution': point?.locationResolution?.name,
        'latitude': point?.latitude,
        'longitude': point?.longitude,
      },
    );
  }

  void _logLocationSummary(SalesLiveMapLocationDiagnostics diagnostics) {
    if (!diagnostics.hasAnySignal) {
      return;
    }

    AppLogger.debug(
      'Sales live map geolocation summary',
      context: <String, Object?>{
        'operation': 'LoadSalesLiveMapUseCase',
        'providedGeoPoint': diagnostics.resolvedByProvidedGeoPointCount,
        'ibgeMunicipalityCode': diagnostics.resolvedByIbgeMunicipalityCodeCount,
        'cep': diagnostics.resolvedByCepCount,
        'cityUf': diagnostics.resolvedByCityUfCount,
        'capitalUf': diagnostics.resolvedByCapitalUfCount,
        'stateUf': diagnostics.resolvedByStateUfCount,
        'unknownResolution': diagnostics.unknownResolutionCount,
        'unresolvedBranch': diagnostics.unresolvedBranchCount,
      },
    );
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

  SalesLiveMapLoadResult _failedResult(
    AppFailure failure, {
    required DateTime refreshedAt,
  }) {
    return SalesLiveMapLoadResult(
      points: const <SalesLiveMapPoint>[],
      branchOptions: const <SalesLiveMapBranchOption>[],
      totalRevenue: 0,
      totalSalesCount: 0,
      totalBranchCount: 0,
      mappedBranchCount: 0,
      mappedMunicipalityCount: 0,
      queriedAgentCount: 0,
      plannedAgentCount: 0,
      failedAgentCount: 0,
      missingClientTokenAgentCount: 0,
      skippedOfflineAgentCount: 0,
      rowCapReachedAgentCount: 0,
      loadFailed: true,
      loadFailureMessage: failure.userMessage,
      refreshedAt: refreshedAt,
    );
  }

  SalesLiveMapLoadResult _pendingBaseResult({
    required DateTime refreshedAt,
  }) {
    return SalesLiveMapLoadResult(
      points: const <SalesLiveMapPoint>[],
      branchOptions: const <SalesLiveMapBranchOption>[],
      totalRevenue: 0,
      totalSalesCount: 0,
      totalBranchCount: 0,
      mappedBranchCount: 0,
      mappedMunicipalityCount: 0,
      queriedAgentCount: 0,
      plannedAgentCount: 0,
      failedAgentCount: 0,
      missingClientTokenAgentCount: 0,
      skippedOfflineAgentCount: 0,
      rowCapReachedAgentCount: 0,
      salesDataPending: true,
      refreshedAt: refreshedAt,
    );
  }

  SalesLiveMapLoadResult _cancelledResult({
    required DateTime refreshedAt,
  }) {
    _logTrace(
      'Sales live map load cancelled before local processing completed',
      <String, Object?>{'refreshedAt': refreshedAt.toIso8601String()},
    );
    return SalesLiveMapLoadResult(
      points: const <SalesLiveMapPoint>[],
      branchOptions: const <SalesLiveMapBranchOption>[],
      totalRevenue: 0,
      totalSalesCount: 0,
      totalBranchCount: 0,
      mappedBranchCount: 0,
      mappedMunicipalityCount: 0,
      queriedAgentCount: 0,
      plannedAgentCount: 0,
      failedAgentCount: 0,
      missingClientTokenAgentCount: 0,
      skippedOfflineAgentCount: 0,
      rowCapReachedAgentCount: 0,
      refreshedAt: refreshedAt,
      cancelled: true,
    );
  }

  List<_SalesLiveMapBranchAggregate> _aggregateRows(
    Iterable<
      AgentQueryExecutionParticipant<ResumoTotalVendasMunicipioFilialPeriodoRow>
    >
    participants,
  ) {
    final byKey = <String, _SalesLiveMapBranchAggregate>{};
    for (final participant in participants) {
      if (!participant.isSuccess) {
        continue;
      }
      for (final row in participant.rows) {
        if (!_isPrimaryBranch(row.codEmpresa, row.codFilial)) {
          continue;
        }
        final key = _branchKey(
          participant.agentId,
          row.codEmpresa,
          row.codFilial,
        );
        byKey
            .putIfAbsent(
              key,
              () => _SalesLiveMapBranchAggregate.fromRow(
                participant: participant,
                row: row,
              ),
            )
            .add(row);
      }
    }

    final aggregates = byKey.values.toList(growable: false)
      ..sort(
        (left, right) {
          final amount = right.totalVenda.compareTo(left.totalVenda);
          if (amount != 0) {
            return amount;
          }
          return left.name.compareTo(right.name);
        },
      );
    return aggregates;
  }

  List<_SalesLiveMapBranchAggregate> _aggregateCatalogRows({
    required AgentQueryExecutionReport<CadastroFilialRow> catalogReport,
    required AgentQueryExecutionReport<
      ResumoTotalVendasMunicipioFilialPeriodoRow
    >?
    salesReport,
    required Map<String, String> salesUnavailableLabelsByAgentId,
    required bool salesDataPending,
  }) {
    final byKey = <String, _SalesLiveMapBranchAggregate>{};
    for (final participant in catalogReport.participants) {
      if (!participant.isSuccess) {
        continue;
      }
      for (final row in participant.rows) {
        final key = _branchKey(
          participant.agentId,
          row.codEmpresa,
          row.codFilial,
        );
        byKey.putIfAbsent(
          key,
          () {
            final aggregate = _SalesLiveMapBranchAggregate.fromCadastro(
              participant: participant,
              row: row,
            );
            final statusLabel =
                salesUnavailableLabelsByAgentId[participant.agentId];
            if (salesDataPending) {
              aggregate.markSalesDataLoading();
            } else if (statusLabel != null) {
              aggregate.markSalesDataUnavailable(statusLabel);
            }
            return aggregate;
          },
        );
      }
    }

    if (salesReport != null) {
      for (final participant in salesReport.participants) {
        if (!participant.isSuccess) {
          continue;
        }
        for (final row in participant.rows) {
          if (!_isPrimaryBranch(row.codEmpresa, row.codFilial)) {
            continue;
          }
          final aggregate =
              byKey[_branchKey(
                participant.agentId,
                row.codEmpresa,
                row.codFilial,
              )];
          aggregate?.add(row);
        }
      }
    }

    final aggregates = byKey.values.toList(growable: false)
      ..sort(
        (left, right) {
          final amount = right.totalVenda.compareTo(left.totalVenda);
          if (amount != 0) {
            return amount;
          }
          return left.name.compareTo(right.name);
        },
      );
    return aggregates;
  }

  Map<String, String> _salesUnavailableLabelsByAgentId({
    required AgentQueryExecutionReport<CadastroFilialRow>? catalogReport,
    required AgentQueryExecutionReport<
      ResumoTotalVendasMunicipioFilialPeriodoRow
    >?
    salesReport,
    required AppFailure? salesFailure,
  }) {
    if (catalogReport == null) {
      return const <String, String>{};
    }

    final catalogSuccessAgentIds = catalogReport.participants
        .where((participant) => participant.isSuccess)
        .map((participant) => participant.agentId)
        .toSet();
    if (catalogSuccessAgentIds.isEmpty) {
      return const <String, String>{};
    }

    if (salesReport == null) {
      if (salesFailure == null) {
        return const <String, String>{};
      }
      return <String, String>{
        for (final agentId in catalogSuccessAgentIds)
          agentId: _salesUnavailableLabel(salesFailure),
      };
    }

    final labelsByAgentId = <String, String>{};
    for (final participant in salesReport.participants) {
      if (participant.isSuccess ||
          !catalogSuccessAgentIds.contains(participant.agentId)) {
        continue;
      }
      labelsByAgentId[participant.agentId] = _salesUnavailableLabel(
        participant.failure,
      );
    }
    return Map<String, String>.unmodifiable(labelsByAgentId);
  }

  String _salesUnavailableLabel(AppFailure? failure) {
    final userMessage = failure?.userMessage?.trim();
    if (userMessage != null && userMessage.isNotEmpty) {
      return userMessage;
    }
    return 'Vendas indisponiveis';
  }

  int _combinedFailedAgentCount({
    required AgentQueryExecutionReport<CadastroFilialRow>? catalogReport,
    required AgentQueryExecutionReport<
      ResumoTotalVendasMunicipioFilialPeriodoRow
    >?
    salesReport,
    required AppFailure? catalogFailure,
    required AppFailure? salesFailure,
    required int plannedTargets,
  }) {
    final failed = <String>{};
    if (catalogReport != null) {
      failed.addAll(catalogReport.failedAgentIds);
    } else if (catalogFailure != null && salesReport == null) {
      return plannedTargets;
    }
    if (salesReport != null) {
      failed.addAll(salesReport.failedAgentIds);
    } else if (salesFailure != null) {
      return plannedTargets;
    }
    return failed.length;
  }

  String _branchKey(String agentId, int codEmpresa, int codFilial) {
    return '$agentId:$codEmpresa:$codFilial';
  }

  static bool _isPrimaryBranch(int codEmpresa, int codFilial) {
    return codEmpresa == primaryCompanyCode && codFilial == primaryBranchCode;
  }

  List<_SalesLiveMapBranchAggregate> _filterAggregatesByBranch(
    List<_SalesLiveMapBranchAggregate> aggregates,
    SalesLiveMapFilter filter,
  ) {
    final selectedBranchIds = filter.selectedBranchIds;
    if (selectedBranchIds == null || selectedBranchIds.isEmpty) {
      return aggregates;
    }

    return aggregates
        .where((aggregate) => selectedBranchIds.contains(aggregate.branchRef))
        .toList(growable: false);
  }

  DateTime _resolveNow() => (_now ?? DateTime.now)();

  Stopwatch? _startTraceStopwatch() {
    if (!_shouldTracePerformance) {
      return null;
    }
    return Stopwatch()..start();
  }

  void _logTrace(String message, Map<String, Object?> context) {
    if (!_shouldTracePerformance) {
      return;
    }
    AppLogger.info(
      message,
      context: <String, Object?>{
        'operation': 'LoadSalesLiveMapUseCase',
        ...context,
      },
    );
  }

  bool get _shouldTracePerformance => kDebugMode || kProfileMode;

  int _rowCapReachedAgentCount(
    AgentQueryExecutionReport<ResumoTotalVendasMunicipioFilialPeriodoRow>
    report,
  ) {
    return report.participants
        .where(
          (participant) => participant.reachedSourceRowLimit(
            AgentQueriesBoundedResultMaxRows
                .resumoTotalVendasMunicipioFilialPeriodo,
          ),
        )
        .length;
  }

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

  int _geolocationConcurrencyFor(int branchCount) {
    if (branchCount <= 1) {
      return 1;
    }
    return branchCount < geolocationMaxConcurrency
        ? branchCount
        : geolocationMaxConcurrency;
  }

  int _mappedMunicipalityCount(Iterable<SalesLiveMapPoint> points) {
    return points.map(_municipalityKeyFor).toSet().length;
  }

  List<SalesLiveMapBranchOption> _unmappedBranchOptions({
    required List<_SalesLiveMapBranchAggregate> visibleAggregates,
    required List<SalesLiveMapPoint> points,
  }) {
    final mappedBranchIds = points.map((point) => point.id).toSet();

    return visibleAggregates
        .where((aggregate) => !mappedBranchIds.contains(aggregate.id))
        .map((aggregate) => aggregate.toBranchOption())
        .toList(growable: false);
  }

  String _municipalityKeyFor(SalesLiveMapPoint point) {
    final municipalityCode = point.municipalityCode?.trim();
    if (municipalityCode != null && municipalityCode.isNotEmpty) {
      return 'ibge:${municipalityCode.toUpperCase()}';
    }

    final city = point.city?.trim();
    if (city != null && city.isNotEmpty) {
      return 'city:${city.toUpperCase()}:${point.uf.trim().toUpperCase()}';
    }

    return 'coordinate:${point.latitude}:${point.longitude}:${point.uf.trim().toUpperCase()}';
  }
}

SalesLiveMapPoint _mergePartialGeoIntoAggregate(
  SalesLiveMapPoint base,
  _SalesLiveMapBranchAggregate aggregate,
) {
  return const SalesLiveMapPointFactory().mergeAggregateOntoResolvedBase(
    base: base,
    name: aggregate.name,
    salesAmount: aggregate.totalVenda,
    salesCount: aggregate.qtdVendas,
    fantasyName: _SalesLiveMapBranchAggregate._trimmedOrNull(
      aggregate.nomeFantasiaFilial,
    ),
    branchName: _SalesLiveMapBranchAggregate._trimmedOrNull(
      aggregate.nomeFilial,
    ),
    companyCode: aggregate.codEmpresa,
    branchCode: aggregate.codFilial,
    agentName: _SalesLiveMapBranchAggregate._trimmedOrNull(
      aggregate.agentName,
    ),
    salesDataLoading: aggregate.salesDataLoading,
    salesDataUnavailable: aggregate.salesDataUnavailable,
    salesDataStatusLabel: _SalesLiveMapBranchAggregate._trimmedOrNull(
      aggregate.salesDataStatusLabel,
    ),
    subtitle:
        'Agente ${aggregate.agentName} - Empresa ${aggregate.codEmpresa} - Filial ${aggregate.codFilial}',
    payload: aggregate,
  );
}

class _SalesLiveMapBranchAggregate {
  _SalesLiveMapBranchAggregate({
    required this.agentId,
    required this.agentName,
    required this.codEmpresa,
    required this.codFilial,
    required this.nomeFilial,
    required this.nomeMunicipioFilial,
    required this.ufMunicipioFilial,
    this.nomeFantasiaFilial,
    this.cepFilial,
    this.codigoIbgeMunicipioFilial,
  });

  factory _SalesLiveMapBranchAggregate.fromRow({
    required AgentQueryExecutionParticipant<
      ResumoTotalVendasMunicipioFilialPeriodoRow
    >
    participant,
    required ResumoTotalVendasMunicipioFilialPeriodoRow row,
  }) {
    return _SalesLiveMapBranchAggregate(
      agentId: participant.agentId,
      agentName: participant.displayName,
      codEmpresa: row.codEmpresa,
      codFilial: row.codFilial,
      nomeFilial: row.nomeFilial,
      nomeFantasiaFilial: row.nomeFantasiaFilial,
      cepFilial: row.cepFilial,
      nomeMunicipioFilial: row.nomeMunicipioFilial,
      ufMunicipioFilial: row.ufMunicipioFilial,
      codigoIbgeMunicipioFilial: row.codigoIbgeMunicipioFilial,
    );
  }

  factory _SalesLiveMapBranchAggregate.fromCadastro({
    required AgentQueryExecutionParticipant<CadastroFilialRow> participant,
    required CadastroFilialRow row,
  }) {
    return _SalesLiveMapBranchAggregate(
      agentId: participant.agentId,
      agentName: participant.displayName,
      codEmpresa: row.codEmpresa,
      codFilial: row.codFilial,
      nomeFilial: row.nomeFilial,
      nomeFantasiaFilial: row.nomeFantasia,
      cepFilial: row.cep,
      nomeMunicipioFilial: row.nomeMunicipio,
      ufMunicipioFilial: row.ufMunicipio,
      codigoIbgeMunicipioFilial: row.codigoIbge,
    );
  }

  final String agentId;
  final String agentName;
  final int codEmpresa;
  final int codFilial;
  final String nomeFilial;
  final String? nomeFantasiaFilial;
  final String? cepFilial;
  final String? nomeMunicipioFilial;
  final String? ufMunicipioFilial;
  final String? codigoIbgeMunicipioFilial;
  double totalVenda = 0;
  int qtdVendas = 0;
  bool salesDataLoading = false;
  bool salesDataUnavailable = false;
  String? salesDataStatusLabel;

  String get id => '$agentId-$codEmpresa-$codFilial';

  SalesLiveMapBranchRef get branchRef => SalesLiveMapBranchRef(
    agentId: agentId,
    codEmpresa: codEmpresa,
    codFilial: codFilial,
  );

  String get locationSourceSignature {
    return <String>[
      _normalizeLocationPart(ufMunicipioFilial),
      _normalizeLocationPart(nomeMunicipioFilial),
      _normalizeLocationPart(cepFilial),
      _normalizeLocationPart(codigoIbgeMunicipioFilial),
    ].join('|');
  }

  String get name {
    final fantasy = nomeFantasiaFilial?.trim();
    if (fantasy != null && fantasy.isNotEmpty) {
      return fantasy;
    }
    return nomeFilial;
  }

  String get registrationName {
    final branch = nomeFilial.trim();
    if (branch.isNotEmpty) {
      return branch;
    }
    return name;
  }

  void add(ResumoTotalVendasMunicipioFilialPeriodoRow row) {
    totalVenda += row.totalVenda;
    qtdVendas += row.qtdVendas;
  }

  void markSalesDataLoading() {
    salesDataLoading = true;
    salesDataUnavailable = false;
    salesDataStatusLabel = null;
  }

  void markSalesDataUnavailable(String statusLabel) {
    salesDataLoading = false;
    salesDataUnavailable = true;
    salesDataStatusLabel = statusLabel;
  }

  SalesLiveMapPointSource toPointSource(
    SalesLiveMapPointFactory pointFactory,
  ) {
    return pointFactory.createSource(
      id: id,
      name: name,
      salesAmount: totalVenda,
      salesCount: qtdVendas,
      uf: ufMunicipioFilial,
      city: nomeMunicipioFilial,
      latitude: null,
      longitude: null,
      cep: cepFilial,
      ibgeMunicipalityCode: codigoIbgeMunicipioFilial,
      allowUfFallback: false,
      fantasyName: _trimmedOrNull(nomeFantasiaFilial),
      branchName: _trimmedOrNull(nomeFilial),
      companyCode: codEmpresa,
      branchCode: codFilial,
      agentName: _trimmedOrNull(agentName),
      salesDataLoading: salesDataLoading,
      salesDataUnavailable: salesDataUnavailable,
      salesDataStatusLabel: _trimmedOrNull(salesDataStatusLabel),
      subtitle: 'Agente $agentName - Empresa $codEmpresa - Filial $codFilial',
      payload: this,
    );
  }

  SalesLiveMapBranchOption toBranchOption() {
    return SalesLiveMapBranchOption(
      id: id,
      agentId: agentId,
      agentName: agentName,
      codEmpresa: codEmpresa,
      codFilial: codFilial,
      registrationName: registrationName,
      fantasyName: _trimmedOrNull(nomeFantasiaFilial),
      city: _branchCityLabel,
      uf: _branchUfLabel,
    );
  }

  String get _branchCityLabel {
    final city = nomeMunicipioFilial?.trim();
    if (city != null && city.isNotEmpty) {
      return city;
    }

    return 'Sem municipio';
  }

  String get _branchUfLabel {
    final uf = ufMunicipioFilial?.trim();
    if (uf != null && uf.isNotEmpty) {
      return uf;
    }

    return '--';
  }

  static String _normalizeLocationPart(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return '';
    }
    return trimmed.toUpperCase();
  }

  static String? _trimmedOrNull(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }
}

class _SalesLiveMapGeolocationResult {
  const _SalesLiveMapGeolocationResult({
    this.points = const <SalesLiveMapPoint>[],
    this.cacheHitCount = 0,
    this.cacheMissCount = 0,
    this.cacheUnresolvedHitCount = 0,
    this.resolvedAndCachedCount = 0,
    this.unresolvedAndCachedCount = 0,
    this.partialGeoReuseCount = 0,
    this.cancelled = false,
  });

  final List<SalesLiveMapPoint> points;
  final int cacheHitCount;
  final int cacheMissCount;
  final int cacheUnresolvedHitCount;
  final int resolvedAndCachedCount;
  final int unresolvedAndCachedCount;
  final int partialGeoReuseCount;
  final bool cancelled;
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

class _SalesLiveMapCatalogLookup {
  const _SalesLiveMapCatalogLookup({
    required this.result,
    required this.source,
  });

  final CadastroFilialAcrossAgentsPageResult result;
  final SalesLiveMapCatalogSource source;
}

class _SalesLiveMapCachedCatalogResult {
  const _SalesLiveMapCachedCatalogResult({
    required this.result,
    required this.cachedAt,
  });

  final CadastroFilialAcrossAgentsPageResult result;
  final DateTime cachedAt;

  bool isExpired(DateTime now, {required Duration ttl}) {
    return now.difference(cachedAt) > ttl;
  }
}

class _SalesLiveMapCachedBranchLocation {
  const _SalesLiveMapCachedBranchLocation({
    required this.sourceSignature,
    required this.cachedAt,
    required this.resolved,
    this.uf,
    this.latitude,
    this.longitude,
    this.municipalityCode,
    this.city,
    this.locationResolution,
  });

  factory _SalesLiveMapCachedBranchLocation.fromResolved({
    required String sourceSignature,
    required DateTime cachedAt,
    required SalesLiveMapResolvedPoint resolved,
  }) {
    final point = resolved.point;
    return _SalesLiveMapCachedBranchLocation(
      sourceSignature: sourceSignature,
      cachedAt: cachedAt,
      resolved: true,
      uf: point.uf,
      latitude: point.latitude,
      longitude: point.longitude,
      municipalityCode: point.municipalityCode,
      city: point.city,
      locationResolution: point.locationResolution,
    );
  }

  const _SalesLiveMapCachedBranchLocation.unresolved({
    required this.sourceSignature,
    required this.cachedAt,
  }) : resolved = false,
       uf = null,
       latitude = null,
       longitude = null,
       municipalityCode = null,
       city = null,
       locationResolution = null;

  final String sourceSignature;
  final DateTime cachedAt;
  final bool resolved;
  final String? uf;
  final double? latitude;
  final double? longitude;
  final String? municipalityCode;
  final String? city;
  final SalesLiveMapLocationResolution? locationResolution;

  bool isExpired(DateTime now, {required Duration ttl}) {
    return now.difference(cachedAt) > ttl;
  }

  SalesLiveMapPoint? toPoint(
    _SalesLiveMapBranchAggregate aggregate, {
    required SalesLiveMapPointFactory pointFactory,
  }) {
    final resolvedUf = uf;
    final resolvedLatitude = latitude;
    final resolvedLongitude = longitude;
    if (!resolved ||
        resolvedUf == null ||
        resolvedLatitude == null ||
        resolvedLongitude == null) {
      return null;
    }

    return pointFactory.createPoint(
      id: aggregate.id,
      name: aggregate.name,
      uf: resolvedUf,
      latitude: resolvedLatitude,
      longitude: resolvedLongitude,
      salesAmount: aggregate.totalVenda,
      salesCount: aggregate.qtdVendas,
      municipalityCode: municipalityCode,
      city: city,
      fantasyName: _SalesLiveMapBranchAggregate._trimmedOrNull(
        aggregate.nomeFantasiaFilial,
      ),
      branchName: _SalesLiveMapBranchAggregate._trimmedOrNull(
        aggregate.nomeFilial,
      ),
      companyCode: aggregate.codEmpresa,
      branchCode: aggregate.codFilial,
      agentName: _SalesLiveMapBranchAggregate._trimmedOrNull(
        aggregate.agentName,
      ),
      salesDataLoading: aggregate.salesDataLoading,
      salesDataUnavailable: aggregate.salesDataUnavailable,
      salesDataStatusLabel: _SalesLiveMapBranchAggregate._trimmedOrNull(
        aggregate.salesDataStatusLabel,
      ),
      locationResolution: locationResolution,
      subtitle:
          'Agente ${aggregate.agentName} - Empresa ${aggregate.codEmpresa} - Filial ${aggregate.codFilial}',
      payload: aggregate,
    );
  }
}

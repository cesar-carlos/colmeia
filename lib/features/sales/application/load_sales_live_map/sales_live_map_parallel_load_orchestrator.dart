import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_total_vendas_municipio_filial_periodo_across_agents_use_case.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_report.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target_resolution.dart';
import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_across_agents_page_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_vendas_municipio_filial_periodo_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_vendas_municipio_filial_periodo_row.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_catalog_lookup.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_diagnostics_logger.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_load_cancel_token.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_load_result.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_mapped_result.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_progressive_emit_policy.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_refresh_metrics_recorder.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_report_mapper.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_result_builder.dart';
import 'package:colmeia/features/sales/application/sales_live_map_catalog_scope.dart';
import 'package:colmeia/features/sales/application/sales_live_map_refresh_metrics.dart';
import 'package:colmeia/features/sales/application/sales_live_map_reload_reason.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_filter.dart';
import 'package:result_dart/result_dart.dart';

/// Progressive load path that fetches catalog and sales reports in parallel
/// through their dedicated across-agents use cases.
class SalesLiveMapParallelLoadOrchestrator {
  SalesLiveMapParallelLoadOrchestrator({
    required LoadResumoTotalVendasMunicipioFilialPeriodoAcrossAgentsUseCase
    loadSalesAcrossAgents,
    required SalesLiveMapCatalogLookup catalogLookup,
    required SalesLiveMapReportMapper reportMapper,
    required SalesLiveMapDiagnosticsLogger diagnosticsLogger,
    required SalesLiveMapRefreshMetricsRecorder metricsRecorder,
    required SalesLiveMapProgressiveEmitPolicy emitPolicy,
    required int bridgeTimeoutMs,
  }) : _loadSalesAcrossAgents = loadSalesAcrossAgents,
       _catalogLookup = catalogLookup,
       _reportMapper = reportMapper,
       _diagnosticsLogger = diagnosticsLogger,
       _metricsRecorder = metricsRecorder,
       _emitPolicy = emitPolicy,
       _bridgeTimeoutMs = bridgeTimeoutMs;

  final LoadResumoTotalVendasMunicipioFilialPeriodoAcrossAgentsUseCase
  _loadSalesAcrossAgents;
  final SalesLiveMapCatalogLookup _catalogLookup;
  final SalesLiveMapReportMapper _reportMapper;
  final SalesLiveMapDiagnosticsLogger _diagnosticsLogger;
  final SalesLiveMapRefreshMetricsRecorder _metricsRecorder;
  final SalesLiveMapProgressiveEmitPolicy _emitPolicy;
  final int _bridgeTimeoutMs;

  Stream<SalesLiveMapLoadResult> loadProgressive({
    required String userId,
    required SalesLiveMapFilter filter,
    required SalesLiveMapReloadReason reason,
    required DateTime now,
    required SalesLiveMapCatalogScope catalogScope,
    required ResumoTotalVendasMunicipioFilialPeriodoFilter queryFilter,
    required Set<String>? selectedAgentIds,
    required AgentQueryTargetResolution resolution,
    required SalesLiveMapLoadCancelToken? cancelToken,
    required int mergeWaveSize,
    required Stopwatch? resolveSw,
    required Stopwatch? totalStopwatch,
    required SalesLiveMapCatalogLookupResult? cachedCatalog,
    required CadastroFilialAcrossAgentsPageResult? cachedCatalogPage,
    required bool loadedViaMergedSqlBatch,
  }) async* {
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
    {
      salesFuture = _trackStopwatch(
        _loadSalesAcrossAgents(
          userId: userId,
          filter: queryFilter,
          selectedAgentIds: selectedAgentIds,
          bridgeTimeoutMs: _bridgeTimeoutMs,
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
                bridgeTimeoutMs: _bridgeTimeoutMs,
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
      yield _emitPolicy.cancelledResult(refreshedAt: now);
      return;
    }

    if (catalogPage != null && cachedCatalogPage == null) {
      await for (final partialMapped in _reportMapper.emitMappedReports(
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
      yield _emitPolicy.cancelledResult(refreshedAt: now);
      return;
    }

    if (salesReport != null) {
      _diagnosticsLogger.logParticipantMetrics(salesReport);
    }
    if (cancelToken?.isCancelled ?? false) {
      yield _emitPolicy.cancelledResult(refreshedAt: now);
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

    SalesLiveMapMappedResult? mapped;
    await for (final emission in _reportMapper.emitMappedReports(
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
    mapped ??= SalesLiveMapMappedResult(
      result: _emitPolicy.cancelledResult(refreshedAt: now),
    );
    if (mapped.result.cancelled) {
      return;
    }
    final metricEvent = _emitPolicy.buildCompletionMetricEvent(
      now: now,
      reason: reason,
      catalogScope: catalogScope,
      catalogSource: cachedCatalog?.source ?? SalesLiveMapCatalogSource.remote,
      selectedAgentCount: selectedAgentIds?.length ?? 0,
      selectedBranchCount: queryFilter.selectedBranches.length,
      resolveDurationMs: resolveSw?.elapsedMilliseconds ?? 0,
      catalogDurationMs: catalogStopwatch?.elapsedMilliseconds ?? 0,
      salesDurationMs: salesStopwatch?.elapsedMilliseconds ?? 0,
      mapped: mapped,
      paginationStalledAgentIds:
          catalogPage?.paginationStalledAgentIds ?? const <String>{},
      mergeWaveSize: mergeWaveSize,
      catalogSalesBatchMerged: loadedViaMergedSqlBatch,
    );
    _metricsRecorder.record(metricEvent);
    _emitPolicy.logLoadCompleted(
      totalStopwatch: totalStopwatch,
      metricEvent: metricEvent,
      mapped: mapped,
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
}

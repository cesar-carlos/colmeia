import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target_resolution.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_vendas_municipio_filial_periodo_filter.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_catalog_lookup.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_catalog_persister.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_diagnostics_logger.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_load_cancel_token.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_load_result.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_mapped_result.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_progressive_emit_policy.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_refresh_metrics_recorder.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_report_mapper.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_result_builder.dart';
import 'package:colmeia/features/sales/application/ports/sales_live_map_batch_loader.dart';
import 'package:colmeia/features/sales/application/sales_live_map_catalog_scope.dart';
import 'package:colmeia/features/sales/application/sales_live_map_refresh_metrics.dart';
import 'package:colmeia/features/sales/application/sales_live_map_reload_reason.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_filter.dart';

/// Progressive load path that merges catalog and sales SQL per target via
/// [SalesLiveMapBatchLoader].
class SalesLiveMapBatchLoadOrchestrator {
  SalesLiveMapBatchLoadOrchestrator({
    required this._batchLoader,
    required this._reportMapper,
    required this._catalogPersister,
    required this._diagnosticsLogger,
    required this._metricsRecorder,
    required this._emitPolicy,
    required this._bridgeTimeoutMs,
  });

  final SalesLiveMapBatchLoader _batchLoader;
  final SalesLiveMapReportMapper _reportMapper;
  final SalesLiveMapCatalogPersister _catalogPersister;
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
    required bool loadedViaMergedSqlBatch,
  }) async* {
    yield SalesLiveMapResultBuilder.pendingBase(refreshedAt: now);

    final salesStopwatch = _diagnosticsLogger.startTraceStopwatch();
    final catalogStopwatch = _diagnosticsLogger.startTraceStopwatch();
    SalesLiveMapBatchLoadResult? finalBatch;
    SalesLiveMapMappedResult? mapped;

    await for (final batchResult in _batchLoader.loadProgressively(
      userId: userId,
      catalogFilter: catalogScope.toCatalogFilter(),
      salesFilter: queryFilter,
      preResolvedResolution: resolution,
      cancelScope: cancelToken?.sqlCancelScope,
      bridgeTimeoutMs: _bridgeTimeoutMs,
      targetWaveConcurrency: mergeWaveSize,
    )) {
      final batch = batchResult.getOrNull();
      if (batch == null) {
        if (finalBatch == null) {
          yield SalesLiveMapResultBuilder.failed(
            batchResult.exceptionOrNull()!,
            refreshedAt: now,
          );
        }
        return;
      }

      if (cancelToken?.isCancelled ?? false) {
        yield _emitPolicy.cancelledResult(refreshedAt: now);
        return;
      }

      final salesReport = batch.salesReport.participants.isNotEmpty
          ? batch.salesReport
          : null;
      await for (final emission in _reportMapper.emitMappedReports(
        salesReport,
        catalogResult: batch.catalogPage,
        filter: filter,
        refreshedAt: now,
        cancelToken: cancelToken,
        salesDataPending: !batch.salesLoadingComplete,
        allowPartialGeoReuse: batch.isFinal,
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

      if (batch.isFinal) {
        finalBatch = batch;
        _catalogPersister.persist(
          userId: userId,
          scope: catalogScope,
          now: now,
          page: batch.catalogPage,
        );
      }
    }

    final batch = finalBatch;
    if (batch == null) {
      yield SalesLiveMapResultBuilder.failed(
        const UnknownFailure(
          message: 'Sales live map merged batch load produced no data',
          userMessage: 'Unable to load the sales live map.',
        ),
        refreshedAt: now,
      );
      return;
    }

    final catalogPage = batch.catalogPage;
    final salesReport = batch.salesReport;
    if (catalogStopwatch?.isRunning ?? false) {
      catalogStopwatch!.stop();
    }
    if (salesStopwatch?.isRunning ?? false) {
      salesStopwatch!.stop();
    }
    _diagnosticsLogger
      ..trace(
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
          'salesReportElapsedMs': salesReport.totalElapsedMs,
          'catalogReportElapsedMs': catalogPage.report.totalElapsedMs,
          'salesLoadSuccess': true,
          'catalogLoadSuccess': true,
        },
      )
      ..logParticipantMetrics(salesReport);

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
      paginationStalledAgentIds: catalogPage.paginationStalledAgentIds,
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
}

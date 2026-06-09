import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_diagnostics_logger.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_load_result.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_mapped_result.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_result_builder.dart';
import 'package:colmeia/features/sales/application/ports/sales_live_map_batch_loader.dart';
import 'package:colmeia/features/sales/application/sales_live_map_catalog_scope.dart';
import 'package:colmeia/features/sales/application/sales_live_map_refresh_metrics.dart';
import 'package:colmeia/features/sales/application/sales_live_map_reload_reason.dart';

/// Progressive emission rules shared by the parallel and merged-batch load
/// paths: cancellation handling, completion metrics and load-mode flags.
class SalesLiveMapProgressiveEmitPolicy {
  const SalesLiveMapProgressiveEmitPolicy({
    required SalesLiveMapDiagnosticsLogger diagnosticsLogger,
  }) : _diagnosticsLogger = diagnosticsLogger;

  final SalesLiveMapDiagnosticsLogger _diagnosticsLogger;

  bool useMergedSqlBatchPerTarget({
    required bool envFlag,
    required SalesLiveMapBatchLoader? batchLoader,
    required bool catalogCacheMiss,
  }) {
    return envFlag && batchLoader != null && catalogCacheMiss;
  }

  SalesLiveMapLoadResult cancelledResult({required DateTime refreshedAt}) {
    _diagnosticsLogger.trace(
      'Sales live map load cancelled before local processing completed',
      <String, Object?>{'refreshedAt': refreshedAt.toIso8601String()},
    );
    return SalesLiveMapResultBuilder.cancelled(refreshedAt: refreshedAt);
  }

  SalesLiveMapRefreshMetricEvent buildCompletionMetricEvent({
    required DateTime now,
    required SalesLiveMapReloadReason reason,
    required SalesLiveMapCatalogScope catalogScope,
    required SalesLiveMapCatalogSource catalogSource,
    required int selectedAgentCount,
    required int selectedBranchCount,
    required int resolveDurationMs,
    required int catalogDurationMs,
    required int salesDurationMs,
    required SalesLiveMapMappedResult mapped,
    required Set<String> paginationStalledAgentIds,
    required int mergeWaveSize,
    required bool catalogSalesBatchMerged,
  }) {
    return SalesLiveMapRefreshMetricEvent(
      recordedAt: now,
      reloadReason: reason,
      catalogScopeKind: catalogScope.kind,
      catalogSource: catalogSource,
      selectedAgentCount: selectedAgentCount,
      selectedBranchCount: selectedBranchCount,
      resolveDurationMs: resolveDurationMs,
      catalogDurationMs: catalogDurationMs,
      salesDurationMs: salesDurationMs,
      mapDurationMs: mapped.mapDurationMs,
      geoDurationMs: mapped.geoDurationMs,
      plannedAgentCount: mapped.result.plannedAgentCount,
      queriedAgentCount: mapped.result.queriedAgentCount,
      rowCapReachedAgentCount: mapped.result.rowCapReachedAgentCount,
      paginationStalledAgentIds: paginationStalledAgentIds,
      partialFailure: mapped.result.hasPartialIssue,
      loadFailed: mapped.result.loadFailed,
      mergeWaveSize: mergeWaveSize,
      catalogSalesBatchMerged: catalogSalesBatchMerged,
      partialIssueBreakdown: mapped.result.hasPartialIssue
          ? mapped.result.partialIssueActiveKeys
          : null,
    );
  }

  void logLoadCompleted({
    required Stopwatch? totalStopwatch,
    required SalesLiveMapRefreshMetricEvent metricEvent,
    required SalesLiveMapMappedResult mapped,
  }) {
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
}

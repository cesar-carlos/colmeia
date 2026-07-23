import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_diagnostics_logger.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_load_result.dart'
    show SalesLiveMapLoadResult;
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_mapped_result.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_progressive_emit_policy.dart';
import 'package:colmeia/features/sales/application/ports/sales_live_map_batch_loader.dart';
import 'package:colmeia/features/sales/application/sales_live_map_catalog_scope.dart';
import 'package:colmeia/features/sales/application/sales_live_map_refresh_metrics.dart';
import 'package:colmeia/features/sales/application/sales_live_map_reload_reason.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_branch_option.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_point.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSalesLiveMapBatchLoader extends Mock
    implements SalesLiveMapBatchLoader {}

void main() {
  late _SpyDiagnosticsLogger diagnostics;
  late SalesLiveMapProgressiveEmitPolicy policy;

  setUp(() {
    diagnostics = _SpyDiagnosticsLogger();
    policy = SalesLiveMapProgressiveEmitPolicy(diagnosticsLogger: diagnostics);
  });

  group('useMergedSqlBatchPerTarget', () {
    test('returns true when env and batch loader are set (ignores catalog)', () {
      final batchLoader = _MockSalesLiveMapBatchLoader();

      expect(
        policy.useMergedSqlBatchPerTarget(
          envFlag: true,
          batchLoader: batchLoader,
        ),
        isTrue,
      );
      expect(
        policy.useMergedSqlBatchPerTarget(
          envFlag: false,
          batchLoader: batchLoader,
        ),
        isFalse,
      );
      expect(
        policy.useMergedSqlBatchPerTarget(
          envFlag: true,
          batchLoader: null,
        ),
        isFalse,
      );
    });
  });

  test('cancelledResult traces and returns cancelled load result', () {
    final refreshedAt = DateTime(2026, 5, 27, 18);

    final result = policy.cancelledResult(refreshedAt: refreshedAt);

    expect(result.cancelled, isTrue);
    expect(result.refreshedAt, refreshedAt);
    expect(diagnostics.traces, hasLength(1));
    expect(
      diagnostics.traces.single.message,
      'Sales live map load cancelled before local processing completed',
    );
  });

  test('buildCompletionMetricEvent copies mapped timing and partial flags', () {
    final now = DateTime(2026, 5, 27, 18);
    final mapped = SalesLiveMapMappedResult(
      result: SalesLiveMapLoadResult(
        points: const <SalesLiveMapPoint>[],
        branchOptions: const <SalesLiveMapBranchOption>[],
        totalRevenue: 0,
        totalSalesCount: 0,
        totalBranchCount: 2,
        mappedBranchCount: 1,
        mappedMunicipalityCount: 1,
        queriedAgentCount: 2,
        plannedAgentCount: 3,
        failedAgentCount: 1,
        missingClientTokenAgentCount: 0,
        skippedOfflineAgentCount: 0,
        rowCapReachedAgentCount: 1,
        refreshedAt: now,
      ),
      mapDurationMs: 11,
      geoDurationMs: 22,
    );

    final event = policy.buildCompletionMetricEvent(
      now: now,
      reason: SalesLiveMapReloadReason.autoRefresh,
      catalogScope: SalesLiveMapCatalogScope.fullAgent(),
      catalogSource: SalesLiveMapCatalogSource.remote,
      selectedAgentCount: 1,
      selectedBranchCount: 0,
      resolveDurationMs: 5,
      catalogDurationMs: 6,
      salesDurationMs: 7,
      mapped: mapped,
      paginationStalledAgentIds: const <String>{'agent-1'},
      mergeWaveSize: 4,
      catalogSalesBatchMerged: true,
    );

    expect(event.mapDurationMs, 11);
    expect(event.geoDurationMs, 22);
    expect(event.partialFailure, isTrue);
    expect(event.plannedAgentCount, 3);
    expect(event.mergeWaveSize, 4);
    expect(event.catalogSalesBatchMerged, isTrue);
    expect(event.paginationStalledAgentIds, const <String>{'agent-1'});
  });

  test('logLoadCompleted emits completion trace with metric context', () {
    final now = DateTime(2026, 5, 27, 18);
    final mapped = SalesLiveMapMappedResult(
      result: SalesLiveMapLoadResult(
        points: const <SalesLiveMapPoint>[],
        branchOptions: const <SalesLiveMapBranchOption>[],
        totalRevenue: 0,
        totalSalesCount: 0,
        totalBranchCount: 1,
        mappedBranchCount: 0,
        mappedMunicipalityCount: 0,
        queriedAgentCount: 1,
        plannedAgentCount: 1,
        failedAgentCount: 0,
        missingClientTokenAgentCount: 0,
        skippedOfflineAgentCount: 0,
        rowCapReachedAgentCount: 0,
        refreshedAt: now,
      ),
    );
    final metricEvent = policy.buildCompletionMetricEvent(
      now: now,
      reason: SalesLiveMapReloadReason.manual,
      catalogScope: SalesLiveMapCatalogScope.fullAgent(),
      catalogSource: SalesLiveMapCatalogSource.memory,
      selectedAgentCount: 0,
      selectedBranchCount: 0,
      resolveDurationMs: 0,
      catalogDurationMs: 0,
      salesDurationMs: 0,
      mapped: mapped,
      paginationStalledAgentIds: const <String>{},
      mergeWaveSize: 1,
      catalogSalesBatchMerged: false,
    );

    policy.logLoadCompleted(
      totalStopwatch: null,
      metricEvent: metricEvent,
      mapped: mapped,
    );

    expect(
      diagnostics.traces.single.message,
      'Sales live map load completed',
    );
    expect(
      diagnostics.traces.single.context,
      containsPair('reloadReason', SalesLiveMapReloadReason.manual.name),
    );
  });
}

class _SpyDiagnosticsLogger extends SalesLiveMapDiagnosticsLogger {
  final List<_TraceCall> traces = <_TraceCall>[];

  @override
  void trace(String message, Map<String, Object?> context) {
    traces.add(_TraceCall(message: message, context: Map.of(context)));
  }
}

class _TraceCall {
  const _TraceCall({required this.message, required this.context});

  final String message;
  final Map<String, Object?> context;
}

import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_diagnostics_logger.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_refresh_metrics_recorder.dart';
import 'package:colmeia/features/sales/application/sales_live_map_catalog_scope.dart';
import 'package:colmeia/features/sales/application/sales_live_map_refresh_metrics.dart';
import 'package:colmeia/features/sales/application/sales_live_map_reload_reason.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late SalesLiveMapRefreshMetrics metrics;
  late _SpyDiagnosticsLogger diagnostics;
  late SalesLiveMapRefreshMetricsRecorder recorder;

  setUp(() {
    metrics = SalesLiveMapRefreshMetrics();
    diagnostics = _SpyDiagnosticsLogger();
    recorder = SalesLiveMapRefreshMetricsRecorder(
      metrics: metrics,
      diagnosticsLogger: diagnostics,
    );
  });

  test('record pushes the event into the metrics buffer', () {
    final event = _buildEvent();
    recorder.record(event);

    expect(metrics.latest, same(event));
    expect(metrics.getRecentEvents(), hasLength(1));
  });

  test('record emits an info trace on every call', () {
    final event = _buildEvent();
    recorder.record(event);

    expect(diagnostics.traces, hasLength(1));
    expect(
      diagnostics.traces.single.message,
      'Sales live map refresh completed',
    );
    expect(
      diagnostics.traces.single.context,
      containsPair('reloadReason', SalesLiveMapReloadReason.manual.name),
    );
  });

  test(
    'multiple records keep the most recent event at the front of '
    'getRecentEvents',
    () {
      final first = _buildEvent(recordedAt: DateTime(2026, 5, 27, 17));
      final second = _buildEvent(recordedAt: DateTime(2026, 5, 27, 18));

      recorder
        ..record(first)
        ..record(second);

      final recent = metrics.getRecentEvents();
      expect(recent.first, same(second));
      expect(recent.last, same(first));
    },
  );
}

SalesLiveMapRefreshMetricEvent _buildEvent({
  DateTime? recordedAt,
  bool partialFailure = false,
  bool loadFailed = false,
  Set<String> paginationStalledAgentIds = const <String>{},
  int rowCapReachedAgentCount = 0,
}) {
  return SalesLiveMapRefreshMetricEvent(
    recordedAt: recordedAt ?? DateTime(2026, 5, 27),
    reloadReason: SalesLiveMapReloadReason.manual,
    catalogScopeKind: SalesLiveMapCatalogScopeKind.fullAgent,
    catalogSource: SalesLiveMapCatalogSource.remote,
    selectedAgentCount: 1,
    selectedBranchCount: 0,
    resolveDurationMs: 10,
    catalogDurationMs: 20,
    salesDurationMs: 30,
    mapDurationMs: 5,
    geoDurationMs: 5,
    plannedAgentCount: 1,
    queriedAgentCount: 1,
    rowCapReachedAgentCount: rowCapReachedAgentCount,
    paginationStalledAgentIds: paginationStalledAgentIds,
    partialFailure: partialFailure,
    loadFailed: loadFailed,
  );
}

class _SpyDiagnosticsLogger extends SalesLiveMapDiagnosticsLogger {
  _SpyDiagnosticsLogger();

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

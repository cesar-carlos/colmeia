import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_diagnostics_logger.dart';
import 'package:colmeia/features/sales/application/sales_live_map_refresh_metrics.dart';

const String _kOperation = 'LoadSalesLiveMapUseCase';

/// Persists a [SalesLiveMapRefreshMetricEvent] in the in-memory metrics
/// buffer and routes it to the right log sink:
///
/// - Always pushes the event to [SalesLiveMapRefreshMetrics];
/// - Emits an info trace via [SalesLiveMapDiagnosticsLogger] (gated by
///   debug/profile builds so release telemetry stays quiet);
/// - Escalates to `AppLogger.warning` whenever the event flags any
///   anomaly (partial failure, hard load failure, paginação travada or
///   row-cap reached).
///
/// Extracted from `LoadSalesLiveMapUseCase` so the recording rules can
/// be unit-tested without spinning up the full use case.
class SalesLiveMapRefreshMetricsRecorder {
  const SalesLiveMapRefreshMetricsRecorder({
    required SalesLiveMapRefreshMetrics metrics,
    required SalesLiveMapDiagnosticsLogger diagnosticsLogger,
  }) : _metrics = metrics,
       _diagnosticsLogger = diagnosticsLogger;

  final SalesLiveMapRefreshMetrics _metrics;
  final SalesLiveMapDiagnosticsLogger _diagnosticsLogger;

  void record(SalesLiveMapRefreshMetricEvent event) {
    _metrics.record(event);
    _diagnosticsLogger.trace(
      'Sales live map refresh completed',
      event.toLogContext(),
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
        'operation': _kOperation,
        ...event.toLogContext(),
      },
    );
  }
}

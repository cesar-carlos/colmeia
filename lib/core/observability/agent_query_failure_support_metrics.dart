import 'package:colmeia/core/observability/socket/socket_channel_metrics.dart';
import 'package:colmeia/features/agent_queries/data/repositories/coalescing_agent_queries_repository.dart';

/// Session transport metrics for support clipboard bundles.
abstract final class AgentQueryFailureSupportMetrics {
  /// Optional DI hook; set from socket/agent-queries wiring at bootstrap.
  static Map<String, String> Function()? resolver;

  static Map<String, String> collectOptional() => resolver?.call() ?? const {};

  static Map<String, String> collect({
    SocketChannelMetrics? channelMetrics,
    CoalescingAgentQueriesRepository? coalescingRepository,
  }) {
    final lines = <String, String>{};
    final metrics = channelMetrics;
    if (metrics != null) {
      final snap = metrics.snapshot();
      lines['batchEmissionsTotal'] = '${snap.batchEmissionsTotal}';
      lines['sessionPeakMaxAgentInflight'] =
          '${snap.lastGateSessionPeakSample}';
    }
    final coalescing = coalescingRepository;
    if (coalescing != null) {
      lines['coalescedCount'] = '${coalescing.coalescedCount}';
    }
    return lines;
  }
}

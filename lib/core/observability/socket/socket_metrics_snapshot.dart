/// Read-only snapshot of `SocketChannelMetrics`. Useful for diagnostics,
/// snapshot tests and manual inspection in debug builds.
class SocketMetricsSnapshot {
  const SocketMetricsSnapshot({
    required this.handshakeMs,
    required this.dispatchMsByKey,
    required this.outcomesTotal,
    required this.reconnectsTotalByReason,
    required this.coalescedTotal,
    required this.batchEmissionsTotal,
    required this.batchSizeDistribution,
    required this.batchPartialFailureTotal,
    required this.batchBypassTotalByReason,
  });

  /// Histogram across **all** completed handshakes since process start
  /// (or last `reset()`).
  final HistogramSnapshot handshakeMs;

  /// Per-key histograms of `dispatch_ms`. The key format is
  /// `"<agentId>|<method>"` (or `"<agentId>|<unknown>"` when the method
  /// could not be extracted).
  final Map<String, HistogramSnapshot> dispatchMsByKey;

  /// Counter map keyed by `"<kind>|<reasonCode>"` (e.g.
  /// `"AgentCommandSuccess|-"`, `"AgentCommandFailedAuth|AGENT_ACCESS_DENIED"`).
  final Map<String, int> outcomesTotal;

  /// Counter map keyed by reconnect reason (e.g. `app_paused`,
  /// `unauthorized`, `transient_error`).
  final Map<String, int> reconnectsTotalByReason;

  /// Number of `agents:command` calls that were deduplicated against an
  /// in-flight request (PR-G coalescing). Higher is better.
  final int coalescedTotal;

  /// PR-I: total batches emitted (each one wraps 1..N RPCs).
  final int batchEmissionsTotal;

  /// PR-I: histogram of items per batch (count + percentiles).
  final HistogramSnapshot batchSizeDistribution;

  /// PR-I: number of batches where at least one item came back with an
  /// RPC-level error.
  final int batchPartialFailureTotal;

  /// PR-I: counts of submissions that bypassed the batch coordinator
  /// (`paginated`, `multi_result`, `executeBatch`, `cancel`,
  /// `caller_opt_out`, `disabled`).
  final Map<String, int> batchBypassTotalByReason;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'handshakeMs': handshakeMs.toJson(),
      'dispatchMsByKey': <String, Object?>{
        for (final entry in dispatchMsByKey.entries)
          entry.key: entry.value.toJson(),
      },
      'outcomesTotal': outcomesTotal,
      'reconnectsTotalByReason': reconnectsTotalByReason,
      'coalescedTotal': coalescedTotal,
      'batchEmissionsTotal': batchEmissionsTotal,
      'batchSizeDistribution': batchSizeDistribution.toJson(),
      'batchPartialFailureTotal': batchPartialFailureTotal,
      'batchBypassTotalByReason': batchBypassTotalByReason,
    };
  }
}

/// Compact percentile view computed from an in-memory reservoir. The
/// implementation is sort-then-pick, so percentiles are exact for the
/// retained samples but bounded in cost by the reservoir size.
class HistogramSnapshot {
  const HistogramSnapshot({
    required this.count,
    required this.mean,
    required this.p50,
    required this.p95,
    required this.p99,
    required this.max,
  });

  static const HistogramSnapshot empty = HistogramSnapshot(
    count: 0,
    mean: 0,
    p50: 0,
    p95: 0,
    p99: 0,
    max: 0,
  );

  /// Total observations recorded (may exceed the reservoir size; the
  /// percentiles are computed only over the retained samples).
  final int count;

  /// Arithmetic mean over the retained samples (ms).
  final double mean;
  final double p50;
  final double p95;
  final double p99;
  final double max;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'count': count,
      'mean': mean,
      'p50': p50,
      'p95': p95,
      'p99': p99,
      'max': max,
    };
  }
}

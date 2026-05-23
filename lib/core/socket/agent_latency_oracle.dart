import 'dart:math' as math;

import 'package:colmeia/core/socket/agent_latency_budget.dart';

/// Estimates a per `(agentId, method)` recommended timeout from observed
/// dispatch latencies, so the dispatcher can pick a tighter SLA when an
/// agent is consistently fast and a looser SLA when it is consistently
/// slow (review §5.3, P2).
///
/// Implementation uses **EWMA** (exponentially-weighted moving averages)
/// over the per-key mean and variance — constant memory, O(1) per
/// observation, no sample buffer.
///
/// `suggestTimeout` returns `mean + safetyFactor * stddev`, clamped to
/// `[floor, ceiling]`. When fewer than `warmUpSampleCount` samples are
/// available the oracle returns the caller-provided `fallback` so cold
/// starts do not produce pathological estimates.
///
/// **Boundary vs repository decorators:** this oracle feeds **transport**
/// pending timers (relay / socket dispatchers) when the outbound RPC does
/// not carry an explicit `Duration` timeout. The adaptive-timeout repository
/// decorator applies only to Agent SQL requests that already set
/// `AgentSqlExecuteRequest.bridgeTimeoutMs` — it does not replace hub-side SQL
/// execution limits. Prefer oracle-backed transport defaults for relay-heavy
/// workloads; keep explicit `bridgeTimeoutMs` for long-running batches
/// (overview) where the decorator may still refine the declared ceiling.
class AgentLatencyOracle {
  AgentLatencyOracle({
    this.alpha = 0.2,
    this.warmUpSampleCount = 5,
    this.safetyFactor = 3.0,
  }) : assert(
         alpha > 0 && alpha <= 1,
         'alpha must be in (0, 1]',
       ),
       assert(
         warmUpSampleCount >= 1,
         'warmUpSampleCount must be >= 1',
       ),
       assert(
         safetyFactor >= 0,
         'safetyFactor must be >= 0',
       );

  /// Smoothing factor for both mean and variance EWMA. Higher values
  /// react faster but are noisier.
  final double alpha;

  /// Minimum number of recorded samples before [suggestTimeout] returns
  /// a derived value instead of the caller-provided `fallback`.
  final int warmUpSampleCount;

  /// Multiplier applied to the EWMA stddev when deriving the suggested
  /// timeout (`mean + safetyFactor * stddev`). 3.0 ≈ p99.7 for normal
  /// distributions; we use it as a conservative envelope.
  final double safetyFactor;

  final Map<String, _EwmaStats> _stats = <String, _EwmaStats>{};

  void record({
    required String agentId,
    required String method,
    required Duration elapsed,
  }) {
    final ms = elapsed.inMicroseconds / 1000.0;
    if (ms.isNaN || ms.isInfinite || ms < 0) {
      return;
    }
    final key = _key(agentId: agentId, method: method);
    _stats.putIfAbsent(key, _EwmaStats.new).observe(value: ms, alpha: alpha);
  }

  /// Returns a recommended dispatch timeout for the given pivot. Falls
  /// back to [fallback] before warm-up; otherwise clamps the EWMA-based
  /// estimate inside `[floor, ceiling]`.
  Duration suggestTimeout({
    required String agentId,
    required String method,
    Duration fallback = const Duration(seconds: 15),
    Duration floor = const Duration(seconds: 3),
    Duration ceiling = const Duration(seconds: 60),
  }) {
    assert(floor <= ceiling, 'floor must be <= ceiling');
    final key = _key(agentId: agentId, method: method);
    final stats = _stats[key];
    if (stats == null) {
      return AgentLatencyBudget.clampDuration(
        fallback,
        floor,
        ceiling,
      );
    }
    return AgentLatencyBudget.suggest(
      meanMs: stats.mean,
      stdDevMs: AgentLatencyBudget.stdDevFromEwmaVariance(stats.variance),
      sampleCount: stats.count,
      warmUpSampleCount: warmUpSampleCount,
      safetyFactor: safetyFactor,
      fallback: fallback,
      floor: floor,
      ceiling: ceiling,
    );
  }

  /// Number of samples recorded for the given pivot. Mostly useful for
  /// metrics and tests.
  int sampleCountFor({required String agentId, required String method}) {
    return _stats[_key(agentId: agentId, method: method)]?.count ?? 0;
  }

  /// Snapshot of the current mean for the pivot, or `null` if no sample
  /// has been recorded.
  double? meanMsFor({required String agentId, required String method}) {
    return _stats[_key(agentId: agentId, method: method)]?.mean;
  }

  String _key({required String agentId, required String method}) {
    return '$agentId|$method';
  }
}

class _EwmaStats {
  double mean = 0;
  double variance = 0;
  int count = 0;

  double get stddev => math.sqrt(variance);

  void observe({required double value, required double alpha}) {
    if (count == 0) {
      mean = value;
      variance = 0;
    } else {
      final previousMean = mean;
      mean = alpha * value + (1 - alpha) * previousMean;
      // EWMA of squared deviations approximates variance under stationary
      // assumptions; good enough for choosing a safety envelope.
      final delta = value - previousMean;
      variance = alpha * delta * delta + (1 - alpha) * variance;
    }
    count += 1;
  }
}

import 'dart:math' as math;

/// Shared clamping for latency-derived timeout budgets.
///
/// Keeps [AgentLatencyOracle] (transport EWMA) and repository decorators
/// (adaptive `bridgeTimeoutMs`) aligned on floor/ceiling semantics without
/// merging their sample stores.
abstract final class AgentLatencyBudget {
  /// Returns [fallback] until [sampleCount] reaches [warmUpSampleCount],
  /// then `mean + safetyFactor * stdDev` clamped to `[floor, ceiling]`.
  static Duration suggest({
    required double meanMs,
    required double stdDevMs,
    required int sampleCount,
    required int warmUpSampleCount,
    required double safetyFactor,
    Duration fallback = const Duration(seconds: 15),
    Duration floor = const Duration(seconds: 3),
    Duration ceiling = const Duration(seconds: 60),
  }) {
    if (sampleCount < warmUpSampleCount) {
      return fallback;
    }
    if (meanMs.isNaN || meanMs.isInfinite || meanMs < 0) {
      return fallback;
    }
    final spread = stdDevMs.isNaN || stdDevMs.isInfinite || stdDevMs < 0
        ? 0.0
        : stdDevMs;
    final rawMs = meanMs + safetyFactor * spread;
    final clampedMs = rawMs
        .round()
        .clamp(floor.inMilliseconds, ceiling.inMilliseconds);
    return Duration(milliseconds: clampedMs);
  }

  /// Simple moving-average budget for repository decorators (no variance).
  static Duration? suggestFromAverage({
    required List<Duration> history,
    required double safetyMultiplier,
    required Duration minTimeout,
    required Duration maxTimeout,
  }) {
    if (history.isEmpty) {
      return null;
    }
    final sum = history.fold<int>(
      0,
      (total, duration) => total + duration.inMilliseconds,
    );
    final avgMs = sum / history.length;
    final adaptiveMs = (avgMs * safetyMultiplier).round();
    return clampDuration(
      Duration(milliseconds: adaptiveMs),
      minTimeout,
      maxTimeout,
    );
  }

  static Duration clampDuration(
    Duration value,
    Duration floor,
    Duration ceiling,
  ) {
    final ms = value.inMilliseconds.clamp(
      floor.inMilliseconds,
      ceiling.inMilliseconds,
    );
    return Duration(milliseconds: ms);
  }

  static double stdDevFromEwmaVariance(double variance) {
    if (variance.isNaN || variance.isInfinite || variance <= 0) {
      return 0;
    }
    return math.sqrt(variance);
  }
}

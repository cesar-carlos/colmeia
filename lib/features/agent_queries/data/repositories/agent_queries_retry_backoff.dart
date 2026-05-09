import 'dart:math' as math;

/// Retry backoff math for Agent SQL calls.
///
/// Full jitter samples a delay between zero and the exponential ceiling. This
/// spreads concurrent client retries after shared bridge/socket failures.
abstract final class AgentQueriesRetryBackoff {
  /// Returns the exponential ceiling for [failedAttempt].
  ///
  /// Attempt 1 uses [initialDelay], attempt 2 doubles it, and so on.
  static Duration ceiling({
    required Duration initialDelay,
    required int failedAttempt,
  }) {
    if (initialDelay <= Duration.zero || failedAttempt <= 0) {
      return Duration.zero;
    }

    final exponent = math.min(failedAttempt - 1, 30);
    return initialDelay * (1 << exponent);
  }

  /// Samples a full-jitter delay in `[0, ceiling]`.
  static Duration fullJitter({
    required Duration ceiling,
    required math.Random random,
  }) {
    final maxMs = ceiling.inMilliseconds;
    if (maxMs <= 0) {
      return Duration.zero;
    }

    return Duration(milliseconds: random.nextInt(maxMs + 1));
  }
}

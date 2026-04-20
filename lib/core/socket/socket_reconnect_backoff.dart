import 'dart:math' as math;

/// Pure helpers for the consumer socket reconnect policy. Extracted from
/// `ConsumerSocketConnection` so the math is unit-testable in isolation —
/// see `test/core/socket/socket_reconnect_backoff_test.dart`.
///
/// Performance review §5.4 (P0): full jitter prevents thundering-herd when
/// many clients reconnect simultaneously after a hub restart.
abstract final class SocketReconnectBackoff {
  /// Doubles [current] up to [maxDelay]. Pure; no side effects.
  static Duration nextCeiling({
    required Duration current,
    required Duration maxDelay,
  }) {
    final doubled = current * 2;
    return doubled > maxDelay ? maxDelay : doubled;
  }

  /// Full jitter: samples uniformly in `[0, ceiling]`. The caller injects
  /// [random] so tests can use `math.Random(seed)` for deterministic runs.
  static Duration jittered({
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

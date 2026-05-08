import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/retry_after_gate.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RetryAfterGate', () {
    test('starts open and reports null remaining', () {
      final gate = RetryAfterGate();
      check(gate.isOpen).isTrue();
      check(gate.remaining).isNull();
      gate.dispose();
    });

    test('arm() closes the gate and notifies listeners', () {
      var ticks = 0;
      final gate = RetryAfterGate()
        ..addListener(() => ticks++)
        ..arm(const Duration(seconds: 5));

      check(gate.isOpen).isFalse();
      check(gate.remaining).isNotNull();
      check(ticks).isGreaterOrEqual(1);
      gate.dispose();
    });

    test('release() reopens the gate immediately', () {
      final gate = RetryAfterGate()..arm(const Duration(seconds: 30));
      check(gate.isOpen).isFalse();
      gate
        ..release()
        ..dispose();
      check(gate.isOpen).isTrue();
      check(gate.remaining).isNull();
    });

    test('non-positive arm() acts as release()', () {
      final gate = RetryAfterGate()
        ..arm(const Duration(seconds: 5))
        ..arm(Duration.zero);
      check(gate.isOpen).isTrue();
      gate.dispose();
    });

    test(
      'subsequent arm() preserves the larger window (no shrinking)',
      () {
        FakeAsync().run((async) {
          final gate =
              RetryAfterGate(
                  tickInterval: const Duration(milliseconds: 200),
                  clock: () => DateTime.utc(2026, 4, 18, 12),
                )
                ..arm(const Duration(seconds: 30))
                // Same clock, so the second arm() with a smaller window should
                // not move the deadline backwards.
                ..arm(const Duration(seconds: 5));
          check(gate.remaining!.inSeconds).isGreaterOrEqual(29);
          gate.dispose();
          async.flushTimers();
        });
      },
    );

    test('countdown reaches null after the cooldown elapses', () {
      FakeAsync().run((async) {
        var fakeNow = DateTime.utc(2026, 4, 18, 12);
        final gate = RetryAfterGate(
          tickInterval: const Duration(milliseconds: 100),
          clock: () => fakeNow,
        )..arm(const Duration(seconds: 2));
        check(gate.isOpen).isFalse();

        // Advance both the fake clock and the timer queue.
        fakeNow = fakeNow.add(const Duration(seconds: 3));
        async.elapse(const Duration(seconds: 3));

        check(gate.isOpen).isTrue();
        check(gate.remaining).isNull();
        gate.dispose();
      });
    });

    test('dispose() stops the ticker and short-circuits future arm()', () {
      FakeAsync().run((async) {
        RetryAfterGate(
            tickInterval: const Duration(milliseconds: 100),
          )
          ..addListener(() {})
          ..arm(const Duration(seconds: 5))
          ..dispose()
          // Subsequent arm calls after dispose are no-ops; no timers
          // should remain to fire.
          ..arm(const Duration(seconds: 5));
        async.flushTimers();
        check(async.pendingTimers.length).equals(0);
      });
    });
  });
}

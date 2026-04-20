import 'package:checks/checks.dart';
import 'package:colmeia/core/socket/agent_latency_oracle.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AgentLatencyOracle constructor guards', () {
    test('rejects alpha outside (0, 1]', () {
      check(() => AgentLatencyOracle(alpha: 0)).throws<AssertionError>();
      check(() => AgentLatencyOracle(alpha: -0.1)).throws<AssertionError>();
      check(() => AgentLatencyOracle(alpha: 1.1)).throws<AssertionError>();
    });

    test('rejects warmUpSampleCount < 1', () {
      check(
        () => AgentLatencyOracle(warmUpSampleCount: 0),
      ).throws<AssertionError>();
    });

    test('rejects negative safetyFactor', () {
      check(
        () => AgentLatencyOracle(safetyFactor: -1),
      ).throws<AssertionError>();
    });
  });

  group('AgentLatencyOracle.suggestTimeout', () {
    test('returns fallback before warm-up completes', () {
      final oracle = AgentLatencyOracle();
      // Default warm-up is 5; record 4 → still warming up.
      for (var i = 0; i < 4; i++) {
        oracle.record(
          agentId: 'a',
          method: 'sql.execute',
          elapsed: const Duration(milliseconds: 50),
        );
      }
      final suggestion = oracle.suggestTimeout(
        agentId: 'a',
        method: 'sql.execute',
        fallback: const Duration(seconds: 7),
      );
      check(suggestion).equals(const Duration(seconds: 7));
    });

    test('clamps fallback to floor/ceiling during warm-up', () {
      final oracle = AgentLatencyOracle();
      final tooLow = oracle.suggestTimeout(
        agentId: 'a',
        method: 'm',
        fallback: const Duration(milliseconds: 10),
        floor: const Duration(seconds: 1),
        ceiling: const Duration(seconds: 5),
      );
      check(tooLow).equals(const Duration(seconds: 1));

      final tooHigh = oracle.suggestTimeout(
        agentId: 'a',
        method: 'm',
        fallback: const Duration(seconds: 999),
        floor: const Duration(seconds: 1),
        ceiling: const Duration(seconds: 5),
      );
      check(tooHigh).equals(const Duration(seconds: 5));
    });

    test('produces a stable estimate when latencies are constant', () {
      final oracle = AgentLatencyOracle();
      for (var i = 0; i < 30; i++) {
        oracle.record(
          agentId: 'a',
          method: 'sql.execute',
          elapsed: const Duration(milliseconds: 100),
        );
      }
      final suggestion = oracle.suggestTimeout(
        agentId: 'a',
        method: 'sql.execute',
      );
      // mean ~= 100 ms, stddev ~= 0 → estimate ~= 100 ms, then clamped to
      // the floor (default 3 s).
      check(suggestion).equals(const Duration(seconds: 3));
    });

    test('grows with variance: noisy latencies push suggestion up', () {
      final oracle = AgentLatencyOracle();
      // Alternating slow/fast samples produce non-zero variance.
      for (var i = 0; i < 30; i++) {
        final ms = i.isEven ? 200 : 1200;
        oracle.record(
          agentId: 'a',
          method: 'sql.execute',
          elapsed: Duration(milliseconds: ms),
        );
      }
      final noisy = oracle.suggestTimeout(
        agentId: 'a',
        method: 'sql.execute',
      );
      check(noisy).isGreaterThan(const Duration(milliseconds: 1500));
    });

    test('honors ceiling even when EWMA pushes way above', () {
      final oracle = AgentLatencyOracle();
      for (var i = 0; i < 30; i++) {
        oracle.record(
          agentId: 'a',
          method: 'sql.execute',
          elapsed: const Duration(seconds: 30),
        );
      }
      final clamped = oracle.suggestTimeout(
        agentId: 'a',
        method: 'sql.execute',
        ceiling: const Duration(seconds: 10),
      );
      check(clamped).equals(const Duration(seconds: 10));
    });

    test('isolates statistics by (agentId, method)', () {
      final oracle = AgentLatencyOracle(warmUpSampleCount: 1)
        ..record(
          agentId: 'fast',
          method: 'sql.execute',
          elapsed: const Duration(milliseconds: 50),
        )
        ..record(
          agentId: 'slow',
          method: 'sql.execute',
          elapsed: const Duration(milliseconds: 5000),
        );

      check(oracle.meanMsFor(agentId: 'fast', method: 'sql.execute'))
          .isNotNull()
          .isLessThan(100);
      check(oracle.meanMsFor(agentId: 'slow', method: 'sql.execute'))
          .isNotNull()
          .isGreaterThan(1000);
    });

    test('drops invalid samples (negative or NaN durations)', () {
      final oracle = AgentLatencyOracle(warmUpSampleCount: 1)
        ..record(
          agentId: 'a',
          method: 'm',
          elapsed: const Duration(milliseconds: -5),
        );
      check(oracle.sampleCountFor(agentId: 'a', method: 'm')).equals(0);
    });

    test('sampleCountFor reflects recorded observations', () {
      final oracle = AgentLatencyOracle()
        ..record(
          agentId: 'a',
          method: 'm',
          elapsed: const Duration(milliseconds: 1),
        )
        ..record(
          agentId: 'a',
          method: 'm',
          elapsed: const Duration(milliseconds: 2),
        )
        ..record(
          agentId: 'a',
          method: 'm',
          elapsed: const Duration(milliseconds: 3),
        );
      check(oracle.sampleCountFor(agentId: 'a', method: 'm')).equals(3);
    });
  });
}

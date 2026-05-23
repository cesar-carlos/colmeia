import 'package:colmeia/core/socket/agent_latency_budget.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AgentLatencyBudget.suggest', () {
    test('returns fallback before warm-up sample count', () {
      final duration = AgentLatencyBudget.suggest(
        meanMs: 100,
        stdDevMs: 10,
        sampleCount: 2,
        warmUpSampleCount: 5,
        safetyFactor: 2,
        fallback: const Duration(seconds: 15),
      );

      expect(duration, const Duration(seconds: 15));
    });

    test('clamps mean + safety * stdDev to ceiling', () {
      final duration = AgentLatencyBudget.suggest(
        meanMs: 100000,
        stdDevMs: 1000,
        sampleCount: 10,
        warmUpSampleCount: 5,
        safetyFactor: 2,
        floor: const Duration(seconds: 3),
        ceiling: const Duration(seconds: 60),
      );

      expect(duration, const Duration(seconds: 60));
    });
  });

  group('AgentLatencyBudget.suggestFromAverage', () {
    test('returns null for empty history', () {
      expect(
        AgentLatencyBudget.suggestFromAverage(
          history: const <Duration>[],
          safetyMultiplier: 1.5,
          minTimeout: const Duration(seconds: 5),
          maxTimeout: const Duration(seconds: 120),
        ),
        isNull,
      );
    });

    test('applies multiplier and clamps', () {
      final duration = AgentLatencyBudget.suggestFromAverage(
        history: const <Duration>[
          Duration(milliseconds: 1000),
          Duration(milliseconds: 3000),
        ],
        safetyMultiplier: 2,
        minTimeout: const Duration(seconds: 5),
        maxTimeout: const Duration(seconds: 10),
      );

      expect(duration, const Duration(seconds: 5));
    });
  });
}

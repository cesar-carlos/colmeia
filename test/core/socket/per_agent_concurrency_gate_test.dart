import 'package:checks/checks.dart';
import 'package:colmeia/core/socket/per_agent_concurrency_gate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PerAgentConcurrencyGate', () {
    test('rejects non-positive maxInflightPerAgent', () {
      check(
        () => PerAgentConcurrencyGate(maxInflightPerAgent: 0),
      ).throws<AssertionError>();
      check(
        () => PerAgentConcurrencyGate(maxInflightPerAgent: -1),
      ).throws<AssertionError>();
    });

    test('acquire under the limit completes immediately', () async {
      final gate = PerAgentConcurrencyGate(maxInflightPerAgent: 2);

      await gate.acquire('a');
      await gate.acquire('a');

      check(gate.inflightFor('a')).equals(2);
      check(gate.waitingFor('a')).equals(0);
    });

    test('acquire over the limit blocks until release frees a slot', () async {
      final gate = PerAgentConcurrencyGate(maxInflightPerAgent: 1);

      await gate.acquire('a');
      check(gate.inflightFor('a')).equals(1);

      var thirdResolved = false;
      final third = gate.acquire('a').whenComplete(() => thirdResolved = true);

      await Future<void>.delayed(const Duration(milliseconds: 10));
      check(thirdResolved).isFalse();
      check(gate.waitingFor('a')).equals(1);

      gate.release('a');
      await third;
      check(thirdResolved).isTrue();
      check(gate.inflightFor('a')).equals(1);
      check(gate.waitingFor('a')).equals(0);
    });

    test(
      'agents are isolated (slot exhaustion in A does not block B)',
      () async {
        final gate = PerAgentConcurrencyGate(maxInflightPerAgent: 1);
        await gate.acquire('a');

        // Even though A is full, B has its own counter and acquires
        // immediately.
        var bResolved = false;
        await gate.acquire('b').whenComplete(() => bResolved = true);
        check(bResolved).isTrue();
        check(gate.inflightFor('a')).equals(1);
        check(gate.inflightFor('b')).equals(1);
      },
    );

    test('FIFO order: waiters are served in the order they queued', () async {
      final gate = PerAgentConcurrencyGate(maxInflightPerAgent: 1);
      await gate.acquire('a');

      final completed = <int>[];
      final f1 = gate.acquire('a').whenComplete(() => completed.add(1));
      final f2 = gate.acquire('a').whenComplete(() => completed.add(2));
      final f3 = gate.acquire('a').whenComplete(() => completed.add(3));

      gate.release('a');
      await f1;
      gate.release('a');
      await f2;
      gate.release('a');
      await f3;

      check(completed).deepEquals(<int>[1, 2, 3]);
    });

    test('release without an acquire is safe (no negative counter)', () {
      final gate = PerAgentConcurrencyGate(maxInflightPerAgent: 4)
        ..release('a');
      check(gate.inflightFor('a')).equals(0);
    });

    test('peakInflight tracks the highest concurrent occupancy', () async {
      final gate = PerAgentConcurrencyGate(maxInflightPerAgent: 3);
      await gate.acquire('a');
      await gate.acquire('a');
      await gate.acquire('b');

      check(gate.peakInflight).equals(2);

      gate
        ..release('a')
        ..release('a')
        ..release('b');
      check(gate.peakInflight).equals(0);
    });

    test('cleanup: agent entry is removed when counter reaches zero', () async {
      final gate = PerAgentConcurrencyGate(maxInflightPerAgent: 2);
      await gate.acquire('a');
      gate.release('a');
      check(gate.inflightFor('a')).equals(0);
    });
  });
}

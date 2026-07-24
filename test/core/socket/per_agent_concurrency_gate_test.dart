import 'dart:async';

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

    test(
      'throws StateError when waiter queue exceeds maxWaitersPerAgent',
      () async {
        final gate = PerAgentConcurrencyGate(
          maxInflightPerAgent: 1,
          maxWaitersPerAgent: 1,
        );
        await gate.acquire('a');
        final waiter = gate.acquire('a');
        await expectLater(
          () => gate.acquire('a'),
          throwsA(isA<StateError>()),
        );
        gate.release('a');
        await waiter;
      },
    );

    test('invokes onWaiterQueueRejected when waiter queue is full', () async {
      var rejected = 0;
      final gate = PerAgentConcurrencyGate(
        maxInflightPerAgent: 1,
        maxWaitersPerAgent: 1,
        onWaiterQueueRejected: () => rejected++,
      );
      await gate.acquire('a');
      final waiter = gate.acquire('a');
      await expectLater(
        () => gate.acquire('a'),
        throwsA(isA<StateError>()),
      );
      check(rejected).equals(1);
      gate.release('a');
      await waiter;
    });

    test(
      'queued acquire fails with TimeoutException after maxWaitForSlot',
      () async {
        var timeouts = 0;
        final gate = PerAgentConcurrencyGate(
          maxInflightPerAgent: 1,
          maxWaitForSlot: const Duration(milliseconds: 50),
          onAcquireWaitTimeout: () => timeouts++,
        );
        await gate.acquire('a');
        final queued = gate.acquire('a');
        await expectLater(
          queued,
          throwsA(isA<TimeoutException>()),
        );
        check(timeouts).equals(1);
        gate.release('a');
        await gate.acquire('a');
        gate.release('a');
      },
    );

    group('acquireSlots', () {
      test('rejects count less than 1', () async {
        final gate = PerAgentConcurrencyGate(maxInflightPerAgent: 4);
        await expectLater(
          () => gate.acquireSlots('a', 0),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('rejects count above maxInflightPerAgent', () async {
        final gate = PerAgentConcurrencyGate(maxInflightPerAgent: 4);
        await expectLater(
          () => gate.acquireSlots('a', 5),
          throwsA(isA<StateError>()),
        );
      });

      test('grants multiple slots atomically when capacity allows', () async {
        final gate = PerAgentConcurrencyGate();
        await gate.acquireSlots('a', 8);
        check(gate.inflightFor('a')).equals(8);
        gate.releaseSlots('a', 8);
        check(gate.inflightFor('a')).equals(0);
      });

      test(
        'waits until enough capacity exists instead of deadlocking',
        () async {
          final gate = PerAgentConcurrencyGate();
          await gate.acquireSlots('a', 5);

          var batchResolved = false;
          final batch = gate
              .acquireSlots('a', 8)
              .whenComplete(() => batchResolved = true);

          await Future<void>.delayed(const Duration(milliseconds: 10));
          check(batchResolved).isFalse();
          check(gate.waitingFor('a')).equals(1);

          // Freeing one slot is not enough for an 8-slot waiter.
          gate.releaseSlots('a', 1);
          await Future<void>.delayed(const Duration(milliseconds: 10));
          check(batchResolved).isFalse();

          // Free the remaining 4 → 0 inflight → 8-slot batch can grant.
          gate.releaseSlots('a', 4);
          await batch;
          check(batchResolved).isTrue();
          check(gate.inflightFor('a')).equals(8);
          gate.releaseSlots('a', 8);
        },
      );

      test(
        'FIFO does not skip a large head waiter for a smaller one',
        () async {
          final gate = PerAgentConcurrencyGate(maxInflightPerAgent: 4);
          await gate.acquireSlots('a', 2);

          var largeDone = false;
          var smallDone = false;
          final large = gate
              .acquireSlots('a', 4)
              .whenComplete(() => largeDone = true);
          final small = gate
              .acquireSlots('a', 1)
              .whenComplete(() => smallDone = true);

          gate.releaseSlots('a', 2);
          await Future<void>.delayed(const Duration(milliseconds: 10));
          // Head waiter needs 4; with 0 inflight it should grant and then
          // the small waiter stays blocked until large releases.
          await large;
          check(largeDone).isTrue();
          check(smallDone).isFalse();
          gate.releaseSlots('a', 4);
          await small;
          check(smallDone).isTrue();
          gate.release('a');
        },
      );

      test('cancelQueuedWaiter fails a multi-slot wait', () async {
        final gate = PerAgentConcurrencyGate(maxInflightPerAgent: 2);
        await gate.acquireSlots('a', 2);
        late Completer<void> queued;
        final waiting = gate.acquireSlots(
          'a',
          2,
          onQueuedWaiter: (c) => queued = c,
        );
        gate.cancelQueuedWaiter('a', queued);
        await expectLater(waiting, throwsA(isA<GateQueueWaitCancelled>()));
        gate.releaseSlots('a', 2);
      });
    });
  });
}

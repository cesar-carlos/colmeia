import 'package:checks/checks.dart';
import 'package:colmeia/core/observability/socket/socket_channel_metrics.dart';
import 'package:colmeia/core/observability/socket/socket_metrics_snapshot.dart';
import 'package:colmeia/core/socket/agent_command_outcome.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late SocketChannelMetrics metrics;

  setUp(() {
    metrics = SocketChannelMetrics(reservoirSize: 8);
  });

  group('SocketChannelMetrics', () {
    test('empty snapshot reports zeroed histograms and empty counters', () {
      final snap = metrics.snapshot();
      check(snap.handshakeMs).equals(HistogramSnapshot.empty);
      check(snap.dispatchMsByKey).isEmpty();
      check(snap.outcomesTotal).isEmpty();
      check(snap.reconnectsTotalByReason).isEmpty();
      check(snap.gateWaiterQueueRejectedTotal).equals(0);
      check(snap.gateAcquireWaitTimeoutTotal).equals(0);
      check(snap.relayStreamingUnhandledErrorTotal).equals(0);
    });

    test('handshake histogram aggregates count, mean and percentiles', () {
      for (final ms in <int>[10, 20, 30, 40, 50]) {
        metrics.recordHandshake(elapsed: Duration(milliseconds: ms));
      }
      final snap = metrics.snapshot().handshakeMs;
      check(snap.count).equals(5);
      check(snap.mean).equals(30);
      check(snap.p50).equals(30);
      check(snap.p95).isGreaterOrEqual(40);
      check(snap.max).equals(50);
    });

    test('dispatch histograms are bucketed by agentId|method', () {
      metrics
        ..recordDispatch(
          agentId: 'a-1',
          method: 'sql.execute',
          elapsed: const Duration(milliseconds: 100),
        )
        ..recordDispatch(
          agentId: 'a-1',
          method: 'sql.execute',
          elapsed: const Duration(milliseconds: 200),
        )
        ..recordDispatch(
          agentId: 'a-2',
          method: 'agent.getProfile',
          elapsed: const Duration(milliseconds: 50),
        );

      final snap = metrics.snapshot().dispatchMsByKey;
      check(snap.keys.toSet()).deepEquals(<String>{
        'a-1|sql.execute',
        'a-2|agent.getProfile',
      });
      check(snap['a-1|sql.execute']!.count).equals(2);
      check(snap['a-1|sql.execute']!.max).equals(200);
      check(snap['a-2|agent.getProfile']!.count).equals(1);
    });

    test('null method is bucketed under <unknown>', () {
      metrics.recordDispatch(
        agentId: 'a-3',
        method: null,
        elapsed: const Duration(milliseconds: 7),
      );
      check(
        metrics.snapshot().dispatchMsByKey.keys,
      ).contains('a-3|<unknown>');
    });

    test('outcomes counter pivots on (kind, reasonCode)', () {
      metrics
        ..recordOutcome(
          outcome: AgentCommandSuccess(
            agentId: 'a',
            rpcId: '1',
            observedAt: DateTime.utc(2026),
            elapsed: Duration.zero,
          ),
        )
        ..recordOutcome(
          outcome: AgentCommandSuccess(
            agentId: 'a',
            rpcId: '2',
            observedAt: DateTime.utc(2026),
            elapsed: Duration.zero,
          ),
        )
        ..recordOutcome(
          outcome: AgentCommandFailedAuth(
            agentId: 'a',
            rpcId: '3',
            observedAt: DateTime.utc(2026),
            elapsed: Duration.zero,
            reasonCode: 'AGENT_ACCESS_DENIED',
          ),
        );

      final snap = metrics.snapshot().outcomesTotal;
      check(snap['AgentCommandSuccess|-']).equals(2);
      check(snap['AgentCommandFailedAuth|AGENT_ACCESS_DENIED']).equals(1);
    });

    test('reconnect counter aggregates per reason', () {
      metrics
        ..recordReconnect(reason: 'app_paused')
        ..recordReconnect(reason: 'app_paused')
        ..recordReconnect(reason: 'transient_error');

      final snap = metrics.snapshot().reconnectsTotalByReason;
      check(snap['app_paused']).equals(2);
      check(snap['transient_error']).equals(1);
    });

    test('reservoir keeps the most recent samples (count keeps growing)', () {
      for (var i = 1; i <= 16; i++) {
        metrics.recordHandshake(elapsed: Duration(milliseconds: i * 10));
      }
      // Reservoir size is 8 (constructor); count tracks ALL observations,
      // percentiles are computed over the retained slice.
      final snap = metrics.snapshot().handshakeMs;
      check(snap.count).equals(16);
      check(snap.max).equals(160);
      check(snap.p50).isGreaterThan(80);
    });

    test('coalesced counter increments per recordCoalesced call', () {
      metrics
        ..recordCoalesced()
        ..recordCoalesced()
        ..recordCoalesced();
      check(metrics.snapshot().coalescedTotal).equals(3);
    });

    test('gate and relay streaming counters increment', () {
      metrics
        ..recordGateWaiterQueueRejected()
        ..recordGateAcquireWaitTimeout()
        ..recordRelayStreamingUnhandledError()
        ..recordRelayStreamingUnhandledError();
      final snap = metrics.snapshot();
      check(snap.gateWaiterQueueRejectedTotal).equals(1);
      check(snap.gateAcquireWaitTimeoutTotal).equals(1);
      check(snap.relayStreamingUnhandledErrorTotal).equals(2);
    });

    test('reset clears every counter and reservoir', () {
      metrics
        ..recordHandshake(elapsed: const Duration(milliseconds: 5))
        ..recordReconnect(reason: 'app_paused')
        ..recordCoalesced()
        ..recordGateWaiterQueueRejected()
        ..recordGateAcquireWaitTimeout()
        ..recordRelayStreamingUnhandledError()
        ..reset();

      final snap = metrics.snapshot();
      check(snap.handshakeMs.count).equals(0);
      check(snap.reconnectsTotalByReason).isEmpty();
      check(snap.coalescedTotal).equals(0);
      check(snap.gateWaiterQueueRejectedTotal).equals(0);
      check(snap.gateAcquireWaitTimeoutTotal).equals(0);
      check(snap.relayStreamingUnhandledErrorTotal).equals(0);
    });
  });
}

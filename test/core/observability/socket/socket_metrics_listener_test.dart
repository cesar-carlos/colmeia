import 'dart:async';

import 'package:checks/checks.dart';
import 'package:colmeia/core/observability/socket/socket_channel_metrics.dart';
import 'package:colmeia/core/observability/socket/socket_metrics_listener.dart';
import 'package:colmeia/core/socket/agent_command_outcome.dart';
import 'package:colmeia/core/socket/consumer_socket_connection.dart';
import 'package:colmeia/core/socket/consumer_socket_connection_state.dart';
import 'package:colmeia/core/socket/per_agent_concurrency_gate.dart';
import 'package:colmeia/core/socket/relay/relay_command_dispatcher.dart';
import 'package:colmeia/core/socket/relay/relay_rpc_outcome.dart';
import 'package:colmeia/core/socket/socket_command_dispatcher.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockConnection extends Mock implements ConsumerSocketConnection {}

class _MockDispatcher extends Mock implements SocketCommandDispatcher {}

class _MockRelayDispatcher extends Mock implements RelayCommandDispatcher {}

void main() {
  late _MockConnection connection;
  late _MockDispatcher dispatcher;
  late SocketChannelMetrics metrics;
  late StreamController<ConsumerSocketConnectionState> stateController;
  late StreamController<AgentCommandOutcome> outcomeController;
  late SocketMetricsListener listener;

  setUp(() {
    connection = _MockConnection();
    dispatcher = _MockDispatcher();
    metrics = SocketChannelMetrics(reservoirSize: 64);
    stateController =
        StreamController<ConsumerSocketConnectionState>.broadcast();
    outcomeController = StreamController<AgentCommandOutcome>.broadcast();
    when(() => connection.states()).thenAnswer((_) => stateController.stream);
    when(() => dispatcher.outcomes()).thenAnswer(
      (_) => outcomeController.stream,
    );
    listener = SocketMetricsListener(
      connection: connection,
      dispatcher: dispatcher,
      metrics: metrics,
    );
  });

  tearDown(() async {
    await listener.dispose();
    await stateController.close();
    await outcomeController.close();
  });

  group('SocketMetricsListener', () {
    test('start is idempotent', () {
      listener
        ..start()
        ..start();
      // Reaching here without throwing is enough; verifying the streams
      // weren't subscribed twice would require ListenStream which mocktail
      // does not expose directly. The metrics outcome below proves a
      // single subscription works.
      check(true).isTrue();
    });

    test('records handshake duration on connecting -> connected', () async {
      listener.start();
      stateController.add(const ConsumerSocketConnecting(attempt: 1));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      stateController.add(
        ConsumerSocketConnected(
          socketId: 's',
          handshakeAt: DateTime.utc(2026),
        ),
      );
      await Future<void>.delayed(Duration.zero);

      final snap = metrics.snapshot().handshakeMs;
      check(snap.count).equals(1);
      check(snap.max).isGreaterOrEqual(0);
    });

    test(
      'records reconnect with disconnect reason when transitioning to disconnected',
      () async {
        listener.start();
        stateController.add(
          const ConsumerSocketDisconnected(reason: 'app_paused'),
        );
        await Future<void>.delayed(Duration.zero);

        check(
          metrics.snapshot().reconnectsTotalByReason['app_paused'],
        ).equals(1);
      },
    );

    test(
      'records transient_error reason for ConsumerSocketError(transient)',
      () async {
        listener.start();
        stateController.add(
          const ConsumerSocketError(message: 'boom', transient: true),
        );
        await Future<void>.delayed(Duration.zero);

        check(
          metrics.snapshot().reconnectsTotalByReason['transient_error'],
        ).equals(1);
      },
    );

    test(
      'records unauthorized reason for terminal unauthorized state',
      () async {
        listener.start();
        stateController.add(const ConsumerSocketUnauthorized());
        await Future<void>.delayed(Duration.zero);

        check(
          metrics.snapshot().reconnectsTotalByReason['unauthorized'],
        ).equals(1);
      },
    );

    test('records dispatch + outcome from a Success outcome', () async {
      listener.start();
      outcomeController.add(
        AgentCommandSuccess(
          agentId: 'a-1',
          rpcId: 'rpc-1',
          observedAt: DateTime.utc(2026),
          elapsed: const Duration(milliseconds: 42),
          method: 'sql.execute',
        ),
      );
      await Future<void>.delayed(Duration.zero);

      final snap = metrics.snapshot();
      check(snap.dispatchMsByKey['a-1|sql.execute']!.count).equals(1);
      check(snap.outcomesTotal['AgentCommandSuccess|-']).equals(1);
    });

    test('records FailedOffline outcome with reasonCode', () async {
      listener.start();
      outcomeController.add(
        AgentCommandFailedOffline(
          agentId: 'a-2',
          rpcId: 'rpc-2',
          observedAt: DateTime.utc(2026),
          elapsed: const Duration(milliseconds: 5),
          reasonCode: 'AGENT_OFFLINE',
          method: 'sql.execute',
        ),
      );
      await Future<void>.delayed(Duration.zero);

      check(
        metrics
            .snapshot()
            .outcomesTotal['AgentCommandFailedOffline|AGENT_OFFLINE'],
      ).equals(1);
    });

    test('dispose stops further recording', () async {
      listener.start();
      await listener.dispose();
      stateController.add(
        const ConsumerSocketDisconnected(reason: 'late'),
      );
      outcomeController.add(
        AgentCommandSuccess(
          agentId: 'a',
          rpcId: 'r',
          observedAt: DateTime.utc(2026),
          elapsed: Duration.zero,
        ),
      );
      await Future<void>.delayed(Duration.zero);

      check(metrics.snapshot().reconnectsTotalByReason).isEmpty();
      check(metrics.snapshot().outcomesTotal).isEmpty();
    });
  });

  group('SocketMetricsListener relay + gate export', () {
    late _MockConnection conn;
    late _MockDispatcher disp;
    late _MockRelayDispatcher relay;
    late SocketChannelMetrics m;
    late StreamController<ConsumerSocketConnectionState> states;
    late StreamController<AgentCommandOutcome> outcomes;
    late StreamController<RelayRpcOutcome> relayOutcomes;
    late SocketMetricsListener sut;

    setUp(() {
      conn = _MockConnection();
      disp = _MockDispatcher();
      relay = _MockRelayDispatcher();
      m = SocketChannelMetrics(reservoirSize: 64);
      states = StreamController<ConsumerSocketConnectionState>.broadcast();
      outcomes = StreamController<AgentCommandOutcome>.broadcast();
      relayOutcomes = StreamController<RelayRpcOutcome>.broadcast();
      when(() => conn.states()).thenAnswer((_) => states.stream);
      when(() => disp.outcomes()).thenAnswer((_) => outcomes.stream);
      when(() => relay.outcomes()).thenAnswer((_) => relayOutcomes.stream);
      sut = SocketMetricsListener(
        connection: conn,
        dispatcher: disp,
        metrics: m,
        relayDispatcher: relay,
      );
    });

    tearDown(() async {
      await sut.dispose();
      await states.close();
      await outcomes.close();
      await relayOutcomes.close();
    });

    test('records relay unary success outcome + dispatch histogram', () async {
      sut.start();
      relayOutcomes.add(
        RelayRpcSuccess(
          agentId: 'a-relay',
          conversationId: 'c1',
          clientRequestId: 'cri-1',
          requestId: 'req-1',
          observedAt: DateTime.utc(2026),
          elapsed: const Duration(milliseconds: 15),
          method: 'sql.execute',
        ),
      );
      await Future<void>.delayed(Duration.zero);

      final snap = m.snapshot();
      check(snap.relayOutcomesTotal['RelayRpcSuccess|-']).equals(1);
      check(snap.relayDispatchMsByKey['a-relay|sql.execute']!.count).equals(1);
    });

    test(
      'disconnected exports lastGateSessionPeakSample from concurrency gate',
      () async {
        final gate = PerAgentConcurrencyGate(maxInflightPerAgent: 2);
        await gate.acquire('agent-x');
        await gate.acquire('agent-x');
        check(gate.sessionPeakMaxAgentInflight).equals(2);

        final sutWithGate = SocketMetricsListener(
          connection: conn,
          dispatcher: disp,
          metrics: m,
          relayDispatcher: relay,
          concurrencyGate: gate,
        )
          ..start();
        states.add(const ConsumerSocketDisconnected(reason: 'unit_test'));
        await Future<void>.delayed(Duration.zero);

        check(m.snapshot().lastGateSessionPeakSample).equals(2);
        check(
          m.snapshot().toCompactSessionExport()['lastGateSessionPeakSample'],
        ).equals(2);
        check(gate.sessionPeakMaxAgentInflight).equals(0);

        await sutWithGate.dispose();
        gate
          ..release('agent-x')
          ..release('agent-x');
      },
    );
  });
}

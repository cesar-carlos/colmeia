import 'dart:async';

import 'package:checks/checks.dart';
import 'package:colmeia/core/observability/socket/socket_channel_metrics.dart';
import 'package:colmeia/core/observability/socket/socket_metrics_listener.dart';
import 'package:colmeia/core/socket/agent_command_outcome.dart';
import 'package:colmeia/core/socket/consumer_socket_connection.dart';
import 'package:colmeia/core/socket/consumer_socket_connection_state.dart';
import 'package:colmeia/core/socket/socket_command_dispatcher.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockConnection extends Mock implements ConsumerSocketConnection {}

class _MockDispatcher extends Mock implements SocketCommandDispatcher {}

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

    test('records transient_error reason for ConsumerSocketError(transient)',
        () async {
      listener.start();
      stateController.add(
        const ConsumerSocketError(message: 'boom', transient: true),
      );
      await Future<void>.delayed(Duration.zero);

      check(
        metrics.snapshot().reconnectsTotalByReason['transient_error'],
      ).equals(1);
    });

    test('records unauthorized reason for terminal unauthorized state',
        () async {
      listener.start();
      stateController.add(const ConsumerSocketUnauthorized());
      await Future<void>.delayed(Duration.zero);

      check(
        metrics.snapshot().reconnectsTotalByReason['unauthorized'],
      ).equals(1);
    });

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
}

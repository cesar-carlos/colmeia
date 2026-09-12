import 'dart:async';

import 'package:checks/checks.dart';
import 'package:colmeia/core/socket/agent_command_outcome.dart';
import 'package:colmeia/core/socket/consumer_socket_connection.dart';
import 'package:colmeia/core/socket/consumer_socket_connection_state.dart';
import 'package:colmeia/core/socket/per_agent_concurrency_gate.dart';
import 'package:colmeia/core/socket/socket_command_dispatcher_impl.dart';
import 'package:colmeia/core/socket/socket_dispatch_exception.dart';
import 'package:colmeia/core/socket/socket_request_correlator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class _MockConnection extends Mock implements ConsumerSocketConnection {}

class _MockSocket extends Mock implements io.Socket {}

class _MockCorrelator extends Mock implements SocketRequestCorrelator {}

Map<String, Object?> _body({
  String rpcId = 'rpc-1',
  String method = 'sql.execute',
}) {
  return <String, Object?>{
    'agentId': 'agent-1',
    'command': <String, Object?>{
      'jsonrpc': '2.0',
      'method': method,
      'id': rpcId,
      'params': const <String, Object?>{'sql': 'SELECT 1'},
    },
  };
}

void main() {
  setUpAll(() {
    registerFallbackValue(const ConsumerSocketDisconnected());
    registerFallbackValue(<String, Object?>{});
    registerFallbackValue(Duration.zero);
  });

  late _MockConnection connection;
  late _MockSocket rawSocket;
  late _MockCorrelator correlator;
  late StreamController<ConsumerSocketConnectionState> stateController;
  late SocketCommandDispatcherImpl dispatcher;

  setUp(() {
    connection = _MockConnection();
    rawSocket = _MockSocket();
    correlator = _MockCorrelator();
    stateController =
        StreamController<ConsumerSocketConnectionState>.broadcast();

    when(() => connection.states()).thenAnswer((_) => stateController.stream);
    when(connection.connect).thenAnswer(
      (_) async => ConsumerSocketConnected(
        socketId: 's',
        handshakeAt: DateTime.utc(2026),
      ),
    );
    when(() => connection.raw).thenReturn(rawSocket);
    when(() => rawSocket.on(any(), any())).thenReturn(() {});
    when(correlator.dispose).thenAnswer((_) async {});

    dispatcher = SocketCommandDispatcherImpl(
      connection: connection,
      correlator: correlator,
    );
  });

  tearDown(() async {
    await dispatcher.dispose();
    await stateController.close();
  });

  group('SocketCommandDispatcherImpl.cancel', () {
    test(
      'forwards a SocketDispatchCancelled to the correlator and emits a '
      'transient outcome with reasonCode=cancelled',
      () async {
        final pending = Completer<Map<String, dynamic>>();
        when(
          () => correlator.register(any(), timeout: any(named: 'timeout')),
        ).thenAnswer((_) => pending.future);
        when(() => correlator.failWith(any(), any())).thenAnswer((invocation) {
          pending.completeError(invocation.positionalArguments[1] as Object);
        });

        final outcomes = <AgentCommandOutcome>[];
        final outcomesSub = dispatcher.outcomes().listen(outcomes.add);

        final future = dispatcher.sendAgentsCommand(
          agentId: 'agent-1',
          body: _body(rpcId: 'rpc-cancel'),
          rpcId: 'rpc-cancel',
        );
        await Future<void>.delayed(Duration.zero);

        dispatcher.cancel('rpc-cancel', reason: 'route_left');

        // Verify the dispatcher asked the correlator to fail the
        // pending with a SocketDispatchCancelled carrying our reason.
        final captured = verify(
          () => correlator.failWith(
            'rpc-cancel',
            captureAny(),
          ),
        ).captured;
        check(captured.length).isGreaterOrEqual(1);
        final cancelException = captured.first as SocketDispatchException;
        check(cancelException).isA<SocketDispatchCancelled>();
        check(cancelException.code).equals('cancelled');
        check(cancelException.message).contains('route_left');

        await check(future).throws<SocketDispatchCancelled>();
        await outcomesSub.cancel();
        final transients = outcomes
            .whereType<AgentCommandFailedTransient>()
            .toList();
        check(transients.length).equals(1);
        check(transients.single.reasonCode).equals('cancelled');
      },
    );

    test('cancel of an unknown rpcId is a silent no-op', () {
      // No pending request registered. cancel() should not throw nor
      // call failWith.
      dispatcher.cancel('never-registered');
      verifyNever(() => correlator.failWith(any(), any()));
    });

    test(
      'cancels a non-coalesced request while it waits for a gate slot',
      () async {
        final gate = PerAgentConcurrencyGate(maxInflightPerAgent: 1);
        await gate.acquire('agent-1');
        await dispatcher.dispose();
        dispatcher = SocketCommandDispatcherImpl(
          connection: connection,
          correlator: correlator,
          concurrencyGate: gate,
        );
        final outcomes = <AgentCommandOutcome>[];
        final outcomesSub = dispatcher.outcomes().listen(outcomes.add);

        final future = dispatcher.sendAgentsCommand(
          agentId: 'agent-1',
          body: _body(rpcId: 'rpc-queued'),
          rpcId: 'rpc-queued',
          coalesce: false,
        );
        final assertion = expectLater(
          future,
          throwsA(isA<SocketDispatchCancelled>()),
        );
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);
        check(gate.waitingFor('agent-1')).equals(1);

        dispatcher.cancel('rpc-queued', reason: 'route_left');

        await assertion;
        await Future<void>.delayed(Duration.zero);
        verifyNever(
          () => correlator.register(any(), timeout: any(named: 'timeout')),
        );
        verifyNever(() => rawSocket.emit('agents:command', any<dynamic>()));
        check(gate.waitingFor('agent-1')).equals(0);
        check(gate.inflightFor('agent-1')).equals(1);
        final cancelled = outcomes
            .whereType<AgentCommandFailedTransient>()
            .where((outcome) => outcome.rpcId == 'rpc-queued')
            .toList();
        check(cancelled.length).equals(1);
        check(cancelled.single.reasonCode).equals('cancelled');

        await outcomesSub.cancel();
        gate.release('agent-1');
      },
    );

    test(
      'cancels only the leader client while a queued coalesced follower remains',
      () async {
        final gate = PerAgentConcurrencyGate(maxInflightPerAgent: 1);
        await gate.acquire('agent-1');
        final pending = Completer<Map<String, dynamic>>();
        when(
          () => correlator.register(any(), timeout: any(named: 'timeout')),
        ).thenAnswer((_) => pending.future);
        await dispatcher.dispose();
        dispatcher = SocketCommandDispatcherImpl(
          connection: connection,
          correlator: correlator,
          concurrencyGate: gate,
        );
        final outcomes = <AgentCommandOutcome>[];
        final outcomesSub = dispatcher.outcomes().listen(outcomes.add);

        final leader = dispatcher.sendAgentsCommand(
          agentId: 'agent-1',
          body: _body(rpcId: 'rpc-leader'),
          rpcId: 'rpc-leader',
        );
        final follower = dispatcher.sendAgentsCommand(
          agentId: 'agent-1',
          body: _body(rpcId: 'rpc-follower'),
          rpcId: 'rpc-follower',
        );
        final leaderAssertion = expectLater(
          leader,
          throwsA(isA<SocketDispatchCancelled>()),
        );
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);
        check(gate.waitingFor('agent-1')).equals(1);

        dispatcher.cancel('rpc-leader');

        await leaderAssertion;
        verifyNever(() => correlator.failWith(any(), any()));
        check(gate.waitingFor('agent-1')).equals(1);

        gate.release('agent-1');
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);
        verify(
          () => correlator.register(
            'rpc-leader',
            timeout: any(named: 'timeout'),
          ),
        ).called(1);
        verify(() => rawSocket.emit('agents:command', any<dynamic>()))
            .called(1);

        pending.complete(<String, dynamic>{
          'response': <String, dynamic>{
            'type': 'single',
            'item': <String, dynamic>{'id': 'rpc-leader', 'success': true},
          },
        });
        await follower;
        await Future<void>.delayed(Duration.zero);

        final leaderOutcomes = outcomes
            .where((outcome) => outcome.rpcId == 'rpc-leader')
            .toList();
        final followerOutcomes = outcomes
            .where((outcome) => outcome.rpcId == 'rpc-follower')
            .toList();
        check(leaderOutcomes.length).equals(1);
        check(leaderOutcomes.single).isA<AgentCommandFailedTransient>();
        check(followerOutcomes.length).equals(1);
        check(followerOutcomes.single).isA<AgentCommandSuccess>();

        await outcomesSub.cancel();
      },
    );

    test(
      'cancelAllPending cancels a request waiting for a gate slot',
      () async {
        final gate = PerAgentConcurrencyGate(maxInflightPerAgent: 1);
        await gate.acquire('agent-1');
        await dispatcher.dispose();
        dispatcher = SocketCommandDispatcherImpl(
          connection: connection,
          correlator: correlator,
          concurrencyGate: gate,
        );
        final future = dispatcher.sendAgentsCommand(
          agentId: 'agent-1',
          body: _body(rpcId: 'rpc-cancel-all'),
          rpcId: 'rpc-cancel-all',
          coalesce: false,
        );
        final assertion = expectLater(
          future,
          throwsA(isA<SocketDispatchCancelled>()),
        );
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);

        dispatcher.cancelAllPending(reason: 'e2e_teardown');

        await assertion;
        verifyNever(
          () => correlator.register(any(), timeout: any(named: 'timeout')),
        );
        verifyNever(() => rawSocket.emit('agents:command', any<dynamic>()));
        check(gate.waitingFor('agent-1')).equals(0);
        gate.release('agent-1');
      },
    );

    test('cancelAllPending fail-fasts every tracked rpcId', () async {
      final pendingA = Completer<Map<String, dynamic>>();
      final pendingB = Completer<Map<String, dynamic>>();
      when(
        () => correlator.register('rpc-a', timeout: any(named: 'timeout')),
      ).thenAnswer((_) => pendingA.future);
      when(
        () => correlator.register('rpc-b', timeout: any(named: 'timeout')),
      ).thenAnswer((_) => pendingB.future);
      when(() => correlator.failWith(any(), any())).thenReturn(null);

      final futureA = dispatcher.sendAgentsCommand(
        agentId: 'agent-1',
        body: _body(rpcId: 'rpc-a'),
        rpcId: 'rpc-a',
        coalesce: false,
      );
      final futureB = dispatcher.sendAgentsCommand(
        agentId: 'agent-1',
        body: _body(rpcId: 'rpc-b'),
        rpcId: 'rpc-b',
        coalesce: false,
      );
      unawaited(futureA.catchError((Object _) => <String, dynamic>{}));
      unawaited(futureB.catchError((Object _) => <String, dynamic>{}));
      await Future<void>.delayed(Duration.zero);

      dispatcher.cancelAllPending(reason: 'e2e_teardown');

      verify(() => correlator.failWith('rpc-a', any())).called(1);
      verify(() => correlator.failWith('rpc-b', any())).called(1);
    });
  });
}

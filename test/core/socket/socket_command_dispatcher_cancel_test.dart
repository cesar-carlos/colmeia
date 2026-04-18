// Test-only: arrange-then-act statements (`dispatcher.sendAgentsCommand`
// then `dispatcher.cancel`) read more clearly as separate lines than as
// cascades on the dispatcher.
// ignore_for_file: cascade_invocations

import 'dart:async';

import 'package:checks/checks.dart';
import 'package:colmeia/core/socket/agent_command_outcome.dart';
import 'package:colmeia/core/socket/consumer_socket_connection.dart';
import 'package:colmeia/core/socket/consumer_socket_connection_state.dart';
import 'package:colmeia/core/socket/socket_command_dispatcher_impl.dart';
import 'package:colmeia/core/socket/socket_dispatch_exception.dart';
import 'package:colmeia/core/socket/socket_request_correlator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class _MockConnection extends Mock implements ConsumerSocketConnection {}

class _MockSocket extends Mock implements io.Socket {}

class _MockCorrelator extends Mock implements SocketRequestCorrelator {}

Map<String, Object?> _body({String rpcId = 'rpc-1', String method = 'sql.execute'}) {
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
        // Mock register to return a future the dispatcher will await
        // forever. We do not settle it: the test verifies the cancel
        // call surface (correlator.failWith + outcome emission), not
        // the future propagation (covered by integration with the real
        // correlator in `socket_request_correlator_test.dart`).
        final pending = Completer<Map<String, dynamic>>();
        when(
          () => correlator.register(any(), timeout: any(named: 'timeout')),
        ).thenAnswer((_) => pending.future);
        when(() => correlator.failWith(any(), any())).thenReturn(null);

        final outcomes = <AgentCommandOutcome>[];
        final outcomesSub = dispatcher.outcomes().listen(outcomes.add);

        // Fire-and-track: we never await the wrapper future because
        // the mock pending never settles (and the test does not need
        // it to — propagation has its own coverage).
        final future = dispatcher.sendAgentsCommand(
          agentId: 'agent-1',
          body: _body(rpcId: 'rpc-cancel'),
          rpcId: 'rpc-cancel',
        );
        // Pre-attach a no-op so the eventual implicit close from
        // teardown does not fire an unhandled async error.
        // ignore: unawaited_futures
        future.catchError((Object _) => <String, dynamic>{});
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

        // Outcome stream got the transient with reasonCode=cancelled.
        await Future<void>.delayed(Duration.zero);
        await outcomesSub.cancel();
        final transients = outcomes.whereType<AgentCommandFailedTransient>()
            .toList();
        check(transients.length).isGreaterOrEqual(1);
        check(transients.last.reasonCode).equals('cancelled');
      },
    );

    test('cancel of an unknown rpcId is a silent no-op', () {
      // No pending request registered. cancel() should not throw nor
      // call failWith.
      dispatcher.cancel('never-registered');
      verifyNever(() => correlator.failWith(any(), any()));
    });
  });
}

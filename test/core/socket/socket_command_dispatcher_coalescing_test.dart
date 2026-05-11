import 'dart:async';

import 'package:checks/checks.dart';
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

Map<String, Object?> _body({
  String agentId = 'agent-1',
  String rpcId = 'rpc-1',
  String method = 'sql.execute',
  Map<String, Object?> params = const <String, Object?>{
    'sql': 'SELECT 1',
  },
}) {
  return <String, Object?>{
    'agentId': agentId,
    'command': <String, Object?>{
      'jsonrpc': '2.0',
      'method': method,
      'id': rpcId,
      'params': params,
    },
  };
}

void main() {
  setUpAll(() {
    registerFallbackValue(const ConsumerSocketDisconnected());
    registerFallbackValue(<String, Object?>{});
    registerFallbackValue(Duration.zero);
    registerFallbackValue(() {});
  });

  late _MockConnection connection;
  late _MockSocket rawSocket;
  late _MockCorrelator correlator;
  late StreamController<ConsumerSocketConnectionState> stateController;
  late SocketCommandDispatcherImpl dispatcher;
  var coalescedCount = 0;

  setUp(() {
    connection = _MockConnection();
    rawSocket = _MockSocket();
    correlator = _MockCorrelator();
    stateController =
        StreamController<ConsumerSocketConnectionState>.broadcast();
    coalescedCount = 0;

    when(() => connection.states()).thenAnswer((_) => stateController.stream);
    when(connection.connect).thenAnswer(
      (_) async => ConsumerSocketConnected(
        socketId: 's',
        handshakeAt: DateTime.utc(2026),
      ),
    );
    when(() => connection.raw).thenReturn(rawSocket);
    // socket_io_client's `on` returns a `Function()` cleanup callback;
    // mocktail will not synthesize one. `emit` and `off` are void and
    // do not need explicit stubs.
    when(() => rawSocket.on(any(), any())).thenReturn(() {});
    when(correlator.dispose).thenAnswer((_) async {});
  });

  tearDown(() async {
    await dispatcher.dispose();
    await stateController.close();
  });

  group('SocketCommandDispatcherImpl coalescing', () {
    test('two concurrent identical sends share the same Future', () async {
      final pending = Completer<Map<String, dynamic>>();
      when(
        () => correlator.register(any(), timeout: any(named: 'timeout')),
      ).thenAnswer((_) => pending.future);

      dispatcher = SocketCommandDispatcherImpl(
        connection: connection,
        correlator: correlator,
        onCoalesced: () => coalescedCount += 1,
      );

      final f1 = dispatcher.sendAgentsCommand(
        agentId: 'agent-1',
        body: _body(rpcId: 'rpc-A'),
        rpcId: 'rpc-A',
      );
      final f2 = dispatcher.sendAgentsCommand(
        agentId: 'agent-1',
        body: _body(rpcId: 'rpc-B'),
        rpcId: 'rpc-B',
      );

      await Future<void>.delayed(Duration.zero);

      // The dispatcher only registered ONE pending request and emitted ONCE.
      verify(
        () => correlator.register(any(), timeout: any(named: 'timeout')),
      ).called(1);
      verify(
        () => rawSocket.emit('agents:command', any<dynamic>()),
      ).called(1);
      check(coalescedCount).equals(1);

      pending.complete(<String, dynamic>{
        'response': <String, dynamic>{
          'type': 'single',
          'item': <String, dynamic>{'id': 'rpc-A', 'success': true},
        },
      });

      final r1 = await f1;
      final r2 = await f2;
      check(identical(f1, f2)).isFalse();
      check(r1).deepEquals(r2);
    });

    test('coalesced follower can be cancelled without cancelling leader', () async {
      final pending = Completer<Map<String, dynamic>>();
      when(
        () => correlator.register(any(), timeout: any(named: 'timeout')),
      ).thenAnswer((_) => pending.future);

      dispatcher = SocketCommandDispatcherImpl(
        connection: connection,
        correlator: correlator,
      );

      final f1 = dispatcher.sendAgentsCommand(
        agentId: 'agent-1',
        body: _body(rpcId: 'rpc-A'),
        rpcId: 'rpc-A',
      );
      final f2 = dispatcher.sendAgentsCommand(
        agentId: 'agent-1',
        body: _body(rpcId: 'rpc-B'),
        rpcId: 'rpc-B',
      );
      await Future<void>.delayed(Duration.zero);

      dispatcher.cancel('rpc-B');

      await check(f2).throws<SocketDispatchCancelled>();
      verifyNever(() => correlator.failWith(any(), any()));

      pending.complete(<String, dynamic>{
        'response': <String, dynamic>{
          'type': 'single',
          'item': <String, dynamic>{'id': 'rpc-A', 'success': true},
        },
      });

      await f1;
    });

    test('different params do NOT coalesce', () async {
      when(
        () => correlator.register(any(), timeout: any(named: 'timeout')),
      ).thenAnswer((invocation) {
        final completer = Completer<Map<String, dynamic>>();
        // Resolve quickly so each send completes independently.
        scheduleMicrotask(() {
          completer.complete(<String, dynamic>{
            'response': <String, dynamic>{
              'type': 'single',
              'item': <String, dynamic>{
                'id': invocation.positionalArguments.first,
                'success': true,
              },
            },
          });
        });
        return completer.future;
      });

      dispatcher = SocketCommandDispatcherImpl(
        connection: connection,
        correlator: correlator,
        onCoalesced: () => coalescedCount += 1,
      );

      await dispatcher.sendAgentsCommand(
        agentId: 'agent-1',
        body: _body(rpcId: 'rpc-A'),
        rpcId: 'rpc-A',
      );
      await dispatcher.sendAgentsCommand(
        agentId: 'agent-1',
        body: _body(
          rpcId: 'rpc-B',
          params: const <String, Object?>{
            'sql': 'SELECT 2',
          },
        ),
        rpcId: 'rpc-B',
      );

      verify(
        () => correlator.register(any(), timeout: any(named: 'timeout')),
      ).called(2);
      verify(
        () => rawSocket.emit('agents:command', any<dynamic>()),
      ).called(2);
      check(coalescedCount).equals(0);
    });

    test('coalesce: false bypasses dedup even for identical bodies', () async {
      when(
        () => correlator.register(any(), timeout: any(named: 'timeout')),
      ).thenAnswer((invocation) {
        final completer = Completer<Map<String, dynamic>>();
        scheduleMicrotask(() {
          completer.complete(<String, dynamic>{
            'response': <String, dynamic>{
              'type': 'single',
              'item': <String, dynamic>{
                'id': invocation.positionalArguments.first,
                'success': true,
              },
            },
          });
        });
        return completer.future;
      });

      dispatcher = SocketCommandDispatcherImpl(
        connection: connection,
        correlator: correlator,
        onCoalesced: () => coalescedCount += 1,
      );

      // Both calls explicitly opt out of coalescing.
      await dispatcher.sendAgentsCommand(
        agentId: 'agent-1',
        body: _body(rpcId: 'rpc-A'),
        rpcId: 'rpc-A',
        coalesce: false,
      );
      await dispatcher.sendAgentsCommand(
        agentId: 'agent-1',
        body: _body(rpcId: 'rpc-B'),
        rpcId: 'rpc-B',
        coalesce: false,
      );

      verify(
        () => correlator.register(any(), timeout: any(named: 'timeout')),
      ).called(2);
      check(coalescedCount).equals(0);
    });

    test('coalescingEnabled=false disables coalescing globally', () async {
      when(
        () => correlator.register(any(), timeout: any(named: 'timeout')),
      ).thenAnswer((invocation) {
        final completer = Completer<Map<String, dynamic>>();
        scheduleMicrotask(() {
          completer.complete(<String, dynamic>{
            'response': <String, dynamic>{
              'type': 'single',
              'item': <String, dynamic>{
                'id': invocation.positionalArguments.first,
                'success': true,
              },
            },
          });
        });
        return completer.future;
      });

      dispatcher = SocketCommandDispatcherImpl(
        connection: connection,
        correlator: correlator,
        coalescingEnabled: false,
        onCoalesced: () => coalescedCount += 1,
      );

      await dispatcher.sendAgentsCommand(
        agentId: 'agent-1',
        body: _body(rpcId: 'rpc-A'),
        rpcId: 'rpc-A',
      );
      await dispatcher.sendAgentsCommand(
        agentId: 'agent-1',
        body: _body(rpcId: 'rpc-B'),
        rpcId: 'rpc-B',
      );

      verify(
        () => correlator.register(any(), timeout: any(named: 'timeout')),
      ).called(2);
      check(coalescedCount).equals(0);
    });

    test(
      'inflight entry is cleared after completion (next call re-emits)',
      () async {
        var registerCount = 0;
        when(
          () => correlator.register(any(), timeout: any(named: 'timeout')),
        ).thenAnswer((invocation) {
          registerCount += 1;
          final completer = Completer<Map<String, dynamic>>();
          scheduleMicrotask(() {
            completer.complete(<String, dynamic>{
              'response': <String, dynamic>{
                'type': 'single',
                'item': <String, dynamic>{
                  'id': invocation.positionalArguments.first,
                  'success': true,
                },
              },
            });
          });
          return completer.future;
        });

        dispatcher = SocketCommandDispatcherImpl(
          connection: connection,
          correlator: correlator,
          onCoalesced: () => coalescedCount += 1,
        );

        await dispatcher.sendAgentsCommand(
          agentId: 'agent-1',
          body: _body(rpcId: 'rpc-A'),
          rpcId: 'rpc-A',
        );
        // First completed; the second send must register again.
        await dispatcher.sendAgentsCommand(
          agentId: 'agent-1',
          body: _body(rpcId: 'rpc-B'),
          rpcId: 'rpc-B',
        );

        check(registerCount).equals(2);
        check(coalescedCount).equals(0);
      },
    );

    test('reattaches listeners when the raw socket instance changes', () async {
      final socketB = _MockSocket();
      final handlersA = <String, List<Function>>{};
      final handlersB = <String, List<Function>>{};

      void wire(_MockSocket socket, Map<String, List<Function>> handlers) {
        when(() => socket.on(any(), any())).thenAnswer((invocation) {
          final event = invocation.positionalArguments[0] as String;
          final handler = invocation.positionalArguments[1] as Function;
          handlers.putIfAbsent(event, () => <Function>[]).add(handler);
          return () => handlers[event]?.remove(handler);
        });
        when(() => socket.off(any())).thenAnswer((invocation) {
          final event = invocation.positionalArguments[0] as String;
          handlers.remove(event);
        });
        when(() => socket.off(any(), any())).thenAnswer((invocation) {
          final event = invocation.positionalArguments[0] as String;
          final handler = invocation.positionalArguments[1];
          if (handler == null) {
            handlers.remove(event);
            return;
          }
          handlers[event]?.remove(handler);
          if (handlers[event]?.isEmpty ?? false) {
            handlers.remove(event);
          }
        });
      }

      void fire(
        Map<String, List<Function>> handlers,
        String event,
        Object? payload,
      ) {
        for (final handler in List<Function>.of(
          handlers[event] ?? <Function>[],
        )) {
          Function.apply(handler, <Object?>[payload]);
        }
      }

      wire(rawSocket, handlersA);
      wire(socketB, handlersB);

      var currentSocket = rawSocket;
      when(() => connection.raw).thenAnswer((_) => currentSocket);
      final realCorrelator = SocketRequestCorrelator(
        sweepInterval: const Duration(seconds: 30),
      );
      dispatcher = SocketCommandDispatcherImpl(
        connection: connection,
        correlator: realCorrelator,
        defaultTimeout: const Duration(milliseconds: 250),
      );

      final first = dispatcher.sendAgentsCommand(
        agentId: 'agent-1',
        body: _body(rpcId: 'rpc-A'),
        rpcId: 'rpc-A',
      );
      await Future<void>.delayed(Duration.zero);
      final firstFailure = expectLater(
        first,
        throwsA(isA<SocketDispatchDisconnected>()),
      );

      stateController.add(
        const ConsumerSocketDisconnected(reason: 'transport close'),
      );
      await firstFailure;

      currentSocket = socketB;
      final second = dispatcher.sendAgentsCommand(
        agentId: 'agent-1',
        body: _body(rpcId: 'rpc-B'),
        rpcId: 'rpc-B',
      );
      await Future<void>.delayed(Duration.zero);

      fire(handlersB, 'agents:command_response', <String, dynamic>{
        'rpcId': 'rpc-B',
        'response': <String, dynamic>{
          'type': 'single',
          'item': <String, dynamic>{'id': 'rpc-B', 'success': true},
        },
      });

      final response = await second;
      check(response['rpcId']).equals('rpc-B');
      verify(() => rawSocket.off('agents:command_response')).called(1);
      verify(() => socketB.on('agents:command_response', any())).called(1);
    });
  });
}

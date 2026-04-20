import 'dart:async';

import 'package:checks/checks.dart';
import 'package:colmeia/core/socket/consumer_socket_connection.dart';
import 'package:colmeia/core/socket/consumer_socket_connection_state.dart';
import 'package:colmeia/core/socket/socket_command_dispatcher_impl.dart';
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
    stateController = StreamController<ConsumerSocketConnectionState>.broadcast();
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

      pending.complete(<String, dynamic>{'response': <String, dynamic>{
        'type': 'single',
        'item': <String, dynamic>{'id': 'rpc-A', 'success': true},
      }});

      final r1 = await f1;
      final r2 = await f2;
      // Both consumers receive the SAME Map instance (truly shared).
      check(identical(r1, r2)).isTrue();
    });

    test('different params do NOT coalesce', () async {
      when(
        () => correlator.register(any(), timeout: any(named: 'timeout')),
      ).thenAnswer((invocation) {
        final completer = Completer<Map<String, dynamic>>();
        // Resolve quickly so each send completes independently.
        scheduleMicrotask(() {
          completer.complete(<String, dynamic>{'response': <String, dynamic>{
            'type': 'single',
            'item': <String, dynamic>{
              'id': invocation.positionalArguments.first,
              'success': true,
            },
          }});
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
        body: _body(rpcId: 'rpc-B', params: const <String, Object?>{
          'sql': 'SELECT 2',
        }),
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
          completer.complete(<String, dynamic>{'response': <String, dynamic>{
            'type': 'single',
            'item': <String, dynamic>{
              'id': invocation.positionalArguments.first,
              'success': true,
            },
          }});
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
          completer.complete(<String, dynamic>{'response': <String, dynamic>{
            'type': 'single',
            'item': <String, dynamic>{
              'id': invocation.positionalArguments.first,
              'success': true,
            },
          }});
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

    test('inflight entry is cleared after completion (next call re-emits)',
        () async {
      var registerCount = 0;
      when(
        () => correlator.register(any(), timeout: any(named: 'timeout')),
      ).thenAnswer((invocation) {
        registerCount += 1;
        final completer = Completer<Map<String, dynamic>>();
        scheduleMicrotask(() {
          completer.complete(<String, dynamic>{'response': <String, dynamic>{
            'type': 'single',
            'item': <String, dynamic>{
              'id': invocation.positionalArguments.first,
              'success': true,
            },
          }});
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
    });
  });
}

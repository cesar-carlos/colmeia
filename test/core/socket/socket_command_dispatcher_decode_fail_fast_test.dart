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

import 'agents_command_routing_test_utils.dart';

class _MockConnection extends Mock implements ConsumerSocketConnection {}

class _MockSocket extends Mock implements io.Socket {}

Map<String, Object?> _body({
  required String rpcId,
  String sql = 'SELECT 1',
}) {
  return <String, Object?>{
    'agentId': 'agent-1',
    'command': <String, Object?>{
      'jsonrpc': '2.0',
      'method': 'sql.execute',
      'id': rpcId,
      'params': <String, Object?>{'sql': sql},
    },
  };
}

const _malformedPayloadFrame = <String, Object?>{
  'schemaVersion': '1.0',
  'enc': 'json',
  'cmp': 'none',
  'contentType': 'application/json',
  'originalSize': 2,
  'compressedSize': 2,
  'payload': '!!',
};

void main() {
  setUpAll(() {
    registerFallbackValue(const ConsumerSocketDisconnected());
    registerFallbackValue(<String, Object?>{});
    registerFallbackValue(Duration.zero);
  });

  late _MockConnection connection;
  late _MockSocket rawSocket;
  late StreamController<ConsumerSocketConnectionState> stateController;
  late SocketRequestCorrelator correlator;
  late SocketCommandDispatcherImpl dispatcher;
  void Function(Object?)? commandResponseHandler;

  setUp(() {
    connection = _MockConnection();
    rawSocket = _MockSocket();
    stateController =
        StreamController<ConsumerSocketConnectionState>.broadcast();
    correlator = SocketRequestCorrelator();

    when(() => connection.states()).thenAnswer((_) => stateController.stream);
    when(connection.connect).thenAnswer(
      (_) async => ConsumerSocketConnected(
        socketId: 's',
        handshakeAt: DateTime.utc(2026),
      ),
    );
    when(() => connection.raw).thenReturn(rawSocket);
    when(() => rawSocket.on(any(), any())).thenAnswer((invocation) {
      final event = invocation.positionalArguments[0] as String;
      final handler =
          invocation.positionalArguments[1]
              as void Function(
                Object? data,
              );
      if (event == 'agents:command_response') {
        commandResponseHandler = handler;
      }
      return () {};
    });
    when(() => rawSocket.emit(any<String>(), any<Object?>())).thenReturn(null);

    dispatcher = SocketCommandDispatcherImpl(
      connection: connection,
      correlator: correlator,
    );
  });

  tearDown(() async {
    await dispatcher.dispose();
    await stateController.close();
  });

  Future<void> attachHandler() async {
    await Future<void>.delayed(Duration.zero);
    check(commandResponseHandler).isNotNull();
  }

  Future<void> waitForPendingCount(int expected) async {
    for (var attempt = 0; attempt < 20; attempt++) {
      await Future<void>.delayed(Duration.zero);
      if (correlator.pendingCount == expected) {
        return;
      }
    }
    fail(
      'expected $expected pending requests, got ${correlator.pendingCount}',
    );
  }

  group('SocketCommandDispatcherImpl decode fail-fast', () {
    group('PayloadFrameDecodeException', () {
      test(
        'fails sole pending with SocketDispatchDecodeFailure',
        () async {
          const rpcId = 'rpc-decode-sole';
          final future = dispatcher.sendAgentsCommand(
            agentId: 'agent-1',
            body: _body(rpcId: rpcId),
            rpcId: rpcId,
            timeout: const Duration(seconds: 2),
          );
          await attachHandler();

          final expectation = expectLater(
            future,
            throwsA(
              isA<SocketDispatchDecodeFailure>().having(
                (e) => e.message,
                'message',
                contains('PayloadFrame decode failed'),
              ),
            ),
          );
          commandResponseHandler!(_malformedPayloadFrame);
          await flushAgentsCommandRouting();
          await expectation;
        },
      );

      test(
        'fails every pending with SocketDispatchDecodeFailure',
        () async {
          final f1 = dispatcher.sendAgentsCommand(
            agentId: 'agent-1',
            body: _body(rpcId: 'rpc-decode-a'),
            rpcId: 'rpc-decode-a',
            timeout: const Duration(seconds: 2),
            coalesce: false,
          );
          final f2 = dispatcher.sendAgentsCommand(
            agentId: 'agent-1',
            body: _body(rpcId: 'rpc-decode-b', sql: 'SELECT 2'),
            rpcId: 'rpc-decode-b',
            timeout: const Duration(seconds: 2),
            coalesce: false,
          );
          await attachHandler();
          await waitForPendingCount(2);

          final e1 = expectLater(
            f1,
            throwsA(isA<SocketDispatchDecodeFailure>()),
          );
          final e2 = expectLater(
            f2,
            throwsA(isA<SocketDispatchDecodeFailure>()),
          );
          commandResponseHandler!(_malformedPayloadFrame);
          await flushAgentsCommandRouting();
          await Future.wait<void>(<Future<void>>[e1, e2]);
        },
      );
    });

    group('non-map payload', () {
      test(
        'fails sole pending with SocketDispatchDecodeFailure',
        () async {
          const rpcId = 'rpc-nonmap-sole';
          final future = dispatcher.sendAgentsCommand(
            agentId: 'agent-1',
            body: _body(rpcId: rpcId),
            rpcId: rpcId,
            timeout: const Duration(seconds: 2),
          );
          await attachHandler();

          final expectation = expectLater(
            future,
            throwsA(
              isA<SocketDispatchDecodeFailure>().having(
                (e) => e.message,
                'message',
                'agents:command_response is not a Map',
              ),
            ),
          );
          commandResponseHandler!('not-a-map');
          await flushAgentsCommandRouting();
          await expectation;
        },
      );

      test(
        'fails every pending with SocketDispatchDecodeFailure',
        () async {
          final f1 = dispatcher.sendAgentsCommand(
            agentId: 'agent-1',
            body: _body(rpcId: 'rpc-nonmap-a'),
            rpcId: 'rpc-nonmap-a',
            timeout: const Duration(seconds: 2),
            coalesce: false,
          );
          final f2 = dispatcher.sendAgentsCommand(
            agentId: 'agent-1',
            body: _body(rpcId: 'rpc-nonmap-b', sql: 'SELECT 2'),
            rpcId: 'rpc-nonmap-b',
            timeout: const Duration(seconds: 2),
            coalesce: false,
          );
          await attachHandler();
          await waitForPendingCount(2);

          final e1 = expectLater(
            f1,
            throwsA(isA<SocketDispatchDecodeFailure>()),
          );
          final e2 = expectLater(
            f2,
            throwsA(isA<SocketDispatchDecodeFailure>()),
          );
          commandResponseHandler!('not-a-map');
          await flushAgentsCommandRouting();
          await Future.wait<void>(<Future<void>>[e1, e2]);
        },
      );
    });

    group('missing rpcId', () {
      test(
        'fails sole pending with SocketDispatchDecodeFailure',
        () async {
          const rpcId = 'rpc-missing-sole';
          final future = dispatcher.sendAgentsCommand(
            agentId: 'agent-1',
            body: _body(rpcId: rpcId),
            rpcId: rpcId,
            timeout: const Duration(seconds: 2),
          );
          await attachHandler();

          final expectation = expectLater(
            future,
            throwsA(
              isA<SocketDispatchDecodeFailure>().having(
                (e) => e.message,
                'message',
                'agents:command_response missing rpcId',
              ),
            ),
          );
          commandResponseHandler!(
            <String, dynamic>{'uncorrelatable': true},
          );
          await flushAgentsCommandRouting();
          await expectation;
        },
      );

      test(
        'fails every pending with SocketDispatchDecodeFailure',
        () async {
          final f1 = dispatcher.sendAgentsCommand(
            agentId: 'agent-1',
            body: _body(rpcId: 'rpc-missing-a'),
            rpcId: 'rpc-missing-a',
            timeout: const Duration(seconds: 2),
            coalesce: false,
          );
          final f2 = dispatcher.sendAgentsCommand(
            agentId: 'agent-1',
            body: _body(rpcId: 'rpc-missing-b', sql: 'SELECT 2'),
            rpcId: 'rpc-missing-b',
            timeout: const Duration(seconds: 2),
            coalesce: false,
          );
          await attachHandler();
          await waitForPendingCount(2);

          final e1 = expectLater(
            f1,
            throwsA(isA<SocketDispatchDecodeFailure>()),
          );
          final e2 = expectLater(
            f2,
            throwsA(isA<SocketDispatchDecodeFailure>()),
          );
          commandResponseHandler!(
            <String, dynamic>{'uncorrelatable': true},
          );
          await flushAgentsCommandRouting();
          await Future.wait<void>(<Future<void>>[e1, e2]);
        },
      );
    });

    test('uncorrelatable decode with zero pendings is a no-op', () async {
      await attachHandler();

      commandResponseHandler!(_malformedPayloadFrame);
      await flushAgentsCommandRouting();

      check(correlator.pendingCount).equals(0);
    });
  });
}

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

  test(
    'agents:command_response with stream_id and empty rows fails the '
    'correlator with SocketDispatchLegacyStreamingUnsupported',
    () async {
      const rpcId = 'rpc-stream-1';
      final body = <String, Object?>{
        'agentId': 'agent-1',
        'command': <String, Object?>{
          'jsonrpc': '2.0',
          'method': 'sql.execute',
          'id': rpcId,
          'params': const <String, Object?>{'sql': 'SELECT 1'},
        },
      };

      final future = dispatcher.sendAgentsCommand(
        agentId: 'agent-1',
        body: body,
        rpcId: rpcId,
        timeout: const Duration(seconds: 2),
      );

      await Future<void>.delayed(Duration.zero);
      check(commandResponseHandler).isNotNull();

      commandResponseHandler!(
        <String, dynamic>{
          'rpcId': rpcId,
          'response': <String, dynamic>{
            'type': 'single',
            'success': true,
            'item': <String, dynamic>{
              'id': rpcId,
              'success': true,
              'result': <String, dynamic>{
                'stream_id': 'hub-stream-99',
                'rows': <Object?>[],
              },
            },
          },
        },
      );

      await expectLater(
        future,
        throwsA(isA<SocketDispatchLegacyStreamingUnsupported>()),
      );
    },
  );

  test(
    'agents:command_response with stream_id and non-empty rows still fails '
    'the correlator with SocketDispatchLegacyStreamingUnsupported',
    () async {
      const rpcId = 'rpc-stream-2';
      final body = <String, Object?>{
        'agentId': 'agent-1',
        'command': <String, Object?>{
          'jsonrpc': '2.0',
          'method': 'sql.execute',
          'id': rpcId,
          'params': const <String, Object?>{'sql': 'SELECT 1'},
        },
      };

      final future = dispatcher.sendAgentsCommand(
        agentId: 'agent-1',
        body: body,
        rpcId: rpcId,
        timeout: const Duration(seconds: 2),
      );

      await Future<void>.delayed(Duration.zero);
      check(commandResponseHandler).isNotNull();

      commandResponseHandler!(
        <String, dynamic>{
          'rpcId': rpcId,
          'response': <String, dynamic>{
            'type': 'single',
            'success': true,
            'item': <String, dynamic>{
              'id': rpcId,
              'success': true,
              'result': <String, dynamic>{
                'stream_id': 'hub-stream-partial',
                'rows': <Object?>[
                  <String, Object?>{'n': 1},
                ],
              },
            },
          },
        },
      );

      await expectLater(
        future,
        throwsA(isA<SocketDispatchLegacyStreamingUnsupported>()),
      );
    },
  );

  test(
    'agents:command_response correlates when only top-level JSON-RPC id is '
    'present (hub batch / plug-style envelope)',
    () async {
      const rpcId = 'rpc-jsonrpc-id-only';
      final body = <String, Object?>{
        'agentId': 'agent-1',
        'command': <String, Object?>{
          'jsonrpc': '2.0',
          'method': 'sql.executeBatch',
          'id': rpcId,
          'params': const <String, Object?>{
            'commands': <Map<String, Object?>>[
              <String, Object?>{'sql': 'SELECT 1'},
            ],
          },
        },
      };

      final future = dispatcher.sendAgentsCommand(
        agentId: 'agent-1',
        body: body,
        rpcId: rpcId,
        timeout: const Duration(seconds: 2),
      );

      await Future<void>.delayed(Duration.zero);
      check(commandResponseHandler).isNotNull();

      final expected = <String, dynamic>{
        'mode': 'bridge',
        'agentId': 'agent-1',
        'id': rpcId,
        'response': <String, dynamic>{
          'type': 'batch',
          'success': true,
          'items': <Object?>[
            <String, dynamic>{
              'id': rpcId,
              'success': true,
              'result': <String, dynamic>{'rows': <Object?>[]},
            },
          ],
        },
      };

      commandResponseHandler!(expected);

      final got = await future;
      check(got).equals(expected);
    },
  );
}

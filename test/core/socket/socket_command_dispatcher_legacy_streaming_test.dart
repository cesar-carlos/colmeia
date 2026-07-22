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

  test(
    'agents:command_response correlates REST-parity sql.executeBatch envelope '
    'without wire ids when exactly one rpc is pending',
    () async {
      const rpcId = 'rpc-rest-parity-batch';
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

      final bridgeOnly = <String, dynamic>{
        'response': <String, dynamic>{
          'success': true,
          'item': <String, dynamic>{
            'success': true,
            'result': <String, dynamic>{
              'items': <Object?>[
                <String, dynamic>{
                  'index': 0,
                  'ok': true,
                  'rows': <Object?>[],
                  'row_count': 0,
                },
              ],
            },
          },
        },
      };

      commandResponseHandler!(bridgeOnly);

      final got = await future;
      check(got).equals(bridgeOnly);
    },
  );

  test(
    'agents:command_response accepts List payload wrapping the bridge map',
    () async {
      const rpcId = 'rpc-list-wrap';
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

      final inner = <String, dynamic>{
        'response': <String, dynamic>{
          'success': true,
          'item': <String, dynamic>{
            'success': true,
            'result': <String, dynamic>{
              'items': <Object?>[
                <String, dynamic>{
                  'index': 0,
                  'ok': true,
                  'rows': <Object?>[],
                  'row_count': 0,
                },
              ],
            },
          },
        },
      };

      commandResponseHandler!(<Object?>[inner]);

      final got = await future;
      check(got).equals(inner);
    },
  );

  test(
    'agents:command_response correlates sole pending sql.executeBatch when '
    'hub sends flat {success,error} envelope without response',
    () async {
      const rpcId = 'rpc-flat-success';
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

      final flat = <String, dynamic>{'success': true, 'error': null};
      commandResponseHandler!(flat);

      final got = await future;
      check(got).equals(flat);
    },
  );

  test(
    'flat top-level bridge failure fails sole pending sql.executeBatch rpc',
    () async {
      const rpcId = 'rpc-flat-fail';
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

      commandResponseHandler!(
        <String, dynamic>{
          'success': false,
          'error': <String, dynamic>{
            'code': -32001,
            'message': 'nope',
          },
        },
      );

      await expectLater(future, throwsA(isA<SocketDispatchAppError>()));
    },
  );

  test(
    'agents:command_response success:false with requestId fails pending '
    'and surfaces retryAfterMs (overload shed)',
    () async {
      const rpcId = 'rpc-overload-1';
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
          'success': false,
          'requestId': rpcId,
          'error': <String, dynamic>{
            'code': 'SERVICE_UNAVAILABLE',
            'message': 'Consumer namespace temporarily overloaded',
            'statusCode': 503,
            'retryAfterMs': 800,
          },
        },
      );

      await expectLater(
        future,
        throwsA(
          isA<SocketDispatchAppError>()
              .having((e) => e.code, 'code', 'SERVICE_UNAVAILABLE')
              .having(
                (e) => e.retryAfter,
                'retryAfter',
                const Duration(milliseconds: 800),
              ),
        ),
      );
    },
  );
}

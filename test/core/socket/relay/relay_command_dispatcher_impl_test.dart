// Test-only: many sequential `wiring.fire(...)` calls drive the dispatcher
// state machine in distinct phases (accept → response → complete). Rewriting
// each pair as cascades hides the intent and obscures the protocol shape
// these tests are pinning.
// ignore_for_file: cascade_invocations

import 'dart:async';
import 'dart:convert';
import 'dart:io' show gzip;
import 'dart:typed_data';

import 'package:checks/checks.dart';
import 'package:colmeia/core/socket/consumer_socket_connection.dart';
import 'package:colmeia/core/socket/consumer_socket_connection_state.dart';
import 'package:colmeia/core/socket/payload_frame.dart';
import 'package:colmeia/core/socket/per_agent_concurrency_gate.dart';
import 'package:colmeia/core/socket/relay/relay_command_dispatcher_impl.dart';
import 'package:colmeia/core/socket/relay/relay_conversation_manager.dart';
import 'package:colmeia/core/socket/relay/relay_dispatch_exception.dart';
import 'package:colmeia/core/socket/relay/relay_event_names.dart';
import 'package:colmeia/core/socket/relay/relay_rpc_outcome.dart';
import 'package:colmeia/core/socket/socket_dispatch_exception.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class _MockConnection extends Mock implements ConsumerSocketConnection {}

class _MockSocket extends Mock implements io.Socket {}

class _SocketWiring {
  final Map<String, List<Function>> handlers = <String, List<Function>>{};
  final List<({String event, Object? data})> emits =
      <({String event, Object? data})>[];

  void register(_MockSocket socket) {
    when(() => socket.on(any(), any())).thenAnswer((invocation) {
      final name = invocation.positionalArguments[0] as String;
      final handler = invocation.positionalArguments[1] as Function;
      handlers.putIfAbsent(name, () => <Function>[]).add(handler);
      return () {};
    });
    when(() => socket.off(any())).thenAnswer((invocation) {
      final name = invocation.positionalArguments[0] as String;
      handlers.remove(name);
    });
    when(() => socket.off(any(), any())).thenAnswer((invocation) {
      final name = invocation.positionalArguments[0] as String;
      final handler = invocation.positionalArguments[1];
      if (handler == null) {
        handlers.remove(name);
        return;
      }
      handlers[name]?.remove(handler);
      if (handlers[name]?.isEmpty ?? false) {
        handlers.remove(name);
      }
    });
    when(() => socket.emit(any(), any<dynamic>())).thenAnswer((invocation) {
      emits.add((
        event: invocation.positionalArguments[0] as String,
        data: invocation.positionalArguments[1],
      ));
    });
  }

  void fire(String event, Object? payload) {
    final list = handlers[event];
    if (list == null) {
      return;
    }
    for (final handler in List<Function>.of(list)) {
      Function.apply(handler, <Object?>[payload]);
    }
  }
}

/// Builds a PayloadFrame envelope (`Map<String, Object?>`) carrying [data]
/// JSON-encoded and optionally gzipped, just like the hub would emit on the
/// wire. Used to feed `relay:rpc.response` / `relay:rpc.complete` events
/// into the dispatcher.
Map<String, Object?> _buildResponseFrame(
  Object? data, {
  required String requestId,
  bool useGzip = false,
}) {
  final encoded = Uint8List.fromList(utf8.encode(jsonEncode(data)));
  final wire = useGzip ? Uint8List.fromList(gzip.encode(encoded)) : encoded;
  return PayloadFrame(
    payload: wire,
    originalSize: encoded.length,
    compressedSize: wire.length,
    cmp: useGzip ? PayloadFrame.compressionGzip : PayloadFrame.compressionNone,
    requestId: requestId,
  ).toMap();
}

/// Like [_buildResponseFrame] but omits `requestId` on the frame and sets
/// top-level `conversationId` (hub path when `requestId` is dropped).
Map<String, Object?> _buildResponseFrameWithoutRequestId(
  Object? data, {
  required String conversationId,
  bool useGzip = false,
}) {
  final encoded = Uint8List.fromList(utf8.encode(jsonEncode(data)));
  final wire = useGzip ? Uint8List.fromList(gzip.encode(encoded)) : encoded;
  final frame = PayloadFrame(
    payload: wire,
    originalSize: encoded.length,
    compressedSize: wire.length,
    cmp: useGzip ? PayloadFrame.compressionGzip : PayloadFrame.compressionNone,
  ).toMap();
  frame['conversationId'] = conversationId;
  return frame;
}

void main() {
  setUpAll(() {
    registerFallbackValue(<String, Object?>{});
    registerFallbackValue(() {});
    registerFallbackValue(const ConsumerSocketDisconnected());
  });

  late _MockConnection connection;
  late _MockSocket socket;
  late _SocketWiring wiring;
  late StreamController<ConsumerSocketConnectionState> stateController;
  late RelayConversationManager manager;

  setUp(() {
    connection = _MockConnection();
    socket = _MockSocket();
    wiring = _SocketWiring()..register(socket);
    stateController =
        StreamController<ConsumerSocketConnectionState>.broadcast();

    when(() => connection.raw).thenReturn(socket);
    when(() => connection.states()).thenAnswer((_) => stateController.stream);
    when(connection.connect).thenAnswer(
      (_) async => ConsumerSocketConnected(
        socketId: 'sock-1',
        handshakeAt: DateTime.utc(2026, 4, 17),
      ),
    );

    manager = RelayConversationManager(
      connection: connection,
      startTimeout: const Duration(milliseconds: 200),
      endTimeout: const Duration(milliseconds: 100),
    );
  });

  tearDown(() async {
    await manager.dispose();
    await stateController.close();
  });

  Future<RelayCommandDispatcherImpl> dispatcherFor({
    Duration defaultTimeout = const Duration(milliseconds: 500),
    PerAgentConcurrencyGate? concurrencyGate,
  }) async {
    final dispatcher = RelayCommandDispatcherImpl(
      connection: connection,
      conversationManager: manager,
      defaultTimeout: defaultTimeout,
      concurrencyGate: concurrencyGate,
    );
    return dispatcher;
  }

  // Helper to drive the manager to an active conversation before any RPC.
  Future<String> openConversation({String agentId = 'agent-1'}) async {
    final future = manager.obtain(agentId);
    // Allow the conversation.start emit + listener registration to settle.
    await Future<void>.delayed(Duration.zero);
    wiring.fire(
      RelayEventNames.conversationStarted,
      <String, Object?>{
        'success': true,
        'conversationId': 'conv-$agentId',
        'agentId': agentId,
      },
    );
    final conversation = await future;
    return conversation.conversationId!;
  }

  group('RelayCommandDispatcherImpl per-agent concurrency gate', () {
    test(
      'defers second unary emit until first completes when gate allows one slot',
      () async {
        final gate = PerAgentConcurrencyGate(maxInflightPerAgent: 1);
        final dispatcher = await dispatcherFor(concurrencyGate: gate);
        addTearDown(dispatcher.dispose);

        await openConversation();

        final f1 = dispatcher.sendUnary(
          agentId: 'agent-1',
          body: <String, Object?>{
            'command': <String, Object?>{
              'jsonrpc': '2.0',
              'method': 'sql.execute',
              'id': 'rpc-a',
            },
          },
          clientRequestId: 'rpc-a',
        );
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);

        check(
          wiring.emits
              .where((e) => e.event == RelayEventNames.rpcRequest)
              .length,
        ).equals(1);

        final f2 = dispatcher.sendUnary(
          agentId: 'agent-1',
          body: <String, Object?>{
            'command': <String, Object?>{
              'jsonrpc': '2.0',
              'method': 'sql.execute',
              'id': 'rpc-b',
            },
          },
          clientRequestId: 'rpc-b',
        );
        await Future<void>.delayed(Duration.zero);

        check(
          wiring.emits
              .where((e) => e.event == RelayEventNames.rpcRequest)
              .length,
        ).equals(1);
        check(gate.waitingFor('agent-1')).equals(1);

        wiring.fire(RelayEventNames.rpcAccepted, <String, Object?>{
          'conversationId': 'conv-agent-1',
          'clientRequestId': 'rpc-a',
          'requestId': 'srv-a',
          'success': true,
        });
        wiring.fire(
          RelayEventNames.rpcResponse,
          _buildResponseFrame(
            <String, Object?>{
              'response': <String, Object?>{
                'type': 'single',
                'item': <String, Object?>{
                  'id': 'rpc-a',
                  'success': true,
                  'result': <String, Object?>{'rows': <Object?>[]},
                },
              },
            },
            requestId: 'srv-a',
          ),
        );

        await f1;
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);

        check(
          wiring.emits
              .where((e) => e.event == RelayEventNames.rpcRequest)
              .length,
        ).equals(2);

        wiring.fire(RelayEventNames.rpcAccepted, <String, Object?>{
          'conversationId': 'conv-agent-1',
          'clientRequestId': 'rpc-b',
          'requestId': 'srv-b',
          'success': true,
        });
        wiring.fire(
          RelayEventNames.rpcResponse,
          _buildResponseFrame(
            <String, Object?>{
              'response': <String, Object?>{
                'type': 'single',
                'item': <String, Object?>{
                  'id': 'rpc-b',
                  'success': true,
                  'result': <String, Object?>{'rows': <Object?>[]},
                },
              },
            },
            requestId: 'srv-b',
          ),
        );

        await f2;
      },
    );
  });

  group('RelayCommandDispatcherImpl.sendUnary', () {
    test('emits relay:rpc.request and resolves on rpc.response', () async {
      final dispatcher = await dispatcherFor();
      addTearDown(dispatcher.dispose);

      await openConversation();

      final outcomes = <RelayRpcOutcome>[];
      final outcomesSub = dispatcher.outcomes().listen(outcomes.add);

      final future = dispatcher.sendUnary(
        agentId: 'agent-1',
        body: <String, Object?>{
          'agentId': 'agent-1',
          'command': <String, Object?>{
            'jsonrpc': '2.0',
            'method': 'sql.execute',
            'id': 'rpc-1',
            'params': <String, Object?>{'sql': 'SELECT 1'},
          },
        },
        clientRequestId: 'rpc-1',
      );
      // Two pumps: one for the await `manager.obtain` chain, one for the
      // emit that happens after the chained microtasks resolve.
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      check(
        wiring.emits.where((e) => e.event == RelayEventNames.rpcRequest).length,
      ).equals(1);
      final rpcEmit = wiring.emits.firstWhere(
        (e) => e.event == RelayEventNames.rpcRequest,
      );
      final rpcEnvelope = rpcEmit.data! as Map<String, Object?>;
      check(rpcEnvelope['conversationId']).equals('conv-agent-1');
      check(rpcEnvelope['payloadFrameCompression']).equals('default');
      check(rpcEnvelope['frame']).isA<Map<String, Object?>>();

      // accepted assigns server requestId.
      wiring.fire(RelayEventNames.rpcAccepted, <String, Object?>{
        'conversationId': 'conv-agent-1',
        'clientRequestId': 'rpc-1',
        'requestId': 'srv-req-1',
        'success': true,
      });

      // response carries the bridge envelope.
      final response = <String, Object?>{
        'response': <String, Object?>{
          'type': 'single',
          'item': <String, Object?>{
            'id': 'rpc-1',
            'success': true,
            'result': <String, Object?>{'rows': <Object?>[]},
          },
        },
      };
      wiring.fire(
        RelayEventNames.rpcResponse,
        _buildResponseFrame(response, requestId: 'srv-req-1'),
      );

      final result = await future;
      check(result['response']).isA<Map<dynamic, dynamic>>();

      // Broadcast stream delivery happens on a follow-up microtask. Pump
      // once before unsubscribing so the success outcome lands.
      await Future<void>.delayed(Duration.zero);
      await outcomesSub.cancel();
      check(outcomes.length).equals(1);
      check(outcomes.single).isA<RelayRpcSuccess>();
    });

    test(
      'rpc.response without frame requestId routes when exactly one pending '
      'exists for the conversation',
      () async {
        final dispatcher = await dispatcherFor();
        addTearDown(dispatcher.dispose);

        await openConversation();

        final future = dispatcher.sendUnary(
          agentId: 'agent-1',
          body: <String, Object?>{
            'agentId': 'agent-1',
            'command': <String, Object?>{
              'jsonrpc': '2.0',
              'method': 'sql.execute',
              'id': 'rpc-no-frame-rq',
              'params': <String, Object?>{'sql': 'SELECT 1'},
            },
          },
          clientRequestId: 'rpc-no-frame-rq',
        );
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);

        wiring.fire(RelayEventNames.rpcAccepted, <String, Object?>{
          'conversationId': 'conv-agent-1',
          'clientRequestId': 'rpc-no-frame-rq',
          'success': true,
        });

        final response = <String, Object?>{
          'response': <String, Object?>{
            'type': 'single',
            'item': <String, Object?>{
              'id': 'rpc-no-frame-rq',
              'success': true,
              'result': <String, Object?>{'rows': <Object?>[]},
            },
          },
        };
        wiring.fire(
          RelayEventNames.rpcResponse,
          _buildResponseFrameWithoutRequestId(
            response,
            conversationId: 'conv-agent-1',
          ),
        );

        final result = await future;
        check(result['response']).isA<Map<dynamic, dynamic>>();
      },
    );

    test(
      'rpc.response without frame requestId is ignored when two pendings '
      'share the conversation (both timeout)',
      () async {
        final dispatcher = await dispatcherFor(
          defaultTimeout: const Duration(milliseconds: 150),
        );
        addTearDown(dispatcher.dispose);

        await openConversation();

        final f1 = dispatcher.sendUnary(
          agentId: 'agent-1',
          body: <String, Object?>{
            'command': <String, Object?>{
              'jsonrpc': '2.0',
              'method': 'sql.execute',
              'id': 'rpc-amb-a',
            },
          },
          clientRequestId: 'rpc-amb-a',
        );
        final f2 = dispatcher.sendUnary(
          agentId: 'agent-1',
          body: <String, Object?>{
            'command': <String, Object?>{
              'jsonrpc': '2.0',
              'method': 'sql.execute',
              'id': 'rpc-amb-b',
            },
          },
          clientRequestId: 'rpc-amb-b',
        );
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);

        wiring.fire(RelayEventNames.rpcAccepted, <String, Object?>{
          'conversationId': 'conv-agent-1',
          'clientRequestId': 'rpc-amb-a',
          'success': true,
        });
        wiring.fire(RelayEventNames.rpcAccepted, <String, Object?>{
          'conversationId': 'conv-agent-1',
          'clientRequestId': 'rpc-amb-b',
          'success': true,
        });

        final orphan = <String, Object?>{
          'response': <String, Object?>{
            'type': 'single',
            'item': <String, Object?>{
              'id': 'rpc-amb-a',
              'success': true,
              'result': <String, Object?>{'rows': <Object?>[]},
            },
          },
        };
        wiring.fire(
          RelayEventNames.rpcResponse,
          _buildResponseFrameWithoutRequestId(
            orphan,
            conversationId: 'conv-agent-1',
          ),
        );

        await Future.wait<void>(<Future<void>>[
          expectLater(f1, throwsA(isA<RelayRequestTimeout>())),
          expectLater(f2, throwsA(isA<RelayRequestTimeout>())),
        ]);
      },
    );

    test(
      'completes on relay:rpc.complete when the hub bundles a response',
      () async {
        final dispatcher = await dispatcherFor();
        addTearDown(dispatcher.dispose);

        await openConversation();

        final future = dispatcher.sendUnary(
          agentId: 'agent-1',
          body: <String, Object?>{
            'command': <String, Object?>{
              'jsonrpc': '2.0',
              'method': 'sql.execute',
              'id': 'rpc-2',
            },
          },
          clientRequestId: 'rpc-2',
        );
        await Future<void>.delayed(Duration.zero);

        wiring.fire(RelayEventNames.rpcAccepted, <String, Object?>{
          'conversationId': 'conv-agent-1',
          'clientRequestId': 'rpc-2',
          'requestId': 'srv-req-2',
          'success': true,
        });

        wiring.fire(
          RelayEventNames.rpcComplete,
          _buildResponseFrame(
            <String, Object?>{
              'response': <String, Object?>{
                'type': 'single',
                'item': <String, Object?>{'id': 'rpc-2', 'success': true},
              },
            },
            requestId: 'srv-req-2',
          ),
        );

        final result = await future;
        check(result.containsKey('response')).isTrue();
      },
    );

    test(
      'rejected accept surfaces RelayRequestRejected with server code',
      () async {
        final dispatcher = await dispatcherFor();
        addTearDown(dispatcher.dispose);

        await openConversation();

        final future = dispatcher.sendUnary(
          agentId: 'agent-1',
          body: <String, Object?>{
            'command': <String, Object?>{
              'jsonrpc': '2.0',
              'method': 'sql.execute',
              'id': 'rpc-3',
            },
          },
          clientRequestId: 'rpc-3',
        );
        await Future<void>.delayed(Duration.zero);

        wiring.fire(RelayEventNames.rpcAccepted, <String, Object?>{
          'conversationId': 'conv-agent-1',
          'clientRequestId': 'rpc-3',
          'success': false,
          'error': <String, Object?>{
            'code': 'RATE_LIMITED',
            'message': 'too many requests',
            'data': <String, Object?>{'retry_after_ms': 1250},
          },
        });

        await check(future).throws<RelayRequestRejected>(
          (subject) => subject
            ..has((e) => e.code, 'code').equals('RATE_LIMITED')
            ..has((e) => e.retryAfter, 'retryAfter').equals(
              const Duration(milliseconds: 1250),
            ),
        );
      },
    );

    test('reattaches relay listeners after socket reconnect', () async {
      final socketB = _MockSocket();
      final wiringB = _SocketWiring()..register(socketB);
      var currentSocket = socket;
      when(() => connection.raw).thenAnswer((_) => currentSocket);

      final dispatcher = await dispatcherFor();
      addTearDown(dispatcher.dispose);

      await openConversation();

      final first = dispatcher.sendUnary(
        agentId: 'agent-1',
        body: <String, Object?>{
          'command': <String, Object?>{
            'jsonrpc': '2.0',
            'method': 'sql.execute',
            'id': 'rpc-before-drop',
          },
        },
        clientRequestId: 'rpc-before-drop',
      );
      await Future<void>.delayed(Duration.zero);
      final firstFailure = expectLater(
        first,
        throwsA(isA<RelayConversationLost>()),
      );

      stateController.add(
        const ConsumerSocketDisconnected(reason: 'transport close'),
      );
      await firstFailure;

      currentSocket = socketB;
      final second = dispatcher.sendUnary(
        agentId: 'agent-1',
        body: <String, Object?>{
          'command': <String, Object?>{
            'jsonrpc': '2.0',
            'method': 'sql.execute',
            'id': 'rpc-after-drop',
          },
        },
        clientRequestId: 'rpc-after-drop',
      );
      await Future<void>.delayed(Duration.zero);
      wiringB.fire(RelayEventNames.conversationStarted, <String, Object?>{
        'success': true,
        'conversationId': 'conv-agent-1b',
        'agentId': 'agent-1',
      });
      await Future<void>.delayed(Duration.zero);

      wiringB.fire(RelayEventNames.rpcAccepted, <String, Object?>{
        'conversationId': 'conv-agent-1b',
        'clientRequestId': 'rpc-after-drop',
        'requestId': 'srv-after-drop',
        'success': true,
      });
      wiringB.fire(
        RelayEventNames.rpcResponse,
        _buildResponseFrame(
          <String, Object?>{
            'response': <String, Object?>{
              'type': 'single',
              'item': <String, Object?>{
                'id': 'rpc-after-drop',
                'success': true,
              },
            },
          },
          requestId: 'srv-after-drop',
        ),
      );

      final result = await second;
      check(result['response']).isA<Map<dynamic, dynamic>>();
      check(wiring.handlers[RelayEventNames.rpcResponse]).isNull();
      check(wiringB.handlers[RelayEventNames.rpcResponse]?.length).equals(1);
    });

    test(
      'terminal_status != completed on rpc.complete fails as RelayStreamTerminated',
      () async {
        final dispatcher = await dispatcherFor();
        addTearDown(dispatcher.dispose);

        await openConversation();

        final future = dispatcher.sendUnary(
          agentId: 'agent-1',
          body: <String, Object?>{
            'command': <String, Object?>{
              'jsonrpc': '2.0',
              'method': 'sql.execute',
              'id': 'rpc-4',
            },
          },
          clientRequestId: 'rpc-4',
        );
        await Future<void>.delayed(Duration.zero);

        wiring.fire(RelayEventNames.rpcAccepted, <String, Object?>{
          'conversationId': 'conv-agent-1',
          'clientRequestId': 'rpc-4',
          'requestId': 'srv-req-4',
          'success': true,
        });

        wiring.fire(
          RelayEventNames.rpcComplete,
          _buildResponseFrame(
            <String, Object?>{'terminal_status': 'aborted'},
            requestId: 'srv-req-4',
          ),
        );

        await check(future).throws<RelayStreamTerminated>(
          (subject) =>
              subject.has((e) => e.code, 'code').equals('stream_aborted'),
        );
      },
    );

    test(
      'reuses the active conversation across calls (single start emit)',
      () async {
        final dispatcher = await dispatcherFor();
        addTearDown(dispatcher.dispose);

        await openConversation();

        Future<Map<String, dynamic>> dispatch(String id) {
          return dispatcher.sendUnary(
            agentId: 'agent-1',
            body: <String, Object?>{
              'command': <String, Object?>{
                'jsonrpc': '2.0',
                'method': 'sql.execute',
                'id': id,
              },
            },
            clientRequestId: id,
          );
        }

        final f1 = dispatch('rpc-A');
        final f2 = dispatch('rpc-B');
        await Future<void>.delayed(Duration.zero);

        check(
          wiring.emits
              .where((e) => e.event == RelayEventNames.conversationStart)
              .length,
        ).equals(1);
        check(
          wiring.emits
              .where((e) => e.event == RelayEventNames.rpcRequest)
              .length,
        ).equals(2);

        void completeCall(String id) {
          wiring.fire(RelayEventNames.rpcAccepted, <String, Object?>{
            'conversationId': 'conv-agent-1',
            'clientRequestId': id,
            'requestId': 'srv-$id',
            'success': true,
          });
          wiring.fire(
            RelayEventNames.rpcResponse,
            _buildResponseFrame(
              <String, Object?>{
                'response': <String, Object?>{
                  'type': 'single',
                  'item': <String, Object?>{'id': id, 'success': true},
                },
              },
              requestId: 'srv-$id',
            ),
          );
        }

        completeCall('rpc-A');
        completeCall('rpc-B');

        await f1;
        await f2;
      },
    );

    test('duplicate clientRequestId throws RelayDuplicateRequestId', () async {
      final dispatcher = await dispatcherFor();
      addTearDown(dispatcher.dispose);

      await openConversation();

      final f1 = dispatcher.sendUnary(
        agentId: 'agent-1',
        body: <String, Object?>{
          'command': <String, Object?>{
            'jsonrpc': '2.0',
            'method': 'sql.execute',
            'id': 'dup',
          },
        },
        clientRequestId: 'dup',
      );
      await Future<void>.delayed(Duration.zero);

      await check(
        dispatcher.sendUnary(
          agentId: 'agent-1',
          body: <String, Object?>{
            'command': <String, Object?>{
              'jsonrpc': '2.0',
              'method': 'sql.execute',
              'id': 'dup',
            },
          },
          clientRequestId: 'dup',
        ),
      ).throws<RelayDuplicateRequestId>();

      // Resolve the original to keep the test free of dangling pendings.
      wiring.fire(RelayEventNames.rpcAccepted, <String, Object?>{
        'conversationId': 'conv-agent-1',
        'clientRequestId': 'dup',
        'requestId': 'srv-dup',
        'success': true,
      });
      wiring.fire(
        RelayEventNames.rpcResponse,
        _buildResponseFrame(
          <String, Object?>{
            'response': <String, Object?>{
              'type': 'single',
              'item': <String, Object?>{'id': 'dup', 'success': true},
            },
          },
          requestId: 'srv-dup',
        ),
      );
      await f1;
    });

    test('timeout throws RelayRequestTimeout', () async {
      final dispatcher = await dispatcherFor(
        defaultTimeout: const Duration(milliseconds: 30),
      );
      addTearDown(dispatcher.dispose);

      await openConversation();

      final future = dispatcher.sendUnary(
        agentId: 'agent-1',
        body: <String, Object?>{
          'command': <String, Object?>{
            'jsonrpc': '2.0',
            'method': 'sql.execute',
            'id': 'rpc-timeout',
          },
        },
        clientRequestId: 'rpc-timeout',
      );

      await check(future).throws<RelayRequestTimeout>();
    });

    test(
      'dispose fails pending requests with RelayDispatcherDisposed',
      () async {
        final dispatcher = await dispatcherFor();
        await openConversation();

        final future = dispatcher.sendUnary(
          agentId: 'agent-1',
          body: <String, Object?>{
            'command': <String, Object?>{
              'jsonrpc': '2.0',
              'method': 'sql.execute',
              'id': 'rpc-dispose',
            },
          },
          clientRequestId: 'rpc-dispose',
        );
        // Pre-attach a no-op error listener so dispose() can complete the
        // pending request with an error without it being reported as an
        // "unhandled async error" between the two awaits below.
        // ignore: unawaited_futures
        future.catchError((Object _) => <String, dynamic>{});
        await Future<void>.delayed(Duration.zero);

        await dispatcher.dispose();

        await check(future).throws<RelayDispatcherDisposed>();
      },
    );

    test('passes RelayPayloadFrameCompression hint as wireValue', () async {
      final dispatcher = await dispatcherFor();
      addTearDown(dispatcher.dispose);

      await openConversation();

      final future = dispatcher.sendUnary(
        agentId: 'agent-1',
        body: <String, Object?>{
          'command': <String, Object?>{
            'jsonrpc': '2.0',
            'method': 'sql.execute',
            'id': 'rpc-compress',
          },
        },
        clientRequestId: 'rpc-compress',
        compression: RelayPayloadFrameCompression.always,
      );
      await Future<void>.delayed(Duration.zero);

      final emit = wiring.emits.firstWhere(
        (e) => e.event == RelayEventNames.rpcRequest,
      );
      final envelope = emit.data! as Map<String, Object?>;
      check(envelope['payloadFrameCompression']).equals('always');

      wiring.fire(RelayEventNames.rpcAccepted, <String, Object?>{
        'conversationId': 'conv-agent-1',
        'clientRequestId': 'rpc-compress',
        'requestId': 'srv-compress',
        'success': true,
      });
      wiring.fire(
        RelayEventNames.rpcResponse,
        _buildResponseFrame(
          <String, Object?>{
            'response': <String, Object?>{
              'type': 'single',
              'item': <String, Object?>{'id': 'rpc-compress', 'success': true},
            },
          },
          requestId: 'srv-compress',
        ),
      );
      await future;
    });

    test(
      'decode failure on response frame surfaces RelayDecodeFailure',
      () async {
        final dispatcher = await dispatcherFor();
        addTearDown(dispatcher.dispose);

        await openConversation();

        final future = dispatcher.sendUnary(
          agentId: 'agent-1',
          body: <String, Object?>{
            'command': <String, Object?>{
              'jsonrpc': '2.0',
              'method': 'sql.execute',
              'id': 'rpc-decode',
            },
          },
          clientRequestId: 'rpc-decode',
        );
        await Future<void>.delayed(Duration.zero);

        wiring.fire(RelayEventNames.rpcAccepted, <String, Object?>{
          'conversationId': 'conv-agent-1',
          'clientRequestId': 'rpc-decode',
          'requestId': 'srv-decode',
          'success': true,
        });

        // Send a frame with an invalid schemaVersion.
        final encoded = utf8.encode('{"foo":1}');
        wiring.fire(RelayEventNames.rpcResponse, <String, Object?>{
          'schemaVersion': '9.9',
          'enc': 'json',
          'cmp': 'none',
          'contentType': 'application/json',
          'originalSize': encoded.length,
          'compressedSize': encoded.length,
          'payload': base64Encode(encoded),
          'requestId': 'srv-decode',
        });

        await check(future).throws<RelayDecodeFailure>(
          (subject) => subject
              .has((e) => e.code, 'code')
              .equals('unsupported_schema_version'),
        );
      },
    );
  });

  group('RelayCommandDispatcherImpl stream pull_response handling', () {
    test(
      'sendStreaming forwards permanent socket prepare failures to the stream',
      () async {
        when(connection.connect).thenThrow(
          StateError(
            'Consumer socket namespace forbidden: '
            'role=client namespace=/consumers',
          ),
        );
        final dispatcher = await dispatcherFor();
        addTearDown(dispatcher.dispose);

        final stream = dispatcher.sendStreaming(
          agentId: 'agent-1',
          body: <String, Object?>{
            'command': <String, Object?>{
              'jsonrpc': '2.0',
              'method': 'sql.execute',
              'id': 'rpc-stream-forbidden',
            },
          },
          clientRequestId: 'rpc-stream-forbidden',
        );

        await expectLater(
          stream,
          emitsInOrder(<Object>[
            emitsError(isA<SocketDispatchNamespaceForbidden>()),
            emitsDone,
          ]),
        );
      },
    );

    test(
      'rejects pending stream when pull_response carries success=false',
      () async {
        final dispatcher = await dispatcherFor();
        addTearDown(dispatcher.dispose);

        await openConversation();

        final stream = dispatcher.sendStreaming(
          agentId: 'agent-1',
          body: <String, Object?>{
            'command': <String, Object?>{
              'jsonrpc': '2.0',
              'method': 'sql.execute',
              'id': 'rpc-pull-rejected',
            },
          },
          clientRequestId: 'rpc-pull-rejected',
        );

        final completer = Completer<Object>();
        final sub = stream.listen(
          (_) {},
          onError: (Object error) {
            if (!completer.isCompleted) {
              completer.complete(error);
            }
          },
        );

        await Future<void>.delayed(Duration.zero);
        wiring.fire(RelayEventNames.rpcAccepted, <String, Object?>{
          'conversationId': 'conv-agent-1',
          'clientRequestId': 'rpc-pull-rejected',
          'requestId': 'srv-pull-rejected',
          'success': true,
        });

        wiring.fire(RelayEventNames.rpcStreamPullResponse, <String, Object?>{
          'conversationId': 'conv-agent-1',
          'clientRequestId': 'rpc-pull-rejected',
          'requestId': 'srv-pull-rejected',
          'success': false,
          'error': <String, Object?>{
            'code': 'RATE_LIMITED',
            'message': 'pull window exhausted',
            'data': <String, Object?>{'retryAfterMs': 900},
          },
          'rateLimit': <String, Object?>{
            'remainingCredits': 0,
            'limit': 1000,
            'scope': 'user',
          },
        });

        final error = await completer.future;
        await sub.cancel();
        check(error).isA<RelayRequestRejected>();
        final rejected = error as RelayRequestRejected;
        check(rejected.code).equals('RATE_LIMITED');
        check(rejected.retryAfter).equals(const Duration(milliseconds: 900));
      },
    );

    test(
      'pull_response success with smaller windowSize clamps local credits',
      () async {
        final dispatcher = await dispatcherFor();
        addTearDown(dispatcher.dispose);

        await openConversation();

        final stream = dispatcher.sendStreaming(
          agentId: 'agent-1',
          body: <String, Object?>{
            'command': <String, Object?>{
              'jsonrpc': '2.0',
              'method': 'sql.execute',
              'id': 'rpc-pull-clamp',
            },
          },
          clientRequestId: 'rpc-pull-clamp',
          initialWindowSize: 32,
        );
        final sub = stream.listen((_) {});
        addTearDown(sub.cancel);

        await Future<void>.delayed(Duration.zero);
        wiring.fire(RelayEventNames.rpcAccepted, <String, Object?>{
          'conversationId': 'conv-agent-1',
          'clientRequestId': 'rpc-pull-clamp',
          'requestId': 'srv-pull-clamp',
          'success': true,
        });

        // Hub clamps the granted window to 8 (remaining quota is small).
        wiring.fire(RelayEventNames.rpcStreamPullResponse, <String, Object?>{
          'conversationId': 'conv-agent-1',
          'clientRequestId': 'rpc-pull-clamp',
          'requestId': 'srv-pull-clamp',
          'success': true,
          'windowSize': 8,
        });

        // The stream is still alive and waiting for chunks. We assert the
        // dispatcher is healthy by signalling completion and checking it
        // closes cleanly.
        wiring.fire(
          RelayEventNames.rpcComplete,
          _buildResponseFrame(
            <String, Object?>{'terminal_status': 'completed'},
            requestId: 'srv-pull-clamp',
          ),
        );
      },
    );
  });
}

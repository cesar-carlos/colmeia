// Test-only: many sequential `wiring.fire(...)` calls drive the dispatcher
// through distinct stream phases (accept → chunks → complete). Cascades
// would obscure the protocol shape these tests are pinning.
// ignore_for_file: cascade_invocations

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:checks/checks.dart';
import 'package:colmeia/core/socket/consumer_socket_connection.dart';
import 'package:colmeia/core/socket/consumer_socket_connection_state.dart';
import 'package:colmeia/core/socket/payload_frame.dart';
import 'package:colmeia/core/socket/payload_frame_codec.dart';
import 'package:colmeia/core/socket/relay/relay_command_dispatcher_impl.dart';
import 'package:colmeia/core/socket/relay/relay_conversation_manager.dart';
import 'package:colmeia/core/socket/relay/relay_dispatch_exception.dart';
import 'package:colmeia/core/socket/relay/relay_event_names.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class _MockConnection extends Mock implements ConsumerSocketConnection {}

class _MockSocket extends Mock implements io.Socket {}

class _SocketWiring {
  final Map<String, List<Function>> handlers = <String, List<Function>>{};
  final List<({String event, Object? data})> emits =
      <({String event, Object? data})>[];
  String? throwOnEmitEvent;

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
      final event = invocation.positionalArguments[0] as String;
      final data = invocation.positionalArguments[1];
      if (event == throwOnEmitEvent) {
        throw StateError('emit failed for $event');
      }
      emits.add((event: event, data: data));
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
/// JSON-encoded as the wire format. Used to feed `relay:rpc.chunk` and
/// `relay:rpc.complete` events into the dispatcher.
Map<String, Object?> _frame(Object? data, {required String requestId}) {
  final encoded = Uint8List.fromList(utf8.encode(jsonEncode(data)));
  return PayloadFrame(
    payload: encoded,
    originalSize: encoded.length,
    compressedSize: encoded.length,
    requestId: requestId,
  ).toMap();
}

Map<String, dynamic> _decodePullPayload(Object? raw) {
  if (raw is! Map) {
    fail('Expected relay pull envelope Map, got $raw');
  }
  final envelope = raw.map(
    (key, value) => MapEntry<String, Object?>(key.toString(), value),
  );
  final frame = PayloadFrame.tryParse(envelope['frame']);
  check(frame).isNotNull();
  final decoded = const PayloadFrameCodec().decodeJson(frame!);
  if (decoded is! Map) {
    fail('Expected relay pull PayloadFrame Map, got $decoded');
  }
  return decoded.map(
    (key, value) => MapEntry<String, dynamic>(key.toString(), value),
  );
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

  Future<String> openConversation({String agentId = 'agent-1'}) async {
    final future = manager.obtain(agentId);
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

  RelayCommandDispatcherImpl buildDispatcher({
    Duration defaultTimeout = const Duration(milliseconds: 500),
    int initialWindow = 4,
    int refillThreshold = 2,
  }) {
    return RelayCommandDispatcherImpl(
      connection: connection,
      conversationManager: manager,
      defaultTimeout: defaultTimeout,
      defaultStreamInitialWindow: initialWindow,
      defaultStreamRefillThreshold: refillThreshold,
    );
  }

  group('RelayCommandDispatcherImpl.sendStreaming', () {
    test(
      'emits relay:rpc.request once + initial pull on accept + chunks land in '
      'the stream + complete closes normally',
      () async {
        final dispatcher = buildDispatcher();
        addTearDown(dispatcher.dispose);

        await openConversation();

        final stream = dispatcher.sendStreaming(
          agentId: 'agent-1',
          body: <String, Object?>{
            'agentId': 'agent-1',
            'command': <String, Object?>{
              'jsonrpc': '2.0',
              'method': 'sql.execute',
              'id': 'rpc-1',
              'params': <String, Object?>{'sql': 'SELECT * FROM big_table'},
            },
          },
          clientRequestId: 'rpc-1',
        );

        final streamClosed = Completer<void>();
        final received = <Map<String, dynamic>>[];
        final sub = stream.listen(
          received.add,
          onDone: () {
            if (!streamClosed.isCompleted) {
              streamClosed.complete();
            }
          },
        );
        addTearDown(sub.cancel);

        // Pump twice: one for await manager.obtain chain, one for emit.
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);

        // The request was emitted exactly once.
        check(
          wiring.emits
              .where((e) => e.event == RelayEventNames.rpcRequest)
              .length,
        ).equals(1);
        // No pull yet — the dispatcher waits for the accepted ack.
        check(
          wiring.emits
              .where((e) => e.event == RelayEventNames.rpcStreamPull)
              .length,
        ).equals(0);

        // Accepted assigns the server requestId; the dispatcher then grants
        // the initial window via relay:rpc.stream.pull.
        wiring.fire(RelayEventNames.rpcAccepted, <String, Object?>{
          'conversationId': 'conv-agent-1',
          'clientRequestId': 'rpc-1',
          'requestId': 'srv-req-1',
          'success': true,
        });

        final pulls = wiring.emits
            .where((e) => e.event == RelayEventNames.rpcStreamPull)
            .toList();
        check(pulls.length).equals(1);
        final firstPull = pulls.single.data! as Map<String, Object?>;
        check(firstPull['conversationId']).equals('conv-agent-1');
        check(firstPull['frame']).isA<Map<String, Object?>>();
        final firstPullPayload = _decodePullPayload(firstPull);
        check(firstPullPayload['request_id']).equals('srv-req-1');
        check(firstPullPayload['window_size']).equals(4);

        // Stream three chunks. With initial=4 and refill_threshold=2:
        //   chunk 1 → outstanding=3 (no refill)
        //   chunk 2 → outstanding=2, refill of (4 - 2)=2 → outstanding=4
        //   chunk 3 → outstanding=3 (no refill)
        // → expect ONE refill pull granting 2 credits, two total pulls.
        for (var i = 0; i < 3; i++) {
          wiring.fire(
            RelayEventNames.rpcChunk,
            _frame(
              <String, Object?>{
                'row': i,
                'value': 'r$i',
                if (i == 0) 'stream_id': 'stream-1',
              },
              requestId: 'srv-req-1',
            ),
          );
        }
        // Broadcast stream delivery is microtask-scheduled; pump a couple
        // times to flush the three pending adds.
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);
        check(received.length).equals(3);
        check(received[1]['row']).equals(1);

        final allPullsAfterChunks = wiring.emits
            .where((e) => e.event == RelayEventNames.rpcStreamPull)
            .toList();
        check(allPullsAfterChunks.length).equals(2);
        final refillEnvelope =
            allPullsAfterChunks.last.data! as Map<String, Object?>;
        final refillPayload = _decodePullPayload(refillEnvelope);
        check(refillPayload['request_id']).equals('srv-req-1');
        check(refillPayload['stream_id']).equals('stream-1');
        check(refillPayload['window_size']).equals(2);

        // Complete with healthy terminal_status closes the stream normally.
        // Since PR-L+ p3.5 the complete payload is forwarded as the
        // FINAL stream item before close, so collectors can grab
        // execution_id / total_rows. The chunk-only listener simply
        // appends one more map (without `row`) to `received`.
        wiring.fire(
          RelayEventNames.rpcComplete,
          _frame(
            <String, Object?>{
              'terminal_status': 'completed',
              'total_rows': 3,
              'execution_id': 'exec-1',
            },
            requestId: 'srv-req-1',
          ),
        );
        await Future<void>.delayed(Duration.zero);

        check(received.length).equals(4);
        final completePayload = received.last;
        check(completePayload['total_rows']).equals(3);
        check(completePayload['execution_id']).equals('exec-1');

        await streamClosed.future.timeout(const Duration(milliseconds: 100));
      },
    );

    test(
      'unhealthy terminal_status surfaces RelayStreamTerminated on the stream',
      () async {
        final dispatcher = buildDispatcher();
        addTearDown(dispatcher.dispose);

        await openConversation();

        final stream = dispatcher.sendStreaming(
          agentId: 'agent-1',
          body: <String, Object?>{
            'command': <String, Object?>{
              'jsonrpc': '2.0',
              'method': 'sql.execute',
              'id': 'rpc-abort',
            },
          },
          clientRequestId: 'rpc-abort',
        );

        final errors = <Object>[];
        final sub = stream.listen(
          (_) {},
          onError: errors.add,
        );
        addTearDown(sub.cancel);

        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);

        wiring.fire(RelayEventNames.rpcAccepted, <String, Object?>{
          'conversationId': 'conv-agent-1',
          'clientRequestId': 'rpc-abort',
          'requestId': 'srv-req-abort',
          'success': true,
        });
        wiring.fire(
          RelayEventNames.rpcComplete,
          _frame(
            <String, Object?>{'terminal_status': 'aborted'},
            requestId: 'srv-req-abort',
          ),
        );
        await Future<void>.delayed(Duration.zero);

        check(errors.length).equals(1);
        check(errors.single).isA<RelayStreamTerminated>();
        check(
          (errors.single as RelayStreamTerminated).code,
        ).equals('stream_aborted');
      },
    );

    test(
      'non-streaming relay:rpc.response forwards as a single chunk + closes',
      () async {
        final dispatcher = buildDispatcher();
        addTearDown(dispatcher.dispose);

        await openConversation();

        final stream = dispatcher.sendStreaming(
          agentId: 'agent-1',
          body: <String, Object?>{
            'command': <String, Object?>{
              'jsonrpc': '2.0',
              'method': 'sql.execute',
              'id': 'rpc-resp',
            },
          },
          clientRequestId: 'rpc-resp',
        );
        final streamClosed = Completer<void>();
        final received = <Map<String, dynamic>>[];
        final sub = stream.listen(
          received.add,
          onDone: () {
            if (!streamClosed.isCompleted) {
              streamClosed.complete();
            }
          },
        );
        addTearDown(sub.cancel);

        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);

        wiring.fire(RelayEventNames.rpcAccepted, <String, Object?>{
          'conversationId': 'conv-agent-1',
          'clientRequestId': 'rpc-resp',
          'requestId': 'srv-resp',
          'success': true,
        });
        wiring.fire(
          RelayEventNames.rpcResponse,
          _frame(
            <String, Object?>{
              'response': <String, Object?>{
                'type': 'single',
                'item': <String, Object?>{'id': 'rpc-resp', 'success': true},
              },
            },
            requestId: 'srv-resp',
          ),
        );

        await streamClosed.future.timeout(const Duration(milliseconds: 100));
        check(received.length).equals(1);
        check(received.single['response']).isA<Map<dynamic, dynamic>>();
      },
    );

    test(
      'rejected accept emits a single error on the stream and closes it',
      () async {
        final dispatcher = buildDispatcher();
        addTearDown(dispatcher.dispose);

        await openConversation();

        final stream = dispatcher.sendStreaming(
          agentId: 'agent-1',
          body: <String, Object?>{
            'command': <String, Object?>{
              'jsonrpc': '2.0',
              'method': 'sql.execute',
              'id': 'rpc-reject',
            },
          },
          clientRequestId: 'rpc-reject',
        );

        final errors = <Object>[];
        final sub = stream.listen((_) {}, onError: errors.add);
        addTearDown(sub.cancel);

        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);

        wiring.fire(RelayEventNames.rpcAccepted, <String, Object?>{
          'conversationId': 'conv-agent-1',
          'clientRequestId': 'rpc-reject',
          'success': false,
          'error': <String, Object?>{
            'code': 'RATE_LIMITED',
            'message': 'too many streams',
          },
        });
        await Future<void>.delayed(Duration.zero);

        check(errors.length).equals(1);
        check(errors.single).isA<RelayRequestRejected>();
        check(
          (errors.single as RelayRequestRejected).code,
        ).equals('RATE_LIMITED');
      },
    );

    test('timeout closes the stream with RelayRequestTimeout', () async {
      final dispatcher = buildDispatcher(
        defaultTimeout: const Duration(milliseconds: 30),
      );
      addTearDown(dispatcher.dispose);

      await openConversation();

      final stream = dispatcher.sendStreaming(
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
      final errors = <Object>[];
      final sub = stream.listen((_) {}, onError: errors.add);
      addTearDown(sub.cancel);

      await Future<void>.delayed(const Duration(milliseconds: 80));
      check(errors.length).equals(1);
      check(errors.single).isA<RelayRequestTimeout>();
    });

    test(
      'dispose closes pending streaming requests with RelayDispatcherDisposed',
      () async {
        final dispatcher = buildDispatcher();
        await openConversation();

        final stream = dispatcher.sendStreaming(
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
        final errors = <Object>[];
        final sub = stream.listen((_) {}, onError: errors.add);
        addTearDown(sub.cancel);

        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);

        await dispatcher.dispose();
        await Future<void>.delayed(Duration.zero);

        check(errors.length).equals(1);
        check(errors.single).isA<RelayDispatcherDisposed>();
      },
    );

    test(
      'streamId from pull_response is included in subsequent pull frames',
      () async {
        final dispatcher = buildDispatcher();
        addTearDown(dispatcher.dispose);

        await openConversation();

        final stream = dispatcher.sendStreaming(
          agentId: 'agent-1',
          body: <String, Object?>{
            'command': <String, Object?>{
              'jsonrpc': '2.0',
              'method': 'sql.execute',
              'id': 'rpc-stream-id',
            },
          },
          clientRequestId: 'rpc-stream-id',
        );
        final sub = stream.listen((_) {});
        addTearDown(sub.cancel);

        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);

        wiring.fire(RelayEventNames.rpcAccepted, <String, Object?>{
          'conversationId': 'conv-agent-1',
          'clientRequestId': 'rpc-stream-id',
          'requestId': 'srv-stream-id',
          'success': true,
        });
        wiring.fire(RelayEventNames.rpcStreamPullResponse, <String, Object?>{
          'conversationId': 'conv-agent-1',
          'clientRequestId': 'rpc-stream-id',
          'requestId': 'srv-stream-id',
          'streamId': 'stream-from-ack',
          'success': true,
          'windowSize': 4,
        });

        for (var i = 0; i < 2; i++) {
          wiring.fire(
            RelayEventNames.rpcChunk,
            _frame(<String, Object?>{'row': i}, requestId: 'srv-stream-id'),
          );
        }

        final pulls = wiring.emits
            .where((e) => e.event == RelayEventNames.rpcStreamPull)
            .toList();
        check(pulls.length).equals(2);
        final refillPayload = _decodePullPayload(pulls.last.data);
        check(refillPayload['request_id']).equals('srv-stream-id');
        check(refillPayload['stream_id']).equals('stream-from-ack');
        check(refillPayload['window_size']).equals(2);
      },
    );

    test(
      'stream pull emit failure fails pending stream immediately',
      () async {
        final dispatcher = buildDispatcher(
          defaultTimeout: const Duration(seconds: 5),
        );
        addTearDown(dispatcher.dispose);

        await openConversation();

        final stream = dispatcher.sendStreaming(
          agentId: 'agent-1',
          body: <String, Object?>{
            'command': <String, Object?>{
              'jsonrpc': '2.0',
              'method': 'sql.execute',
              'id': 'rpc-pull-emit-fails',
            },
          },
          clientRequestId: 'rpc-pull-emit-fails',
        );

        final errors = <Object>[];
        final sub = stream.listen((_) {}, onError: errors.add);
        addTearDown(sub.cancel);

        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);

        wiring.throwOnEmitEvent = RelayEventNames.rpcStreamPull;
        wiring.fire(RelayEventNames.rpcAccepted, <String, Object?>{
          'conversationId': 'conv-agent-1',
          'clientRequestId': 'rpc-pull-emit-fails',
          'requestId': 'srv-pull-emit-fails',
          'success': true,
        });
        await Future<void>.delayed(Duration.zero);

        check(errors.length).equals(1);
        check(errors.single).isA<RelayConversationLost>();
        check((errors.single as RelayConversationLost).message).contains(
          'relay:rpc.stream.pull',
        );
      },
    );

    test(
      'socket disconnect fails pending stream immediately',
      () async {
        final dispatcher = buildDispatcher(
          defaultTimeout: const Duration(seconds: 5),
        );
        addTearDown(dispatcher.dispose);

        await openConversation();

        final stream = dispatcher.sendStreaming(
          agentId: 'agent-1',
          body: <String, Object?>{
            'command': <String, Object?>{
              'jsonrpc': '2.0',
              'method': 'sql.execute',
              'id': 'rpc-drop',
            },
          },
          clientRequestId: 'rpc-drop',
        );

        final errors = <Object>[];
        final sub = stream.listen((_) {}, onError: errors.add);
        addTearDown(sub.cancel);

        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);

        stateController.add(
          const ConsumerSocketDisconnected(reason: 'transport close'),
        );
        await Future<void>.delayed(Duration.zero);

        check(errors.length).equals(1);
        check(errors.single).isA<RelayConversationLost>();
        check(
          (errors.single as RelayConversationLost).message,
        ).contains('transport close');
      },
    );
  });
}

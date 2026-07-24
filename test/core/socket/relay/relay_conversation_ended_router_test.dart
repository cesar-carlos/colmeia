import 'dart:async';

import 'package:checks/checks.dart';
import 'package:colmeia/core/socket/consumer_socket_connection.dart';
import 'package:colmeia/core/socket/consumer_socket_connection_state.dart';
import 'package:colmeia/core/socket/relay/relay_conversation_ended_router.dart';
import 'package:colmeia/core/socket/relay/relay_event_names.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class _MockConnection extends Mock implements ConsumerSocketConnection {}

class _MockSocket extends Mock implements io.Socket {}

class _Wiring {
  final Map<String, List<Function>> handlers = <String, List<Function>>{};

  void register(_MockSocket socket) {
    when(() => socket.on(any(), any())).thenAnswer((invocation) {
      final name = invocation.positionalArguments[0] as String;
      final handler = invocation.positionalArguments[1] as Function;
      handlers.putIfAbsent(name, () => <Function>[]).add(handler);
      return () {};
    });
    when(() => socket.off(any(), any())).thenAnswer((invocation) {
      final name = invocation.positionalArguments[0] as String;
      final handler = invocation.positionalArguments[1] as Function;
      handlers[name]?.remove(handler);
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

void main() {
  setUpAll(() {
    registerFallbackValue(<String, Object?>{});
    registerFallbackValue(() {});
  });

  late _MockConnection connection;
  late _MockSocket socket;
  late _Wiring wiring;
  late StreamController<ConsumerSocketConnectionState> states;

  setUp(() {
    connection = _MockConnection();
    socket = _MockSocket();
    wiring = _Wiring()..register(socket);
    states = StreamController<ConsumerSocketConnectionState>.broadcast();
    when(() => connection.raw).thenReturn(socket);
    when(() => connection.states()).thenAnswer((_) => states.stream);
    when(() => connection.isConnected).thenReturn(false);
  });

  tearDown(() async {
    await states.close();
  });

  test('fans out typed conversation.ended to all listeners', () async {
    final router = RelayConversationEndedRouter(connection: connection);
    addTearDown(router.dispose);

    states.add(
      ConsumerSocketConnected(
        socketId: 'sid',
        handshakeAt: DateTime.utc(2026, 7, 24),
      ),
    );
    await Future<void>.delayed(Duration.zero);

    final seen = <({String id, String? requestId, String? reason})>[];
    router.addListener(({
      required conversationId,
      requestId,
      reason,
    }) {
      seen.add((id: conversationId, requestId: requestId, reason: reason));
    });

    wiring.fire(
      RelayEventNames.conversationEnded,
      <String, Object?>{
        'conversationId': 'conv-1',
        'requestId': 'req-1',
        'reason': 'expired',
      },
    );

    check(seen).deepEquals(<({String id, String? requestId, String? reason})>[
      (id: 'conv-1', requestId: 'req-1', reason: 'expired'),
    ]);
  });

  test('ignores malformed payloads without conversationId', () async {
    final router = RelayConversationEndedRouter(connection: connection);
    addTearDown(router.dispose);
    states.add(
      ConsumerSocketConnected(
        socketId: 'sid',
        handshakeAt: DateTime.utc(2026, 7, 24),
      ),
    );
    await Future<void>.delayed(Duration.zero);

    var calls = 0;
    router.addListener(({
      required conversationId,
      requestId,
      reason,
    }) {
      calls++;
    });

    wiring
      ..fire(RelayEventNames.conversationEnded, <String, Object?>{
        'reason': 'expired',
      })
      ..fire(RelayEventNames.conversationEnded, 'not-a-map');

    check(calls).equals(0);
  });

  test('detaches on disconnect and re-attaches on reconnect', () async {
    final router = RelayConversationEndedRouter(connection: connection);
    addTearDown(router.dispose);

    states.add(
      ConsumerSocketConnected(
        socketId: 'sid-1',
        handshakeAt: DateTime.utc(2026, 7, 24),
      ),
    );
    await Future<void>.delayed(Duration.zero);
    check(wiring.handlers[RelayEventNames.conversationEnded]?.length).equals(1);

    states.add(const ConsumerSocketDisconnected(reason: 'drop'));
    await Future<void>.delayed(Duration.zero);
    check(
      wiring.handlers[RelayEventNames.conversationEnded] ?? <Function>[],
    ).isEmpty();

    states.add(
      ConsumerSocketConnected(
        socketId: 'sid-2',
        handshakeAt: DateTime.utc(2026, 7, 24, 1),
      ),
    );
    await Future<void>.delayed(Duration.zero);
    check(wiring.handlers[RelayEventNames.conversationEnded]?.length).equals(1);
  });

  test('attaches immediately when already connected at construction', () {
    when(() => connection.isConnected).thenReturn(true);
    final router = RelayConversationEndedRouter(connection: connection);
    addTearDown(router.dispose);
    // No state event emitted — should have attached synchronously.
    check(wiring.handlers[RelayEventNames.conversationEnded]?.length).equals(1);
  });

  test('broadcasts to multiple listeners', () async {
    final router = RelayConversationEndedRouter(connection: connection);
    addTearDown(router.dispose);

    states.add(
      ConsumerSocketConnected(
        socketId: 'sid',
        handshakeAt: DateTime.utc(2026, 7, 24),
      ),
    );
    await Future<void>.delayed(Duration.zero);

    var calls1 = 0;
    var calls2 = 0;
    router
      ..addListener(({required conversationId, requestId, reason}) => calls1++)
      ..addListener(
        ({required conversationId, requestId, reason}) => calls2++,
      );

    wiring.fire(
      RelayEventNames.conversationEnded,
      <String, Object?>{'conversationId': 'conv-x'},
    );

    check(calls1).equals(1);
    check(calls2).equals(1);
  });

  test('removeListener stops notifications for that listener', () async {
    final router = RelayConversationEndedRouter(connection: connection);
    addTearDown(router.dispose);

    states.add(
      ConsumerSocketConnected(
        socketId: 'sid',
        handshakeAt: DateTime.utc(2026, 7, 24),
      ),
    );
    await Future<void>.delayed(Duration.zero);

    var calls = 0;
    void listener({
      required String conversationId,
      String? requestId,
      String? reason,
    }) {
      calls++;
    }

    router.addListener(listener);
    wiring.fire(
      RelayEventNames.conversationEnded,
      <String, Object?>{'conversationId': 'conv-1'},
    );
    check(calls).equals(1);

    router.removeListener(listener);
    wiring.fire(
      RelayEventNames.conversationEnded,
      <String, Object?>{'conversationId': 'conv-2'},
    );
    check(calls).equals(1);
  });

  test('normalises empty requestId/reason to null', () async {
    final router = RelayConversationEndedRouter(connection: connection);
    addTearDown(router.dispose);

    states.add(
      ConsumerSocketConnected(
        socketId: 'sid',
        handshakeAt: DateTime.utc(2026, 7, 24),
      ),
    );
    await Future<void>.delayed(Duration.zero);

    ({String? requestId, String? reason})? captured;
    router.addListener(({required conversationId, requestId, reason}) {
      captured = (requestId: requestId, reason: reason);
    });

    wiring.fire(
      RelayEventNames.conversationEnded,
      <String, Object?>{
        'conversationId': 'conv-1',
        'requestId': '',
        'reason': '',
      },
    );

    check(captured).isNotNull();
    check(captured!.requestId).isNull();
    check(captured!.reason).isNull();
  });
}

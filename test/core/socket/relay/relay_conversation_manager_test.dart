import 'dart:async';

import 'package:checks/checks.dart';
import 'package:colmeia/core/socket/consumer_socket_connection.dart';
import 'package:colmeia/core/socket/consumer_socket_connection_state.dart';
import 'package:colmeia/core/socket/relay/relay_conversation_manager.dart';
import 'package:colmeia/core/socket/relay/relay_event_names.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class _MockConnection extends Mock implements ConsumerSocketConnection {}

class _MockSocket extends Mock implements io.Socket {}

class _Wiring {
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
    when(connection.connect).thenAnswer(
      (_) async => ConsumerSocketConnected(
        socketId: 'sock-1',
        handshakeAt: DateTime.utc(2026, 4, 17),
      ),
    );
  });

  tearDown(() async {
    await states.close();
  });

  group('RelayConversationManager.obtain', () {
    test(
      'concurrent obtain for same agentId shares a single conversation.start',
      () async {
        final manager = RelayConversationManager(
          connection: connection,
          startTimeout: const Duration(seconds: 2),
        );
        addTearDown(manager.dispose);

        final f1 = manager.obtain('agent-a');
        final f2 = manager.obtain('agent-a');

        await Future<void>.delayed(Duration.zero);
        check(
          wiring.emits
              .where((e) => e.event == RelayEventNames.conversationStart)
              .length,
        ).equals(1);

        wiring.fire(
          RelayEventNames.conversationStarted,
          <String, Object?>{
            'success': true,
            'conversationId': 'conv-a',
            'agentId': 'agent-a',
            'createdAt': '2026-04-17T00:00:00Z',
          },
        );

        final c1 = await f1;
        final c2 = await f2;
        check(identical(c1, c2)).isTrue();
        check(c1.conversationId).equals('conv-a');
        verify(() => connection.connect()).called(1);
      },
    );

    test('second obtain after active reuses without new start emit', () async {
      final manager = RelayConversationManager(
        connection: connection,
        startTimeout: const Duration(seconds: 2),
      );
      addTearDown(manager.dispose);

      final first = manager.obtain('agent-a');
      await Future<void>.delayed(Duration.zero);
      wiring.fire(
        RelayEventNames.conversationStarted,
        <String, Object?>{
          'success': true,
          'conversationId': 'conv-a',
          'agentId': 'agent-a',
        },
      );
      final conversation = await first;

      final startEmitsBefore = wiring.emits
          .where((e) => e.event == RelayEventNames.conversationStart)
          .length;

      final again = await manager.obtain('agent-a');
      check(identical(again, conversation)).isTrue();
      check(
        wiring.emits
            .where((e) => e.event == RelayEventNames.conversationStart)
            .length,
      ).equals(startEmitsBefore);
    });

    test('different agentIds open independent conversations', () async {
      final manager = RelayConversationManager(
        connection: connection,
        startTimeout: const Duration(seconds: 2),
      );
      addTearDown(manager.dispose);

      final fa = manager.obtain('agent-a');
      final fb = manager.obtain('agent-b');
      await Future<void>.delayed(Duration.zero);

      check(
        wiring.emits
            .where((e) => e.event == RelayEventNames.conversationStart)
            .length,
      ).equals(2);

      wiring
        ..fire(
          RelayEventNames.conversationStarted,
          <String, Object?>{
            'success': true,
            'conversationId': 'conv-a',
            'agentId': 'agent-a',
          },
        )
        ..fire(
          RelayEventNames.conversationStarted,
          <String, Object?>{
            'success': true,
            'conversationId': 'conv-b',
            'agentId': 'agent-b',
          },
        );

      final a = await fa;
      final b = await fb;
      check(a.conversationId).equals('conv-a');
      check(b.conversationId).equals('conv-b');
      check(identical(a, b)).isFalse();
    });
  });
}

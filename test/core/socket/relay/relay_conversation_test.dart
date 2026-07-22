import 'package:checks/checks.dart';
import 'package:colmeia/core/socket/consumer_socket_connection.dart';
import 'package:colmeia/core/socket/relay/relay_conversation.dart';
import 'package:colmeia/core/socket/relay/relay_conversation_state.dart';
import 'package:colmeia/core/socket/relay/relay_dispatch_exception.dart';
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
    // off(name) and off(name, handler) are void; mocktail tolerates them
    // unstubbed. We don't track removals because the wiring helper only
    // exposes `fire` for the most recently active handlers.
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

  setUp(() {
    connection = _MockConnection();
    socket = _MockSocket();
    wiring = _Wiring()..register(socket);
    when(() => connection.raw).thenReturn(socket);
  });

  RelayConversation buildConversation({
    Duration startTimeout = const Duration(milliseconds: 200),
    Duration endTimeout = const Duration(milliseconds: 100),
  }) {
    return RelayConversation(
      connection: connection,
      agentId: 'agent-1',
      startTimeout: startTimeout,
      endTimeout: endTimeout,
    );
  }

  group('RelayConversation.start', () {
    test('emits start and resolves on relay:conversation.started', () async {
      final conversation = buildConversation();
      final future = conversation.start();

      await Future<void>.delayed(Duration.zero);
      check(wiring.emits.length).equals(1);
      check(wiring.emits.first.event).equals(RelayEventNames.conversationStart);
      final startBody = Map<Object?, Object?>.from(
        wiring.emits.first.data! as Map,
      );
      check(startBody['agentId']).equals('agent-1');
      check(startBody['requestId']).isA<String>();
      final startRequestId = startBody['requestId']! as String;

      wiring.fire(
        RelayEventNames.conversationStarted,
        <String, Object?>{
          'success': true,
          'requestId': startRequestId,
          'conversationId': 'conv-1',
          'agentId': 'agent-1',
          'createdAt': '2026-04-17T00:00:00Z',
        },
      );

      final state = await future;
      check(state.conversationId).equals('conv-1');
      check(conversation.isActive).isTrue();
      check(conversation.state).isA<RelayConversationActive>();
    });

    test('rejects when started arrives with success=false', () async {
      final conversation = buildConversation();
      final future = conversation.start();
      await Future<void>.delayed(Duration.zero);

      wiring.fire(
        RelayEventNames.conversationStarted,
        <String, Object?>{
          'success': false,
          'agentId': 'agent-1',
          'error': <String, Object?>{
            'code': 'AGENT_OFFLINE',
            'message': 'agent is offline',
          },
        },
      );

      await check(future).throws<RelayConversationStartFailure>(
        (subject) => subject.has((e) => e.code, 'code').equals('AGENT_OFFLINE'),
      );
      check(conversation.isActive).isFalse();
    });

    test('throws RelayConversationStartFailure on timeout', () async {
      final conversation = buildConversation(
        startTimeout: const Duration(milliseconds: 10),
      );
      final future = conversation.start();

      await check(future).throws<RelayConversationStartFailure>(
        (subject) => subject.has((e) => e.code, 'code').equals('start_timeout'),
      );
    });

    test('is single-flight: concurrent calls share the same Future', () async {
      final conversation = buildConversation();
      final f1 = conversation.start();
      final f2 = conversation.start();

      await Future<void>.delayed(Duration.zero);
      // Only one start emit must have been issued.
      check(
        wiring.emits
            .where((e) => e.event == RelayEventNames.conversationStart)
            .length,
      ).equals(1);

      wiring.fire(
        RelayEventNames.conversationStarted,
        <String, Object?>{
          'success': true,
          'conversationId': 'conv-2',
          'agentId': 'agent-1',
        },
      );

      final r1 = await f1;
      final r2 = await f2;
      check(r1.conversationId).equals(r2.conversationId);
    });

    test('returns the active state immediately when already opened', () async {
      final conversation = buildConversation();
      final initial = conversation.start();
      await Future<void>.delayed(Duration.zero);
      wiring.fire(
        RelayEventNames.conversationStarted,
        <String, Object?>{
          'success': true,
          'conversationId': 'conv-3',
          'agentId': 'agent-1',
        },
      );
      await initial;

      final again = await conversation.start();
      check(again.conversationId).equals('conv-3');
      // Only one start emit total.
      check(
        wiring.emits
            .where((e) => e.event == RelayEventNames.conversationStart)
            .length,
      ).equals(1);
    });
  });

  group('RelayConversation.end', () {
    test('emits end and waits for relay:conversation.ended', () async {
      final conversation = buildConversation();
      final start = conversation.start();
      await Future<void>.delayed(Duration.zero);
      wiring.fire(
        RelayEventNames.conversationStarted,
        <String, Object?>{
          'success': true,
          'conversationId': 'conv-4',
          'agentId': 'agent-1',
        },
      );
      await start;

      final endFuture = conversation.end(reason: 'logout');
      await Future<void>.delayed(Duration.zero);

      final endEmit = wiring.emits.lastWhere(
        (e) => e.event == RelayEventNames.conversationEnd,
      );
      final endBody = Map<Object?, Object?>.from(endEmit.data! as Map);
      check(endBody['conversationId']).equals('conv-4');
      check(endBody['requestId']).isA<String>();
      final endRequestId = endBody['requestId']! as String;

      wiring.fire(
        RelayEventNames.conversationEnded,
        <String, Object?>{
          'success': true,
          'requestId': endRequestId,
          'conversationId': 'conv-4',
          'reason': 'consumer_ended',
        },
      );

      await endFuture;
      check(conversation.isActive).isFalse();
      final ended = conversation.state as RelayConversationEnded;
      check(ended.reason).equals('consumer_ended');
    });

    test('end without prior start is a no-op', () async {
      final conversation = buildConversation();
      await conversation.end();
      check(conversation.state).isA<RelayConversationIdle>();
      check(wiring.emits).isEmpty();
    });

    test('forceEnd transitions to ended without emitting', () async {
      final conversation = buildConversation();
      final start = conversation.start();
      await Future<void>.delayed(Duration.zero);
      wiring.fire(
        RelayEventNames.conversationStarted,
        <String, Object?>{
          'success': true,
          'conversationId': 'conv-5',
          'agentId': 'agent-1',
        },
      );
      await start;

      conversation.forceEnd(reason: 'socket_dropped');

      check(conversation.isActive).isFalse();
      check(
        wiring.emits
            .where((e) => e.event == RelayEventNames.conversationEnd)
            .length,
      ).equals(0);
    });
  });
}

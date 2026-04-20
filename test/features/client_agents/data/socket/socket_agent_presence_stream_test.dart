import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:checks/checks.dart';
import 'package:colmeia/core/socket/agent_command_outcome.dart';
import 'package:colmeia/core/socket/consumer_socket_connection.dart';
import 'package:colmeia/core/socket/consumer_socket_connection_state.dart';
import 'package:colmeia/core/socket/payload_frame.dart';
import 'package:colmeia/core/socket/socket_command_dispatcher.dart';
import 'package:colmeia/features/client_agents/data/socket/agent_command_presence_hinter.dart';
import 'package:colmeia/features/client_agents/data/socket/client_agent_profile_updated_listener.dart';
import 'package:colmeia/features/client_agents/data/socket/socket_agent_presence_stream.dart';
import 'package:colmeia/features/client_agents/domain/events/agent_presence_event.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class _MockConnection extends Mock implements ConsumerSocketConnection {}

class _MockSocket extends Mock implements io.Socket {}

class _MockDispatcher extends Mock implements SocketCommandDispatcher {}

class _SocketWiring {
  final Map<String, List<Function>> handlers = <String, List<Function>>{};

  void register(_MockSocket socket) {
    when(() => socket.on(any(), any())).thenAnswer((invocation) {
      final name = invocation.positionalArguments[0] as String;
      final handler = invocation.positionalArguments[1] as Function;
      handlers.putIfAbsent(name, () => <Function>[]).add(handler);
      return () {};
    });
    when(() => socket.off(any())).thenAnswer((invocation) {
      handlers[invocation.positionalArguments[0] as String]?.clear();
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

Map<String, Object?> _frame(Object? data) {
  final encoded = Uint8List.fromList(utf8.encode(jsonEncode(data)));
  return PayloadFrame(
    payload: encoded,
    originalSize: encoded.length,
    compressedSize: encoded.length,
  ).toMap();
}

void main() {
  setUpAll(() {
    registerFallbackValue(<String, Object?>{});
    registerFallbackValue(() {});
    registerFallbackValue(const ConsumerSocketDisconnected());
  });

  late _MockConnection connection;
  late _MockSocket socket;
  late _MockDispatcher dispatcher;
  late _SocketWiring wiring;
  late StreamController<ConsumerSocketConnectionState> stateController;
  late StreamController<AgentCommandOutcome> outcomes;

  setUp(() {
    connection = _MockConnection();
    socket = _MockSocket();
    dispatcher = _MockDispatcher();
    wiring = _SocketWiring()..register(socket);
    stateController =
        StreamController<ConsumerSocketConnectionState>.broadcast();
    outcomes = StreamController<AgentCommandOutcome>.broadcast();

    when(() => connection.raw).thenReturn(socket);
    when(() => connection.states()).thenAnswer((_) => stateController.stream);
    when(() => connection.isConnected).thenReturn(true);
    when(dispatcher.outcomes).thenAnswer((_) => outcomes.stream);
  });

  tearDown(() async {
    await stateController.close();
    await outcomes.close();
  });

  SocketAgentPresenceStream buildStream() {
    final stream = SocketAgentPresenceStream.deferred(connection: connection);
    final listener = ClientAgentProfileUpdatedListener(
      connection: connection,
      sink: stream.sink,
    );
    final hinter = AgentCommandPresenceHinter(
      dispatcher: dispatcher,
      sink: stream.sink,
    );
    stream.bind(catalogListener: listener, commandHinter: hinter);
    return stream;
  }

  group('SocketAgentPresenceStream', () {
    test(
      'emits both catalog updates and command hints into a single stream',
      () async {
        final stream = buildStream();
        addTearDown(stream.dispose);

        final received = <AgentPresenceEvent>[];
        final sub = stream.events().listen(received.add);
        addTearDown(sub.cancel);

        wiring.fire(
          ClientAgentProfileUpdatedListener.eventName,
          _frame(<String, Object?>{
            'agent_id': 'agent-7',
            'profile_version': 1,
            'changed_fields': <String>['phone'],
            'profileUpdatedAt': '2026-04-17T15:30:00Z',
          }),
        );
        outcomes.add(
          AgentCommandSuccess(
            agentId: 'agent-9',
            rpcId: 'rpc-1',
            observedAt: DateTime.utc(2026, 4, 17, 16),
            elapsed: Duration.zero,
            method: 'sql.execute',
          ),
        );
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);

        check(received.length).equals(2);
        check(received.whereType<AgentPresenceCatalogUpdated>().length)
            .equals(1);
        check(received.whereType<AgentPresenceHint>().length).equals(1);
      },
    );

    test('re-attaches listener on socket reconnect', () async {
      when(() => connection.isConnected).thenReturn(false);
      final stream = buildStream();
      addTearDown(stream.dispose);

      final received = <AgentPresenceEvent>[];
      final sub = stream.events().listen(received.add);
      addTearDown(sub.cancel);

      // First connect: listener attaches via state stream.
      stateController.add(
        ConsumerSocketConnected(
          socketId: 'sock-1',
          handshakeAt: DateTime.utc(2026, 4, 17),
        ),
      );
      await Future<void>.delayed(Duration.zero);

      wiring.fire(
        ClientAgentProfileUpdatedListener.eventName,
        _frame(<String, Object?>{
          'agent_id': 'agent-after-connect',
          'changed_fields': <String>[],
        }),
      );
      await Future<void>.delayed(Duration.zero);

      check(received.length).equals(1);
      check(received.first).isA<AgentPresenceCatalogUpdated>();

      // Disconnect detaches; reconnect re-attaches a fresh handler.
      stateController.add(const ConsumerSocketDisconnected());
      await Future<void>.delayed(Duration.zero);
      stateController.add(
        ConsumerSocketConnected(
          socketId: 'sock-2',
          handshakeAt: DateTime.utc(2026, 4, 17, 1),
        ),
      );
      await Future<void>.delayed(Duration.zero);

      wiring.fire(
        ClientAgentProfileUpdatedListener.eventName,
        _frame(<String, Object?>{
          'agent_id': 'agent-after-reconnect',
          'changed_fields': <String>[],
        }),
      );
      await Future<void>.delayed(Duration.zero);

      check(received.length).equals(2);
      check((received.last as AgentPresenceCatalogUpdated).agentId)
          .equals('agent-after-reconnect');
    });

    test('dispose tears down listener, hinter and the broadcast controller',
        () async {
      final stream = buildStream();
      final received = <AgentPresenceEvent>[];
      final sub = stream.events().listen(received.add);

      await stream.dispose();
      // After dispose the controller is closed; listening returns done.
      await sub.cancel();
      // Subsequent socket events / outcomes have nowhere to land without
      // throwing. Firing here just exercises the no-op guard.
      wiring.fire(
        ClientAgentProfileUpdatedListener.eventName,
        _frame(<String, Object?>{'agent_id': 'late', 'changed_fields': <String>[]}),
      );
      outcomes.add(
        AgentCommandSuccess(
          agentId: 'late',
          rpcId: 'late',
          observedAt: DateTime.utc(2026),
          elapsed: Duration.zero,
        ),
      );
      await Future<void>.delayed(Duration.zero);
      check(received).isEmpty();
    });
  });
}

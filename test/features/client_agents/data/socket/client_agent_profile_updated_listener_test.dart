// Test-only: arrange/act splits read better as sequential statements
// (`listener.attach()` then `listener.dispose()`) than cascades.
// ignore_for_file: cascade_invocations

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:checks/checks.dart';
import 'package:colmeia/core/socket/consumer_socket_connection.dart';
import 'package:colmeia/core/socket/payload_frame.dart';
import 'package:colmeia/features/client_agents/data/socket/client_agent_profile_updated_listener.dart';
import 'package:colmeia/features/client_agents/domain/events/agent_presence_event.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class _MockConnection extends Mock implements ConsumerSocketConnection {}

class _MockSocket extends Mock implements io.Socket {}

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
    when(() => socket.off(any(), any())).thenAnswer((invocation) {
      final name = invocation.positionalArguments[0] as String;
      final handler = invocation.positionalArguments[1];
      handlers[name]?.remove(handler);
      if (handlers[name]?.isEmpty ?? false) {
        handlers.remove(name);
      }
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

Map<String, Object?> _payloadFrame(Object? data) {
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
  });

  late _MockConnection connection;
  late _MockSocket socket;
  late _SocketWiring wiring;
  late StreamController<AgentPresenceEvent> sink;

  setUp(() {
    connection = _MockConnection();
    socket = _MockSocket();
    wiring = _SocketWiring()..register(socket);
    // Broadcast so close() does not block on a missing subscriber. The
    // production stream is broadcast.
    sink = StreamController<AgentPresenceEvent>.broadcast();
    when(() => connection.raw).thenReturn(socket);
  });

  tearDown(() => sink.close());

  ClientAgentProfileUpdatedListener buildListener({
    bool acceptLegacyRawJson = false,
  }) {
    return ClientAgentProfileUpdatedListener(
      connection: connection,
      sink: sink.sink,
      acceptLegacyRawJson: acceptLegacyRawJson,
    );
  }

  group('ClientAgentProfileUpdatedListener', () {
    test('attach is idempotent and reports state', () {
      final listener = buildListener();
      check(listener.isAttached).isFalse();
      listener.attach();
      listener.attach();
      check(listener.isAttached).isTrue();
    });

    test('dispose detaches and is idempotent', () async {
      final listener = buildListener();
      listener.attach();
      await listener.dispose();
      await listener.dispose();
      check(listener.isAttached).isFalse();
    });

    test('dispose removes only its own handler', () async {
      final listener = buildListener();
      void sentinel(Object? _) {}
      wiring.handlers
          .putIfAbsent(
            ClientAgentProfileUpdatedListener.eventName,
            () => <Function>[],
          )
          .add(sentinel);

      listener.attach();
      await listener.dispose();

      check(
        wiring.handlers[ClientAgentProfileUpdatedListener.eventName]?.contains(
          sentinel,
        ),
      ).equals(true);
      verify(
        () => socket.off(ClientAgentProfileUpdatedListener.eventName, any()),
      ).called(1);
    });

    test(
      'PayloadFrame envelope decodes into AgentPresenceCatalogUpdated',
      () async {
        buildListener().attach();
        final emitted = sink.stream.toList();

        final frame = _payloadFrame(<String, Object?>{
          'agent_id': 'agent-7',
          'profile_version': 12,
          'changed_fields': <String>['phone', 'address'],
          'profileUpdatedAt': '2026-04-17T15:30:00Z',
          'source': 'http',
        });
        wiring.fire(ClientAgentProfileUpdatedListener.eventName, frame);
        await Future<void>.delayed(Duration.zero);
        await sink.close();

        final list = await emitted;
        check(list.length).equals(1);
        final event = list.single as AgentPresenceCatalogUpdated;
        check(event.agentId).equals('agent-7');
        check(event.profileVersion).equals(12);
        check(
          event.changedFields,
        ).deepEquals(const <String>{'phone', 'address'});
        check(event.observedAt).equals(DateTime.utc(2026, 4, 17, 15, 30));
        check(event.source).equals('http');
      },
    );

    test('raw JSON map is ignored by default', () async {
      buildListener().attach();
      final emitted = sink.stream.toList();

      wiring.fire(
        ClientAgentProfileUpdatedListener.eventName,
        <String, Object?>{
          'agent_id': 'agent-legacy',
          'profile_version': 1,
          'changed_fields': <String>['name'],
        },
      );
      await Future<void>.delayed(Duration.zero);
      await sink.close();

      check(await emitted).isEmpty();
    });

    test(
      'raw JSON map is accepted only in legacy compatibility mode',
      () async {
        buildListener(acceptLegacyRawJson: true).attach();
        final emitted = sink.stream.toList();

        wiring.fire(
          ClientAgentProfileUpdatedListener.eventName,
          <String, Object?>{
            'agent_id': 'agent-legacy',
            'profile_version': 1,
            'changed_fields': <String>['name'],
          },
        );
        await Future<void>.delayed(Duration.zero);
        await sink.close();

        final list = await emitted;
        check(list.length).equals(1);
        final event = list.single as AgentPresenceCatalogUpdated;
        check(event.agentId).equals('agent-legacy');
        check(event.changedFields).deepEquals(const <String>{'name'});
      },
    );

    test('payload without agent_id is dropped silently', () async {
      buildListener().attach();
      final emitted = sink.stream.toList();

      wiring.fire(
        ClientAgentProfileUpdatedListener.eventName,
        _payloadFrame(<String, Object?>{
          'profile_version': 5,
          'changed_fields': <String>['phone'],
        }),
      );
      await Future<void>.delayed(Duration.zero);
      await sink.close();

      check(await emitted).isEmpty();
    });

    test('PayloadFrame with broken schema is dropped silently', () async {
      buildListener().attach();
      final emitted = sink.stream.toList();

      // schemaVersion mismatch makes PayloadFrameCodec.decodeJson throw,
      // which the listener catches and logs.
      wiring.fire(
        ClientAgentProfileUpdatedListener.eventName,
        <String, Object?>{
          'schemaVersion': '9.9',
          'enc': 'json',
          'cmp': 'none',
          'contentType': 'application/json',
          'originalSize': 2,
          'compressedSize': 2,
          'payload': base64Encode(<int>[123, 125]),
        },
      );
      await Future<void>.delayed(Duration.zero);
      await sink.close();

      check(await emitted).isEmpty();
    });
  });
}

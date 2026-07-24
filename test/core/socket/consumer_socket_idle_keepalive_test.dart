import 'dart:async';

import 'package:checks/checks.dart';
import 'package:colmeia/core/socket/consumer_socket_connection.dart';
import 'package:colmeia/core/socket/consumer_socket_connection_state.dart';
import 'package:colmeia/core/socket/consumer_socket_idle_keepalive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class _MockConnection extends Mock implements ConsumerSocketConnection {}

class _MockSocket extends Mock implements io.Socket {}

void main() {
  late _MockConnection connection;
  late _MockSocket socket;
  late StreamController<ConsumerSocketConnectionState> states;
  late ConsumerSocketIdleKeepalive keepalive;

  setUpAll(() {
    registerFallbackValue(<String, Object?>{});
  });

  setUp(() {
    connection = _MockConnection();
    socket = _MockSocket();
    states = StreamController<ConsumerSocketConnectionState>.broadcast();

    when(() => connection.states()).thenAnswer((_) => states.stream);
    when(() => connection.isConnected).thenReturn(false);
    when(() => connection.raw).thenReturn(socket);
    when(() => socket.emit(any<String>(), any<Object?>())).thenReturn(null);

    keepalive = ConsumerSocketIdleKeepalive(
      connection: connection,
      interval: const Duration(milliseconds: 20),
    );
  });

  tearDown(() async {
    await keepalive.dispose();
    await states.close();
  });

  test('arms timer when connection becomes Connected', () async {
    keepalive.start();
    check(keepalive.isActive).isFalse();

    states.add(
      ConsumerSocketConnected(
        socketId: 'sid',
        handshakeAt: _handshakeAt,
      ),
    );
    when(() => connection.isConnected).thenReturn(true);

    await Future<void>.delayed(const Duration(milliseconds: 30));

    check(keepalive.isActive).isTrue();
  });

  test('stops timer on Disconnected', () async {
    when(() => connection.isConnected).thenReturn(true);
    keepalive.start();
    states.add(
      ConsumerSocketConnected(
        socketId: 'sid',
        handshakeAt: _handshakeAt,
      ),
    );

    await Future<void>.delayed(const Duration(milliseconds: 30));
    check(keepalive.isActive).isTrue();

    states.add(const ConsumerSocketDisconnected());
    when(() => connection.isConnected).thenReturn(false);

    await Future<void>.delayed(const Duration(milliseconds: 5));
    check(keepalive.isActive).isFalse();
  });

  test('emits subscribe then unsubscribe on each touch', () async {
    when(() => connection.isConnected).thenReturn(true);
    keepalive.start();
    states.add(
      ConsumerSocketConnected(
        socketId: 'sid',
        handshakeAt: _handshakeAt,
      ),
    );

    await Future<void>.delayed(const Duration(milliseconds: 25));

    final captured = verify(
      () => socket.emit(captureAny<String>(), captureAny<Object?>()),
    ).captured;

    final eventNames = <String>[
      for (var i = 0; i < captured.length; i += 2) captured[i] as String,
    ];
    check(eventNames).contains('socket:event.subscribe');
    check(eventNames).contains('socket:event.unsubscribe');
    final subscribeIndex = captured.indexOf('socket:event.subscribe');
    final subscribePayload =
        captured[subscribeIndex + 1] as Map<String, Object?>;
    check(subscribePayload['eventName']).equals(
      ConsumerSocketIdleKeepalive.defaultEventName,
    );
  });

  test('dispose stops timer and cancels state subscription', () async {
    when(() => connection.isConnected).thenReturn(true);
    keepalive.start();
    states.add(
      ConsumerSocketConnected(
        socketId: 'sid',
        handshakeAt: _handshakeAt,
      ),
    );

    await Future<void>.delayed(const Duration(milliseconds: 25));
    check(keepalive.isActive).isTrue();

    await keepalive.dispose();
    check(keepalive.isActive).isFalse();
  });

  test('emit failure does not throw', () async {
    when(() => connection.isConnected).thenReturn(true);
    when(
      () => socket.emit(any<String>(), any<Object?>()),
    ).thenThrow(StateError('emit failed'));
    keepalive.start();
    states.add(
      ConsumerSocketConnected(
        socketId: 'sid',
        handshakeAt: _handshakeAt,
      ),
    );

    await Future<void>.delayed(const Duration(milliseconds: 25));

    check(keepalive.isActive).isTrue();
  });
}

final _handshakeAt = DateTime.utc(2026, 7, 24);

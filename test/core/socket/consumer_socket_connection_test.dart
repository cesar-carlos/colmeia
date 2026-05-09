import 'dart:async';

import 'package:checks/checks.dart';
import 'package:colmeia/core/socket/app_socket_url_resolver.dart';
import 'package:colmeia/core/socket/connection_ready_payload.dart';
import 'package:colmeia/core/socket/consumer_socket_connection.dart';
import 'package:colmeia/core/socket/consumer_socket_connection_state.dart';
import 'package:colmeia/core/socket/socket_auth_token_provider.dart';
import 'package:colmeia/core/socket/socket_io_client_factory.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

/// Fake provider that does not require AuthSessionAccessor / Dio plumbing.
class _FakeTokenProvider implements SocketAuthTokenProvider {
  _FakeTokenProvider({
    String? token,
    String? refreshToken,
  }) : _token = token,
       _refreshToken = refreshToken,
       _events = StreamController<void>.broadcast();

  String? _token;
  final String? _refreshToken;
  final StreamController<void> _events;

  // Simple mutator used by tests to mimic post-login token availability.
  // ignore: use_setters_to_change_properties
  void updateToken(String? value) => _token = value;

  void emitInvalidation() => _events.add(null);

  @override
  Future<String?> readAccessToken() async => _token;

  @override
  Future<String?> refreshAccessToken() async {
    _token = _refreshToken;
    return _refreshToken;
  }

  @override
  Stream<void> sessionInvalidations() => _events.stream;

  Future<void> dispose() => _events.close();
}

/// Factory that records calls and returns a never-resolving fake socket so
/// the connection never observes `connection:ready` (validates timeout +
/// reconnect path without booting Socket.IO).
class _RecordingFactory implements SocketIoClientFactory {
  final List<({String url, String accessToken})> calls = [];

  @override
  io.Socket create({required String url, required String accessToken}) {
    calls.add((url: url, accessToken: accessToken));
    // Returning a real Socket.IO instance with no auto-connect. The test
    // never calls connect() on it; we only verify factory behaviour and
    // state transitions of ConsumerSocketConnection.
    return io.io(
      url,
      io.OptionBuilder()
          .setTransports(<String>['websocket'])
          .disableAutoConnect()
          .disableReconnection()
          .setAuth(<String, dynamic>{'token': accessToken})
          .build(),
    );
  }
}

class _MockSocket extends Mock implements io.Socket {}

class _InteractiveFactory implements SocketIoClientFactory {
  _InteractiveFactory() {
    when(() => socket.on(any(), any())).thenAnswer((invocation) {
      final event = invocation.positionalArguments[0] as String;
      final handler = invocation.positionalArguments[1] as Function;
      handlers.putIfAbsent(event, () => <Function>[]).add(handler);
      return () => handlers[event]?.remove(handler);
    });
    when(() => socket.off(any())).thenAnswer((invocation) {
      final event = invocation.positionalArguments[0] as String;
      handlers.remove(event);
    });
    when(() => socket.off(any(), any())).thenAnswer((invocation) {
      final event = invocation.positionalArguments[0] as String;
      final handler = invocation.positionalArguments[1];
      if (handler == null) {
        handlers.remove(event);
        return;
      }
      handlers[event]?.remove(handler);
      if (handlers[event]?.isEmpty ?? false) {
        handlers.remove(event);
      }
    });
    when(socket.connect).thenReturn(socket);
    when(socket.disconnect).thenReturn(socket);
    when(socket.dispose).thenAnswer((_) {});
  }

  final _MockSocket socket = _MockSocket();
  final Map<String, List<Function>> handlers = <String, List<Function>>{};
  final List<({String url, String accessToken})> calls = [];

  @override
  io.Socket create({required String url, required String accessToken}) {
    calls.add((url: url, accessToken: accessToken));
    return socket;
  }

  void fire(String event, Object? payload) {
    for (final handler in List<Function>.of(handlers[event] ?? <Function>[])) {
      Function.apply(handler, <Object?>[payload]);
    }
  }
}

ConsumerSocketConnection _build({
  required _FakeTokenProvider tokenProvider,
  SocketIoClientFactory? factory,
}) {
  return ConsumerSocketConnection(
    urlResolver: AppSocketUrlResolver(
      rawApiBaseUrl: 'https://hub.example.com/api/v1',
    ),
    tokenProvider: tokenProvider,
    factory: factory ?? _RecordingFactory(),
    readyDecoder: const JsonOnlyConnectionReadyDecoder(),
    handshakeTimeout: const Duration(milliseconds: 50),
    maxReconnectAttempts: 1,
    reconnectInitialDelay: const Duration(milliseconds: 1),
    reconnectMaxDelay: const Duration(milliseconds: 1),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(() {});
  });

  group('ConsumerSocketConnection', () {
    test('starts disconnected and isConnected is false', () {
      final tokens = _FakeTokenProvider(token: 'tok');
      final conn = _build(tokenProvider: tokens);
      addTearDown(() async {
        await conn.dispose();
        await tokens.dispose();
      });

      check(conn.state).isA<ConsumerSocketDisconnected>();
      check(conn.isConnected).isFalse();
    });

    test('connect() without a token transitions to unauthorized', () async {
      final tokens = _FakeTokenProvider();
      final conn = _build(tokenProvider: tokens);
      addTearDown(() async {
        await conn.dispose();
        await tokens.dispose();
      });

      await check(conn.connect()).throws<StateError>();
      check(conn.state).isA<ConsumerSocketUnauthorized>();
    });

    test(
      'reading raw before connect throws StateError',
      () {
        final tokens = _FakeTokenProvider(token: 'tok');
        final conn = _build(tokenProvider: tokens);
        addTearDown(() async {
          await conn.dispose();
          await tokens.dispose();
        });

        check(() => conn.raw).throws<StateError>();
      },
    );

    test('disconnect() is idempotent and emits disconnected state', () async {
      final tokens = _FakeTokenProvider(token: 'tok');
      final conn = _build(tokenProvider: tokens);
      addTearDown(() async {
        await conn.dispose();
        await tokens.dispose();
      });

      final emitted = <ConsumerSocketConnectionState>[];
      final sub = conn.states().listen(emitted.add);

      await conn.disconnect(reason: 'first');
      await conn.disconnect(reason: 'second');

      await sub.cancel();

      check(emitted.length).equals(2);
      check(emitted.first).isA<ConsumerSocketDisconnected>();
      check(emitted.last).isA<ConsumerSocketDisconnected>();
    });

    test(
      'session invalidation triggers disconnect',
      () async {
        final tokens = _FakeTokenProvider(token: 'tok');
        final conn = _build(tokenProvider: tokens);
        addTearDown(() async {
          await conn.dispose();
          await tokens.dispose();
        });

        final emitted = <ConsumerSocketConnectionState>[];
        final sub = conn.states().listen(emitted.add);

        tokens.emitInvalidation();
        await Future<void>.delayed(const Duration(milliseconds: 10));
        await sub.cancel();

        check(emitted.length).isGreaterOrEqual(1);
        check(emitted.last).isA<ConsumerSocketDisconnected>();
      },
    );

    test('dispose() prevents further state emissions', () async {
      final tokens = _FakeTokenProvider(token: 'tok');
      final conn = _build(tokenProvider: tokens);
      addTearDown(tokens.dispose);

      final emitted = <ConsumerSocketConnectionState>[];
      final sub = conn.states().listen(emitted.add);

      await conn.dispose();
      // After dispose, additional disconnect() should be a no-op for state.
      await conn.disconnect(reason: 'late');
      await sub.cancel();

      // The post-dispose disconnect must NOT push a new state because the
      // controller has already been closed.
      check(
        emitted.whereType<ConsumerSocketDisconnected>().length,
      ).isLessOrEqual(1);
    });

    test(
      'connect() is single-flight: concurrent calls share the same Future',
      () async {
        final tokens = _FakeTokenProvider();
        final conn = _build(tokenProvider: tokens);
        addTearDown(() async {
          await conn.dispose();
          await tokens.dispose();
        });

        // Two concurrent connect() calls without token both go to
        // unauthorized through the SAME single-flight Future.
        final f1 = conn.connect();
        final f2 = conn.connect();

        // Both should reject with the same StateError (unauthorized).
        await check(f1).throws<StateError>();
        await check(f2).throws<StateError>();

        check(conn.state).isA<ConsumerSocketUnauthorized>();
      },
    );

    test('connect() after dispose throws StateError', () async {
      final tokens = _FakeTokenProvider(token: 'tok');
      final conn = _build(tokenProvider: tokens);
      await conn.dispose();
      addTearDown(tokens.dispose);

      await check(conn.connect()).throws<StateError>();
    });

    test(
      'successful connection keeps remote disconnect listener active',
      () async {
        final tokens = _FakeTokenProvider(token: 'tok');
        final factory = _InteractiveFactory();
        final conn = _build(tokenProvider: tokens, factory: factory);
        addTearDown(() async {
          await conn.dispose();
          await tokens.dispose();
        });

        final emitted = <ConsumerSocketConnectionState>[];
        final sub = conn.states().listen(emitted.add);
        addTearDown(sub.cancel);

        final future = conn.connect();
        await Future<void>.delayed(Duration.zero);
        factory.fire('connection:ready', <String, Object?>{
          'id': 'socket-1',
          'message': 'ready',
          'user': <String, Object?>{},
          'hub_instance_id': 'hub-a',
        });

        final connected = await future;
        check(connected.socketId).equals('socket-1');
        check(conn.isConnected).isTrue();

        factory.fire('disconnect', 'transport close');
        await Future<void>.delayed(Duration.zero);

        check(conn.isConnected).isFalse();
        final last = emitted.last;
        check(last).isA<ConsumerSocketDisconnected>();
        check((last as ConsumerSocketDisconnected).reason).equals(
          'transport close',
        );
      },
    );
  });
}

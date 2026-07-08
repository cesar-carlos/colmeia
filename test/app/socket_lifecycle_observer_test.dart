import 'package:checks/checks.dart';
import 'package:colmeia/app/authentication_gate.dart';
import 'package:colmeia/app/socket_lifecycle_observer.dart';
import 'package:colmeia/core/config/agent_bridge_transport.dart';
import 'package:colmeia/core/socket/consumer_socket_connection.dart';
import 'package:colmeia/core/socket/consumer_socket_connection_state.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockConnection extends Mock implements ConsumerSocketConnection {}

class _StubAuthGate extends ChangeNotifier implements AuthenticationGate {
  bool _isAuthenticated = false;

  @override
  bool get isAuthenticated => _isAuthenticated;

  void setAuthenticated({required bool value}) {
    if (_isAuthenticated == value) {
      return;
    }
    _isAuthenticated = value;
    notifyListeners();
  }
}

Future<void> _pumpObserver(
  WidgetTester tester, {
  required _MockConnection? connection,
  required _StubAuthGate authGate,
  required AgentBridgeTransport transport,
  required bool warmUpAfterLogin,
}) async {
  await tester.pumpWidget(
    MediaQuery(
      data: const MediaQueryData(),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: SocketLifecycleObserver(
          connection: connection,
          authGate: authGate,
          transport: transport,
          warmUpAfterLogin: warmUpAfterLogin,
          child: const SizedBox.shrink(),
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(const ConsumerSocketDisconnected());
  });

  group('SocketLifecycleObserver', () {
    late _MockConnection connection;
    late _StubAuthGate authGate;

    setUp(() {
      connection = _MockConnection();
      when(() => connection.pause()).thenAnswer((_) async {});
      when(() => connection.resume()).thenAnswer(
        (_) async => ConsumerSocketConnected(
          socketId: 'sock-1',
          handshakeAt: DateTime.utc(2026),
        ),
      );
      // states() is called in initState to subscribe to unexpected disconnects.
      when(() => connection.states()).thenAnswer(
        (_) => const Stream<ConsumerSocketConnectionState>.empty(),
      );
      when(() => connection.state).thenReturn(
        const ConsumerSocketDisconnected(reason: 'disconnect'),
      );
      authGate = _StubAuthGate();
    });

    tearDown(() {
      authGate.dispose();
    });

    testWidgets(
      'app paused triggers connection.pause when transport is socket',
      (tester) async {
        await _pumpObserver(
          tester,
          connection: connection,
          authGate: authGate,
          transport: AgentBridgeTransport.socket,
          warmUpAfterLogin: true,
        );

        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.paused,
        );
        await tester.pump();
        verify(() => connection.pause()).called(1);
      },
    );

    testWidgets(
      'app resumed triggers resume when authenticated and transport is socket',
      (tester) async {
        authGate.setAuthenticated(value: true);
        await _pumpObserver(
          tester,
          connection: connection,
          authGate: authGate,
          transport: AgentBridgeTransport.socket,
          warmUpAfterLogin: true,
        );
        // Mounting with an already-authenticated gate triggers the
        // cold-start warm-up (covered by a dedicated test below). Clear
        // the interaction so this test keeps its single concern: the
        // AppLifecycleState.resumed handler must call resume() exactly once.
        await tester.pump();
        clearInteractions(connection);

        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pump();
        verify(() => connection.resume()).called(1);
      },
    );

    testWidgets(
      'app resumed does not resume when there is no session',
      (tester) async {
        await _pumpObserver(
          tester,
          connection: connection,
          authGate: authGate,
          transport: AgentBridgeTransport.socket,
          warmUpAfterLogin: true,
        );

        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pump();
        verifyNever(() => connection.resume());
      },
    );

    testWidgets(
      'transport=rest with null connection disables every lifecycle action',
      (tester) async {
        authGate.setAuthenticated(value: true);
        await _pumpObserver(
          tester,
          connection: null,
          authGate: authGate,
          transport: AgentBridgeTransport.rest,
          warmUpAfterLogin: true,
        );

        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.paused,
        );
        await tester.pump();
        verifyNever(() => connection.pause());

        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pump();
        verifyNever(() => connection.resume());
      },
    );

    testWidgets(
      'REST transport still pauses a non-null connection (relay socket path)',
      (tester) async {
        authGate.setAuthenticated(value: true);
        await _pumpObserver(
          tester,
          connection: connection,
          authGate: authGate,
          transport: AgentBridgeTransport.rest,
          warmUpAfterLogin: true,
        );

        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.paused,
        );
        await tester.pump();
        verify(() => connection.pause()).called(1);
      },
    );

    testWidgets(
      'login transition (null -> authenticated) warms up the socket',
      (tester) async {
        await _pumpObserver(
          tester,
          connection: connection,
          authGate: authGate,
          transport: AgentBridgeTransport.socket,
          warmUpAfterLogin: true,
        );

        authGate.setAuthenticated(value: true);
        await tester.pump();
        verify(() => connection.resume()).called(1);
      },
    );

    testWidgets(
      'warm-up disabled keeps the socket dormant after login',
      (tester) async {
        await _pumpObserver(
          tester,
          connection: connection,
          authGate: authGate,
          transport: AgentBridgeTransport.socket,
          warmUpAfterLogin: false,
        );

        authGate.setAuthenticated(value: true);
        await tester.pump();
        verifyNever(() => connection.resume());
      },
    );

    testWidgets(
      'sign-out transition (authenticated -> null) pauses the socket',
      (tester) async {
        authGate.setAuthenticated(value: true);
        await _pumpObserver(
          tester,
          connection: connection,
          authGate: authGate,
          transport: AgentBridgeTransport.socket,
          warmUpAfterLogin: true,
        );
        clearInteractions(connection);

        authGate.setAuthenticated(value: false);
        await tester.pump();
        verify(() => connection.pause()).called(1);
      },
    );

    testWidgets(
      'pause failure is swallowed (must not crash the app)',
      (tester) async {
        when(() => connection.pause()).thenThrow(StateError('boom'));
        await _pumpObserver(
          tester,
          connection: connection,
          authGate: authGate,
          transport: AgentBridgeTransport.socket,
          warmUpAfterLogin: true,
        );

        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.paused,
        );
        await tester.pump();
        // No exception was thrown above; sanity-check explicit pass.
        check(true).isTrue();
      },
    );

    testWidgets(
      'observer detaches WidgetsBindingObserver on dispose',
      (tester) async {
        await _pumpObserver(
          tester,
          connection: connection,
          authGate: authGate,
          transport: AgentBridgeTransport.socket,
          warmUpAfterLogin: true,
        );
        await tester.pumpWidget(const SizedBox.shrink());

        // After dispose, lifecycle changes must not reach the observer.
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.paused,
        );
        await tester.pump();
        verifyNever(() => connection.pause());
      },
    );

    testWidgets(
      'mount-already-authenticated warms up the socket '
      '(cold-start race fix when restoreSession resolves before initState)',
      (tester) async {
        // Auth gate is already authenticated BEFORE the observer mounts:
        // simulates the cold-start race where the auth restore future
        // completed before the widget tree built.
        authGate.setAuthenticated(value: true);
        await _pumpObserver(
          tester,
          connection: connection,
          authGate: authGate,
          transport: AgentBridgeTransport.socket,
          warmUpAfterLogin: true,
        );
        await tester.pump();
        verify(() => connection.resume()).called(1);
      },
    );

    testWidgets(
      'mount-already-authenticated does not warm up when warmUp is disabled',
      (tester) async {
        authGate.setAuthenticated(value: true);
        await _pumpObserver(
          tester,
          connection: connection,
          authGate: authGate,
          transport: AgentBridgeTransport.socket,
          warmUpAfterLogin: false,
        );
        await tester.pump();
        verifyNever(() => connection.resume());
      },
    );

    testWidgets(
      'mount-already-authenticated does not warm up on REST transport '
      '(no consumer connection wired)',
      (tester) async {
        authGate.setAuthenticated(value: true);
        await _pumpObserver(
          tester,
          connection: null,
          authGate: authGate,
          transport: AgentBridgeTransport.rest,
          warmUpAfterLogin: true,
        );
        await tester.pump();
        verifyNever(() => connection.resume());
      },
    );

    testWidgets(
      'null connection (REST-only build) is a no-op for every action',
      (tester) async {
        // Even on socket transport, a missing connection must not crash:
        // this models the REST-only DI path where ConsumerSocketConnection
        // is never materialised.
        await _pumpObserver(
          tester,
          connection: null,
          authGate: authGate,
          transport: AgentBridgeTransport.socket,
          warmUpAfterLogin: true,
        );

        authGate.setAuthenticated(value: true);
        await tester.pump();

        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.paused,
        );
        await tester.pump();

        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pump();

        authGate.setAuthenticated(value: false);
        await tester.pump();

        // Sanity-check: nothing was thrown above. A separate verifyNever on
        // the unused mock connection is unnecessary because we passed null.
        check(true).isTrue();
      },
    );

    testWidgets(
      'sign-out on REST transport with null connection does not call pause',
      (tester) async {
        authGate.setAuthenticated(value: true);
        await _pumpObserver(
          tester,
          connection: null,
          authGate: authGate,
          transport: AgentBridgeTransport.rest,
          warmUpAfterLogin: true,
        );
        clearInteractions(connection);

        authGate.setAuthenticated(value: false);
        await tester.pump();
        verifyNever(() => connection.pause());
      },
    );
  });
}

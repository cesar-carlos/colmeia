import 'dart:async';

import 'package:checks/checks.dart';
import 'package:colmeia/core/socket/consumer_socket_connection.dart';
import 'package:colmeia/core/socket/consumer_socket_connection_state.dart';
import 'package:colmeia/core/socket/relay/relay_conversation.dart';
import 'package:colmeia/core/socket/relay/relay_conversation_manager.dart';
import 'package:colmeia/core/socket/relay/relay_conversation_pre_warmer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockConnection extends Mock implements ConsumerSocketConnection {}

class _MockConversationManager extends Mock
    implements RelayConversationManager {}

class _MockConversation extends Mock implements RelayConversation {}

ConsumerSocketConnected _connected({String socketId = 'sock-1'}) {
  return ConsumerSocketConnected(
    socketId: socketId,
    handshakeAt: DateTime.utc(2026),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue('');
  });

  late _MockConnection connection;
  late _MockConversationManager manager;
  late StreamController<ConsumerSocketConnectionState> states;
  late _MockConversation fakeConversation;

  setUp(() {
    connection = _MockConnection();
    manager = _MockConversationManager();
    states = StreamController<ConsumerSocketConnectionState>.broadcast();
    fakeConversation = _MockConversation();
    when(() => connection.states()).thenAnswer((_) => states.stream);
    when(() => manager.obtain(any())).thenAnswer((_) async => fakeConversation);
  });

  tearDown(() async {
    await states.close();
  });

  RelayConversationPreWarmer build({
    required RelayPreWarmAgentIdsLoader loader,
    int maxAgents = 8,
    int maxConcurrentStarts = 2,
  }) {
    return RelayConversationPreWarmer(
      connection: connection,
      conversationManager: manager,
      loadAgentIds: loader,
      maxAgents: maxAgents,
      maxConcurrentStarts: maxConcurrentStarts,
    );
  }

  test(
    'opens one conversation per loaded agent on first connected event',
    () async {
      final loadCalls = <int>[];
      final preWarmer = build(
        loader: () async {
          loadCalls.add(1);
          return <String>['agent-a', 'agent-b', 'agent-c'];
        },
      );

      states.add(_connected());
      await pumpEventQueue();

      check(loadCalls).length.equals(1);
      verify(() => manager.obtain('agent-a')).called(1);
      verify(() => manager.obtain('agent-b')).called(1);
      verify(() => manager.obtain('agent-c')).called(1);
      verifyNoMoreInteractions(manager);

      await preWarmer.dispose();
    },
  );

  test('caps the sweep at maxAgents', () async {
    final preWarmer = build(
      loader: () async => List<String>.generate(20, (i) => 'agent-$i'),
      maxAgents: 3,
    );

    states.add(_connected());
    await pumpEventQueue();

    verify(() => manager.obtain('agent-0')).called(1);
    verify(() => manager.obtain('agent-1')).called(1);
    verify(() => manager.obtain('agent-2')).called(1);
    verifyNever(() => manager.obtain('agent-3'));

    await preWarmer.dispose();
  });

  test('skips obtain when the loader returns no agents', () async {
    final preWarmer = build(loader: () async => const <String>[]);

    states.add(_connected());
    await pumpEventQueue();

    verifyNever(() => manager.obtain(any()));

    await preWarmer.dispose();
  });

  test(
    'swallows loader failures and never calls obtain',
    () async {
      final preWarmer = build(loader: () async => throw StateError('boom'));

      states.add(_connected());
      await pumpEventQueue();

      verifyNever(() => manager.obtain(any()));

      await preWarmer.dispose();
    },
  );

  test(
    'swallows per-agent obtain failures so the sweep completes',
    () async {
      when(
        () => manager.obtain('agent-a'),
      ).thenThrow(StateError('not connected'));
      when(
        () => manager.obtain('agent-b'),
      ).thenAnswer((_) async => fakeConversation);

      final preWarmer = build(
        loader: () async => <String>['agent-a', 'agent-b'],
      );

      states.add(_connected());
      await pumpEventQueue();

      verify(() => manager.obtain('agent-a')).called(1);
      verify(() => manager.obtain('agent-b')).called(1);

      await preWarmer.dispose();
    },
  );

  test(
    'consecutive connected events are coalesced into a single in-flight sweep',
    () async {
      final loaderCompleter = Completer<List<String>>();
      final preWarmer = build(loader: () => loaderCompleter.future);

      states
        ..add(_connected())
        ..add(_connected());
      await pumpEventQueue();

      verifyNever(() => manager.obtain(any()));

      loaderCompleter.complete(<String>['agent-a']);
      await pumpEventQueue();

      verify(() => manager.obtain('agent-a')).called(1);
      verifyNoMoreInteractions(manager);

      await preWarmer.dispose();
    },
  );

  test('re-runs the sweep after disconnect + reconnect', () async {
    var calls = 0;
    final preWarmer = build(
      loader: () async {
        calls++;
        return <String>['agent-x'];
      },
    );

    states.add(_connected(socketId: 'sock-first'));
    await pumpEventQueue();

    states.add(const ConsumerSocketDisconnected(reason: 'transport_close'));
    await pumpEventQueue();

    states.add(_connected(socketId: 'sock-second'));
    await pumpEventQueue();

    check(calls).equals(2);
    verify(() => manager.obtain('agent-x')).called(2);

    await preWarmer.dispose();
  });

  test(
    'aborts the in-flight sweep when dispose lands before the loader completes',
    () async {
      final loaderCompleter = Completer<List<String>>();
      final preWarmer = build(loader: () => loaderCompleter.future);

      states.add(_connected());
      await pumpEventQueue();

      await preWarmer.dispose();

      loaderCompleter.complete(<String>['agent-late']);
      await pumpEventQueue();

      verifyNever(() => manager.obtain(any()));
    },
  );

  test('does not subscribe to further state events after dispose', () async {
    final preWarmer = build(loader: () async => <String>['agent-a']);

    await preWarmer.dispose();

    states.add(_connected());
    await pumpEventQueue();

    verifyNever(() => manager.obtain(any()));
  });

  test(
    'ignores Connecting, Error and Unauthorized states without obtaining',
    () async {
      final preWarmer = build(loader: () async => <String>['agent-a']);

      states
        ..add(const ConsumerSocketConnecting(attempt: 1))
        ..add(const ConsumerSocketError(message: 'fail', transient: true))
        ..add(const ConsumerSocketUnauthorized());
      await pumpEventQueue();

      verifyNever(() => manager.obtain(any()));

      await preWarmer.dispose();
    },
  );

  test('throws ArgumentError when maxAgents is not positive', () {
    check(
      () => build(loader: () async => const <String>[], maxAgents: 0),
    ).throws<ArgumentError>();
    check(
      () => build(loader: () async => const <String>[], maxAgents: -1),
    ).throws<ArgumentError>();
  });

  test('throws ArgumentError when maxConcurrentStarts is not positive', () {
    check(
      () => build(
        loader: () async => const <String>[],
        maxConcurrentStarts: 0,
      ),
    ).throws<ArgumentError>();
  });

  test(
    'does not start more than maxConcurrentStarts obtains at once',
    () async {
      final started = <String>[];
      final gates = <String, Completer<RelayConversation>>{
        'agent-a': Completer<RelayConversation>(),
        'agent-b': Completer<RelayConversation>(),
        'agent-c': Completer<RelayConversation>(),
      };
      when(() => manager.obtain(any())).thenAnswer((invocation) {
        final id = invocation.positionalArguments[0] as String;
        started.add(id);
        return gates[id]!.future;
      });

      final preWarmer = build(
        loader: () async => <String>['agent-a', 'agent-b', 'agent-c'],
      );

      states.add(_connected());
      await pumpEventQueue();

      check(started).deepEquals(<String>['agent-a', 'agent-b']);
      verifyNever(() => manager.obtain('agent-c'));

      gates['agent-a']!.complete(fakeConversation);
      await pumpEventQueue();

      check(started).deepEquals(<String>['agent-a', 'agent-b']);
      verifyNever(() => manager.obtain('agent-c'));

      gates['agent-b']!.complete(fakeConversation);
      await pumpEventQueue();

      check(started).deepEquals(<String>['agent-a', 'agent-b', 'agent-c']);
      verify(() => manager.obtain('agent-c')).called(1);

      gates['agent-c']!.complete(fakeConversation);
      await pumpEventQueue();
      await preWarmer.dispose();
    },
  );

  test(
    'aborts remaining obtain waves when the socket disconnects mid-sweep',
    () async {
      final firstWave = Completer<RelayConversation>();
      when(() => manager.obtain('agent-a')).thenAnswer((_) => firstWave.future);
      when(() => manager.obtain('agent-b')).thenAnswer((_) => firstWave.future);
      when(
        () => manager.obtain('agent-c'),
      ).thenAnswer((_) async => fakeConversation);

      final preWarmer = build(
        loader: () async => <String>['agent-a', 'agent-b', 'agent-c'],
      );

      states.add(_connected());
      await pumpEventQueue();

      verify(() => manager.obtain('agent-a')).called(1);
      verify(() => manager.obtain('agent-b')).called(1);
      verifyNever(() => manager.obtain('agent-c'));

      states.add(const ConsumerSocketDisconnected(reason: 'transport_close'));
      await pumpEventQueue();

      firstWave.complete(fakeConversation);
      await pumpEventQueue();

      verifyNever(() => manager.obtain('agent-c'));

      await preWarmer.dispose();
    },
  );

  // Regression for the disconnect-during-sweep race: when the socket drops
  // while the loader is still in-flight, the sweep must short-circuit
  // before issuing any `obtain()` call. Otherwise the next reconnect would
  // start a parallel sweep and both could race against
  // RelayConversationManager.obtain() for the same agentId, leaving orphan
  // conversationIds on the hub.
  test(
    'aborts the in-flight sweep when the socket disconnects before the '
    'loader completes',
    () async {
      final loaderCompleter = Completer<List<String>>();
      final preWarmer = build(loader: () => loaderCompleter.future);

      states.add(_connected(socketId: 'sock-first'));
      await pumpEventQueue();

      states.add(const ConsumerSocketDisconnected(reason: 'transport_close'));
      await pumpEventQueue();

      loaderCompleter.complete(<String>['agent-a', 'agent-b']);
      await pumpEventQueue();

      verifyNever(() => manager.obtain(any()));

      await preWarmer.dispose();
    },
  );

  // After the previous abort, a fresh `connected` event must still trigger
  // a brand-new sweep using the latest loader result — proving the
  // generation guard cleans `_inFlight` correctly even when the stale
  // sweep is allowed to complete silently.
  test(
    'restarts the sweep after a stale one was aborted by disconnect',
    () async {
      var loaderInvocations = 0;
      final firstLoader = Completer<List<String>>();
      final secondLoader = Completer<List<String>>();
      final preWarmer = build(
        loader: () {
          loaderInvocations++;
          return loaderInvocations == 1
              ? firstLoader.future
              : secondLoader.future;
        },
      );

      states.add(_connected());
      await pumpEventQueue();

      states.add(const ConsumerSocketDisconnected(reason: 'transport_close'));
      await pumpEventQueue();

      firstLoader.complete(<String>['agent-stale']);
      await pumpEventQueue();

      verifyNever(() => manager.obtain(any()));

      states.add(_connected(socketId: 'sock-2'));
      await pumpEventQueue();

      secondLoader.complete(<String>['agent-fresh']);
      await pumpEventQueue();

      check(loaderInvocations).equals(2);
      verifyNever(() => manager.obtain('agent-stale'));
      verify(() => manager.obtain('agent-fresh')).called(1);

      await preWarmer.dispose();
    },
  );
}

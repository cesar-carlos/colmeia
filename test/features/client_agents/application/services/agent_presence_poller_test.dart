// Test-only: sequential `poller.start()` / `poller.stop()` reads
// better as separate statements that mark the test phases (arrange,
// act, repeat-act) than as cascades.
// ignore_for_file: cascade_invocations

import 'dart:async';

import 'package:checks/checks.dart';
import 'package:colmeia/features/client_agents/application/services/agent_presence_poller.dart';
import 'package:colmeia/features/client_agents/domain/events/agent_presence_event.dart';
import 'package:colmeia/features/client_agents/domain/repositories/client_agents_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockClientAgentsRepository extends Mock
    implements ClientAgentsRepository {}

void main() {
  late _MockClientAgentsRepository repository;
  late StreamController<AgentPresenceEvent> sink;

  setUp(() {
    repository = _MockClientAgentsRepository();
    sink = StreamController<AgentPresenceEvent>.broadcast();
  });

  tearDown(() => sink.close());

  AgentPresencePoller buildPoller({
    Duration interval = const Duration(milliseconds: 50),
  }) {
    return AgentPresencePoller(
      clientAgentsRepository: repository,
      sink: sink.sink,
      interval: interval,
    );
  }

  group('AgentPresencePoller', () {
    test(
      'start fires an immediate tick and converts each id into an online hint',
      () async {
        when(
          () => repository.loadOnlineAgentIds(userId: any(named: 'userId')),
        ).thenAnswer((_) async => <String>{'a1', 'a2'});

        final poller = buildPoller();
        addTearDown(poller.dispose);

        final events = <AgentPresenceEvent>[];
        final sub = sink.stream.listen(events.add);
        addTearDown(sub.cancel);

        poller.start(userId: 'client-1');
        // Yield twice: once for the immediate tick's await chain, once
        // for the broadcast delivery to the listener.
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);

        check(events.length).equals(2);
        for (final event in events) {
          check(event).isA<AgentPresenceHint>();
          final hint = event as AgentPresenceHint;
          check(hint.online).isTrue();
          check(hint.source).equals('polling_rest');
        }
        check(<String>{
          for (final hint in events.cast<AgentPresenceHint>()) hint.agentId,
        }).deepEquals(<String>{'a1', 'a2'});
      },
    );

    test('start is idempotent for the same userId', () async {
      when(
        () => repository.loadOnlineAgentIds(userId: any(named: 'userId')),
      ).thenAnswer((_) async => <String>{});

      final poller = buildPoller(interval: const Duration(milliseconds: 200));
      addTearDown(poller.dispose);

      poller.start(userId: 'client-1');
      poller.start(userId: 'client-1');
      poller.start(userId: 'client-1');

      // Allow the immediate tick to settle.
      await Future<void>.delayed(const Duration(milliseconds: 20));
      check(poller.isRunning).isTrue();
      verify(
        () => repository.loadOnlineAgentIds(userId: 'client-1'),
      ).called(1);
    });

    test('start with a different userId reschedules the timer', () async {
      when(
        () => repository.loadOnlineAgentIds(userId: any(named: 'userId')),
      ).thenAnswer((_) async => <String>{});

      final poller = buildPoller(interval: const Duration(milliseconds: 500));
      addTearDown(poller.dispose);

      poller.start(userId: 'client-1');
      poller.start(userId: 'client-2');
      await Future<void>.delayed(const Duration(milliseconds: 20));

      verify(
        () => repository.loadOnlineAgentIds(userId: 'client-1'),
      ).called(1);
      verify(
        () => repository.loadOnlineAgentIds(userId: 'client-2'),
      ).called(1);
    });

    test('null result from repository emits NO hint', () async {
      when(
        () => repository.loadOnlineAgentIds(userId: any(named: 'userId')),
      ).thenAnswer((_) async => null);

      final poller = buildPoller();
      addTearDown(poller.dispose);
      final events = <AgentPresenceEvent>[];
      final sub = sink.stream.listen(events.add);
      addTearDown(sub.cancel);

      poller.start(userId: 'client-1');
      await Future<void>.delayed(const Duration(milliseconds: 20));

      check(events).isEmpty();
    });

    test(
      'repository error is logged and swallowed; poller stays alive',
      () async {
        var calls = 0;
        when(
          () => repository.loadOnlineAgentIds(userId: any(named: 'userId')),
        ).thenAnswer((_) async {
          calls += 1;
          throw StateError('boom');
        });

        final poller = buildPoller(interval: const Duration(milliseconds: 30));
        addTearDown(poller.dispose);

        poller.start(userId: 'client-1');
        await Future<void>.delayed(const Duration(milliseconds: 100));

        check(calls).isGreaterOrEqual(2);
        check(poller.isRunning).isTrue();
      },
    );

    test('stop cancels the timer and is idempotent', () async {
      when(
        () => repository.loadOnlineAgentIds(userId: any(named: 'userId')),
      ).thenAnswer((_) async => <String>{});

      final poller = buildPoller();
      addTearDown(poller.dispose);

      poller.start(userId: 'client-1');
      poller.stop();
      poller.stop();
      await Future<void>.delayed(const Duration(milliseconds: 30));
      check(poller.isRunning).isFalse();
    });

    test('does not emit hints after stop while a tick is still in flight', () async {
      final completer = Completer<Set<String>?>();
      when(
        () => repository.loadOnlineAgentIds(userId: any(named: 'userId')),
      ).thenAnswer((_) => completer.future);

      final poller = buildPoller();
      addTearDown(poller.dispose);
      final events = <AgentPresenceEvent>[];
      final sub = sink.stream.listen(events.add);
      addTearDown(sub.cancel);

      poller.start(userId: 'client-1');
      await Future<void>.delayed(Duration.zero);
      poller.stop();
      completer.complete(<String>{'a1'});
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      check(events).isEmpty();
    });

    test('drops stale hints from the previous user after a mid-flight switch', () async {
      final firstUser = Completer<Set<String>?>();
      final secondUser = Completer<Set<String>?>();
      when(
        () => repository.loadOnlineAgentIds(userId: 'client-1'),
      ).thenAnswer((_) => firstUser.future);
      when(
        () => repository.loadOnlineAgentIds(userId: 'client-2'),
      ).thenAnswer((_) => secondUser.future);

      final poller = buildPoller(interval: const Duration(milliseconds: 500));
      addTearDown(poller.dispose);
      final events = <AgentPresenceEvent>[];
      final sub = sink.stream.listen(events.add);
      addTearDown(sub.cancel);

      poller.start(userId: 'client-1');
      await Future<void>.delayed(Duration.zero);
      poller.start(userId: 'client-2');
      firstUser.complete(<String>{'stale-a1'});
      secondUser.complete(<String>{'fresh-a2'});
      await Future<void>.delayed(const Duration(milliseconds: 20));

      check(events.length).equals(1);
      final hint = events.single as AgentPresenceHint;
      check(hint.agentId).equals('fresh-a2');
    });
  });
}

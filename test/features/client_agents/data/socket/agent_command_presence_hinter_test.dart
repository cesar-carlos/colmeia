// Test-only: sequential `hinter.attach() → hinter.dispose()` calls
// inside arrange/act phases read more clearly than cascades.
// ignore_for_file: cascade_invocations

import 'dart:async';

import 'package:checks/checks.dart';
import 'package:colmeia/core/socket/agent_command_outcome.dart';
import 'package:colmeia/core/socket/socket_command_dispatcher.dart';
import 'package:colmeia/features/client_agents/data/socket/agent_command_presence_hinter.dart';
import 'package:colmeia/features/client_agents/domain/events/agent_presence_event.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDispatcher extends Mock implements SocketCommandDispatcher {}

void main() {
  late _MockDispatcher dispatcher;
  late StreamController<AgentCommandOutcome> outcomes;
  late StreamController<AgentPresenceEvent> sink;
  late AgentCommandPresenceHinter hinter;

  setUp(() {
    dispatcher = _MockDispatcher();
    outcomes = StreamController<AgentCommandOutcome>.broadcast();
    // Broadcast so close() does not require a listener to drain. The
    // production stream (`SocketAgentPresenceStream`) is also broadcast.
    sink = StreamController<AgentPresenceEvent>.broadcast();
    when(dispatcher.outcomes).thenAnswer((_) => outcomes.stream);
    hinter = AgentCommandPresenceHinter(
      dispatcher: dispatcher,
      sink: sink.sink,
    );
  });

  tearDown(() async {
    await hinter.dispose();
    await outcomes.close();
    await sink.close();
  });

  group('AgentCommandPresenceHinter', () {
    test('attach is idempotent', () {
      hinter.attach();
      hinter.attach();
      check(hinter.isAttached).isTrue();
    });

    test('Success outcome emits an online hint with the right source',
        () async {
      hinter.attach();
      final emitted = sink.stream.toList();

      outcomes.add(
        AgentCommandSuccess(
          agentId: 'agent-1',
          rpcId: 'r1',
          observedAt: DateTime.utc(2026, 4, 17),
          elapsed: Duration.zero,
          method: 'sql.execute',
        ),
      );
      await Future<void>.delayed(Duration.zero);
      await sink.close();

      final list = await emitted;
      check(list.length).equals(1);
      final hint = list.single as AgentPresenceHint;
      check(hint.agentId).equals('agent-1');
      check(hint.online).isTrue();
      check(hint.source).equals('agents:command_success');
    });

    test('FailedOffline outcome emits an offline hint', () async {
      hinter.attach();
      final emitted = sink.stream.toList();

      outcomes.add(
        AgentCommandFailedOffline(
          agentId: 'agent-2',
          rpcId: 'r2',
          observedAt: DateTime.utc(2026, 4, 17),
          elapsed: Duration.zero,
          reasonCode: 'AGENT_OFFLINE',
        ),
      );
      await Future<void>.delayed(Duration.zero);
      await sink.close();

      final list = await emitted;
      check(list.length).equals(1);
      final hint = list.single as AgentPresenceHint;
      check(hint.agentId).equals('agent-2');
      check(hint.online).isFalse();
      check(hint.source).equals('agents:command_error_offline');
    });

    test('FailedAuth outcome emits NO hint', () async {
      hinter.attach();
      final emitted = sink.stream.toList();

      outcomes.add(
        AgentCommandFailedAuth(
          agentId: 'agent-3',
          rpcId: 'r3',
          observedAt: DateTime.utc(2026, 4, 17),
          elapsed: Duration.zero,
          reasonCode: 'AGENT_ACCESS_DENIED',
        ),
      );
      await Future<void>.delayed(Duration.zero);
      await sink.close();

      check(await emitted).isEmpty();
    });

    test('FailedTransient outcome emits NO hint', () async {
      hinter.attach();
      final emitted = sink.stream.toList();

      outcomes.add(
        AgentCommandFailedTransient(
          agentId: 'agent-4',
          rpcId: 'r4',
          observedAt: DateTime.utc(2026, 4, 17),
          elapsed: Duration.zero,
          reasonCode: 'timeout',
        ),
      );
      await Future<void>.delayed(Duration.zero);
      await sink.close();

      check(await emitted).isEmpty();
    });

    test('dispose cancels the subscription and is idempotent', () async {
      hinter.attach();
      check(hinter.isAttached).isTrue();
      await hinter.dispose();
      await hinter.dispose();
      check(hinter.isAttached).isFalse();
    });
  });
}

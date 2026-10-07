import 'dart:async';

import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/data/agent_sql_execution_eligibility_checker.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_catalog_status.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_connection_status.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_approved_agent_probe_outcome.dart';
import 'package:colmeia/features/client_agents/domain/repositories/client_agents_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

class _MockClientAgentsRepository extends Mock
    implements ClientAgentsRepository {}

void main() {
  late _MockClientAgentsRepository repo;
  late AgentSqlExecutionEligibilityChecker checker;

  setUp(() {
    repo = _MockClientAgentsRepository();
    checker = AgentSqlExecutionEligibilityChecker(clientAgentsRepository: repo);
    when(
      () => repo.probeApprovedAgentLink(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
      ),
    ).thenAnswer((_) async => Success(_probe(AgentConnectionStatus.offline)));
  });

  test('allows when online snapshot is missing', () async {
    when(
      () => repo.loadOnlineAgentIds(userId: any(named: 'userId')),
    ).thenAnswer((_) async => null);

    final out = await checker.evaluate(userId: 'u1', agentId: 'a1');

    check(out.allowed).isTrue();
  });

  test(
    'confirms an explicit offline catalog flag even without a cache',
    () async {
      when(() => repo.loadOnlineAgentIds(userId: 'u1'))
          .thenAnswer((_) async => null);
      final out = await checker.evaluate(
        userId: 'u1',
        agentId: 'a1',
        isHubConnected: false,
      );
      check(out.allowed).isFalse();
      verify(() => repo.probeApprovedAgentLink(userId: 'u1', agentId: 'a1'))
          .called(1);
    },
  );

  test('uses snapshot override without calling loadOnlineAgentIds', () async {
    final out = await checker.evaluate(
      userId: 'u1',
      agentId: 'a1',
      hubPresenceOnlineAgentIdsSnapshot: <String>{},
    );

    check(out.allowed).isFalse();
    verifyNever(
      () => repo.loadOnlineAgentIds(userId: any(named: 'userId')),
    );
  });

  test('reuses cached online ids within TTL across evaluate calls', () async {
    when(
      () => repo.loadOnlineAgentIds(userId: 'u1'),
    ).thenAnswer((_) async => <String>{'a1'});

    await checker.evaluate(userId: 'u1', agentId: 'a1');
    await checker.evaluate(userId: 'u1', agentId: 'a1');

    verify(() => repo.loadOnlineAgentIds(userId: 'u1')).called(1);
  });

  test('allows when agent is in online set', () async {
    when(
      () => repo.loadOnlineAgentIds(userId: any(named: 'userId')),
    ).thenAnswer((_) async => <String>{'a1'});

    final out = await checker.evaluate(userId: 'u1', agentId: 'a1');

    check(out.allowed).isTrue();
  });

  test('denies when snapshot exists and agent is not online', () async {
    when(
      () => repo.loadOnlineAgentIds(userId: any(named: 'userId')),
    ).thenAnswer((_) async => <String>{});

    final out = await checker.evaluate(userId: 'u1', agentId: 'a1');

    check(out.allowed).isFalse();
    check(out.denialReason).isNotNull();
  });

  test(
    'refreshes a negative snapshot and allows an agent that reconnected',
    () async {
      when(
        () => repo.probeApprovedAgentLink(userId: 'u1', agentId: 'a1'),
      ).thenAnswer((_) async => Success(_probe(AgentConnectionStatus.online)));
      final out = await checker.evaluate(
        userId: 'u1',
        agentId: 'a1',
        isHubConnected: false,
        hubPresenceOnlineAgentIdsSnapshot: {},
      );
      check(out.allowed).isTrue();
      verify(() => repo.probeApprovedAgentLink(userId: 'u1', agentId: 'a1'))
          .called(1);
    },
  );

  test('does not use an old snapshot when the probe omits presence', () async {
    when(
      () => repo.probeApprovedAgentLink(userId: 'u1', agentId: 'a1'),
    ).thenAnswer((_) async => Success(_probe(AgentConnectionStatus.unknown)));
    final out = await checker.evaluate(
      userId: 'u1',
      agentId: 'a1',
      hubPresenceOnlineAgentIdsSnapshot: {},
    );
    check(out.allowed).isTrue();
  });

  test('rejects an agent whose account link was removed', () async {
    when(() => repo.probeApprovedAgentLink(userId: 'u1', agentId: 'a1'))
        .thenAnswer(
          (_) async =>
              const Success(ClientApprovedAgentProbeOutcome.notLinked()),
        );
    final out = await checker.evaluate(
      userId: 'u1',
      agentId: 'a1',
      hubPresenceOnlineAgentIdsSnapshot: {},
    );
    check(out.allowed).isFalse();
    check(out.denialReason).isNotNull().contains('not linked');
  });

  test(
    'preserves authentication failure instead of reporting offline',
    () async {
      const failure = SessionFailure(message: 'Expired session');
      when(() => repo.probeApprovedAgentLink(userId: 'u1', agentId: 'a1'))
          .thenAnswer((_) async => const Failure(failure));
      final out = await checker.evaluate(
        userId: 'u1',
        agentId: 'a1',
        hubPresenceOnlineAgentIdsSnapshot: {},
      );
      expect(out.failure, same(failure));
      check(out.allowed).isFalse();
    },
  );

  test(
    'coalesces simultaneous negative checks and clears completed probes',
    () async {
      final pending =
          Completer<Success<ClientApprovedAgentProbeOutcome, AppFailure>>();
      when(() => repo.probeApprovedAgentLink(userId: 'u1', agentId: 'a1'))
          .thenAnswer((_) => pending.future);
      final first = checker.evaluate(
        userId: 'u1',
        agentId: 'a1',
        hubPresenceOnlineAgentIdsSnapshot: {},
      );
      final second = checker.evaluate(
        userId: 'u1',
        agentId: 'a1',
        hubPresenceOnlineAgentIdsSnapshot: {},
      );
      verify(() => repo.probeApprovedAgentLink(userId: 'u1', agentId: 'a1'))
          .called(1);
      pending.complete(Success(_probe(AgentConnectionStatus.offline)));
      await Future.wait([first, second]);
      await checker.evaluate(
        userId: 'u1',
        agentId: 'a1',
        hubPresenceOnlineAgentIdsSnapshot: {},
      );
      verify(() => repo.probeApprovedAgentLink(userId: 'u1', agentId: 'a1'))
          .called(1);
    },
  );
}

ClientApprovedAgentProbeOutcome _probe(AgentConnectionStatus status) =>
    ClientApprovedAgentProbeOutcome.linked(
      ClientAgent(
        agentId: 'a1',
        name: 'Agent',
        catalogStatus: AgentCatalogStatus.active,
        connectionStatus: status,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
    );

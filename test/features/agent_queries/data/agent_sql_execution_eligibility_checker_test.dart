import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/data/agent_sql_execution_eligibility_checker.dart';
import 'package:colmeia/features/client_agents/domain/repositories/client_agents_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockClientAgentsRepository extends Mock
    implements ClientAgentsRepository {}

void main() {
  late _MockClientAgentsRepository repo;
  late AgentSqlExecutionEligibilityChecker checker;

  setUp(() {
    repo = _MockClientAgentsRepository();
    checker = AgentSqlExecutionEligibilityChecker(clientAgentsRepository: repo);
  });

  test('allows when online snapshot is missing', () async {
    when(
      () => repo.loadOnlineAgentIds(userId: any(named: 'userId')),
    ).thenAnswer((_) async => null);

    final out = await checker.evaluate(userId: 'u1', agentId: 'a1');

    check(out.allowed).isTrue();
  });

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
}

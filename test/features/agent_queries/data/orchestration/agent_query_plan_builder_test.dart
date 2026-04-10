import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/application/orchestration/agent_query_plan_builder.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_key.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target_resolution.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_connection_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AgentQueryPlanBuilder builder;

  setUp(() {
    builder = AgentQueryPlanBuilder();
  });

  test('should require exactly one target for single source', () async {
    final result = builder.build(
      queryKey: AgentQueryKey.resumoParcelaFormaPagamento,
      strategy: AgentQueryExecutionStrategy.singleSource,
      resolution: _resolution(targets: [_target('a'), _target('b')]),
    );

    check(result.isError()).isTrue();
    check(result.exceptionOrNull()).isA<ValidationFailure>();
  });

  test(
    'should use default timeout and keep missing token targets in merge all',
    () async {
      final result = builder.build(
        queryKey: AgentQueryKey.resumoParcelaFormaPagamento,
        strategy: AgentQueryExecutionStrategy.mergeAll,
        resolution: _resolution(
          targets: <AgentQueryTarget>[
            _target('agent-a'),
            _target('agent-b', clientToken: null),
          ],
        ),
      );

      check(result.isSuccess()).isTrue();
      final plan = result.getOrThrow();
      check(plan.bridgeTimeoutMs).equals(
        AgentQueryPlanBuilder.defaultBridgeTimeoutMs,
      );
      check(plan.plannedTargets.map((target) => target.agentId)).deepEquals(
        const <String>['agent-a'],
      );
      check(
        plan.missingClientTokenTargets.map((target) => target.agentId),
      ).deepEquals(const <String>['agent-b']);
    },
  );

  test(
    'should apply default race max sources and cap planned targets',
    () async {
      final result = builder.build(
        queryKey: AgentQueryKey.resumoParcelaFormaPagamento,
        strategy: AgentQueryExecutionStrategy.race,
        resolution: _resolution(
          targets: <AgentQueryTarget>[
            _target('agent-a'),
            _target('agent-b'),
            _target('agent-c'),
            _target('agent-d'),
            _target('agent-e'),
          ],
        ),
      );

      check(result.isSuccess()).isTrue();
      final plan = result.getOrThrow();
      check(
        plan.raceMaxSources,
      ).equals(AgentQueryPlanBuilder.defaultRaceMaxSources);
      check(plan.plannedTargets.map((target) => target.agentId)).deepEquals(
        const <String>['agent-a', 'agent-b', 'agent-c', 'agent-d'],
      );
    },
  );

  test('should fail when race max sources is invalid', () async {
    final result = builder.build(
      queryKey: AgentQueryKey.resumoParcelaFormaPagamento,
      strategy: AgentQueryExecutionStrategy.race,
      resolution: _resolution(targets: [_target('agent-a')]),
      raceMaxSources: 0,
    );

    check(result.isError()).isTrue();
    check(result.exceptionOrNull()).isA<ValidationFailure>();
  });
}

AgentQueryTargetResolution _resolution({
  required List<AgentQueryTarget> targets,
}) {
  return AgentQueryTargetResolution(
    consideredApprovedTargets: targets,
    missingClientTokenTargets: targets
        .where((target) => !target.hasClientToken)
        .toList(growable: false),
    consideredApprovedAgentCount: targets.length,
  );
}

AgentQueryTarget _target(String agentId, {String? clientToken = 'token'}) {
  return AgentQueryTarget(
    agentId: agentId,
    displayName: agentId,
    connectionStatus: AgentConnectionStatus.online,
    clientToken: clientToken,
  );
}

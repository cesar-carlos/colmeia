import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/agent_queries/application/orchestration/agent_query_executor.dart';
import 'package:colmeia/features/agent_queries/application/orchestration/agent_query_plan_builder.dart';
import 'package:colmeia/features/agent_queries/data/repositories/agent_query_list_report_across_agents_coordinator.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_key.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_plan.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target_resolution.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_query_target_resolver.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_connection_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

class _MockTargetResolver extends Mock implements AgentQueryTargetResolver {}

class _MockPlanBuilder extends Mock implements AgentQueryPlanBuilder {}

void main() {
  const operation = 'testCoordinatorOp';
  const userId = 'user-1';
  const filter = 'filter-value';

  late Level savedAppLoggerMinimumLevel;

  late _MockTargetResolver targetResolver;
  late _MockPlanBuilder planBuilder;
  late AgentQueryExecutor<String> executor;

  AgentQueryTarget target({
    required String agentId,
    String? clientToken,
  }) {
    return AgentQueryTarget(
      agentId: agentId,
      displayName: agentId,
      connectionStatus: AgentConnectionStatus.online,
      clientToken: clientToken,
    );
  }

  setUpAll(() {
    savedAppLoggerMinimumLevel = AppLogger.minimumLevel;
    AppLogger.minimumLevel = Level.off;
    registerFallbackValue(
      const AgentQueryTargetResolution(
        consideredApprovedTargets: <AgentQueryTarget>[],
        missingClientTokenTargets: <AgentQueryTarget>[],
        consideredApprovedAgentCount: 0,
      ),
    );
    registerFallbackValue(AgentQueryKey.resumoParcelasDiaSemana);
    registerFallbackValue(AgentQueryExecutionStrategy.mergeAll);
  });

  tearDownAll(() {
    AppLogger.minimumLevel = savedAppLoggerMinimumLevel;
  });

  setUp(() {
    targetResolver = _MockTargetResolver();
    planBuilder = _MockPlanBuilder();
    executor = AgentQueryExecutor<String>();
  });

  test(
    'returns failure when target resolution fails without building plan',
    () async {
      when(
        () => targetResolver.resolve(
          userId: any(named: 'userId'),
          selectedAgentIds: any(named: 'selectedAgentIds'),
        ),
      ).thenAnswer(
        (_) async => const Failure<AgentQueryTargetResolution, AppFailure>(
          ValidationFailure(message: 'resolution failed'),
        ),
      );

      final result =
          await AgentQueryListReportAcrossAgentsCoordinator.execute<
            String,
            String
          >(
            operation: operation,
            queryKey: AgentQueryKey.resumoParcelasDiaSemana,
            userId: userId,
            filter: filter,
            targetResolver: targetResolver,
            planBuilder: planBuilder,
            executor: executor,
            loadRowsForTarget: ({
              required userId,
              required agentId,
              required filter,
              clientToken,
              bridgeTimeoutMs,
              hubPresenceOnlineAgentIdsSnapshot,
              hubConnectedFromApprovedCatalogRow,
            }) async => throw StateError('loadRowsForTarget'),
          );

      check(result.isError()).isTrue();
      final failure = result.exceptionOrNull()!;
      check(failure).isA<ValidationFailure>();
      check(
        failure.context['sourceAgentIds']! as List<String>,
      ).deepEquals(const <String>[]);

      verifyNever(
        () => planBuilder.build(
          queryKey: any(named: 'queryKey'),
          strategy: any(named: 'strategy'),
          resolution: any(named: 'resolution'),
          bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
          raceMaxSources: any(named: 'raceMaxSources'),
        ),
      );
    },
  );

  test(
    'returns failure when plan build fails and merges resolution context',
    () async {
      final t = target(agentId: 'agent-a', clientToken: 'tok');
      final resolution = AgentQueryTargetResolution(
        consideredApprovedTargets: <AgentQueryTarget>[t],
        missingClientTokenTargets: <AgentQueryTarget>[],
        consideredApprovedAgentCount: 1,
      );
      when(
        () => targetResolver.resolve(
          userId: any(named: 'userId'),
          selectedAgentIds: any(named: 'selectedAgentIds'),
        ),
      ).thenAnswer(
        (_) async =>
            Success<AgentQueryTargetResolution, AppFailure>(resolution),
      );
      when(
        () => planBuilder.build(
          queryKey: any(named: 'queryKey'),
          strategy: any(named: 'strategy'),
          resolution: any(named: 'resolution'),
          bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
          raceMaxSources: any(named: 'raceMaxSources'),
        ),
      ).thenReturn(
        const Failure<AgentQueryPlan, AppFailure>(
          ValidationFailure(message: 'plan invalid'),
        ),
      );

      var loadInvoked = false;
      final result =
          await AgentQueryListReportAcrossAgentsCoordinator.execute<
            String,
            String
          >(
            operation: operation,
            queryKey: AgentQueryKey.resumoParcelasDiaSemana,
            userId: userId,
            filter: filter,
            targetResolver: targetResolver,
            planBuilder: planBuilder,
            executor: executor,
            loadRowsForTarget:
                ({
                  required userId,
                  required agentId,
                  required filter,
                  clientToken,
                  bridgeTimeoutMs,
                  hubPresenceOnlineAgentIdsSnapshot,
                  hubConnectedFromApprovedCatalogRow,
                }) async {
                  loadInvoked = true;
                  return const Success<List<String>, AppFailure>(<String>['x']);
                },
          );

      check(result.isError()).isTrue();
      check(loadInvoked).isFalse();
      final failure = result.exceptionOrNull()!;
      check(
        failure.context['sourceAgentIds']! as List<String>,
      ).deepEquals(<String>['agent-a']);
    },
  );

  test(
    'returns failure when executor yields only failures and '
    'merges plan context',
    () async {
      final t = target(agentId: 'agent-z', clientToken: 'tok-z');
      final resolution = AgentQueryTargetResolution(
        consideredApprovedTargets: <AgentQueryTarget>[t],
        missingClientTokenTargets: <AgentQueryTarget>[],
        consideredApprovedAgentCount: 1,
      );
      final plan = AgentQueryPlan(
        queryKey: AgentQueryKey.resumoParcelasDiaSemana,
        strategy: AgentQueryExecutionStrategy.mergeAll,
        consideredApprovedAgentCount: 1,
        plannedTargets: <AgentQueryTarget>[t],
        missingClientTokenTargets: <AgentQueryTarget>[],
        bridgeTimeoutMs: 55_000,
      );
      when(
        () => targetResolver.resolve(
          userId: any(named: 'userId'),
          selectedAgentIds: any(named: 'selectedAgentIds'),
        ),
      ).thenAnswer(
        (_) async =>
            Success<AgentQueryTargetResolution, AppFailure>(resolution),
      );
      when(
        () => planBuilder.build(
          queryKey: any(named: 'queryKey'),
          strategy: any(named: 'strategy'),
          resolution: any(named: 'resolution'),
          bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
          raceMaxSources: any(named: 'raceMaxSources'),
        ),
      ).thenReturn(Success<AgentQueryPlan, AppFailure>(plan));

      final result =
          await AgentQueryListReportAcrossAgentsCoordinator.execute<
            String,
            String
          >(
            operation: operation,
            queryKey: AgentQueryKey.resumoParcelasDiaSemana,
            userId: userId,
            filter: filter,
            targetResolver: targetResolver,
            planBuilder: planBuilder,
            executor: executor,
            loadRowsForTarget:
                ({
                  required userId,
                  required agentId,
                  required filter,
                  clientToken,
                  bridgeTimeoutMs,
                  hubPresenceOnlineAgentIdsSnapshot,
                  hubConnectedFromApprovedCatalogRow,
                }) async {
                  check(userId).equals('user-1');
                  check(agentId).equals('agent-z');
                  check(filter).equals('filter-value');
                  check(clientToken).equals('tok-z');
                  check(bridgeTimeoutMs).equals(55_000);
                  return const Failure<List<String>, AppFailure>(
                    ValidationFailure(message: 'load failed'),
                  );
                },
          );

      check(result.isError()).isTrue();
      final failure = result.exceptionOrNull()!;
      check(failure.context['operation']).equals(operation);
      check(failure.context['userId']).equals(userId);
      check(failure.context['queryKey']).equals(
        AgentQueryKey.resumoParcelasDiaSemana.name,
      );
      check(
        failure.context['sourceAgentIds']! as List<String>,
      ).deepEquals(<String>['agent-z']);
    },
  );

  test(
    'returns success report and forwards plan bridgeTimeoutMs to loader',
    () async {
      final t = target(agentId: 'agent-b', clientToken: 'tok-b');
      final missing = target(agentId: 'agent-c');
      final resolution = AgentQueryTargetResolution(
        consideredApprovedTargets: <AgentQueryTarget>[t, missing],
        missingClientTokenTargets: <AgentQueryTarget>[missing],
        consideredApprovedAgentCount: 2,
      );
      final plan = AgentQueryPlan(
        queryKey: AgentQueryKey.resumoParcelasDiaSemana,
        strategy: AgentQueryExecutionStrategy.mergeAll,
        consideredApprovedAgentCount: 2,
        plannedTargets: <AgentQueryTarget>[t],
        missingClientTokenTargets: <AgentQueryTarget>[missing],
        bridgeTimeoutMs: 88_000,
      );
      when(
        () => targetResolver.resolve(
          userId: any(named: 'userId'),
          selectedAgentIds: any(named: 'selectedAgentIds'),
        ),
      ).thenAnswer(
        (_) async =>
            Success<AgentQueryTargetResolution, AppFailure>(resolution),
      );
      when(
        () => planBuilder.build(
          queryKey: any(named: 'queryKey'),
          strategy: any(named: 'strategy'),
          resolution: any(named: 'resolution'),
          bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
          raceMaxSources: any(named: 'raceMaxSources'),
        ),
      ).thenReturn(Success<AgentQueryPlan, AppFailure>(plan));

      final result =
          await AgentQueryListReportAcrossAgentsCoordinator.execute<
            String,
            String
          >(
            operation: operation,
            queryKey: AgentQueryKey.resumoParcelasDiaSemana,
            userId: userId,
            filter: filter,
            targetResolver: targetResolver,
            planBuilder: planBuilder,
            executor: executor,
            selectedAgentIds: const <String>{'agent-b'},
            loadRowsForTarget:
                ({
                  required userId,
                  required agentId,
                  required filter,
                  clientToken,
                  bridgeTimeoutMs,
                  hubPresenceOnlineAgentIdsSnapshot,
                  hubConnectedFromApprovedCatalogRow,
                }) async {
                  check(userId).equals('user-1');
                  check(agentId).equals('agent-b');
                  check(filter).equals('filter-value');
                  check(clientToken).equals('tok-b');
                  check(bridgeTimeoutMs).equals(88_000);
                  return const Success<List<String>, AppFailure>(<String>[
                    'row-1',
                  ]);
                },
          );

      check(result.isSuccess()).isTrue();
      final report = result.getOrNull()!;
      check(report.mergedRows).deepEquals(const <String>['row-1']);
      check(report.missingClientTokenAgentIds).deepEquals(<String>['agent-c']);
    },
  );

  test(
    'executeMapped returns mapped output and forwards plan context to loader',
    () async {
      final t = target(agentId: 'agent-b', clientToken: 'tok-b');
      final resolution = AgentQueryTargetResolution(
        consideredApprovedTargets: <AgentQueryTarget>[t],
        missingClientTokenTargets: const <AgentQueryTarget>[],
        consideredApprovedAgentCount: 1,
      );
      final plan = AgentQueryPlan(
        queryKey: AgentQueryKey.resumoParcelasDiaSemana,
        strategy: AgentQueryExecutionStrategy.mergeAll,
        consideredApprovedAgentCount: 1,
        plannedTargets: <AgentQueryTarget>[t],
        missingClientTokenTargets: const <AgentQueryTarget>[],
        bridgeTimeoutMs: 77_000,
      );
      when(
        () => targetResolver.resolve(
          userId: any(named: 'userId'),
          selectedAgentIds: any(named: 'selectedAgentIds'),
        ),
      ).thenAnswer(
        (_) async =>
            Success<AgentQueryTargetResolution, AppFailure>(resolution),
      );
      when(
        () => planBuilder.build(
          queryKey: any(named: 'queryKey'),
          strategy: any(named: 'strategy'),
          resolution: any(named: 'resolution'),
          bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
          raceMaxSources: any(named: 'raceMaxSources'),
        ),
      ).thenReturn(Success<AgentQueryPlan, AppFailure>(plan));

      final result =
          await AgentQueryListReportAcrossAgentsCoordinator.executeMapped<
            List<String>,
            String
          >(
            operation: operation,
            queryKey: AgentQueryKey.resumoParcelasDiaSemana,
            userId: userId,
            targetResolver: targetResolver,
            planBuilder: planBuilder,
            executor: executor,
            bridgeTimeoutMs: 77_000,
            loadRowsForTarget:
                ({
                  required target,
                  required plan,
                  required resolution,
                }) async {
                  check(target.agentId).equals('agent-b');
                  check(plan.bridgeTimeoutMs).equals(77_000);
                  check(resolution.consideredApprovedAgentCount).equals(1);
                  return const Success<List<String>, AppFailure>(<String>[
                    'z',
                    'a',
                  ]);
                },
            mapReport: (report) => report.mergedRows.toList()..sort(),
          );

      check(result.isSuccess()).isTrue();
      check(result.getOrThrow()).deepEquals(const <String>['a', 'z']);
    },
  );
}

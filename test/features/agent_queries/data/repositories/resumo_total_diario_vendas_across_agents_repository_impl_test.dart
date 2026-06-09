import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/application/orchestration/agent_query_executor.dart';
import 'package:colmeia/features/agent_queries/application/orchestration/agent_query_plan_builder.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_total_diario_vendas_use_case.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_total_diario_vendas_across_agents_repository_impl.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_key.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_plan.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target_resolution.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_diario_vendas_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_diario_vendas_row.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_query_target_resolver.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_connection_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

class _MockTargetResolver extends Mock implements AgentQueryTargetResolver {}

class _MockPlanBuilder extends Mock implements AgentQueryPlanBuilder {}

class _MockLoadResumo extends Mock
    implements LoadResumoTotalDiarioVendasUseCase {}

void main() {
  late _MockTargetResolver targetResolver;
  late _MockPlanBuilder planBuilder;
  late AgentQueryExecutor<ResumoTotalDiarioVendasRow> executor;
  late _MockLoadResumo loadResumo;
  late ResumoTotalDiarioVendasAcrossAgentsRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(
      ResumoTotalDiarioVendasFilter(
        dataVendaInicio: DateTime.utc(2026),
        dataVendaFim: DateTime.utc(2026, 12, 31),
      ),
    );
    registerFallbackValue(
      const AgentQueryTargetResolution(
        consideredApprovedTargets: <AgentQueryTarget>[],
        missingClientTokenTargets: <AgentQueryTarget>[],
        consideredApprovedAgentCount: 0,
      ),
    );
    registerFallbackValue(AgentQueryKey.resumoTotalDiarioVendas);
    registerFallbackValue(AgentQueryExecutionStrategy.mergeAll);
  });

  setUp(() {
    targetResolver = _MockTargetResolver();
    planBuilder = _MockPlanBuilder();
    executor = AgentQueryExecutor<ResumoTotalDiarioVendasRow>();
    loadResumo = _MockLoadResumo();
    repository = ResumoTotalDiarioVendasAcrossAgentsRepositoryImpl(
      targetResolver: targetResolver,
      planBuilder: planBuilder,
      executor: executor,
      loadResumo: loadResumo,
    );
  });

  test(
    'should execute resumo for planned targets and '
    'preserve missing token targets',
    () async {
      final targetWithToken = _target('agent-a', clientToken: 'tok-a');
      final missingTarget = _target('agent-b', clientToken: null);
      final resolution = AgentQueryTargetResolution(
        consideredApprovedTargets: <AgentQueryTarget>[
          targetWithToken,
          missingTarget,
        ],
        missingClientTokenTargets: <AgentQueryTarget>[missingTarget],
        consideredApprovedAgentCount: 2,
      );
      final plan = AgentQueryPlan(
        queryKey: AgentQueryKey.resumoTotalDiarioVendas,
        strategy: AgentQueryExecutionStrategy.mergeAll,
        consideredApprovedAgentCount: 2,
        plannedTargets: <AgentQueryTarget>[targetWithToken],
        missingClientTokenTargets: <AgentQueryTarget>[missingTarget],
        bridgeTimeoutMs: 120000,
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
      when(
        () => loadResumo(
          userId: any(named: 'userId'),
          agentId: any(named: 'agentId'),
          filter: any(named: 'filter'),
          clientToken: any(named: 'clientToken'),
          bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
          hubPresenceOnlineAgentIdsSnapshot: any(
            named: 'hubPresenceOnlineAgentIdsSnapshot',
          ),
          hubConnectedFromApprovedCatalogRow: any(
            named: 'hubConnectedFromApprovedCatalogRow',
          ),
        ),
      ).thenAnswer(
        (_) async => Success<List<ResumoTotalDiarioVendasRow>, AppFailure>(
          <ResumoTotalDiarioVendasRow>[
            ResumoTotalDiarioVendasRow(
              codEmpresa: 1,
              codFilial: 1,
              dataVenda: DateTime(2026, 6, 15),
              qtdVendas: 2,
              valorTotalDiarioVenda: 100,
            ),
          ],
        ),
      );

      final filter = ResumoTotalDiarioVendasFilter(
        dataVendaInicio: DateTime.utc(2026),
        dataVendaFim: DateTime.utc(2026, 12, 31),
      );
      final result = await repository.load(
        userId: 'user-1',
        filter: filter,
        selectedAgentIds: {'agent-a', 'agent-b'},
      );

      check(result.isSuccess()).isTrue();
      final report = result.getOrThrow();
      check(report.mergedRows).has((rows) => rows.length, 'length').equals(1);
      verify(
        () => loadResumo(
          userId: 'user-1',
          agentId: 'agent-a',
          filter: filter,
          clientToken: 'tok-a',
          bridgeTimeoutMs: 120000,
          hubPresenceOnlineAgentIdsSnapshot: any(
            named: 'hubPresenceOnlineAgentIdsSnapshot',
          ),
          hubConnectedFromApprovedCatalogRow: any(
            named: 'hubConnectedFromApprovedCatalogRow',
          ),
        ),
      ).called(1);
    },
  );

  test(
    'should preserve source agent ids in execution failure context',
    () async {
      final resolution = AgentQueryTargetResolution(
        consideredApprovedTargets: <AgentQueryTarget>[
          _target('agent-b'),
          _target('agent-a'),
        ],
        missingClientTokenTargets: const <AgentQueryTarget>[],
        consideredApprovedAgentCount: 2,
      );
      final plan = AgentQueryPlan(
        queryKey: AgentQueryKey.resumoTotalDiarioVendas,
        strategy: AgentQueryExecutionStrategy.mergeAll,
        consideredApprovedAgentCount: 2,
        plannedTargets: <AgentQueryTarget>[
          _target('agent-a'),
          _target('agent-b'),
        ],
        missingClientTokenTargets: const <AgentQueryTarget>[],
        bridgeTimeoutMs: 120000,
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
      when(
        () => loadResumo(
          userId: any(named: 'userId'),
          agentId: any(named: 'agentId'),
          filter: any(named: 'filter'),
          clientToken: any(named: 'clientToken'),
          bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
          hubPresenceOnlineAgentIdsSnapshot: any(
            named: 'hubPresenceOnlineAgentIdsSnapshot',
          ),
          hubConnectedFromApprovedCatalogRow: any(
            named: 'hubConnectedFromApprovedCatalogRow',
          ),
        ),
      ).thenAnswer(
        (_) async =>
            const Failure<List<ResumoTotalDiarioVendasRow>, AppFailure>(
              NetworkFailure(message: 'failed', userMessage: 'failed'),
            ),
      );

      final result = await repository.load(
        userId: 'user-1',
        filter: ResumoTotalDiarioVendasFilter(
          dataVendaInicio: DateTime.utc(2026),
          dataVendaFim: DateTime.utc(2026, 12, 31),
        ),
      );

      check(result.isError()).isTrue();
      final failure = result.exceptionOrNull()!;
      check(
        failure.context['sourceAgentIds']! as List<String>,
      ).deepEquals(const <String>['agent-a', 'agent-b']);
    },
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

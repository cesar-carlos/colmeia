import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/application/orchestration/agent_query_executor.dart';
import 'package:colmeia/features/agent_queries/application/orchestration/agent_query_plan_builder.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_parcela_por_usuario_use_case.dart';
import 'package:colmeia/features/agent_queries/data/orchestration/agent_query_target_resolver.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_parcela_por_usuario_across_agents_repository_impl.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_key.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_plan.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target_resolution.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_por_usuario_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_por_usuario_row.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_connection_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

class _MockTargetResolver extends Mock implements AgentQueryTargetResolver {}

class _MockPlanBuilder extends Mock implements AgentQueryPlanBuilder {}

class _MockLoadResumo extends Mock implements LoadResumoParcelaPorUsuarioUseCase {}

void main() {
  late _MockTargetResolver targetResolver;
  late _MockPlanBuilder planBuilder;
  late AgentQueryExecutor<ResumoParcelaPorUsuarioRow> executor;
  late _MockLoadResumo loadResumo;
  late ResumoParcelaPorUsuarioAcrossAgentsRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(
      ResumoParcelaPorUsuarioFilter(
        dataVendaInicio: DateTime.utc(2026, 4),
        dataVendaFim: DateTime.utc(2026, 4, 30),
      ),
    );
    registerFallbackValue(
      const AgentQueryTargetResolution(
        consideredApprovedTargets: <AgentQueryTarget>[],
        missingClientTokenTargets: <AgentQueryTarget>[],
        consideredApprovedAgentCount: 0,
      ),
    );
    registerFallbackValue(AgentQueryKey.resumoParcelaPorUsuario);
    registerFallbackValue(AgentQueryExecutionStrategy.mergeAll);
  });

  setUp(() {
    targetResolver = _MockTargetResolver();
    planBuilder = _MockPlanBuilder();
    executor = AgentQueryExecutor<ResumoParcelaPorUsuarioRow>();
    loadResumo = _MockLoadResumo();
    repository = ResumoParcelaPorUsuarioAcrossAgentsRepositoryImpl(
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
        queryKey: AgentQueryKey.resumoParcelaPorUsuario,
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
        (_) async =>
            const Success<List<ResumoParcelaPorUsuarioRow>, AppFailure>(
              <ResumoParcelaPorUsuarioRow>[
                ResumoParcelaPorUsuarioRow(
                  codEmpresa: 1,
                  codFilial: 1,
                  nomeUsuario: 'Caixa',
                  qtdVendas: 1,
                  valorParcela: 100,
                ),
              ],
            ),
      );

      final filter = ResumoParcelaPorUsuarioFilter(
        dataVendaInicio: DateTime.utc(2026, 4),
        dataVendaFim: DateTime.utc(2026, 4, 30),
      );
      final result = await repository.load(
        userId: 'user-1',
        filter: filter,
        selectedAgentIds: {'agent-a', 'agent-b'},
      );

      check(result.isSuccess()).isTrue();
      final report = result.getOrThrow();
      check(report.mergedRows).has((rows) => rows.length, 'length').equals(1);
      check(
        report.rowsByAgentId['agent-a']!,
      ).has((rows) => rows.length, 'length').equals(1);
      check(report.rowsByAgentId['agent-b']!).isEmpty();
      check(
        report.missingClientTokenAgentIds,
      ).deepEquals(const <String>['agent-b']);
      verify(
        () => loadResumo(
          userId: 'user-1',
          agentId: 'agent-a',
          filter: filter,
          clientToken: 'tok-a',
          bridgeTimeoutMs: 120000,
          hubConnectedFromApprovedCatalogRow: true,
        ),
      ).called(1);
    },
  );

  test(
    'mergeAll concatenates rows from every successful agent target',
    () async {
      final agentA = _target('agent-a', clientToken: 'tok-a');
      final agentB = _target('agent-b', clientToken: 'tok-b');
      final resolution = AgentQueryTargetResolution(
        consideredApprovedTargets: <AgentQueryTarget>[agentA, agentB],
        missingClientTokenTargets: const <AgentQueryTarget>[],
        consideredApprovedAgentCount: 2,
      );
      final plan = AgentQueryPlan(
        queryKey: AgentQueryKey.resumoParcelaPorUsuario,
        strategy: AgentQueryExecutionStrategy.mergeAll,
        consideredApprovedAgentCount: 2,
        plannedTargets: <AgentQueryTarget>[agentA, agentB],
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
          agentId: 'agent-a',
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
            const Success<List<ResumoParcelaPorUsuarioRow>, AppFailure>(
              <ResumoParcelaPorUsuarioRow>[
                ResumoParcelaPorUsuarioRow(
                  codEmpresa: 1,
                  codFilial: 1,
                  nomeUsuario: 'Ana',
                  qtdVendas: 1,
                  valorParcela: 50,
                ),
              ],
            ),
      );
      when(
        () => loadResumo(
          userId: any(named: 'userId'),
          agentId: 'agent-b',
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
            const Success<List<ResumoParcelaPorUsuarioRow>, AppFailure>(
              <ResumoParcelaPorUsuarioRow>[
                ResumoParcelaPorUsuarioRow(
                  codEmpresa: 2,
                  codFilial: 1,
                  nomeUsuario: 'Bob',
                  qtdVendas: 2,
                  valorParcela: 80,
                ),
              ],
            ),
      );

      final filter = ResumoParcelaPorUsuarioFilter(
        dataVendaInicio: DateTime.utc(2026, 4),
        dataVendaFim: DateTime.utc(2026, 4, 30),
      );
      final result = await repository.load(
        userId: 'user-1',
        filter: filter,
        selectedAgentIds: {'agent-a', 'agent-b'},
      );

      check(result.isSuccess()).isTrue();
      final report = result.getOrThrow();
      check(report.mergedRows).length.equals(2);
      final names = report.mergedRows.map((r) => r.nomeUsuario).toSet();
      check(names.contains('Ana')).isTrue();
      check(names.contains('Bob')).isTrue();
    },
  );

  test('should return planner failure when strategy is invalid', () async {
    final resolution = AgentQueryTargetResolution(
      consideredApprovedTargets: <AgentQueryTarget>[_target('agent-a')],
      missingClientTokenTargets: const <AgentQueryTarget>[],
      consideredApprovedAgentCount: 1,
    );
    when(
      () => targetResolver.resolve(
        userId: any(named: 'userId'),
        selectedAgentIds: any(named: 'selectedAgentIds'),
      ),
    ).thenAnswer(
      (_) async => Success<AgentQueryTargetResolution, AppFailure>(resolution),
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
        ValidationFailure(message: 'invalid strategy'),
      ),
    );

    final result = await repository.load(
      userId: 'user-1',
      filter: ResumoParcelaPorUsuarioFilter(
        dataVendaInicio: DateTime.utc(2026, 4),
        dataVendaFim: DateTime.utc(2026, 4, 30),
      ),
      strategy: AgentQueryExecutionStrategy.singleSource,
    );

    check(result.isError()).isTrue();
    check(result.exceptionOrNull()).isA<ValidationFailure>();
    verifyNever(
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
    );
  });
}

AgentQueryTarget _target(String agentId, {String? clientToken = 'token'}) {
  return AgentQueryTarget(
    agentId: agentId,
    displayName: agentId,
    connectionStatus: AgentConnectionStatus.online,
    clientToken: clientToken,
    hubConnectedFromApprovedCatalogRow: true,
  );
}

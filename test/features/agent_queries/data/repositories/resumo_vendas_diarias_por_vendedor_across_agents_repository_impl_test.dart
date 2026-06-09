import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/application/orchestration/agent_query_executor.dart';
import 'package:colmeia/features/agent_queries/application/orchestration/agent_query_plan_builder.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_vendas_diarias_por_vendedor_use_case.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_vendas_diarias_por_vendedor_across_agents_repository_impl.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_key.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_plan.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target_resolution.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_vendas_diarias_por_vendedor_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_vendas_diarias_por_vendedor_row.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_query_target_resolver.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_connection_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

class _MockTargetResolver extends Mock implements AgentQueryTargetResolver {}

class _MockPlanBuilder extends Mock implements AgentQueryPlanBuilder {}

class _MockLoadResumo extends Mock
    implements LoadResumoVendasDiariasPorVendedorUseCase {}

void main() {
  late _MockTargetResolver targetResolver;
  late _MockPlanBuilder planBuilder;
  late AgentQueryExecutor<ResumoVendasDiariasPorVendedorRow> executor;
  late _MockLoadResumo loadResumo;
  late ResumoVendasDiariasPorVendedorAcrossAgentsRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(
      ResumoVendasDiariasPorVendedorFilter(
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
    registerFallbackValue(AgentQueryKey.resumoVendasDiariasPorVendedor);
    registerFallbackValue(AgentQueryExecutionStrategy.mergeAll);
  });

  setUp(() {
    targetResolver = _MockTargetResolver();
    planBuilder = _MockPlanBuilder();
    executor = AgentQueryExecutor<ResumoVendasDiariasPorVendedorRow>();
    loadResumo = _MockLoadResumo();
    repository = ResumoVendasDiariasPorVendedorAcrossAgentsRepositoryImpl(
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
        queryKey: AgentQueryKey.resumoVendasDiariasPorVendedor,
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
        ),
      ).thenAnswer(
        (_) async =>
            Success<List<ResumoVendasDiariasPorVendedorRow>, AppFailure>(
              <ResumoVendasDiariasPorVendedorRow>[
                ResumoVendasDiariasPorVendedorRow(
                  codEmpresa: 1,
                  codFilial: 1,
                  dataVenda: DateTime.utc(2026, 4),
                  anoMesDataVenda: '2026/04',
                  codVendedor: 10,
                  nomeVendedor: 'Alice',
                  qtdVendas: 1,
                  valorTotalVenda: 100,
                ),
              ],
            ),
      );

      final filter = ResumoVendasDiariasPorVendedorFilter(
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
        ),
      ).called(1);
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
      filter: ResumoVendasDiariasPorVendedorFilter(
        dataVendaInicio: DateTime.utc(2026, 4),
        dataVendaFim: DateTime.utc(2026, 4, 30),
      ),
      strategy: AgentQueryExecutionStrategy.singleSource,
    );

    check(result.isError()).isTrue();
    check(result.exceptionOrNull()).isA<ValidationFailure>();
    verifyNever(
      () => loadResumo.call(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
        filter: any(named: 'filter'),
        clientToken: any(named: 'clientToken'),
        bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
      ),
    );
  });

  test('returns empty merged rows when plan has no executables', () async {
    final missingOnly = _target('agent-b', clientToken: null);
    final resolution = AgentQueryTargetResolution(
      consideredApprovedTargets: <AgentQueryTarget>[missingOnly],
      missingClientTokenTargets: <AgentQueryTarget>[missingOnly],
      consideredApprovedAgentCount: 1,
    );
    final plan = AgentQueryPlan(
      queryKey: AgentQueryKey.resumoVendasDiariasPorVendedor,
      strategy: AgentQueryExecutionStrategy.mergeAll,
      consideredApprovedAgentCount: 1,
      plannedTargets: const <AgentQueryTarget>[],
      missingClientTokenTargets: <AgentQueryTarget>[missingOnly],
      bridgeTimeoutMs: 120000,
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
    ).thenReturn(Success<AgentQueryPlan, AppFailure>(plan));

    final filter = ResumoVendasDiariasPorVendedorFilter(
      dataVendaInicio: DateTime.utc(2026, 4),
      dataVendaFim: DateTime.utc(2026, 4, 30),
    );
    final result = await repository.load(
      userId: 'user-1',
      filter: filter,
      selectedAgentIds: {'agent-b'},
    );

    check(result.isSuccess()).isTrue();
    final report = result.getOrThrow();
    check(report.mergedRows).isEmpty();
    check(
      report.missingClientTokenAgentIds,
    ).deepEquals(const <String>['agent-b']);
    verifyNever(
      () => loadResumo(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
        filter: any(named: 'filter'),
        clientToken: any(named: 'clientToken'),
        bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
      ),
    );
    verify(
      () => planBuilder.build(
        queryKey: AgentQueryKey.resumoVendasDiariasPorVendedor,
        strategy: any(named: 'strategy'),
        resolution: any(named: 'resolution'),
        bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
        raceMaxSources: any(named: 'raceMaxSources'),
      ),
    ).called(1);
  });

  test(
    'mergeAll succeeds with partial failure when one target fails',
    () async {
      final targetA = _target('agent-a', clientToken: 'tok-a');
      final targetB = _target('agent-b', clientToken: 'tok-b');
      final resolution = AgentQueryTargetResolution(
        consideredApprovedTargets: <AgentQueryTarget>[targetA, targetB],
        missingClientTokenTargets: const <AgentQueryTarget>[],
        consideredApprovedAgentCount: 2,
      );
      final plan = AgentQueryPlan(
        queryKey: AgentQueryKey.resumoVendasDiariasPorVendedor,
        strategy: AgentQueryExecutionStrategy.mergeAll,
        consideredApprovedAgentCount: 2,
        plannedTargets: <AgentQueryTarget>[targetA, targetB],
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
        ),
      ).thenAnswer((invocation) async {
        final id = invocation.namedArguments[#agentId] as String;
        if (id == 'agent-a') {
          return const Failure<
            List<ResumoVendasDiariasPorVendedorRow>,
            AppFailure
          >(
            NetworkFailure(message: 'down', userMessage: 'down'),
          );
        }
        return Success<List<ResumoVendasDiariasPorVendedorRow>, AppFailure>(
          <ResumoVendasDiariasPorVendedorRow>[
            ResumoVendasDiariasPorVendedorRow(
              codEmpresa: 1,
              codFilial: 1,
              dataVenda: DateTime.utc(2026, 4),
              anoMesDataVenda: '2026/04',
              codVendedor: 2,
              nomeVendedor: 'Pat',
              qtdVendas: 1,
              valorTotalVenda: 10,
            ),
          ],
        );
      });

      final filter = ResumoVendasDiariasPorVendedorFilter(
        dataVendaInicio: DateTime.utc(2026, 4),
        dataVendaFim: DateTime.utc(2026, 4, 30),
      );
      final result = await repository.load(
        userId: 'user-1',
        filter: filter,
      );

      check(result.isSuccess()).isTrue();
      final report = result.getOrThrow();
      check(report.hasPartialFailure).isTrue();
      check(report.mergedRows).length.equals(1);
      check(report.failedAgentIds).contains('agent-a');
    },
  );

  test('should forward filter to each executed target', () async {
    final targetA = _target('agent-a', clientToken: 'tok-a');
    final resolution = AgentQueryTargetResolution(
      consideredApprovedTargets: <AgentQueryTarget>[targetA],
      missingClientTokenTargets: const <AgentQueryTarget>[],
      consideredApprovedAgentCount: 1,
    );
    final plan = AgentQueryPlan(
      queryKey: AgentQueryKey.resumoVendasDiariasPorVendedor,
      strategy: AgentQueryExecutionStrategy.mergeAll,
      consideredApprovedAgentCount: 1,
      plannedTargets: <AgentQueryTarget>[targetA],
      missingClientTokenTargets: const <AgentQueryTarget>[],
      bridgeTimeoutMs: 5000,
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
    ).thenReturn(Success<AgentQueryPlan, AppFailure>(plan));
    when(
      () => loadResumo(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
        filter: any(named: 'filter'),
        clientToken: any(named: 'clientToken'),
        bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
      ),
    ).thenAnswer(
      (_) async =>
          const Success<List<ResumoVendasDiariasPorVendedorRow>, AppFailure>(
            <ResumoVendasDiariasPorVendedorRow>[],
          ),
    );

    final filter = ResumoVendasDiariasPorVendedorFilter(
      dataVendaInicio: DateTime.utc(2026, 4),
      dataVendaFim: DateTime.utc(2026, 4, 30),
      codVendedor: 42,
      bairro: '  Sul  ',
      municipio: 'Curitiba',
    );
    await repository.load(
      userId: 'user-1',
      filter: filter,
      bridgeTimeoutMs: 5000,
    );

    verify(
      () => loadResumo(
        userId: 'user-1',
        agentId: 'agent-a',
        filter: filter,
        clientToken: 'tok-a',
        bridgeTimeoutMs: 5000,
      ),
    ).called(1);
  });

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
        queryKey: AgentQueryKey.resumoVendasDiariasPorVendedor,
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
        ),
      ).thenAnswer(
        (_) async =>
            const Failure<List<ResumoVendasDiariasPorVendedorRow>, AppFailure>(
              NetworkFailure(message: 'failed', userMessage: 'failed'),
            ),
      );

      final result = await repository.load(
        userId: 'user-1',
        filter: ResumoVendasDiariasPorVendedorFilter(
          dataVendaInicio: DateTime.utc(2026, 4),
          dataVendaFim: DateTime.utc(2026, 4, 30),
        ),
      );

      check(result.isError()).isTrue();
      final failure = result.exceptionOrNull()!;
      check(failure.context['sourceAgentIds']).isNotNull();
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

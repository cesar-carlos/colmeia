import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/application/orchestration/agent_query_executor.dart';
import 'package:colmeia/features/agent_queries/application/orchestration/agent_query_plan_builder.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_total_vendas_municipio_filial_periodo_use_case.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_total_vendas_municipio_filial_periodo_across_agents_repository_impl.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_key.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_loaded_rows.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_plan.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target_resolution.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_vendas_municipio_filial_periodo_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_vendas_municipio_filial_periodo_row.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_query_target_resolver.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_connection_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

class _MockTargetResolver extends Mock implements AgentQueryTargetResolver {}

class _MockPlanBuilder extends Mock implements AgentQueryPlanBuilder {}

class _MockLoadResumo extends Mock
    implements LoadResumoTotalVendasMunicipioFilialPeriodoUseCase {}

void main() {
  late _MockTargetResolver targetResolver;
  late _MockPlanBuilder planBuilder;
  late AgentQueryExecutor<ResumoTotalVendasMunicipioFilialPeriodoRow> executor;
  late _MockLoadResumo loadResumo;
  late ResumoTotalVendasMunicipioFilialPeriodoAcrossAgentsRepositoryImpl
  repository;

  setUpAll(() {
    registerFallbackValue(
      ResumoTotalVendasMunicipioFilialPeriodoFilter(
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
    registerFallbackValue(
      AgentQueryKey.resumoTotalVendasMunicipioFilialPeriodo,
    );
    registerFallbackValue(AgentQueryExecutionStrategy.mergeAll);
  });

  setUp(() {
    targetResolver = _MockTargetResolver();
    planBuilder = _MockPlanBuilder();
    executor = AgentQueryExecutor<ResumoTotalVendasMunicipioFilialPeriodoRow>();
    loadResumo = _MockLoadResumo();
    repository =
        ResumoTotalVendasMunicipioFilialPeriodoAcrossAgentsRepositoryImpl(
          targetResolver: targetResolver,
          planBuilder: planBuilder,
          executor: executor,
          loadResumo: loadResumo,
        );
  });

  test('executes resumo for planned targets', () async {
    final targetWithToken = _target('agent-a', clientToken: 'tok-a');
    final resolution = AgentQueryTargetResolution(
      consideredApprovedTargets: <AgentQueryTarget>[targetWithToken],
      missingClientTokenTargets: const <AgentQueryTarget>[],
      consideredApprovedAgentCount: 1,
    );
    final plan = AgentQueryPlan(
      queryKey: AgentQueryKey.resumoTotalVendasMunicipioFilialPeriodo,
      strategy: AgentQueryExecutionStrategy.mergeAll,
      consideredApprovedAgentCount: 1,
      plannedTargets: <AgentQueryTarget>[targetWithToken],
      missingClientTokenTargets: const <AgentQueryTarget>[],
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
          const Success<
            AgentQueryLoadedRows<ResumoTotalVendasMunicipioFilialPeriodoRow>,
            AppFailure
          >(
            AgentQueryLoadedRows<ResumoTotalVendasMunicipioFilialPeriodoRow>(
              rows: <ResumoTotalVendasMunicipioFilialPeriodoRow>[
                ResumoTotalVendasMunicipioFilialPeriodoRow(
                  codEmpresa: 1,
                  codFilial: 1,
                  nomeFilial: 'F',
                  codMunicipioFilial: 1,
                  nomeMunicipioFilial: 'M',
                  ufMunicipioFilial: 'SP',
                  qtdVendas: 2,
                  totalVenda: 100,
                ),
              ],
              sourceRowCount: 3,
            ),
          ),
    );

    final filter = ResumoTotalVendasMunicipioFilialPeriodoFilter(
      dataVendaInicio: DateTime.utc(2026),
      dataVendaFim: DateTime.utc(2026, 12, 31),
    );
    final result = await repository.load(userId: 'user-1', filter: filter);

    check(result.isSuccess()).isTrue();
    final report = result.getOrThrow();
    check(report.queryKey).equals(
      AgentQueryKey.resumoTotalVendasMunicipioFilialPeriodo,
    );
    check(report.mergedRows).has((rows) => rows.length, 'length').equals(1);
    check(report.participants.single.sourceRowCount).equals(3);
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
  });
}

AgentQueryTarget _target(String agentId, {String? clientToken = 'token'}) {
  return AgentQueryTarget(
    agentId: agentId,
    displayName: agentId,
    connectionStatus: AgentConnectionStatus.online,
    clientToken: clientToken,
  );
}

import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/application/orchestration/agent_query_executor.dart';
import 'package:colmeia/features/agent_queries/application/orchestration/agent_query_plan_builder.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_total_vendas_municipio_filial_periodo_use_case.dart';
import 'package:colmeia/features/agent_queries/data/repositories/agent_query_list_report_across_agents_coordinator.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_report.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_key.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_load_policy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target_resolution.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_vendas_municipio_filial_periodo_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_vendas_municipio_filial_periodo_row.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_query_target_resolver.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_total_vendas_municipio_filial_periodo_across_agents_repository.dart';

class ResumoTotalVendasMunicipioFilialPeriodoAcrossAgentsRepositoryImpl
    implements ResumoTotalVendasMunicipioFilialPeriodoAcrossAgentsRepository {
  ResumoTotalVendasMunicipioFilialPeriodoAcrossAgentsRepositoryImpl({
    required AgentQueryTargetResolver targetResolver,
    required AgentQueryPlanBuilder planBuilder,
    required AgentQueryExecutor<ResumoTotalVendasMunicipioFilialPeriodoRow>
    executor,
    required LoadResumoTotalVendasMunicipioFilialPeriodoUseCase loadResumo,
  }) : _targetResolver = targetResolver,
       _planBuilder = planBuilder,
       _executor = executor,
       _loadResumo = loadResumo;

  final AgentQueryTargetResolver _targetResolver;
  final AgentQueryPlanBuilder _planBuilder;
  final AgentQueryExecutor<ResumoTotalVendasMunicipioFilialPeriodoRow>
  _executor;
  final LoadResumoTotalVendasMunicipioFilialPeriodoUseCase _loadResumo;

  static const String _operation =
      'loadResumoTotalVendasMunicipioFilialPeriodoAcrossAgents';

  @override
  Future<
    AppResult<
      AgentQueryExecutionReport<ResumoTotalVendasMunicipioFilialPeriodoRow>
    >
  >
  load({
    required String userId,
    required ResumoTotalVendasMunicipioFilialPeriodoFilter filter,
    Set<String>? selectedAgentIds,
    AgentQueryExecutionStrategy strategy = AgentQueryExecutionStrategy.mergeAll,
    int? bridgeTimeoutMs,
    int? raceMaxSources,
    AgentQueryTargetResolution? preResolvedResolution,
    AgentQueriesCancelScope? cancelScope,
    bool orderTargetsOnlineFirst = false,
    bool dedupeTargetsByAgentId = false,
    int? mergeAllConcurrencyOverride,
    AgentQueryLoadPolicy cachePolicy = AgentQueryLoadPolicy.defaultLoad,
  }) {
    return AgentQueryListReportAcrossAgentsCoordinator.executeLoadedRows<
      ResumoTotalVendasMunicipioFilialPeriodoFilter,
      ResumoTotalVendasMunicipioFilialPeriodoRow
    >(
      operation: _operation,
      queryKey: AgentQueryKey.resumoTotalVendasMunicipioFilialPeriodo,
      userId: userId,
      filter: filter,
      targetResolver: _targetResolver,
      planBuilder: _planBuilder,
      executor: _executor,
      loadRowsForTarget:
          ({
            required userId,
            required agentId,
            required filter,
            clientToken,
            bridgeTimeoutMs,
            hubPresenceOnlineAgentIdsSnapshot,
            hubConnectedFromApprovedCatalogRow,
          }) => _loadResumo(
            userId: userId,
            agentId: agentId,
            filter: filter,
            clientToken: clientToken,
            bridgeTimeoutMs: bridgeTimeoutMs,
            hubPresenceOnlineAgentIdsSnapshot:
                hubPresenceOnlineAgentIdsSnapshot,
            hubConnectedFromApprovedCatalogRow:
                hubConnectedFromApprovedCatalogRow,
            cancelScope: cancelScope,
            cachePolicy: cachePolicy,
          ),
      selectedAgentIds: selectedAgentIds,
      strategy: strategy,
      bridgeTimeoutMs: bridgeTimeoutMs,
      raceMaxSources: raceMaxSources,
      preResolvedResolution: preResolvedResolution,
      orderPlannedTargetsOnlineFirst: orderTargetsOnlineFirst,
      dedupePlannedTargetsByAgentId: dedupeTargetsByAgentId,
      mergeAllConcurrencyOverride: mergeAllConcurrencyOverride,
    );
  }
}

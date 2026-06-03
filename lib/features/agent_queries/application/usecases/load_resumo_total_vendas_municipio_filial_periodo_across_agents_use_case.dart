import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_report.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_load_policy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target_resolution.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_vendas_municipio_filial_periodo_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_vendas_municipio_filial_periodo_row.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_total_vendas_municipio_filial_periodo_across_agents_repository.dart';

class LoadResumoTotalVendasMunicipioFilialPeriodoAcrossAgentsUseCase {
  LoadResumoTotalVendasMunicipioFilialPeriodoAcrossAgentsUseCase(
    this._repository,
  );

  final ResumoTotalVendasMunicipioFilialPeriodoAcrossAgentsRepository
  _repository;

  Future<
    AppResult<
      AgentQueryExecutionReport<ResumoTotalVendasMunicipioFilialPeriodoRow>
    >
  >
  call({
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
    return _repository.load(
      userId: userId,
      filter: filter,
      selectedAgentIds: selectedAgentIds,
      strategy: strategy,
      bridgeTimeoutMs: bridgeTimeoutMs,
      raceMaxSources: raceMaxSources,
      preResolvedResolution: preResolvedResolution,
      cancelScope: cancelScope,
      orderTargetsOnlineFirst: orderTargetsOnlineFirst,
      dedupeTargetsByAgentId: dedupeTargetsByAgentId,
      mergeAllConcurrencyOverride: mergeAllConcurrencyOverride,
      cachePolicy: cachePolicy,
    );
  }
}

import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_report.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target_resolution.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_vendas_municipio_filial_periodo_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_vendas_municipio_filial_periodo_row.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';

// ignore: one_member_abstracts -- single entry point matches other across-agents repositories.
abstract interface class ResumoTotalVendasMunicipioFilialPeriodoAcrossAgentsRepository {
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
  });
}

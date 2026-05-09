import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_report.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_vendas_municipio_filial_diario_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_vendas_municipio_filial_diario_row.dart';

// ignore: one_member_abstracts — single entry point matches other across-agents repositories.
abstract interface class ResumoTotalVendasMunicipioFilialDiarioAcrossAgentsRepository {
  Future<
    AppResult<
      AgentQueryExecutionReport<ResumoTotalVendasMunicipioFilialDiarioRow>
    >
  >
  load({
    required String userId,
    required ResumoTotalVendasMunicipioFilialDiarioFilter filter,
    Set<String>? selectedAgentIds,
    AgentQueryExecutionStrategy strategy = AgentQueryExecutionStrategy.mergeAll,
    int? bridgeTimeoutMs,
    int? raceMaxSources,
  });
}

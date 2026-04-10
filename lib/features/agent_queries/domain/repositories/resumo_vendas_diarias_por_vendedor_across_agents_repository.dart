import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_report.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_vendas_diarias_por_vendedor_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_vendas_diarias_por_vendedor_row.dart';

// Cross-agent report entry point; more orchestrated queries may be added here.
// ignore: one_member_abstracts
abstract interface class ResumoVendasDiariasPorVendedorAcrossAgentsRepository {
  Future<
    AppResult<AgentQueryExecutionReport<ResumoVendasDiariasPorVendedorRow>>
  >
  load({
    required String userId,
    required ResumoVendasDiariasPorVendedorFilter filter,
    Set<String>? selectedAgentIds,
    AgentQueryExecutionStrategy strategy = AgentQueryExecutionStrategy.mergeAll,
    int? bridgeTimeoutMs,
    int? raceMaxSources,
  });
}

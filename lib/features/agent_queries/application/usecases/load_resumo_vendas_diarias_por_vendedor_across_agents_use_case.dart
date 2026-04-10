import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_report.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_vendas_diarias_por_vendedor_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_vendas_diarias_por_vendedor_row.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_vendas_diarias_por_vendedor_across_agents_repository.dart';

class LoadResumoVendasDiariasPorVendedorAcrossAgentsUseCase {
  LoadResumoVendasDiariasPorVendedorAcrossAgentsUseCase(this._repository);

  final ResumoVendasDiariasPorVendedorAcrossAgentsRepository _repository;

  Future<
    AppResult<AgentQueryExecutionReport<ResumoVendasDiariasPorVendedorRow>>
  >
  call({
    required String userId,
    required ResumoVendasDiariasPorVendedorFilter filter,
    Set<String>? selectedAgentIds,
    AgentQueryExecutionStrategy strategy = AgentQueryExecutionStrategy.mergeAll,
    int? bridgeTimeoutMs,
    int? raceMaxSources,
  }) {
    return _repository.load(
      userId: userId,
      filter: filter,
      selectedAgentIds: selectedAgentIds,
      strategy: strategy,
      bridgeTimeoutMs: bridgeTimeoutMs,
      raceMaxSources: raceMaxSources,
    );
  }
}

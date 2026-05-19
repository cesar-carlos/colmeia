import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_vendas_diarias_por_vendedor_filter_options_batch.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_vendas_diarias_por_vendedor_filter_options_across_agents_repository.dart';

class LoadResumoVendasDiariasPorVendedorAllFilterOptionsAcrossAgentsUseCase {
  LoadResumoVendasDiariasPorVendedorAllFilterOptionsAcrossAgentsUseCase(
    this._repository,
  );

  final ResumoVendasDiariasPorVendedorFilterOptionsAcrossAgentsRepository
  _repository;

  Future<AppResult<ResumoVendasDiariasPorVendedorAllFilterOptionsAcrossAgents>>
  call({
    required String userId,
    required DateTime dataVendaInicio,
    required DateTime dataVendaFim,
    Set<String>? selectedAgentIds,
    String? searchTerm,
    int limit = 20,
    AgentQueryExecutionStrategy strategy = AgentQueryExecutionStrategy.mergeAll,
    int? bridgeTimeoutMs,
    int? raceMaxSources,
  }) {
    return _repository.loadAllOptions(
      userId: userId,
      dataVendaInicio: dataVendaInicio,
      dataVendaFim: dataVendaFim,
      selectedAgentIds: selectedAgentIds,
      searchTerm: searchTerm,
      limit: limit,
      strategy: strategy,
      bridgeTimeoutMs: bridgeTimeoutMs,
      raceMaxSources: raceMaxSources,
    );
  }
}

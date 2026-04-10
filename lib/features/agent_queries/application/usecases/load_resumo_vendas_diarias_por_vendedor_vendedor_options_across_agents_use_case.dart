import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_vendas_diarias_por_vendedor_vendedor_option.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_vendas_diarias_por_vendedor_filter_options_across_agents_repository.dart';

class LoadResumoVendasDiariasPorVendedorVendedorOptionsAcrossAgentsUseCase {
  LoadResumoVendasDiariasPorVendedorVendedorOptionsAcrossAgentsUseCase(
    this._repository,
  );

  final ResumoVendasDiariasPorVendedorFilterOptionsAcrossAgentsRepository
  _repository;

  Future<AppResult<List<ResumoVendasDiariasPorVendedorVendedorOption>>> call({
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
    return _repository.loadVendedorOptions(
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

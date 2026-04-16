import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_vendas_diarias_por_vendedor_text_option.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_vendas_diarias_por_vendedor_vendedor_option.dart';

// Type name encodes feature scope; formatter keeps declaration on one line.
abstract interface class ResumoVendasDiariasPorVendedorFilterOptionsAcrossAgentsRepository {
  Future<AppResult<List<ResumoVendasDiariasPorVendedorVendedorOption>>>
  loadVendedorOptions({
    required String userId,
    required DateTime dataVendaInicio,
    required DateTime dataVendaFim,
    Set<String>? selectedAgentIds,
    String? searchTerm,
    int limit = 20,
    AgentQueryExecutionStrategy strategy = AgentQueryExecutionStrategy.mergeAll,
    int? bridgeTimeoutMs,
    int? raceMaxSources,
  });

  Future<AppResult<List<ResumoVendasDiariasPorVendedorTextOption>>>
  loadBairroOptions({
    required String userId,
    required DateTime dataVendaInicio,
    required DateTime dataVendaFim,
    Set<String>? selectedAgentIds,
    String? searchTerm,
    int limit = 20,
    AgentQueryExecutionStrategy strategy = AgentQueryExecutionStrategy.mergeAll,
    int? bridgeTimeoutMs,
    int? raceMaxSources,
  });

  Future<AppResult<List<ResumoVendasDiariasPorVendedorTextOption>>>
  loadMunicipioOptions({
    required String userId,
    required DateTime dataVendaInicio,
    required DateTime dataVendaFim,
    Set<String>? selectedAgentIds,
    String? searchTerm,
    int limit = 20,
    AgentQueryExecutionStrategy strategy = AgentQueryExecutionStrategy.mergeAll,
    int? bridgeTimeoutMs,
    int? raceMaxSources,
  });
}

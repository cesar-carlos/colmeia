import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_report.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_load_policy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_diario_vendas_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_diario_vendas_row.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_total_diario_vendas_across_agents_repository.dart';

class LoadResumoTotalDiarioVendasAcrossAgentsUseCase {
  LoadResumoTotalDiarioVendasAcrossAgentsUseCase(this._repository);

  final ResumoTotalDiarioVendasAcrossAgentsRepository _repository;

  Future<AppResult<AgentQueryExecutionReport<ResumoTotalDiarioVendasRow>>>
  call({
    required String userId,
    required ResumoTotalDiarioVendasFilter filter,
    Set<String>? selectedAgentIds,
    AgentQueryExecutionStrategy strategy = AgentQueryExecutionStrategy.mergeAll,
    int? bridgeTimeoutMs,
    int? raceMaxSources,
    AgentQueryLoadPolicy cachePolicy = AgentQueryLoadPolicy.defaultLoad,
  }) {
    return _repository.load(
      userId: userId,
      filter: filter,
      selectedAgentIds: selectedAgentIds,
      strategy: strategy,
      bridgeTimeoutMs: bridgeTimeoutMs,
      raceMaxSources: raceMaxSources,
      cachePolicy: cachePolicy,
    );
  }
}

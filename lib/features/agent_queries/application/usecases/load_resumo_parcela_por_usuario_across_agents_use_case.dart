import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_report.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_por_usuario_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_por_usuario_row.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_parcela_por_usuario_across_agents_repository.dart';

class LoadResumoParcelaPorUsuarioAcrossAgentsUseCase {
  LoadResumoParcelaPorUsuarioAcrossAgentsUseCase(this._repository);

  final ResumoParcelaPorUsuarioAcrossAgentsRepository _repository;

  Future<AppResult<AgentQueryExecutionReport<ResumoParcelaPorUsuarioRow>>>
  call({
    required String userId,
    required ResumoParcelaPorUsuarioFilter filter,
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

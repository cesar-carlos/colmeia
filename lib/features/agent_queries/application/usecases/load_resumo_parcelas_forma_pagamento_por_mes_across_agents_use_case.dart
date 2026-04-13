import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_report.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_forma_pagamento_por_mes_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_forma_pagamento_por_mes_row.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_parcelas_forma_pagamento_por_mes_across_agents_repository.dart';

class LoadResumoParcelasFormaPagamentoPorMesAcrossAgentsUseCase {
  LoadResumoParcelasFormaPagamentoPorMesAcrossAgentsUseCase(this._repository);

  final ResumoParcelasFormaPagamentoPorMesAcrossAgentsRepository _repository;

  Future<
    AppResult<AgentQueryExecutionReport<ResumoParcelasFormaPagamentoPorMesRow>>
  >
  call({
    required String userId,
    required ResumoParcelasFormaPagamentoPorMesFilter filter,
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

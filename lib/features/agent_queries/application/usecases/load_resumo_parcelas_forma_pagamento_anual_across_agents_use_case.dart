import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_report.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_forma_pagamento_anual_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_forma_pagamento_anual_row.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_parcelas_forma_pagamento_anual_across_agents_repository.dart';

class LoadResumoParcelasFormaPagamentoAnualAcrossAgentsUseCase {
  LoadResumoParcelasFormaPagamentoAnualAcrossAgentsUseCase(this._repository);

  final ResumoParcelasFormaPagamentoAnualAcrossAgentsRepository _repository;

  Future<
    AppResult<AgentQueryExecutionReport<ResumoParcelasFormaPagamentoAnualRow>>
  >
  call({
    required String userId,
    required ResumoParcelasFormaPagamentoAnualFilter filter,
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

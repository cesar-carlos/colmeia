import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_report.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_forma_pagamento_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_forma_pagamento_row.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_parcela_forma_pagamento_across_agents_repository.dart';

class LoadResumoParcelaFormaPagamentoAcrossAgentsUseCase {
  LoadResumoParcelaFormaPagamentoAcrossAgentsUseCase(this._repository);

  final ResumoParcelaFormaPagamentoAcrossAgentsRepository _repository;

  Future<AppResult<AgentQueryExecutionReport<ResumoParcelaFormaPagamentoRow>>>
  call({
    required String userId,
    required ResumoParcelaFormaPagamentoFilter filter,
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

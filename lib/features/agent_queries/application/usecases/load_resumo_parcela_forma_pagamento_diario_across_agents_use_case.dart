import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_report.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_forma_pagamento_diario_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_forma_pagamento_diario_row.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_parcela_forma_pagamento_diario_across_agents_repository.dart';

class LoadResumoParcelaFormaPagamentoDiarioAcrossAgentsUseCase {
  LoadResumoParcelaFormaPagamentoDiarioAcrossAgentsUseCase(this._repository);

  final ResumoParcelaFormaPagamentoDiarioAcrossAgentsRepository _repository;

  Future<AppResult<AgentQueryExecutionReport<ResumoVendaProdutoDiarioRow>>>
  call({
    required String userId,
    required ResumoParcelaFormaPagamentoDiarioFilter filter,
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

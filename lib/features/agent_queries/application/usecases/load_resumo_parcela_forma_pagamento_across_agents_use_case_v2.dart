import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_report.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_forma_pagamento_filter_v2.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_forma_pagamento_row_v2.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_parcela_forma_pagamento_across_agents_repository_v2.dart';

class LoadResumoParcelaFormaPagamentoAcrossAgentsUseCaseV2 {
  LoadResumoParcelaFormaPagamentoAcrossAgentsUseCaseV2(this._repository);

  final ResumoParcelaFormaPagamentoAcrossAgentsRepositoryV2 _repository;

  Future<AppResult<AgentQueryExecutionReport<ResumoParcelaFormaPagamentoRowV2>>>
  call({
    required String userId,
    required ResumoParcelaFormaPagamentoFilterV2 filter,
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

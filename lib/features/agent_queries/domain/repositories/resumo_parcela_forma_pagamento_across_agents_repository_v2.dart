import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_report.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_forma_pagamento_filter_v2.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_forma_pagamento_row_v2.dart';

// Across-agents entry point for the V2 payment-method resumo query.
// ignore: one_member_abstracts
abstract interface class ResumoParcelaFormaPagamentoAcrossAgentsRepositoryV2 {
  Future<AppResult<AgentQueryExecutionReport<ResumoParcelaFormaPagamentoRowV2>>>
  load({
    required String userId,
    required ResumoParcelaFormaPagamentoFilterV2 filter,
    Set<String>? selectedAgentIds,
    AgentQueryExecutionStrategy strategy = AgentQueryExecutionStrategy.mergeAll,
    int? bridgeTimeoutMs,
    int? raceMaxSources,
  });
}

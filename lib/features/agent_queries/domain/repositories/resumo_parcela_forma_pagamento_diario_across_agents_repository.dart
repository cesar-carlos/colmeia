import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_report.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_forma_pagamento_diario_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_forma_pagamento_diario_row.dart';

// Cross-agent report entry point; more orchestrated queries may be added here.
// Long type name; `dart format` keeps the interface declaration on one line.
// ignore: one_member_abstracts
abstract interface class ResumoParcelaFormaPagamentoDiarioAcrossAgentsRepository {
  Future<AppResult<AgentQueryExecutionReport<ResumoVendaProdutoDiarioRow>>>
  load({
    required String userId,
    required ResumoParcelaFormaPagamentoDiarioFilter filter,
    Set<String>? selectedAgentIds,
    AgentQueryExecutionStrategy strategy = AgentQueryExecutionStrategy.mergeAll,
    int? bridgeTimeoutMs,
    int? raceMaxSources,
  });
}

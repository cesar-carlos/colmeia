import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_report.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_forma_pagamento_por_mes_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_forma_pagamento_por_mes_row.dart';

// Cross-agent report entry point; more orchestrated queries may be added here.
// Long type name; `dart format` keeps the interface declaration on one line.
// ignore: one_member_abstracts, lines_longer_than_80_chars
abstract interface class ResumoParcelasFormaPagamentoPorMesAcrossAgentsRepository {
  Future<
    AppResult<AgentQueryExecutionReport<ResumoParcelasFormaPagamentoPorMesRow>>
  >
  load({
    required String userId,
    required ResumoParcelasFormaPagamentoPorMesFilter filter,
    Set<String>? selectedAgentIds,
    AgentQueryExecutionStrategy strategy = AgentQueryExecutionStrategy.mergeAll,
    int? bridgeTimeoutMs,
    int? raceMaxSources,
  });
}

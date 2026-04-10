import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_report.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_anual_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_anual_row.dart';

// Cross-agent report entry point; more orchestrated queries may be added here.
// ignore: one_member_abstracts
abstract interface class ResumoParcelasAnualAcrossAgentsRepository {
  Future<AppResult<AgentQueryExecutionReport<ResumoParcelasAnualRow>>> load({
    required String userId,
    required ResumoParcelasAnualFilter filter,
    Set<String>? selectedAgentIds,
    AgentQueryExecutionStrategy strategy = AgentQueryExecutionStrategy.mergeAll,
    int? bridgeTimeoutMs,
    int? raceMaxSources,
  });
}

import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_report.dart';
import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_row.dart';

/// Paged branch registration result across agents.
///
/// Pagination is applied per agent. [totalCountByAgentId] exposes each
/// successful participant's catalog total for the requested filter.
class CadastroFilialAcrossAgentsPageResult {
  const CadastroFilialAcrossAgentsPageResult({
    required this.report,
    required this.totalCountByAgentId,
  });

  factory CadastroFilialAcrossAgentsPageResult.fromReport(
    AgentQueryExecutionReport<CadastroFilialRow> report,
  ) {
    final totals = <String, int>{};
    for (final participant in report.participants) {
      if (participant.isSuccess) {
        totals[participant.agentId] = participant.sourceRowCount;
      }
    }
    return CadastroFilialAcrossAgentsPageResult(
      report: report,
      totalCountByAgentId: Map<String, int>.unmodifiable(totals),
    );
  }

  final AgentQueryExecutionReport<CadastroFilialRow> report;
  final Map<String, int> totalCountByAgentId;

  int get totalCount {
    var total = 0;
    for (final count in totalCountByAgentId.values) {
      total += count;
    }
    return total;
  }
}

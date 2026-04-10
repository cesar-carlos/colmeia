import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_participant.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_report.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_report_resumo_parcelas.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_key.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_anual_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_anual_row_merger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ResumoParcelasAnualRowMerger', () {
    test('merge sums quantidade and valorTotal per ano', () {
      final merged = ResumoParcelasAnualRowMerger.merge(
        <ResumoParcelasAnualRow>[
          const ResumoParcelasAnualRow(
            ano: 2025,
            quantidade: 2,
            valorTotal: 10,
          ),
          const ResumoParcelasAnualRow(ano: 2025, quantidade: 3, valorTotal: 5),
          const ResumoParcelasAnualRow(ano: 2026, quantidade: 1, valorTotal: 7),
        ],
      );
      check(merged.length).equals(2);
      check(merged.firstWhere((r) => r.ano == 2025).quantidade).equals(5);
      check(merged.firstWhere((r) => r.ano == 2025).valorTotal).equals(15);
      check(merged.firstWhere((r) => r.ano == 2026).quantidade).equals(1);
    });
  });

  group('AgentQueryExecutionReportResumoParcelasAnualRowsX', () {
    test('aggregatedMergedRows delegates to merger', () {
      const report = AgentQueryExecutionReport<ResumoParcelasAnualRow>(
        queryKey: AgentQueryKey.resumoParcelasAnual,
        strategy: AgentQueryExecutionStrategy.mergeAll,
        consideredApprovedAgentCount: 2,
        plannedTargets: <AgentQueryTarget>[],
        missingClientTokenTargets: <AgentQueryTarget>[],
        participants: <AgentQueryExecutionParticipant<ResumoParcelasAnualRow>>[
          AgentQueryExecutionParticipant<ResumoParcelasAnualRow>(
            agentId: 'a',
            displayName: 'a',
            rows: <ResumoParcelasAnualRow>[
              ResumoParcelasAnualRow(ano: 2025, quantidade: 1, valorTotal: 2),
            ],
            elapsedMs: 1,
          ),
          AgentQueryExecutionParticipant<ResumoParcelasAnualRow>(
            agentId: 'b',
            displayName: 'b',
            rows: <ResumoParcelasAnualRow>[
              ResumoParcelasAnualRow(ano: 2025, quantidade: 4, valorTotal: 8),
            ],
            elapsedMs: 1,
          ),
        ],
        totalElapsedMs: 2,
      );
      check(report.mergedRows.length).equals(2);
      check(report.aggregatedMergedRows.length).equals(1);
      check(report.aggregatedMergedRows.single.quantidade).equals(5);
      check(report.aggregatedMergedRows.single.valorTotal).equals(10);
    });
  });
}

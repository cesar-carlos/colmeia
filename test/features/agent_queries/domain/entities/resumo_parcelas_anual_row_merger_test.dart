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
    test('merge sums qtdVendas and valorTotalVenda per composite key', () {
      const base = (codEmpresa: 1, codFilial: 6, anoDataVenda: 2026);
      final merged = ResumoParcelasAnualRowMerger.merge(
        <ResumoParcelasAnualRow>[
          ResumoParcelasAnualRow(
            codEmpresa: base.codEmpresa,
            codFilial: base.codFilial,
            anoDataVenda: base.anoDataVenda,
            qtdVendas: 2,
            valorTotalVenda: 10,
          ),
          ResumoParcelasAnualRow(
            codEmpresa: base.codEmpresa,
            codFilial: base.codFilial,
            anoDataVenda: base.anoDataVenda,
            qtdVendas: 3,
            valorTotalVenda: 5,
          ),
          const ResumoParcelasAnualRow(
            codEmpresa: 1,
            codFilial: 6,
            anoDataVenda: 2027,
            qtdVendas: 1,
            valorTotalVenda: 7,
          ),
        ],
      );
      check(merged.length).equals(2);
      final y2026 = merged.firstWhere((r) => r.anoDataVenda == 2026);
      check(y2026.qtdVendas).equals(5);
      check(y2026.valorTotalVenda).equals(15);
      check(
        merged.firstWhere((r) => r.anoDataVenda == 2027).qtdVendas,
      ).equals(1);
    });
  });

  group('AgentQueryExecutionReportResumoParcelasAnualRowsX', () {
    test('aggregatedMergedRows delegates to merger', () {
      const row2025 = ResumoParcelasAnualRow(
        codEmpresa: 1,
        codFilial: 1,
        anoDataVenda: 2025,
        qtdVendas: 1,
        valorTotalVenda: 2,
      );
      final report = AgentQueryExecutionReport<ResumoParcelasAnualRow>(
        queryKey: AgentQueryKey.resumoParcelasAnual,
        strategy: AgentQueryExecutionStrategy.mergeAll,
        consideredApprovedAgentCount: 2,
        plannedTargets: <AgentQueryTarget>[],
        missingClientTokenTargets: <AgentQueryTarget>[],
        participants: <AgentQueryExecutionParticipant<ResumoParcelasAnualRow>>[
          const AgentQueryExecutionParticipant<ResumoParcelasAnualRow>(
            agentId: 'a',
            displayName: 'a',
            rows: <ResumoParcelasAnualRow>[row2025],
            elapsedMs: 1,
          ),
          AgentQueryExecutionParticipant<ResumoParcelasAnualRow>(
            agentId: 'b',
            displayName: 'b',
            rows: <ResumoParcelasAnualRow>[
              ResumoParcelasAnualRow(
                codEmpresa: row2025.codEmpresa,
                codFilial: row2025.codFilial,
                anoDataVenda: row2025.anoDataVenda,
                qtdVendas: 4,
                valorTotalVenda: 8,
              ),
            ],
            elapsedMs: 1,
          ),
        ],
        totalElapsedMs: 2,
      );
      check(report.mergedRows.length).equals(2);
      check(report.aggregatedMergedRows.length).equals(1);
      check(report.aggregatedMergedRows.single.qtdVendas).equals(5);
      check(report.aggregatedMergedRows.single.valorTotalVenda).equals(10);
    });
  });
}

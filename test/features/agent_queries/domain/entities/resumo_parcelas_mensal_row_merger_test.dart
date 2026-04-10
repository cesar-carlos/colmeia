import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_participant.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_report.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_report_resumo_parcelas.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_key.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_mensal_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_mensal_row_merger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ResumoParcelasMensalRowMerger', () {
    test('merge sums quantidade and valorTotal per ano and mes', () {
      final merged = ResumoParcelasMensalRowMerger.merge(
        <ResumoParcelasMensalRow>[
          const ResumoParcelasMensalRow(
            ano: 2025,
            mes: 3,
            anoMes: '2025/03',
            quantidade: 2,
            valorTotal: 10,
          ),
          const ResumoParcelasMensalRow(
            ano: 2025,
            mes: 3,
            anoMes: '2025/03',
            quantidade: 3,
            valorTotal: 5,
          ),
          const ResumoParcelasMensalRow(
            ano: 2026,
            mes: 1,
            anoMes: '2026/01',
            quantidade: 1,
            valorTotal: 7,
          ),
        ],
      );
      check(merged.length).equals(2);
      final m202503 = merged.firstWhere((r) => r.ano == 2025 && r.mes == 3);
      check(m202503.quantidade).equals(5);
      check(m202503.valorTotal).equals(15);
      check(m202503.anoMes).equals('2025/03');
      final m202601 = merged.firstWhere((r) => r.ano == 2026 && r.mes == 1);
      check(m202601.quantidade).equals(1);
      check(m202601.anoMes).equals('2026/01');
    });

    test('merge skips invalid mes', () {
      final merged = ResumoParcelasMensalRowMerger.merge(
        <ResumoParcelasMensalRow>[
          const ResumoParcelasMensalRow(
            ano: 2025,
            mes: 0,
            anoMes: 'x',
            quantidade: 99,
            valorTotal: 1,
          ),
          const ResumoParcelasMensalRow(
            ano: 2025,
            mes: 2,
            anoMes: '2025/02',
            quantidade: 1,
            valorTotal: 2,
          ),
        ],
      );
      check(merged.length).equals(1);
      check(merged.single.mes).equals(2);
      check(merged.single.quantidade).equals(1);
    });

    test('merge skips invalid calendar year', () {
      final merged = ResumoParcelasMensalRowMerger.merge(
        <ResumoParcelasMensalRow>[
          const ResumoParcelasMensalRow(
            ano: 1899,
            mes: 6,
            anoMes: 'x',
            quantidade: 50,
            valorTotal: 1,
          ),
          const ResumoParcelasMensalRow(
            ano: 2025,
            mes: 6,
            anoMes: '2025/06',
            quantidade: 1,
            valorTotal: 2,
          ),
        ],
      );
      check(merged.length).equals(1);
      check(merged.single.ano).equals(2025);
    });

    test('mergeWithStats reports skipped invalid rows', () {
      final stats = ResumoParcelasMensalRowMerger.mergeWithStats(
        <ResumoParcelasMensalRow>[
          const ResumoParcelasMensalRow(
            ano: 2025,
            mes: 13,
            anoMes: 'x',
            quantidade: 1,
            valorTotal: 1,
          ),
          const ResumoParcelasMensalRow(
            ano: 2101,
            mes: 1,
            anoMes: 'x',
            quantidade: 1,
            valorTotal: 1,
          ),
          const ResumoParcelasMensalRow(
            ano: 2025,
            mes: 1,
            anoMes: '2025/01',
            quantidade: 2,
            valorTotal: 3,
          ),
        ],
      );
      check(stats.skippedInvalidInputRows).equals(2);
      check(stats.rows.single.quantidade).equals(2);
    });

    test('merge sorts by ano then mes', () {
      final merged = ResumoParcelasMensalRowMerger.merge(
        <ResumoParcelasMensalRow>[
          const ResumoParcelasMensalRow(
            ano: 2026,
            mes: 1,
            anoMes: '2026/01',
            quantidade: 1,
            valorTotal: 1,
          ),
          const ResumoParcelasMensalRow(
            ano: 2025,
            mes: 12,
            anoMes: '2025/12',
            quantidade: 1,
            valorTotal: 1,
          ),
        ],
      );
      check(merged.map((r) => r.anoMes).toList()).deepEquals(
        const <String>['2025/12', '2026/01'],
      );
    });
  });

  group('AgentQueryExecutionReportResumoParcelasMensalRowsX', () {
    test('aggregatedMergedRows delegates to merger', () {
      const report = AgentQueryExecutionReport<ResumoParcelasMensalRow>(
        queryKey: AgentQueryKey.resumoParcelasMensal,
        strategy: AgentQueryExecutionStrategy.mergeAll,
        consideredApprovedAgentCount: 2,
        plannedTargets: <AgentQueryTarget>[],
        missingClientTokenTargets: <AgentQueryTarget>[],
        participants:
            <AgentQueryExecutionParticipant<ResumoParcelasMensalRow>>[
          AgentQueryExecutionParticipant<ResumoParcelasMensalRow>(
            agentId: 'a',
            displayName: 'a',
            rows: <ResumoParcelasMensalRow>[
              ResumoParcelasMensalRow(
                ano: 2025,
                mes: 4,
                anoMes: '2025/04',
                quantidade: 1,
                valorTotal: 2,
              ),
            ],
            elapsedMs: 1,
          ),
          AgentQueryExecutionParticipant<ResumoParcelasMensalRow>(
            agentId: 'b',
            displayName: 'b',
            rows: <ResumoParcelasMensalRow>[
              ResumoParcelasMensalRow(
                ano: 2025,
                mes: 4,
                anoMes: '2025/04',
                quantidade: 4,
                valorTotal: 8,
              ),
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
      check(report.aggregatedMergedRows.single.anoMes).equals('2025/04');
    });
  });
}

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
    test(
      'merge sums qtdVendas and valorParcela per empresa, filial, ano, mes',
      () {
        final merged = ResumoParcelasMensalRowMerger.merge(
          <ResumoParcelasMensalRow>[
            const ResumoParcelasMensalRow(
              codEmpresa: 1,
              codFilial: 1,
              ano: 2025,
              mes: 3,
              anoMes: '2025/03',
              qtdVendas: 2,
              valorParcela: 10,
            ),
            const ResumoParcelasMensalRow(
              codEmpresa: 1,
              codFilial: 1,
              ano: 2025,
              mes: 3,
              anoMes: '2025/03',
              qtdVendas: 3,
              valorParcela: 5,
            ),
            const ResumoParcelasMensalRow(
              codEmpresa: 1,
              codFilial: 1,
              ano: 2026,
              mes: 1,
              anoMes: '2026/01',
              qtdVendas: 1,
              valorParcela: 7,
            ),
          ],
        );
        check(merged.length).equals(2);
        final m202503 = merged.firstWhere((r) => r.ano == 2025 && r.mes == 3);
        check(m202503.qtdVendas).equals(5);
        check(m202503.valorParcela).equals(15);
        check(m202503.anoMes).equals('2025/03');
        final m202601 = merged.firstWhere((r) => r.ano == 2026 && r.mes == 1);
        check(m202601.qtdVendas).equals(1);
        check(m202601.anoMes).equals('2026/01');
      },
    );

    test('merge keeps distinct filial buckets for same month', () {
      final merged = ResumoParcelasMensalRowMerger.merge(
        <ResumoParcelasMensalRow>[
          const ResumoParcelasMensalRow(
            codEmpresa: 1,
            codFilial: 1,
            ano: 2025,
            mes: 4,
            anoMes: '2025/04',
            qtdVendas: 1,
            valorParcela: 10,
          ),
          const ResumoParcelasMensalRow(
            codEmpresa: 1,
            codFilial: 2,
            ano: 2025,
            mes: 4,
            anoMes: '2025/04',
            qtdVendas: 2,
            valorParcela: 20,
          ),
        ],
      );
      check(merged.length).equals(2);
    });

    test('merge skips invalid mes', () {
      final merged = ResumoParcelasMensalRowMerger.merge(
        <ResumoParcelasMensalRow>[
          const ResumoParcelasMensalRow(
            codEmpresa: 1,
            codFilial: 1,
            ano: 2025,
            mes: 0,
            anoMes: 'x',
            qtdVendas: 99,
            valorParcela: 1,
          ),
          const ResumoParcelasMensalRow(
            codEmpresa: 1,
            codFilial: 1,
            ano: 2025,
            mes: 2,
            anoMes: '2025/02',
            qtdVendas: 1,
            valorParcela: 2,
          ),
        ],
      );
      check(merged.length).equals(1);
      check(merged.single.mes).equals(2);
      check(merged.single.qtdVendas).equals(1);
    });

    test('merge skips invalid calendar year', () {
      final merged = ResumoParcelasMensalRowMerger.merge(
        <ResumoParcelasMensalRow>[
          const ResumoParcelasMensalRow(
            codEmpresa: 1,
            codFilial: 1,
            ano: 1899,
            mes: 6,
            anoMes: 'x',
            qtdVendas: 50,
            valorParcela: 1,
          ),
          const ResumoParcelasMensalRow(
            codEmpresa: 1,
            codFilial: 1,
            ano: 2025,
            mes: 6,
            anoMes: '2025/06',
            qtdVendas: 1,
            valorParcela: 2,
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
            codEmpresa: 1,
            codFilial: 1,
            ano: 2025,
            mes: 13,
            anoMes: 'x',
            qtdVendas: 1,
            valorParcela: 1,
          ),
          const ResumoParcelasMensalRow(
            codEmpresa: 1,
            codFilial: 1,
            ano: 2101,
            mes: 1,
            anoMes: 'x',
            qtdVendas: 1,
            valorParcela: 1,
          ),
          const ResumoParcelasMensalRow(
            codEmpresa: 1,
            codFilial: 1,
            ano: 2025,
            mes: 1,
            anoMes: '2025/01',
            qtdVendas: 2,
            valorParcela: 3,
          ),
        ],
      );
      check(stats.skippedInvalidInputRows).equals(2);
      check(stats.rows.single.qtdVendas).equals(2);
    });

    test('merge sorts by empresa, filial, ano, mes', () {
      final merged = ResumoParcelasMensalRowMerger.merge(
        <ResumoParcelasMensalRow>[
          const ResumoParcelasMensalRow(
            codEmpresa: 1,
            codFilial: 2,
            ano: 2026,
            mes: 1,
            anoMes: '2026/01',
            qtdVendas: 1,
            valorParcela: 1,
          ),
          const ResumoParcelasMensalRow(
            codEmpresa: 1,
            codFilial: 1,
            ano: 2025,
            mes: 12,
            anoMes: '2025/12',
            qtdVendas: 1,
            valorParcela: 1,
          ),
        ],
      );
      check(
        merged
            .map((r) => '${r.codEmpresa}-${r.codFilial}-${r.anoMes}')
            .toList(),
      ).deepEquals(const <String>['1-1-2025/12', '1-2-2026/01']);
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
        participants: <AgentQueryExecutionParticipant<ResumoParcelasMensalRow>>[
          AgentQueryExecutionParticipant<ResumoParcelasMensalRow>(
            agentId: 'a',
            displayName: 'a',
            rows: <ResumoParcelasMensalRow>[
              ResumoParcelasMensalRow(
                codEmpresa: 1,
                codFilial: 1,
                ano: 2025,
                mes: 4,
                anoMes: '2025/04',
                qtdVendas: 1,
                valorParcela: 2,
              ),
            ],
            elapsedMs: 1,
          ),
          AgentQueryExecutionParticipant<ResumoParcelasMensalRow>(
            agentId: 'b',
            displayName: 'b',
            rows: <ResumoParcelasMensalRow>[
              ResumoParcelasMensalRow(
                codEmpresa: 1,
                codFilial: 1,
                ano: 2025,
                mes: 4,
                anoMes: '2025/04',
                qtdVendas: 4,
                valorParcela: 8,
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
      check(report.aggregatedMergedRows.single.valorParcela).equals(10);
      check(report.aggregatedMergedRows.single.anoMes).equals('2025/04');
    });
  });
}

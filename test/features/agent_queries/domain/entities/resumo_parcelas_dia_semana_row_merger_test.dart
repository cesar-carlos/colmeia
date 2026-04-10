import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_participant.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_report.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_report_resumo_parcelas.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_key.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_row_merger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ResumoParcelasDiaSemanaRowMerger', () {
    test('merge sums by diaSemanaNumero', () {
      final merged = ResumoParcelasDiaSemanaRowMerger.merge(
        <ResumoParcelasDiaSemanaRow>[
          const ResumoParcelasDiaSemanaRow(
            diaSemanaNumero: 2,
            diaSemana: 'Segunda',
            quantidade: 1,
            valorTotal: 10,
          ),
          const ResumoParcelasDiaSemanaRow(
            diaSemanaNumero: 2,
            diaSemana: 'Segunda',
            quantidade: 2,
            valorTotal: 5,
          ),
        ],
      );
      check(merged.length).equals(1);
      check(merged.single.quantidade).equals(3);
      check(merged.single.valorTotal).equals(15);
      check(merged.single.diaSemanaNumero).equals(2);
      check(merged.single.diaSemana).equals('Segunda');
    });

    test('merge skips invalid diaSemanaNumero', () {
      final merged = ResumoParcelasDiaSemanaRowMerger.merge(
        <ResumoParcelasDiaSemanaRow>[
          const ResumoParcelasDiaSemanaRow(
            diaSemanaNumero: 8,
            diaSemana: 'X',
            quantidade: 9,
            valorTotal: 9,
          ),
        ],
      );
      check(merged).isEmpty();
    });
  });

  group('AgentQueryExecutionReportResumoParcelasDiaSemanaRowsX', () {
    test('aggregatedMergedRows consolidates participants', () {
      const report = AgentQueryExecutionReport<ResumoParcelasDiaSemanaRow>(
        queryKey: AgentQueryKey.resumoParcelasDiaSemana,
        strategy: AgentQueryExecutionStrategy.mergeAll,
        consideredApprovedAgentCount: 2,
        plannedTargets: <AgentQueryTarget>[],
        missingClientTokenTargets: <AgentQueryTarget>[],
        participants:
            <AgentQueryExecutionParticipant<ResumoParcelasDiaSemanaRow>>[
          AgentQueryExecutionParticipant<ResumoParcelasDiaSemanaRow>(
            agentId: 'a',
            displayName: 'a',
            rows: <ResumoParcelasDiaSemanaRow>[
              ResumoParcelasDiaSemanaRow(
                diaSemanaNumero: 3,
                diaSemana: 'Terça',
                quantidade: 1,
                valorTotal: 2,
              ),
            ],
            elapsedMs: 1,
          ),
          AgentQueryExecutionParticipant<ResumoParcelasDiaSemanaRow>(
            agentId: 'b',
            displayName: 'b',
            rows: <ResumoParcelasDiaSemanaRow>[
              ResumoParcelasDiaSemanaRow(
                diaSemanaNumero: 3,
                diaSemana: 'Terça',
                quantidade: 3,
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
      check(report.aggregatedMergedRows.single.quantidade).equals(4);
      check(report.aggregatedMergedRows.single.valorTotal).equals(10);
    });
  });
}

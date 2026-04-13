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
    test('merge sums by codEmpresa, codFilial, and diaSemanaNumero', () {
      final merged = ResumoParcelasDiaSemanaRowMerger.merge(
        <ResumoParcelasDiaSemanaRow>[
          const ResumoParcelasDiaSemanaRow(
            codEmpresa: 1,
            codFilial: 1,
            diaSemanaNumero: 2,
            diaSemana: 'Segunda',
            qtdVendas: 1,
            valorParcela: 10,
          ),
          const ResumoParcelasDiaSemanaRow(
            codEmpresa: 1,
            codFilial: 1,
            diaSemanaNumero: 2,
            diaSemana: 'Segunda',
            qtdVendas: 2,
            valorParcela: 5,
          ),
        ],
      );
      check(merged.length).equals(1);
      check(merged.single.qtdVendas).equals(3);
      check(merged.single.valorParcela).equals(15);
      check(merged.single.diaSemanaNumero).equals(2);
      check(merged.single.diaSemana).equals('Segunda');
    });

    test('merge does not combine different branches', () {
      final merged = ResumoParcelasDiaSemanaRowMerger.merge(
        <ResumoParcelasDiaSemanaRow>[
          const ResumoParcelasDiaSemanaRow(
            codEmpresa: 1,
            codFilial: 1,
            diaSemanaNumero: 2,
            diaSemana: 'Segunda',
            qtdVendas: 1,
            valorParcela: 10,
          ),
          const ResumoParcelasDiaSemanaRow(
            codEmpresa: 1,
            codFilial: 2,
            diaSemanaNumero: 2,
            diaSemana: 'Segunda',
            qtdVendas: 3,
            valorParcela: 7,
          ),
        ],
      );
      check(merged.length).equals(2);
    });

    test(
      'merge does not combine same filial and weekday with different empresa',
      () {
        final merged = ResumoParcelasDiaSemanaRowMerger.merge(
          <ResumoParcelasDiaSemanaRow>[
            const ResumoParcelasDiaSemanaRow(
              codEmpresa: 1,
              codFilial: 5,
              diaSemanaNumero: 4,
              diaSemana: 'Quarta',
              qtdVendas: 2,
              valorParcela: 20,
            ),
            const ResumoParcelasDiaSemanaRow(
              codEmpresa: 2,
              codFilial: 5,
              diaSemanaNumero: 4,
              diaSemana: 'Quarta',
              qtdVendas: 8,
              valorParcela: 30,
            ),
          ],
        );
        check(merged.length).equals(2);
        check(merged.firstWhere((r) => r.codEmpresa == 1).qtdVendas).equals(2);
        check(merged.firstWhere((r) => r.codEmpresa == 2).qtdVendas).equals(8);
      },
    );

    test('merge key is codEmpresa|codFilial|diaSemanaNumero', () {
      final merged = ResumoParcelasDiaSemanaRowMerger.merge(
        <ResumoParcelasDiaSemanaRow>[
          const ResumoParcelasDiaSemanaRow(
            codEmpresa: 9,
            codFilial: 3,
            diaSemanaNumero: 7,
            diaSemana: 'Sábado',
            qtdVendas: 1,
            valorParcela: 1,
          ),
          const ResumoParcelasDiaSemanaRow(
            codEmpresa: 9,
            codFilial: 3,
            diaSemanaNumero: 1,
            diaSemana: 'Domingo',
            qtdVendas: 10,
            valorParcela: 2,
          ),
        ],
      );
      check(merged.length).equals(2);
      check(merged.map((r) => r.diaSemanaNumero).toSet()).deepEquals(
        <int>{1, 7},
      );
    });

    test('merge skips invalid diaSemanaNumero', () {
      final merged = ResumoParcelasDiaSemanaRowMerger.merge(
        <ResumoParcelasDiaSemanaRow>[
          const ResumoParcelasDiaSemanaRow(
            codEmpresa: 1,
            codFilial: 1,
            diaSemanaNumero: 8,
            diaSemana: 'X',
            qtdVendas: 9,
            valorParcela: 9,
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
                    codEmpresa: 1,
                    codFilial: 1,
                    diaSemanaNumero: 3,
                    diaSemana: 'Terça',
                    qtdVendas: 1,
                    valorParcela: 2,
                  ),
                ],
                elapsedMs: 1,
              ),
              AgentQueryExecutionParticipant<ResumoParcelasDiaSemanaRow>(
                agentId: 'b',
                displayName: 'b',
                rows: <ResumoParcelasDiaSemanaRow>[
                  ResumoParcelasDiaSemanaRow(
                    codEmpresa: 1,
                    codFilial: 1,
                    diaSemanaNumero: 3,
                    diaSemana: 'Terça',
                    qtdVendas: 3,
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
      check(report.aggregatedMergedRows.single.qtdVendas).equals(4);
      check(report.aggregatedMergedRows.single.valorParcela).equals(10);
    });
  });
}

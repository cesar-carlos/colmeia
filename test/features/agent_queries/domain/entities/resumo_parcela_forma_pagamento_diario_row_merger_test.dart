import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_participant.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_report.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_report_resumo_parcelas.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_key.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_forma_pagamento_diario_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_forma_pagamento_diario_row_merger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final day = DateTime(2026, 4);

  ResumoVendaProdutoDiarioRow baseRow({
    required DateTime dataVenda,
    int qtdVendas = 1,
    double valorTotalVenda = 10,
    int? codVendedor = 1,
    String? nomeVendedor = 'V',
  }) {
    return ResumoVendaProdutoDiarioRow(
      codEmpresa: 1,
      codFilial: 6,
      codProdutoVendido: 100,
      origem: 'OB',
      codOrigem: 1,
      dataVenda: dataVenda,
      anoMesDataVenda: '2026/04',
      nomeUsuario: 'U',
      codVendedor: codVendedor,
      nomeVendedor: nomeVendedor,
      qtdVendas: qtdVendas,
      valorTotalVenda: valorTotalVenda,
    );
  }

  group('ResumoVendaProdutoDiarioRowMerger', () {
    test('merge sums measures for the same GROUP BY dimensions', () {
      final merged = ResumoVendaProdutoDiarioRowMerger.merge(
        <ResumoVendaProdutoDiarioRow>[
          baseRow(dataVenda: day),
          baseRow(
            dataVenda: DateTime(2026, 4, 1, 23, 59),
            qtdVendas: 2,
            valorTotalVenda: 5,
          ),
        ],
      );
      check(merged.length).equals(1);
      check(merged.single.qtdVendas).equals(3);
      check(merged.single.valorTotalVenda).equals(15);
      check(merged.single.dataVenda).equals(day);
    });

    test('merge sums two participants with null seller into one row', () {
      final merged = ResumoVendaProdutoDiarioRowMerger.merge(
        <ResumoVendaProdutoDiarioRow>[
          baseRow(
            dataVenda: day,
            valorTotalVenda: 2,
            codVendedor: null,
            nomeVendedor: null,
          ),
          baseRow(
            dataVenda: day,
            qtdVendas: 3,
            valorTotalVenda: 8,
            codVendedor: null,
            nomeVendedor: null,
          ),
        ],
      );
      check(merged.length).equals(1);
      check(merged.single.qtdVendas).equals(4);
      check(merged.single.valorTotalVenda).equals(10);
      check(merged.single.codVendedor).isNull();
      check(merged.single.nomeVendedor).isNull();
    });
  });

  group('AgentQueryExecutionReportResumoVendaProdutoDiarioRowsX', () {
    test('aggregatedMergedRows consolidates participants', () {
      final report =
          AgentQueryExecutionReport<ResumoVendaProdutoDiarioRow>(
            queryKey: AgentQueryKey.resumoParcelaFormaPagamentoDiario,
            strategy: AgentQueryExecutionStrategy.mergeAll,
            consideredApprovedAgentCount: 2,
            plannedTargets: <AgentQueryTarget>[],
            missingClientTokenTargets: <AgentQueryTarget>[],
            participants:
                <
                  AgentQueryExecutionParticipant<
                    ResumoVendaProdutoDiarioRow
                  >
                >[
                  AgentQueryExecutionParticipant<
                    ResumoVendaProdutoDiarioRow
                  >(
                    agentId: 'a',
                    displayName: 'a',
                    rows: <ResumoVendaProdutoDiarioRow>[
                      baseRow(
                        dataVenda: day,
                        valorTotalVenda: 2,
                      ),
                    ],
                    elapsedMs: 1,
                  ),
                  AgentQueryExecutionParticipant<
                    ResumoVendaProdutoDiarioRow
                  >(
                    agentId: 'b',
                    displayName: 'b',
                    rows: <ResumoVendaProdutoDiarioRow>[
                      baseRow(
                        dataVenda: day,
                        qtdVendas: 3,
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
      check(report.aggregatedMergedRows.single.qtdVendas).equals(4);
      check(report.aggregatedMergedRows.single.valorTotalVenda).equals(10);
    });
  });
}

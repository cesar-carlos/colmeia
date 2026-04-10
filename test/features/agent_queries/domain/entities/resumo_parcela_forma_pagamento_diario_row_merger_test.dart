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

  group('ResumoParcelaFormaPagamentoDiarioRowMerger', () {
    test('merge sums by calendar day and descricaoFormaPagamento', () {
      final merged = ResumoParcelaFormaPagamentoDiarioRowMerger.merge(
        <ResumoParcelaFormaPagamentoDiarioRow>[
          ResumoParcelaFormaPagamentoDiarioRow(
            dataVenda: day,
            descricaoFormaPagamento: 'Pix',
            quantidade: 1,
            valorTotal: 10,
          ),
          ResumoParcelaFormaPagamentoDiarioRow(
            dataVenda: DateTime(2026, 4, 1, 23, 59),
            descricaoFormaPagamento: 'Pix',
            quantidade: 2,
            valorTotal: 5,
          ),
        ],
      );
      check(merged.length).equals(1);
      check(merged.single.quantidade).equals(3);
      check(merged.single.valorTotal).equals(15);
      check(merged.single.dataVenda).equals(day);
    });
  });

  group('AgentQueryExecutionReportResumoParcelaFormaPagamentoDiarioRowsX', () {
    test('aggregatedMergedRows consolidates participants', () {
      final report =
          AgentQueryExecutionReport<ResumoParcelaFormaPagamentoDiarioRow>(
            queryKey: AgentQueryKey.resumoParcelaFormaPagamentoDiario,
            strategy: AgentQueryExecutionStrategy.mergeAll,
            consideredApprovedAgentCount: 2,
            plannedTargets: <AgentQueryTarget>[],
            missingClientTokenTargets: <AgentQueryTarget>[],
            participants:
                <
                  AgentQueryExecutionParticipant<
                    ResumoParcelaFormaPagamentoDiarioRow
                  >
                >[
                  AgentQueryExecutionParticipant<
                    ResumoParcelaFormaPagamentoDiarioRow
                  >(
                    agentId: 'a',
                    displayName: 'a',
                    rows: <ResumoParcelaFormaPagamentoDiarioRow>[
                      ResumoParcelaFormaPagamentoDiarioRow(
                        dataVenda: day,
                        descricaoFormaPagamento: 'Pix',
                        quantidade: 1,
                        valorTotal: 2,
                      ),
                    ],
                    elapsedMs: 1,
                  ),
                  AgentQueryExecutionParticipant<
                    ResumoParcelaFormaPagamentoDiarioRow
                  >(
                    agentId: 'b',
                    displayName: 'b',
                    rows: <ResumoParcelaFormaPagamentoDiarioRow>[
                      ResumoParcelaFormaPagamentoDiarioRow(
                        dataVenda: day,
                        descricaoFormaPagamento: 'Pix',
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

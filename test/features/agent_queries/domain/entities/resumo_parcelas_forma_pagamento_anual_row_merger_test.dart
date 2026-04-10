import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_participant.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_report.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_report_resumo_parcelas.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_key.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_forma_pagamento_anual_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_forma_pagamento_anual_row_merger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ResumoParcelasFormaPagamentoAnualRowMerger', () {
    test('merge sums by ano and descricaoFormaPagamento', () {
      final merged = ResumoParcelasFormaPagamentoAnualRowMerger.merge(
        <ResumoParcelasFormaPagamentoAnualRow>[
          const ResumoParcelasFormaPagamentoAnualRow(
            ano: 2025,
            descricaoFormaPagamento: 'Pix',
            quantidade: 1,
            valorTotal: 10,
          ),
          const ResumoParcelasFormaPagamentoAnualRow(
            ano: 2025,
            descricaoFormaPagamento: 'Pix',
            quantidade: 2,
            valorTotal: 5,
          ),
          const ResumoParcelasFormaPagamentoAnualRow(
            ano: 2025,
            descricaoFormaPagamento: 'Dinheiro',
            quantidade: 1,
            valorTotal: 3,
          ),
        ],
      );
      check(merged.length).equals(2);
      final pix = merged.firstWhere((r) => r.descricaoFormaPagamento == 'Pix');
      check(pix.quantidade).equals(3);
      check(pix.valorTotal).equals(15);
    });

    test('orders by ano then descricao', () {
      final merged = ResumoParcelasFormaPagamentoAnualRowMerger.merge(
        <ResumoParcelasFormaPagamentoAnualRow>[
          const ResumoParcelasFormaPagamentoAnualRow(
            ano: 2026,
            descricaoFormaPagamento: 'A',
            quantidade: 1,
            valorTotal: 1,
          ),
          const ResumoParcelasFormaPagamentoAnualRow(
            ano: 2025,
            descricaoFormaPagamento: 'B',
            quantidade: 1,
            valorTotal: 1,
          ),
        ],
      );
      check(merged.map((r) => r.ano).toList()).deepEquals(<int>[2025, 2026]);
    });
  });

  group('AgentQueryExecutionReportResumoParcelasFormaPagamentoAnualRowsX', () {
    test('aggregatedMergedRows consolidates participants', () {
      const report =
          AgentQueryExecutionReport<ResumoParcelasFormaPagamentoAnualRow>(
            queryKey: AgentQueryKey.resumoParcelasFormaPagamentoAnual,
            strategy: AgentQueryExecutionStrategy.mergeAll,
            consideredApprovedAgentCount: 2,
            plannedTargets: <AgentQueryTarget>[],
            missingClientTokenTargets: <AgentQueryTarget>[],
            participants:
                <
                  AgentQueryExecutionParticipant<
                    ResumoParcelasFormaPagamentoAnualRow
                  >
                >[
                  AgentQueryExecutionParticipant<
                    ResumoParcelasFormaPagamentoAnualRow
                  >(
                    agentId: 'a',
                    displayName: 'a',
                    rows: <ResumoParcelasFormaPagamentoAnualRow>[
                      ResumoParcelasFormaPagamentoAnualRow(
                        ano: 2025,
                        descricaoFormaPagamento: 'Pix',
                        quantidade: 1,
                        valorTotal: 2,
                      ),
                    ],
                    elapsedMs: 1,
                  ),
                  AgentQueryExecutionParticipant<
                    ResumoParcelasFormaPagamentoAnualRow
                  >(
                    agentId: 'b',
                    displayName: 'b',
                    rows: <ResumoParcelasFormaPagamentoAnualRow>[
                      ResumoParcelasFormaPagamentoAnualRow(
                        ano: 2025,
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

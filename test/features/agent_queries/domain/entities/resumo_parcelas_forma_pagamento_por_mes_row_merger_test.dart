import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_participant.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_report.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_report_resumo_parcelas.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_key.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_forma_pagamento_por_mes_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_forma_pagamento_por_mes_row_merger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ResumoParcelasFormaPagamentoPorMesRowMerger', () {
    test('merge sums by full dimension key', () {
      final merged = ResumoParcelasFormaPagamentoPorMesRowMerger.merge(
        <ResumoParcelasFormaPagamentoPorMesRow>[
          const ResumoParcelasFormaPagamentoPorMesRow(
            codEmpresa: 1,
            codFilial: 1,
            nomeUsuario: 'U',
            anoMesDataVenda: '2025/06',
            codFormaPagamento: 'PX',
            descricaoFormaPagamento: 'Pix',
            qtdVendas: 1,
            valorParcela: 10,
          ),
          const ResumoParcelasFormaPagamentoPorMesRow(
            codEmpresa: 1,
            codFilial: 1,
            nomeUsuario: 'U',
            anoMesDataVenda: '2025/06',
            codFormaPagamento: 'PX',
            descricaoFormaPagamento: 'Pix',
            qtdVendas: 2,
            valorParcela: 5,
          ),
          const ResumoParcelasFormaPagamentoPorMesRow(
            codEmpresa: 1,
            codFilial: 1,
            nomeUsuario: 'U',
            anoMesDataVenda: '2025/06',
            codFormaPagamento: 'DH',
            descricaoFormaPagamento: 'Dinheiro',
            qtdVendas: 1,
            valorParcela: 3,
          ),
        ],
      );
      check(merged.length).equals(2);
      final pix = merged.firstWhere(
        (r) => r.descricaoFormaPagamento == 'Pix',
      );
      check(pix.qtdVendas).equals(3);
      check(pix.valorParcela).equals(15);
    });

    test('orders by month then dimensions', () {
      final merged = ResumoParcelasFormaPagamentoPorMesRowMerger.merge(
        <ResumoParcelasFormaPagamentoPorMesRow>[
          const ResumoParcelasFormaPagamentoPorMesRow(
            codEmpresa: 1,
            codFilial: 1,
            nomeUsuario: 'B',
            anoMesDataVenda: '2026/01',
            codFormaPagamento: 'A',
            descricaoFormaPagamento: 'A',
            qtdVendas: 1,
            valorParcela: 1,
          ),
          const ResumoParcelasFormaPagamentoPorMesRow(
            codEmpresa: 1,
            codFilial: 1,
            nomeUsuario: 'A',
            anoMesDataVenda: '2025/12',
            codFormaPagamento: 'B',
            descricaoFormaPagamento: 'B',
            qtdVendas: 1,
            valorParcela: 1,
          ),
        ],
      );
      check(merged.map((r) => r.anoMesDataVenda).toList()).deepEquals(
        <String>['2025/12', '2026/01'],
      );
    });
  });

  group('AgentQueryExecutionReportResumoParcelasFormaPagamentoPorMesRowsX', () {
    test('aggregatedMergedRows consolidates participants', () {
      const report =
          AgentQueryExecutionReport<ResumoParcelasFormaPagamentoPorMesRow>(
            queryKey: AgentQueryKey.resumoParcelasFormaPagamentoPorMes,
            strategy: AgentQueryExecutionStrategy.mergeAll,
            consideredApprovedAgentCount: 2,
            plannedTargets: <AgentQueryTarget>[],
            missingClientTokenTargets: <AgentQueryTarget>[],
            participants:
                <
                  AgentQueryExecutionParticipant<
                    ResumoParcelasFormaPagamentoPorMesRow
                  >
                >[
                  AgentQueryExecutionParticipant<
                    ResumoParcelasFormaPagamentoPorMesRow
                  >(
                    agentId: 'a',
                    displayName: 'a',
                    rows: <ResumoParcelasFormaPagamentoPorMesRow>[
                      ResumoParcelasFormaPagamentoPorMesRow(
                        codEmpresa: 1,
                        codFilial: 1,
                        nomeUsuario: 'U',
                        anoMesDataVenda: '2025/01',
                        codFormaPagamento: 'PX',
                        descricaoFormaPagamento: 'Pix',
                        qtdVendas: 1,
                        valorParcela: 2,
                      ),
                    ],
                    elapsedMs: 1,
                  ),
                  AgentQueryExecutionParticipant<
                    ResumoParcelasFormaPagamentoPorMesRow
                  >(
                    agentId: 'b',
                    displayName: 'b',
                    rows: <ResumoParcelasFormaPagamentoPorMesRow>[
                      ResumoParcelasFormaPagamentoPorMesRow(
                        codEmpresa: 1,
                        codFilial: 1,
                        nomeUsuario: 'U',
                        anoMesDataVenda: '2025/01',
                        codFormaPagamento: 'PX',
                        descricaoFormaPagamento: 'Pix',
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

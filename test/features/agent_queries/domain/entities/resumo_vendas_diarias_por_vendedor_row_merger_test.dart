import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_participant.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_report.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_report_resumo_parcelas.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_key.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_vendas_diarias_por_vendedor_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_vendas_diarias_por_vendedor_row_merger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ResumoVendasDiariasPorVendedorRowMerger', () {
    test('sums measures for same key across agents', () {
      final day = DateTime(2026, 4, 10);
      final merged = ResumoVendasDiariasPorVendedorRowMerger.merge(
        <ResumoVendasDiariasPorVendedorRow>[
          ResumoVendasDiariasPorVendedorRow(
            codEmpresa: 1,
            codFilial: 2,
            dataVenda: day,
            anoMesDataVenda: '2026/04',
            codVendedor: 5,
            nomeVendedor: 'Ana',
            qtdVendas: 2,
            valorTotalVenda: 100,
          ),
          ResumoVendasDiariasPorVendedorRow(
            codEmpresa: 1,
            codFilial: 2,
            dataVenda: day,
            anoMesDataVenda: '2026/04',
            codVendedor: 5,
            nomeVendedor: 'Ana',
            qtdVendas: 3,
            valorTotalVenda: 50,
          ),
        ],
      );
      check(merged.length).equals(1);
      check(merged.single.qtdVendas).equals(5);
      check(merged.single.valorTotalVenda).equals(150);
    });

    test('keeps distinct rows for null seller dimensions', () {
      final day = DateTime(2026, 4, 10);
      final merged = ResumoVendasDiariasPorVendedorRowMerger.merge(
        <ResumoVendasDiariasPorVendedorRow>[
          ResumoVendasDiariasPorVendedorRow(
            codEmpresa: 1,
            codFilial: 2,
            dataVenda: day,
            anoMesDataVenda: '2026/04',
            qtdVendas: 1,
            valorTotalVenda: 10,
          ),
          ResumoVendasDiariasPorVendedorRow(
            codEmpresa: 1,
            codFilial: 2,
            dataVenda: day,
            anoMesDataVenda: '2026/04',
            codVendedor: 1,
            nomeVendedor: 'Bob',
            qtdVendas: 2,
            valorTotalVenda: 20,
          ),
        ],
      );
      check(merged.length).equals(2);
    });
  });

  group('AgentQueryExecutionReportResumoVendasDiariasPorVendedorRowsX', () {
    test('aggregatedMergedRows consolidates participants', () {
      final day = DateTime(2026, 4, 10);

      ResumoVendasDiariasPorVendedorRow sampleRow({
        required int qtd,
        required double valor,
      }) {
        return ResumoVendasDiariasPorVendedorRow(
          codEmpresa: 1,
          codFilial: 2,
          dataVenda: day,
          anoMesDataVenda: '2026/04',
          codVendedor: 5,
          nomeVendedor: 'Ana',
          qtdVendas: qtd,
          valorTotalVenda: valor,
        );
      }

      final report =
          AgentQueryExecutionReport<ResumoVendasDiariasPorVendedorRow>(
            queryKey: AgentQueryKey.resumoVendasDiariasPorVendedor,
            strategy: AgentQueryExecutionStrategy.mergeAll,
            consideredApprovedAgentCount: 2,
            plannedTargets: <AgentQueryTarget>[],
            missingClientTokenTargets: <AgentQueryTarget>[],
            participants: <AgentQueryExecutionParticipant<
              ResumoVendasDiariasPorVendedorRow
            >>[
              AgentQueryExecutionParticipant<ResumoVendasDiariasPorVendedorRow>(
                agentId: 'a',
                displayName: 'a',
                rows: <ResumoVendasDiariasPorVendedorRow>[
                  sampleRow(qtd: 2, valor: 3),
                ],
                elapsedMs: 1,
              ),
              AgentQueryExecutionParticipant<ResumoVendasDiariasPorVendedorRow>(
                agentId: 'b',
                displayName: 'b',
                rows: <ResumoVendasDiariasPorVendedorRow>[
                  sampleRow(qtd: 1, valor: 7),
                ],
                elapsedMs: 1,
              ),
            ],
            totalElapsedMs: 2,
          );
      check(report.mergedRows.length).equals(2);
      check(report.aggregatedMergedRows.length).equals(1);
      check(report.aggregatedMergedRows.single.qtdVendas).equals(3);
      check(report.aggregatedMergedRows.single.valorTotalVenda).equals(10);
    });
  });
}

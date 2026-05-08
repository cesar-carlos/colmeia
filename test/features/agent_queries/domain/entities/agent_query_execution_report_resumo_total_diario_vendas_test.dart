import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_participant.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_report.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_report_resumo_parcelas.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_key.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_diario_vendas_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_diario_vendas_row.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AgentQueryExecutionReport ResumoTotalDiarioVendas extensions', () {
    test('aggregatedMergedRows merges duplicate keys across participants', () {
      final report = AgentQueryExecutionReport<ResumoTotalDiarioVendasRow>(
        queryKey: AgentQueryKey.resumoTotalDiarioVendas,
        strategy: AgentQueryExecutionStrategy.mergeAll,
        consideredApprovedAgentCount: 2,
        plannedTargets: const <AgentQueryTarget>[],
        missingClientTokenTargets: const <AgentQueryTarget>[],
        participants:
            <AgentQueryExecutionParticipant<ResumoTotalDiarioVendasRow>>[
              AgentQueryExecutionParticipant<ResumoTotalDiarioVendasRow>(
                agentId: 'agent-a',
                displayName: 'A',
                rows: <ResumoTotalDiarioVendasRow>[
                  ResumoTotalDiarioVendasRow(
                    codEmpresa: 1,
                    codFilial: 1,
                    dataVenda: DateTime(2026, 4, 10),
                    qtdVendas: 1,
                    valorTotalDiarioVenda: 10,
                  ),
                ],
                elapsedMs: 1,
              ),
              AgentQueryExecutionParticipant<ResumoTotalDiarioVendasRow>(
                agentId: 'agent-b',
                displayName: 'B',
                rows: <ResumoTotalDiarioVendasRow>[
                  ResumoTotalDiarioVendasRow(
                    codEmpresa: 1,
                    codFilial: 1,
                    dataVenda: DateTime(2026, 4, 10),
                    qtdVendas: 2,
                    valorTotalDiarioVenda: 5,
                  ),
                ],
                elapsedMs: 1,
              ),
            ],
        totalElapsedMs: 2,
      );

      final merged = report.aggregatedMergedRows;
      check(merged).length.equals(1);
      check(merged.single.qtdVendas).equals(3);
      check(merged.single.valorTotalDiarioVenda).equals(15);
    });

    test(
      'chartRowsFilledPeriod fills every calendar day with zeros when missing',
      () {
        final report = AgentQueryExecutionReport<ResumoTotalDiarioVendasRow>(
          queryKey: AgentQueryKey.resumoTotalDiarioVendas,
          strategy: AgentQueryExecutionStrategy.mergeAll,
          consideredApprovedAgentCount: 1,
          plannedTargets: const <AgentQueryTarget>[],
          missingClientTokenTargets: const <AgentQueryTarget>[],
          participants:
              <AgentQueryExecutionParticipant<ResumoTotalDiarioVendasRow>>[
                AgentQueryExecutionParticipant<ResumoTotalDiarioVendasRow>(
                  agentId: 'agent-a',
                  displayName: 'A',
                  rows: <ResumoTotalDiarioVendasRow>[
                    ResumoTotalDiarioVendasRow(
                      codEmpresa: 1,
                      codFilial: 2,
                      dataVenda: DateTime(2026, 5, 2),
                      qtdVendas: 4,
                      valorTotalDiarioVenda: 40,
                    ),
                  ],
                  elapsedMs: 1,
                ),
              ],
          totalElapsedMs: 1,
        );

        final filter = ResumoTotalDiarioVendasFilter(
          dataVendaInicio: DateTime(2026, 5),
          dataVendaFim: DateTime(2026, 5, 3),
        );
        final filled = report.chartRowsFilledPeriod(filter);

        check(filled).length.equals(3);
        check(filled[0].dataVenda).equals(DateTime(2026, 5));
        check(filled[0].qtdVendas).equals(0);
        check(filled[0].valorTotalDiarioVenda).equals(0);
        check(filled[1].dataVenda).equals(DateTime(2026, 5, 2));
        check(filled[1].qtdVendas).equals(4);
        check(filled[1].valorTotalDiarioVenda).equals(40);
        check(filled[2].dataVenda).equals(DateTime(2026, 5, 3));
        check(filled[2].qtdVendas).equals(0);
      },
    );
  });
}

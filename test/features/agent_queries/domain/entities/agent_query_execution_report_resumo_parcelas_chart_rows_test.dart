import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_participant.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_report.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_report_resumo_parcelas.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_key.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_mensal_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_mensal_row.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_connection_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('chartRowsWeek', () {
    test('fills seven weekdays from sparse merged data', () {
      const report = AgentQueryExecutionReport<ResumoParcelasDiaSemanaRow>(
        queryKey: AgentQueryKey.resumoParcelasDiaSemana,
        strategy: AgentQueryExecutionStrategy.mergeAll,
        consideredApprovedAgentCount: 1,
        plannedTargets: <AgentQueryTarget>[
          AgentQueryTarget(
            agentId: 'a',
            displayName: 'A',
            connectionStatus: AgentConnectionStatus.online,
          ),
        ],
        missingClientTokenTargets: <AgentQueryTarget>[],
        participants:
            <AgentQueryExecutionParticipant<ResumoParcelasDiaSemanaRow>>[
              AgentQueryExecutionParticipant<ResumoParcelasDiaSemanaRow>(
                agentId: 'a',
                displayName: 'A',
                elapsedMs: 0,
                rows: <ResumoParcelasDiaSemanaRow>[
                  ResumoParcelasDiaSemanaRow(
                    codEmpresa: 1,
                    codFilial: 1,
                    diaSemanaNumero: 2,
                    diaSemana: 'Segunda',
                    qtdVendas: 3,
                    valorParcela: 9,
                  ),
                ],
              ),
            ],
        totalElapsedMs: 0,
      );

      final chart = report.chartRowsWeek;
      check(chart).has((it) => it.length, 'length').equals(7);
      check(chart.first.diaSemanaNumero).equals(1);
      check(chart.first.qtdVendas).equals(0);
      check(chart[1].diaSemanaNumero).equals(2);
      check(chart[1].qtdVendas).equals(3);
      check(chart[1].valorParcela).equals(9);
    });
  });

  group('chartRowsFilledPeriod', () {
    test('fills months across filter range', () {
      final filter = ResumoParcelasMensalFilter(
        dataVendaInicio: DateTime.utc(2026, 3, 15),
        dataVendaFim: DateTime.utc(2026, 5, 10),
      );
      const report = AgentQueryExecutionReport<ResumoParcelasMensalRow>(
        queryKey: AgentQueryKey.resumoParcelasMensal,
        strategy: AgentQueryExecutionStrategy.mergeAll,
        consideredApprovedAgentCount: 1,
        plannedTargets: <AgentQueryTarget>[
          AgentQueryTarget(
            agentId: 'a',
            displayName: 'A',
            connectionStatus: AgentConnectionStatus.online,
          ),
        ],
        missingClientTokenTargets: <AgentQueryTarget>[],
        participants: <AgentQueryExecutionParticipant<ResumoParcelasMensalRow>>[
          AgentQueryExecutionParticipant<ResumoParcelasMensalRow>(
            agentId: 'a',
            displayName: 'A',
            elapsedMs: 0,
            rows: <ResumoParcelasMensalRow>[
              ResumoParcelasMensalRow(
                codEmpresa: 1,
                codFilial: 1,
                ano: 2026,
                mes: 4,
                anoMes: '2026/04',
                qtdVendas: 2,
                valorParcela: 4,
              ),
            ],
          ),
        ],
        totalElapsedMs: 0,
      );

      final chart = report.chartRowsFilledPeriod(filter);
      check(chart).has((it) => it.length, 'length').equals(3);
      check(chart.map((r) => r.mes).toList()).deepEquals(<int>[3, 4, 5]);
      check(chart[0].qtdVendas).equals(0);
      check(chart[1].qtdVendas).equals(2);
      check(chart[2].qtdVendas).equals(0);
      check(chart[0].codEmpresa).equals(
        ResumoParcelasMensalRow.aggregatedBranchSentinel,
      );
    });
  });
}

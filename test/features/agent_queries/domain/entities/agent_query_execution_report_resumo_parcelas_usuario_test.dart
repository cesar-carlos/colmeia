import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_participant.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_report.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_report_resumo_parcelas.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_key.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_usuario_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_usuario_row_merger.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_connection_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'aggregatedMergedRows applies ResumoParcelasDiaSemanaUsuarioRowMerger',
    () {
      const row = ResumoParcelasDiaSemanaUsuarioRow(
        codEmpresa: 1,
        codFilial: 1,
        nomeUsuario: 'Ada',
        diaSemanaNumero: 2,
        diaSemana: 'Segunda',
        qtdVendas: 1,
        valorParcela: 10,
      );
      const report =
          AgentQueryExecutionReport<ResumoParcelasDiaSemanaUsuarioRow>(
            queryKey: AgentQueryKey.resumoParcelasDiaSemanaUsuario,
            strategy: AgentQueryExecutionStrategy.mergeAll,
            consideredApprovedAgentCount: 1,
            plannedTargets: [
              AgentQueryTarget(
                agentId: 'a',
                displayName: 'a',
                connectionStatus: AgentConnectionStatus.online,
                clientToken: 't',
              ),
            ],
            missingClientTokenTargets: [],
            participants:
                <
                  AgentQueryExecutionParticipant<
                    ResumoParcelasDiaSemanaUsuarioRow
                  >
                >[
                  AgentQueryExecutionParticipant<
                    ResumoParcelasDiaSemanaUsuarioRow
                  >(
                    agentId: 'a',
                    displayName: 'a',
                    elapsedMs: 0,
                    rows: <ResumoParcelasDiaSemanaUsuarioRow>[row, row],
                  ),
                ],
            totalElapsedMs: 1,
          );

      final merged = ResumoParcelasDiaSemanaUsuarioRowMerger.merge(
        <ResumoParcelasDiaSemanaUsuarioRow>[row, row],
      );
      check(report.aggregatedMergedRows.length).equals(merged.length);
      check(
        report.aggregatedMergedRows.single.qtdVendas,
      ).equals(merged.single.qtdVendas);
      check(
        report.aggregatedMergedRows.single.valorParcela,
      ).equals(merged.single.valorParcela);
    },
  );
}

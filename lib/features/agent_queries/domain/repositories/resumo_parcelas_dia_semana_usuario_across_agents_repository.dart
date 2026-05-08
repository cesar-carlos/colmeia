import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_report.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_usuario_row.dart';

// Cross-agent report entry point; more orchestrated queries may be added here.
// Long type name; `dart format` keeps the interface declaration on one line.
// ignore: one_member_abstracts
abstract interface class ResumoParcelasDiaSemanaUsuarioAcrossAgentsRepository {
  Future<
    AppResult<AgentQueryExecutionReport<ResumoParcelasDiaSemanaUsuarioRow>>
  >
  load({
    required String userId,
    required ResumoParcelasDiaSemanaFilter filter,
    Set<String>? selectedAgentIds,
    AgentQueryExecutionStrategy strategy = AgentQueryExecutionStrategy.mergeAll,
    int? bridgeTimeoutMs,
    int? raceMaxSources,
  });
}

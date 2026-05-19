import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_report.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_por_usuario_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_por_usuario_row.dart';

// ignore: one_member_abstracts, reason: Repository boundaries in this project use single-method contracts for DI and testing.
abstract interface class ResumoParcelaPorUsuarioAcrossAgentsRepository {
  Future<AppResult<AgentQueryExecutionReport<ResumoParcelaPorUsuarioRow>>>
  load({
    required String userId,
    required ResumoParcelaPorUsuarioFilter filter,
    Set<String>? selectedAgentIds,
    AgentQueryExecutionStrategy strategy = AgentQueryExecutionStrategy.mergeAll,
    int? bridgeTimeoutMs,
    int? raceMaxSources,
  });
}

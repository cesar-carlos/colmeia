import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/application/orchestration/agent_query_executor.dart';
import 'package:colmeia/features/agent_queries/application/orchestration/agent_query_plan_builder.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_parcelas_anual_use_case.dart';
import 'package:colmeia/features/agent_queries/data/repositories/agent_query_list_report_across_agents_coordinator.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_report.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_key.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_anual_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_anual_row.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_query_target_resolver.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_parcelas_anual_across_agents_repository.dart';

class ResumoParcelasAnualAcrossAgentsRepositoryImpl
    implements ResumoParcelasAnualAcrossAgentsRepository {
  ResumoParcelasAnualAcrossAgentsRepositoryImpl({
    required this._targetResolver,
    required this._planBuilder,
    required this._executor,
    required this._loadResumo,
  });

  final AgentQueryTargetResolver _targetResolver;
  final AgentQueryPlanBuilder _planBuilder;
  final AgentQueryExecutor<ResumoParcelasAnualRow> _executor;
  final LoadResumoParcelasAnualUseCase _loadResumo;

  static const String _operation = 'loadResumoParcelasAnualAcrossAgents';

  @override
  Future<AppResult<AgentQueryExecutionReport<ResumoParcelasAnualRow>>> load({
    required String userId,
    required ResumoParcelasAnualFilter filter,
    Set<String>? selectedAgentIds,
    AgentQueryExecutionStrategy strategy = AgentQueryExecutionStrategy.mergeAll,
    int? bridgeTimeoutMs,
    int? raceMaxSources,
  }) {
    return AgentQueryListReportAcrossAgentsCoordinator.execute<
      ResumoParcelasAnualFilter,
      ResumoParcelasAnualRow
    >(
      operation: _operation,
      queryKey: AgentQueryKey.resumoParcelasAnual,
      userId: userId,
      filter: filter,
      targetResolver: _targetResolver,
      planBuilder: _planBuilder,
      executor: _executor,
      loadRowsForTarget: _loadResumo.call,
      selectedAgentIds: selectedAgentIds,
      strategy: strategy,
      bridgeTimeoutMs: bridgeTimeoutMs,
      raceMaxSources: raceMaxSources,
    );
  }
}

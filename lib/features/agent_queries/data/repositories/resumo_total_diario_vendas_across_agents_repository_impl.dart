import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/application/orchestration/agent_query_executor.dart';
import 'package:colmeia/features/agent_queries/application/orchestration/agent_query_plan_builder.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_total_diario_vendas_use_case.dart';
import 'package:colmeia/features/agent_queries/data/orchestration/agent_query_target_resolver.dart';
import 'package:colmeia/features/agent_queries/data/repositories/agent_query_list_report_across_agents_coordinator.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_report.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_key.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_diario_vendas_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_diario_vendas_row.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_total_diario_vendas_across_agents_repository.dart';

class ResumoTotalDiarioVendasAcrossAgentsRepositoryImpl
    implements ResumoTotalDiarioVendasAcrossAgentsRepository {
  ResumoTotalDiarioVendasAcrossAgentsRepositoryImpl({
    required AgentQueryTargetResolver targetResolver,
    required AgentQueryPlanBuilder planBuilder,
    required AgentQueryExecutor<ResumoTotalDiarioVendasRow> executor,
    required LoadResumoTotalDiarioVendasUseCase loadResumo,
  }) : _targetResolver = targetResolver,
       _planBuilder = planBuilder,
       _executor = executor,
       _loadResumo = loadResumo;

  final AgentQueryTargetResolver _targetResolver;
  final AgentQueryPlanBuilder _planBuilder;
  final AgentQueryExecutor<ResumoTotalDiarioVendasRow> _executor;
  final LoadResumoTotalDiarioVendasUseCase _loadResumo;

  static const String _operation = 'loadResumoTotalDiarioVendasAcrossAgents';

  @override
  Future<AppResult<AgentQueryExecutionReport<ResumoTotalDiarioVendasRow>>>
  load({
    required String userId,
    required ResumoTotalDiarioVendasFilter filter,
    Set<String>? selectedAgentIds,
    AgentQueryExecutionStrategy strategy = AgentQueryExecutionStrategy.mergeAll,
    int? bridgeTimeoutMs,
    int? raceMaxSources,
  }) {
    return AgentQueryListReportAcrossAgentsCoordinator.execute<
      ResumoTotalDiarioVendasFilter,
      ResumoTotalDiarioVendasRow
    >(
      operation: _operation,
      queryKey: AgentQueryKey.resumoTotalDiarioVendas,
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

import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/application/orchestration/agent_query_executor.dart';
import 'package:colmeia/features/agent_queries/application/orchestration/agent_query_plan_builder.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_parcelas_mensal_use_case.dart';
import 'package:colmeia/features/agent_queries/data/orchestration/agent_query_target_resolver.dart';
import 'package:colmeia/features/agent_queries/data/repositories/agent_query_list_report_across_agents_coordinator.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_report.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_key.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_load_policy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_mensal_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_mensal_row.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_parcelas_mensal_across_agents_repository.dart';

class ResumoParcelasMensalAcrossAgentsRepositoryImpl
    implements ResumoParcelasMensalAcrossAgentsRepository {
  ResumoParcelasMensalAcrossAgentsRepositoryImpl({
    required AgentQueryTargetResolver targetResolver,
    required AgentQueryPlanBuilder planBuilder,
    required AgentQueryExecutor<ResumoParcelasMensalRow> executor,
    required LoadResumoParcelasMensalUseCase loadResumo,
  }) : _targetResolver = targetResolver,
       _planBuilder = planBuilder,
       _executor = executor,
       _loadResumo = loadResumo;

  final AgentQueryTargetResolver _targetResolver;
  final AgentQueryPlanBuilder _planBuilder;
  final AgentQueryExecutor<ResumoParcelasMensalRow> _executor;
  final LoadResumoParcelasMensalUseCase _loadResumo;

  static const String _operation = 'loadResumoParcelasMensalAcrossAgents';

  @override
  Future<AppResult<AgentQueryExecutionReport<ResumoParcelasMensalRow>>> load({
    required String userId,
    required ResumoParcelasMensalFilter filter,
    Set<String>? selectedAgentIds,
    AgentQueryExecutionStrategy strategy = AgentQueryExecutionStrategy.mergeAll,
    int? bridgeTimeoutMs,
    int? raceMaxSources,
    AgentQueryLoadPolicy cachePolicy = AgentQueryLoadPolicy.defaultLoad,
  }) {
    return AgentQueryListReportAcrossAgentsCoordinator.execute<
      ResumoParcelasMensalFilter,
      ResumoParcelasMensalRow
    >(
      operation: _operation,
      queryKey: AgentQueryKey.resumoParcelasMensal,
      userId: userId,
      filter: filter,
      targetResolver: _targetResolver,
      planBuilder: _planBuilder,
      executor: _executor,
      loadRowsForTarget:
          ({
            required userId,
            required agentId,
            required filter,
            clientToken,
            bridgeTimeoutMs,
            hubPresenceOnlineAgentIdsSnapshot,
            hubConnectedFromApprovedCatalogRow,
          }) => _loadResumo.call(
            userId: userId,
            agentId: agentId,
            filter: filter,
            clientToken: clientToken,
            bridgeTimeoutMs: bridgeTimeoutMs,
            hubPresenceOnlineAgentIdsSnapshot:
                hubPresenceOnlineAgentIdsSnapshot,
            hubConnectedFromApprovedCatalogRow:
                hubConnectedFromApprovedCatalogRow,
            cachePolicy: cachePolicy,
          ),
      selectedAgentIds: selectedAgentIds,
      strategy: strategy,
      bridgeTimeoutMs: bridgeTimeoutMs,
      raceMaxSources: raceMaxSources,
    );
  }
}

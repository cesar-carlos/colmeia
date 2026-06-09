import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/application/orchestration/agent_query_executor.dart';
import 'package:colmeia/features/agent_queries/application/orchestration/agent_query_plan_builder.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_total_vendas_municipio_filial_diario_use_case.dart';
import 'package:colmeia/features/agent_queries/data/repositories/agent_query_list_report_across_agents_coordinator.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_report.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_key.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_vendas_municipio_filial_diario_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_vendas_municipio_filial_diario_row.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_query_target_resolver.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_total_vendas_municipio_filial_diario_across_agents_repository.dart';

class ResumoTotalVendasMunicipioFilialDiarioAcrossAgentsRepositoryImpl
    implements ResumoTotalVendasMunicipioFilialDiarioAcrossAgentsRepository {
  ResumoTotalVendasMunicipioFilialDiarioAcrossAgentsRepositoryImpl({
    required AgentQueryTargetResolver targetResolver,
    required AgentQueryPlanBuilder planBuilder,
    required AgentQueryExecutor<ResumoTotalVendasMunicipioFilialDiarioRow>
    executor,
    required LoadResumoTotalVendasMunicipioFilialDiarioUseCase loadResumo,
  }) : _targetResolver = targetResolver,
       _planBuilder = planBuilder,
       _executor = executor,
       _loadResumo = loadResumo;

  final AgentQueryTargetResolver _targetResolver;
  final AgentQueryPlanBuilder _planBuilder;
  final AgentQueryExecutor<ResumoTotalVendasMunicipioFilialDiarioRow> _executor;
  final LoadResumoTotalVendasMunicipioFilialDiarioUseCase _loadResumo;

  static const String _operation =
      'loadResumoTotalVendasMunicipioFilialDiarioAcrossAgents';

  @override
  Future<
    AppResult<
      AgentQueryExecutionReport<ResumoTotalVendasMunicipioFilialDiarioRow>
    >
  >
  load({
    required String userId,
    required ResumoTotalVendasMunicipioFilialDiarioFilter filter,
    Set<String>? selectedAgentIds,
    AgentQueryExecutionStrategy strategy = AgentQueryExecutionStrategy.mergeAll,
    int? bridgeTimeoutMs,
    int? raceMaxSources,
  }) {
    return AgentQueryListReportAcrossAgentsCoordinator.execute<
      ResumoTotalVendasMunicipioFilialDiarioFilter,
      ResumoTotalVendasMunicipioFilialDiarioRow
    >(
      operation: _operation,
      queryKey: AgentQueryKey.resumoTotalVendasMunicipioFilialDiario,
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

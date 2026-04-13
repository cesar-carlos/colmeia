import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/application/orchestration/agent_query_executor.dart';
import 'package:colmeia/features/agent_queries/application/orchestration/agent_query_plan_builder.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_parcelas_forma_pagamento_por_mes_use_case.dart';
import 'package:colmeia/features/agent_queries/data/orchestration/agent_query_target_resolver.dart';
import 'package:colmeia/features/agent_queries/data/repositories/agent_query_list_report_across_agents_coordinator.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_report.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_key.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_forma_pagamento_por_mes_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_forma_pagamento_por_mes_row.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_parcelas_forma_pagamento_por_mes_across_agents_repository.dart';

class ResumoParcelasFormaPagamentoPorMesAcrossAgentsRepositoryImpl
    implements ResumoParcelasFormaPagamentoPorMesAcrossAgentsRepository {
  ResumoParcelasFormaPagamentoPorMesAcrossAgentsRepositoryImpl({
    required AgentQueryTargetResolver targetResolver,
    required AgentQueryPlanBuilder planBuilder,
    required AgentQueryExecutor<ResumoParcelasFormaPagamentoPorMesRow> executor,
    required LoadResumoParcelasFormaPagamentoPorMesUseCase loadResumo,
  }) : _targetResolver = targetResolver,
       _planBuilder = planBuilder,
       _executor = executor,
       _loadResumo = loadResumo;

  final AgentQueryTargetResolver _targetResolver;
  final AgentQueryPlanBuilder _planBuilder;
  final AgentQueryExecutor<ResumoParcelasFormaPagamentoPorMesRow> _executor;
  final LoadResumoParcelasFormaPagamentoPorMesUseCase _loadResumo;

  /// Bridge operation id; keep in sync with the agent command allowlist.
  static const String _operation =
      'loadResumoParcelasFormaPagamentoPorMesAcrossAgents';

  @override
  Future<
    AppResult<AgentQueryExecutionReport<ResumoParcelasFormaPagamentoPorMesRow>>
  >
  load({
    required String userId,
    required ResumoParcelasFormaPagamentoPorMesFilter filter,
    Set<String>? selectedAgentIds,
    AgentQueryExecutionStrategy strategy = AgentQueryExecutionStrategy.mergeAll,
    int? bridgeTimeoutMs,
    int? raceMaxSources,
  }) {
    return AgentQueryListReportAcrossAgentsCoordinator.execute<
      ResumoParcelasFormaPagamentoPorMesFilter,
      ResumoParcelasFormaPagamentoPorMesRow
    >(
      operation: _operation,
      queryKey: AgentQueryKey.resumoParcelasFormaPagamentoPorMes,
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

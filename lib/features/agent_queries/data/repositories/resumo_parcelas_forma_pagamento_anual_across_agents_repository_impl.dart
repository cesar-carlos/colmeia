import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/application/orchestration/agent_query_executor.dart';
import 'package:colmeia/features/agent_queries/application/orchestration/agent_query_plan_builder.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_parcelas_forma_pagamento_anual_use_case.dart';
import 'package:colmeia/features/agent_queries/data/orchestration/agent_query_target_resolver.dart';
import 'package:colmeia/features/agent_queries/data/repositories/agent_query_list_report_across_agents_coordinator.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_report.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_key.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_forma_pagamento_anual_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_forma_pagamento_anual_row.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_parcelas_forma_pagamento_anual_across_agents_repository.dart';

class ResumoParcelasFormaPagamentoAnualAcrossAgentsRepositoryImpl
    implements ResumoParcelasFormaPagamentoAnualAcrossAgentsRepository {
  ResumoParcelasFormaPagamentoAnualAcrossAgentsRepositoryImpl({
    required AgentQueryTargetResolver targetResolver,
    required AgentQueryPlanBuilder planBuilder,
    required AgentQueryExecutor<ResumoParcelasFormaPagamentoAnualRow> executor,
    required LoadResumoParcelasFormaPagamentoAnualUseCase loadResumo,
  }) : _targetResolver = targetResolver,
       _planBuilder = planBuilder,
       _executor = executor,
       _loadResumo = loadResumo;

  final AgentQueryTargetResolver _targetResolver;
  final AgentQueryPlanBuilder _planBuilder;
  final AgentQueryExecutor<ResumoParcelasFormaPagamentoAnualRow> _executor;
  final LoadResumoParcelasFormaPagamentoAnualUseCase _loadResumo;

  static const String _operation =
      'loadResumoParcelasFormaPagamentoAnualAcrossAgents';

  @override
  Future<
    AppResult<AgentQueryExecutionReport<ResumoParcelasFormaPagamentoAnualRow>>
  >
  load({
    required String userId,
    required ResumoParcelasFormaPagamentoAnualFilter filter,
    Set<String>? selectedAgentIds,
    AgentQueryExecutionStrategy strategy = AgentQueryExecutionStrategy.mergeAll,
    int? bridgeTimeoutMs,
    int? raceMaxSources,
  }) {
    return AgentQueryListReportAcrossAgentsCoordinator
        .execute<
            ResumoParcelasFormaPagamentoAnualFilter,
            ResumoParcelasFormaPagamentoAnualRow>(
      operation: _operation,
      queryKey: AgentQueryKey.resumoParcelasFormaPagamentoAnual,
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

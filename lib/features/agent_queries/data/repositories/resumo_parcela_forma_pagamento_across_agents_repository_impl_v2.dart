import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/application/orchestration/agent_query_executor.dart';
import 'package:colmeia/features/agent_queries/application/orchestration/agent_query_plan_builder.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_parcela_forma_pagamento_use_case_v2.dart';
import 'package:colmeia/features/agent_queries/data/repositories/agent_query_list_report_across_agents_coordinator.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_report.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_key.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_forma_pagamento_filter_v2.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_forma_pagamento_row_v2.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_query_target_resolver.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_parcela_forma_pagamento_across_agents_repository_v2.dart';

class ResumoParcelaFormaPagamentoAcrossAgentsRepositoryImplV2
    implements ResumoParcelaFormaPagamentoAcrossAgentsRepositoryV2 {
  ResumoParcelaFormaPagamentoAcrossAgentsRepositoryImplV2({
    required AgentQueryTargetResolver targetResolver,
    required AgentQueryPlanBuilder planBuilder,
    required AgentQueryExecutor<ResumoParcelaFormaPagamentoRowV2> executor,
    required LoadResumoParcelaFormaPagamentoUseCaseV2 loadResumo,
  }) : _targetResolver = targetResolver,
       _planBuilder = planBuilder,
       _executor = executor,
       _loadResumo = loadResumo;

  final AgentQueryTargetResolver _targetResolver;
  final AgentQueryPlanBuilder _planBuilder;
  final AgentQueryExecutor<ResumoParcelaFormaPagamentoRowV2> _executor;
  final LoadResumoParcelaFormaPagamentoUseCaseV2 _loadResumo;

  static const String _operation = 'loadResumoParcelaFormaPagamentoAcrossAgentsV2';

  @override
  Future<AppResult<AgentQueryExecutionReport<ResumoParcelaFormaPagamentoRowV2>>>
  load({
    required String userId,
    required ResumoParcelaFormaPagamentoFilterV2 filter,
    Set<String>? selectedAgentIds,
    AgentQueryExecutionStrategy strategy = AgentQueryExecutionStrategy.mergeAll,
    int? bridgeTimeoutMs,
    int? raceMaxSources,
  }) {
    return AgentQueryListReportAcrossAgentsCoordinator.execute<
      ResumoParcelaFormaPagamentoFilterV2,
      ResumoParcelaFormaPagamentoRowV2
    >(
      operation: _operation,
      queryKey: AgentQueryKey.resumoParcelaFormaPagamentoV2,
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

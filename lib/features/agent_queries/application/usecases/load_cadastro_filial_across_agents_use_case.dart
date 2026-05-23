import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target_resolution.dart';
import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_across_agents_page_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_filter.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/cadastro_filial_across_agents_repository.dart';

class LoadCadastroFilialAcrossAgentsUseCase {
  LoadCadastroFilialAcrossAgentsUseCase(this._repository);

  final CadastroFilialAcrossAgentsRepository _repository;

  Future<AppResult<CadastroFilialAcrossAgentsPageResult>> call({
    required String userId,
    required CadastroFilialFilter filter,
    Set<String>? selectedAgentIds,
    AgentQueryExecutionStrategy strategy = AgentQueryExecutionStrategy.mergeAll,
    int? bridgeTimeoutMs,
    int? raceMaxSources,
    AgentQueryTargetResolution? preResolvedResolution,
    AgentQueriesCancelScope? cancelScope,
    bool orderTargetsOnlineFirst = false,
    bool dedupeTargetsByAgentId = false,
    int? mergeAllConcurrencyOverride,
  }) {
    return _repository.loadPage(
      userId: userId,
      filter: filter,
      selectedAgentIds: selectedAgentIds,
      strategy: strategy,
      bridgeTimeoutMs: bridgeTimeoutMs,
      raceMaxSources: raceMaxSources,
      preResolvedResolution: preResolvedResolution,
      cancelScope: cancelScope,
      orderTargetsOnlineFirst: orderTargetsOnlineFirst,
      dedupeTargetsByAgentId: dedupeTargetsByAgentId,
      mergeAllConcurrencyOverride: mergeAllConcurrencyOverride,
    );
  }

  Future<AppResult<CadastroFilialAcrossAgentsPageResult>> loadAll({
    required String userId,
    required CadastroFilialFilter filter,
    Set<String>? selectedAgentIds,
    AgentQueryExecutionStrategy strategy = AgentQueryExecutionStrategy.mergeAll,
    int? bridgeTimeoutMs,
    int? raceMaxSources,
    AgentQueryTargetResolution? preResolvedResolution,
    AgentQueriesCancelScope? cancelScope,
    bool orderTargetsOnlineFirst = false,
    bool dedupeTargetsByAgentId = false,
    int? mergeAllConcurrencyOverride,
  }) {
    return _repository.loadAll(
      userId: userId,
      filter: filter,
      selectedAgentIds: selectedAgentIds,
      strategy: strategy,
      bridgeTimeoutMs: bridgeTimeoutMs,
      raceMaxSources: raceMaxSources,
      preResolvedResolution: preResolvedResolution,
      cancelScope: cancelScope,
      orderTargetsOnlineFirst: orderTargetsOnlineFirst,
      dedupeTargetsByAgentId: dedupeTargetsByAgentId,
      mergeAllConcurrencyOverride: mergeAllConcurrencyOverride,
    );
  }
}

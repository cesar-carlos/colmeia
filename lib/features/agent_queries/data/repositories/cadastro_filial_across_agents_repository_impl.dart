import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/application/orchestration/agent_query_executor.dart';
import 'package:colmeia/features/agent_queries/application/orchestration/agent_query_plan_builder.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_cadastro_filial_page_use_case.dart';
import 'package:colmeia/features/agent_queries/data/orchestration/agent_query_target_resolver.dart';
import 'package:colmeia/features/agent_queries/data/repositories/agent_query_list_report_across_agents_coordinator.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_key.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_loaded_rows.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target_resolution.dart';
import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_across_agents_page_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_row.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/cadastro_filial_across_agents_repository.dart';
import 'package:result_dart/result_dart.dart';

class CadastroFilialAcrossAgentsRepositoryImpl
    implements CadastroFilialAcrossAgentsRepository {
  CadastroFilialAcrossAgentsRepositoryImpl({
    required AgentQueryTargetResolver targetResolver,
    required AgentQueryPlanBuilder planBuilder,
    required AgentQueryExecutor<CadastroFilialRow> executor,
    required LoadCadastroFilialPageUseCase loadCadastroFilial,
  }) : _targetResolver = targetResolver,
       _planBuilder = planBuilder,
       _executor = executor,
       _loadCadastroFilial = loadCadastroFilial;

  final AgentQueryTargetResolver _targetResolver;
  final AgentQueryPlanBuilder _planBuilder;
  final AgentQueryExecutor<CadastroFilialRow> _executor;
  final LoadCadastroFilialPageUseCase _loadCadastroFilial;

  static const String _operation = 'loadCadastroFilialPageAcrossAgents';
  static const String _loadAllOperation = 'loadCadastroFilialAllAcrossAgents';
  static const int _maxAllPagesPerAgent = 400;

  @override
  Future<AppResult<CadastroFilialAcrossAgentsPageResult>> loadPage({
    required String userId,
    required CadastroFilialFilter filter,
    Set<String>? selectedAgentIds,
    AgentQueryExecutionStrategy strategy = AgentQueryExecutionStrategy.mergeAll,
    int? bridgeTimeoutMs,
    int? raceMaxSources,
    AgentQueryTargetResolution? preResolvedResolution,
  }) {
    return AgentQueryListReportAcrossAgentsCoordinator.executeLoadedMapped<
      CadastroFilialAcrossAgentsPageResult,
      CadastroFilialRow
    >(
      operation: _operation,
      queryKey: AgentQueryKey.cadastroFilial,
      userId: userId,
      targetResolver: _targetResolver,
      planBuilder: _planBuilder,
      executor: _executor,
      selectedAgentIds: selectedAgentIds,
      strategy: strategy,
      bridgeTimeoutMs: bridgeTimeoutMs,
      raceMaxSources: raceMaxSources,
      preResolvedResolution: preResolvedResolution,
      loadRowsForTarget:
          ({
            required target,
            required plan,
            required resolution,
          }) async {
            final result = await _loadCadastroFilial(
              userId: userId,
              agentId: target.agentId,
              filter: filter,
              clientToken: target.clientToken,
              bridgeTimeoutMs: plan.bridgeTimeoutMs,
              hubPresenceOnlineAgentIdsSnapshot:
                  resolution.hubPresenceOnlineAgentIdsSnapshot,
              hubConnectedFromApprovedCatalogRow:
                  target.hubConnectedFromApprovedCatalogRow,
            );
            return result.fold(
              (page) =>
                  Success<AgentQueryLoadedRows<CadastroFilialRow>, AppFailure>(
                    AgentQueryLoadedRows<CadastroFilialRow>(
                      rows: page.items,
                      sourceRowCount: page.totalCount,
                    ),
                  ),
              Failure<AgentQueryLoadedRows<CadastroFilialRow>, AppFailure>.new,
            );
          },
      mapReport: CadastroFilialAcrossAgentsPageResult.fromReport,
    );
  }

  @override
  Future<AppResult<CadastroFilialAcrossAgentsPageResult>> loadAll({
    required String userId,
    required CadastroFilialFilter filter,
    Set<String>? selectedAgentIds,
    AgentQueryExecutionStrategy strategy = AgentQueryExecutionStrategy.mergeAll,
    int? bridgeTimeoutMs,
    int? raceMaxSources,
    AgentQueryTargetResolution? preResolvedResolution,
  }) {
    return AgentQueryListReportAcrossAgentsCoordinator.executeLoadedMapped<
      CadastroFilialAcrossAgentsPageResult,
      CadastroFilialRow
    >(
      operation: _loadAllOperation,
      queryKey: AgentQueryKey.cadastroFilial,
      userId: userId,
      targetResolver: _targetResolver,
      planBuilder: _planBuilder,
      executor: _executor,
      selectedAgentIds: selectedAgentIds,
      strategy: strategy,
      bridgeTimeoutMs: bridgeTimeoutMs,
      raceMaxSources: raceMaxSources,
      preResolvedResolution: preResolvedResolution,
      loadRowsForTarget:
          ({
            required target,
            required plan,
            required resolution,
          }) {
            return _loadAllRowsForTarget(
              userId: userId,
              agentId: target.agentId,
              filter: filter,
              clientToken: target.clientToken,
              bridgeTimeoutMs: plan.bridgeTimeoutMs,
              hubPresenceOnlineAgentIdsSnapshot:
                  resolution.hubPresenceOnlineAgentIdsSnapshot,
              hubConnectedFromApprovedCatalogRow:
                  target.hubConnectedFromApprovedCatalogRow,
            );
          },
      mapReport: CadastroFilialAcrossAgentsPageResult.fromReport,
    );
  }

  Future<AppResult<AgentQueryLoadedRows<CadastroFilialRow>>>
  _loadAllRowsForTarget({
    required String userId,
    required String agentId,
    required CadastroFilialFilter filter,
    String? clientToken,
    int? bridgeTimeoutMs,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
  }) async {
    final rows = <CadastroFilialRow>[];
    var page = 1;
    int? totalCount;

    while (page <= _maxAllPagesPerAgent) {
      final pageFilter = filter.copyWith(
        page: page,
        pageSize: CadastroFilialFilter.maxPageSize,
      );
      final result = await _loadCadastroFilial(
        userId: userId,
        agentId: agentId,
        filter: pageFilter,
        clientToken: clientToken,
        bridgeTimeoutMs: bridgeTimeoutMs,
        hubPresenceOnlineAgentIdsSnapshot: hubPresenceOnlineAgentIdsSnapshot,
        hubConnectedFromApprovedCatalogRow: hubConnectedFromApprovedCatalogRow,
      );
      final loaded = result.getOrNull();
      if (loaded == null) {
        return Failure<AgentQueryLoadedRows<CadastroFilialRow>, AppFailure>(
          result.exceptionOrNull()!,
        );
      }

      totalCount ??= loaded.totalCount;
      rows.addAll(loaded.items);

      if (loaded.items.isEmpty) {
        break;
      }

      if (rows.length >= loaded.totalCount ||
          loaded.items.length < CadastroFilialFilter.maxPageSize) {
        break;
      }
      page += 1;
    }

    return Success<AgentQueryLoadedRows<CadastroFilialRow>, AppFailure>(
      AgentQueryLoadedRows<CadastroFilialRow>(
        rows: rows,
        sourceRowCount: totalCount ?? rows.length,
      ),
    );
  }
}

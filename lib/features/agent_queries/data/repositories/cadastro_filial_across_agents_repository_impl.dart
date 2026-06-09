import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/agent_queries/application/orchestration/agent_query_executor.dart';
import 'package:colmeia/features/agent_queries/application/orchestration/agent_query_plan_builder.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_cadastro_filial_page_use_case.dart';
import 'package:colmeia/features/agent_queries/data/repositories/agent_query_list_report_across_agents_coordinator.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_key.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_loaded_rows.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target_resolution.dart';
import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_across_agents_page_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_row.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_query_target_resolver.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/cadastro_filial_across_agents_repository.dart';
import 'package:result_dart/result_dart.dart';

class CadastroFilialAcrossAgentsRepositoryImpl
    implements CadastroFilialAcrossAgentsRepository {
  CadastroFilialAcrossAgentsRepositoryImpl({
    required AgentQueryTargetResolver targetResolver,
    required AgentQueryPlanBuilder planBuilder,
    required AgentQueryExecutor<CadastroFilialRow> executor,
    required LoadCadastroFilialPageUseCase loadCadastroFilial,
    DateTime Function()? now,
  }) : _targetResolver = targetResolver,
       _planBuilder = planBuilder,
       _executor = executor,
       _loadCadastroFilial = loadCadastroFilial,
       _now = now;

  final AgentQueryTargetResolver _targetResolver;
  final AgentQueryPlanBuilder _planBuilder;
  final AgentQueryExecutor<CadastroFilialRow> _executor;
  final LoadCadastroFilialPageUseCase _loadCadastroFilial;
  final DateTime Function()? _now;

  static const String _operation = 'loadCadastroFilialPageAcrossAgents';
  static const String _loadAllOperation = 'loadCadastroFilialAllAcrossAgents';
  static const int _maxAllPagesPerAgent = 400;
  static const Duration _paginationStallWarningDebounce = Duration(
    minutes: 15,
  );

  final Map<String, DateTime> _lastPaginationStallWarningAtByKey =
      <String, DateTime>{};

  @override
  Future<AppResult<CadastroFilialAcrossAgentsPageResult>> loadPage({
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
      orderPlannedTargetsOnlineFirst: orderTargetsOnlineFirst,
      dedupePlannedTargetsByAgentId: dedupeTargetsByAgentId,
      mergeAllConcurrencyOverride: mergeAllConcurrencyOverride,
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
              cancelScope: cancelScope,
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
    AgentQueriesCancelScope? cancelScope,
    bool orderTargetsOnlineFirst = false,
    bool dedupeTargetsByAgentId = false,
    int? mergeAllConcurrencyOverride,
  }) {
    final paginationStalledAgentIds = <String>{};
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
      orderPlannedTargetsOnlineFirst: orderTargetsOnlineFirst,
      dedupePlannedTargetsByAgentId: dedupeTargetsByAgentId,
      mergeAllConcurrencyOverride: mergeAllConcurrencyOverride,
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
              onPaginationStalled: () {
                paginationStalledAgentIds.add(target.agentId);
              },
              clientToken: target.clientToken,
              bridgeTimeoutMs: plan.bridgeTimeoutMs,
              hubPresenceOnlineAgentIdsSnapshot:
                  resolution.hubPresenceOnlineAgentIdsSnapshot,
              hubConnectedFromApprovedCatalogRow:
                  target.hubConnectedFromApprovedCatalogRow,
              cancelScope: cancelScope,
            );
          },
      mapReport: (report) => CadastroFilialAcrossAgentsPageResult.fromReport(
        report,
        paginationStalledAgentIds: paginationStalledAgentIds,
      ),
    );
  }

  Future<AppResult<AgentQueryLoadedRows<CadastroFilialRow>>>
  _loadAllRowsForTarget({
    required String userId,
    required String agentId,
    required CadastroFilialFilter filter,
    required void Function() onPaginationStalled,
    String? clientToken,
    int? bridgeTimeoutMs,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
    AgentQueriesCancelScope? cancelScope,
  }) async {
    // Catalog spike (PR4): Option A (single unbounded SQL) is not used here
    // because the hub still enforces `max_rows`. Option C (parallel pages)
    // adds bridge concurrency risk. We use Option B: raise page chunk size
    // (see `CadastroFilialFilter.maxPageSize` + `cadastroFilialPage`) so each
    // agent needs fewer sequential `loadCadastroFilialPage` calls for `loadAll`.
    final rows = <CadastroFilialRow>[];
    final seenRowKeys = <String>{};
    var page = 1;
    int? totalCount;
    var paginationStalled = false;

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
        cancelScope: cancelScope,
      );
      final loaded = result.getOrNull();
      if (loaded == null) {
        return Failure<AgentQueryLoadedRows<CadastroFilialRow>, AppFailure>(
          result.exceptionOrNull()!,
        );
      }

      totalCount ??= loaded.totalCount;
      var newRowCount = 0;
      for (final row in loaded.items) {
        if (!seenRowKeys.add(_rowKey(row.codEmpresa, row.codFilial))) {
          continue;
        }
        rows.add(row);
        newRowCount += 1;
      }

      if (loaded.items.isEmpty) {
        break;
      }

      if (newRowCount == 0) {
        paginationStalled = true;
        onPaginationStalled();
        _logPaginationStalled(
          agentId: agentId,
          filter: filter,
          page: page,
          pageRowCount: loaded.items.length,
          loadedUniqueRowCount: rows.length,
          reportedTotalCount: loaded.totalCount,
        );
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
        sourceRowCount: paginationStalled
            ? rows.length
            : totalCount ?? rows.length,
      ),
    );
  }

  String _rowKey(int codEmpresa, int codFilial) {
    return '$codEmpresa:$codFilial';
  }

  void _logPaginationStalled({
    required String agentId,
    required CadastroFilialFilter filter,
    required int page,
    required int pageRowCount,
    required int loadedUniqueRowCount,
    required int reportedTotalCount,
  }) {
    final normalizedAgentId = agentId.trim();
    final warningKey = '$normalizedAgentId|${filter.filterScopeSignature}';
    final now = _resolveNow();
    final lastWarningAt = _lastPaginationStallWarningAtByKey[warningKey];
    if (lastWarningAt != null &&
        now.difference(lastWarningAt) < _paginationStallWarningDebounce) {
      return;
    }
    _lastPaginationStallWarningAtByKey[warningKey] = now;
    AppLogger.warning(
      'Cadastro filial pagination stalled without new rows',
      context: <String, Object?>{
        'operation': _loadAllOperation,
        'agentId': normalizedAgentId,
        'filterScopeSignature': filter.filterScopeSignature,
        'page': page,
        'pageRowCount': pageRowCount,
        'loadedUniqueRowCount': loadedUniqueRowCount,
        'reportedTotalCount': reportedTotalCount,
      },
    );
  }

  DateTime _resolveNow() => _now?.call() ?? DateTime.now();
}

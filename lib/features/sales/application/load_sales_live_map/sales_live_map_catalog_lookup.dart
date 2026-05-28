import 'dart:async';

import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_cadastro_filial_across_agents_use_case.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_participant.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_report.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target_resolution.dart';
import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_across_agents_page_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_filter.dart'
    show CadastroFilialBranchRef;
import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_row.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_branch_keys.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_in_memory_catalog_cache.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_load_cancel_token.dart';
import 'package:colmeia/features/sales/application/ports/sales_live_map_catalog_cache.dart';
import 'package:colmeia/features/sales/application/sales_live_map_catalog_scope.dart';
import 'package:colmeia/features/sales/application/sales_live_map_refresh_metrics.dart'
    show SalesLiveMapCatalogSource;

/// Outcome of a cached branch catalog lookup. Carries both the cached
/// page and the source it came from so the use case can record the right
/// label in refresh metrics.
class SalesLiveMapCatalogLookupResult {
  const SalesLiveMapCatalogLookupResult({
    required this.page,
    required this.source,
  });

  final CadastroFilialAcrossAgentsPageResult page;
  final SalesLiveMapCatalogSource source;
}

/// Orchestrates branch catalog reads across the in-memory cache, the
/// disk cache and the remote SQL bridge.
///
/// Encapsulates the cascading lookup that previously lived inline in
/// `LoadSalesLiveMapUseCase`:
///
///  1. exact in-memory hit -> [SalesLiveMapCatalogSource.memory];
///  2. exact disk hit -> [SalesLiveMapCatalogSource.disk] (and hydrates
///     the in-memory cache);
///  3. broader fullAgent in-memory / disk hit narrowed down to the
///     branchSubset -> [SalesLiveMapCatalogSource.broaderCacheFiltered];
///  4. remote load via [LoadCadastroFilialAcrossAgentsUseCase]
///     -> [SalesLiveMapCatalogSource.remote] (and writes through to
///     both caches).
///
/// The broader-cache narrowing filters not just participants but also
/// `plannedTargets`, `missingClientTokenTargets`,
/// `skippedDueToHubPresenceTargets` and `paginationStalledAgentIds` to
/// the subset of agents owning the requested branches — otherwise
/// downstream metrics would inherit the wider scope's counters.
class SalesLiveMapCatalogLookup {
  const SalesLiveMapCatalogLookup({
    required SalesLiveMapInMemoryCatalogCache memoryCache,
    required SalesLiveMapCatalogCache diskCache,
    required LoadCadastroFilialAcrossAgentsUseCase loadCadastroAcrossAgents,
  }) : _memoryCache = memoryCache,
       _diskCache = diskCache,
       _loadCadastroAcrossAgents = loadCadastroAcrossAgents;

  final SalesLiveMapInMemoryCatalogCache _memoryCache;
  final SalesLiveMapCatalogCache _diskCache;
  final LoadCadastroFilialAcrossAgentsUseCase _loadCadastroAcrossAgents;

  /// Looks up the branch catalog purely from the local caches (memory +
  /// disk + broader-cache narrowing). Returns `null` when nothing usable
  /// is cached and the caller should fall back to [loadRemote].
  SalesLiveMapCatalogLookupResult? lookupCached({
    required String userId,
    required SalesLiveMapCatalogScope scope,
    required DateTime now,
  }) {
    final exactMemory = _memoryCache.read(
      userId: userId,
      scope: scope,
      now: now,
    );
    if (exactMemory != null) {
      return SalesLiveMapCatalogLookupResult(
        page: exactMemory,
        source: SalesLiveMapCatalogSource.memory,
      );
    }

    final exactDisk = _diskCache.readIfFresh(
      userId: userId,
      scope: scope,
      now: now,
    );
    if (exactDisk != null) {
      _memoryCache.write(
        userId: userId,
        scope: scope,
        now: now,
        result: exactDisk,
      );
      return SalesLiveMapCatalogLookupResult(
        page: exactDisk,
        source: SalesLiveMapCatalogSource.disk,
      );
    }

    if (!scope.isBranchSubset) {
      return null;
    }

    final broaderScope = scope.compatibleFullAgentScope;
    final broaderMemory = _memoryCache.read(
      userId: userId,
      scope: broaderScope,
      now: now,
    );
    if (broaderMemory != null) {
      final filtered = _filterCatalogBySelectedBranches(
        broaderMemory,
        scope.selectedBranches,
      );
      _memoryCache.write(
        userId: userId,
        scope: scope,
        now: now,
        result: filtered,
      );
      return SalesLiveMapCatalogLookupResult(
        page: filtered,
        source: SalesLiveMapCatalogSource.broaderCacheFiltered,
      );
    }

    final broaderDisk = _diskCache.readIfFresh(
      userId: userId,
      scope: broaderScope,
      now: now,
    );
    if (broaderDisk == null) {
      return null;
    }
    _memoryCache.write(
      userId: userId,
      scope: broaderScope,
      now: now,
      result: broaderDisk,
    );
    final filtered = _filterCatalogBySelectedBranches(
      broaderDisk,
      scope.selectedBranches,
    );
    _memoryCache.write(
      userId: userId,
      scope: scope,
      now: now,
      result: filtered,
    );
    return SalesLiveMapCatalogLookupResult(
      page: filtered,
      source: SalesLiveMapCatalogSource.broaderCacheFiltered,
    );
  }

  /// Loads the branch catalog from the remote SQL bridge and, on success,
  /// hydrates both the in-memory and disk caches under [scope].
  Future<AppResult<CadastroFilialAcrossAgentsPageResult>> loadRemote({
    required String userId,
    required SalesLiveMapCatalogScope scope,
    required DateTime now,
    required AgentQueryTargetResolution preResolvedResolution,
    required int bridgeTimeoutMs,
    required int mergeAllConcurrencyOverride,
    SalesLiveMapLoadCancelToken? cancelToken,
  }) async {
    final result = await _loadCadastroAcrossAgents.loadAll(
      userId: userId,
      filter: scope.toCatalogFilter(),
      selectedAgentIds: scope.selectedAgentIds,
      bridgeTimeoutMs: bridgeTimeoutMs,
      preResolvedResolution: preResolvedResolution,
      cancelScope: cancelToken?.sqlCancelScope,
      orderTargetsOnlineFirst: true,
      dedupeTargetsByAgentId: true,
      mergeAllConcurrencyOverride: mergeAllConcurrencyOverride,
    );
    final page = result.getOrNull();
    if (page != null) {
      _memoryCache.write(
        userId: userId,
        scope: scope,
        now: now,
        result: page,
      );
      unawaited(
        _diskCache.write(
          userId: userId,
          scope: scope,
          now: now,
          result: page,
        ),
      );
    }
    return result;
  }

  CadastroFilialAcrossAgentsPageResult _filterCatalogBySelectedBranches(
    CadastroFilialAcrossAgentsPageResult result,
    Iterable<CadastroFilialBranchRef> selectedBranches,
  ) {
    if (selectedBranches.isEmpty) {
      return result;
    }

    final allowedBranchKeys = selectedBranches
        .map(
          (branch) => SalesLiveMapBranchKeys.of(
            agentId: branch.normalizedAgentId,
            codEmpresa: branch.codEmpresa,
            codFilial: branch.codFilial,
          ),
        )
        .toSet();
    final allowedAgentIds = selectedBranches
        .map((branch) => branch.normalizedAgentId)
        .toSet();
    final participants = result.report.participants
        .where((participant) => allowedAgentIds.contains(participant.agentId))
        .map((participant) {
          if (!participant.isSuccess) {
            return participant;
          }
          final filteredRows = participant.rows
              .where(
                (row) => allowedBranchKeys.contains(
                  SalesLiveMapBranchKeys.of(
                    agentId: participant.agentId,
                    codEmpresa: row.codEmpresa,
                    codFilial: row.codFilial,
                  ),
                ),
              )
              .toList(growable: false);
          if (filteredRows.length == participant.rows.length &&
              participant.sourceRowCount == filteredRows.length) {
            return participant;
          }
          return AgentQueryExecutionParticipant<CadastroFilialRow>(
            agentId: participant.agentId,
            displayName: participant.displayName,
            rows: filteredRows,
            elapsedMs: participant.elapsedMs,
            sourceRowCount: filteredRows.length,
            failure: participant.failure,
            wasDiscardedByRace: participant.wasDiscardedByRace,
          );
        })
        .toList(growable: false);
    final filteredPlannedTargets = result.report.plannedTargets
        .where((target) => allowedAgentIds.contains(target.agentId))
        .toList(growable: false);
    final filteredMissingClientTokenTargets = result
        .report
        .missingClientTokenTargets
        .where((target) => allowedAgentIds.contains(target.agentId))
        .toList(growable: false);
    final filteredSkippedDueToHubPresenceTargets = result
        .report
        .skippedDueToHubPresenceTargets
        .where((target) => allowedAgentIds.contains(target.agentId))
        .toList(growable: false);
    final report = AgentQueryExecutionReport<CadastroFilialRow>(
      queryKey: result.report.queryKey,
      strategy: result.report.strategy,
      consideredApprovedAgentCount: filteredPlannedTargets.length,
      plannedTargets: filteredPlannedTargets,
      missingClientTokenTargets: filteredMissingClientTokenTargets,
      participants: participants,
      winnerAgentId: allowedAgentIds.contains(result.report.winnerAgentId)
          ? result.report.winnerAgentId
          : null,
      totalElapsedMs: result.report.totalElapsedMs,
      skippedDueToHubPresenceTargets: filteredSkippedDueToHubPresenceTargets,
    );
    return CadastroFilialAcrossAgentsPageResult.fromReport(
      report,
      paginationStalledAgentIds: result.paginationStalledAgentIds
          .where(allowedAgentIds.contains)
          .toSet(),
    );
  }
}

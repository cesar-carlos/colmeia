import 'package:colmeia/features/sales/application/load_sales_live_map_use_case.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_branch_ref.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_filter.dart';
import 'package:colmeia/shared/filters/dashboard_filter.dart';

/// Pure helpers used by `SalesLiveMapController` to keep its filter slice
/// internally consistent.
///
/// All methods are stateless â€” the controller owns lifecycle and triggers
/// `setState` / reload; this class only encapsulates the rules that decide
/// "given the current data, what does the next [SalesLiveMapFilter] look
/// like?". Extracted from the controller so the rules can be unit-tested
/// without spinning up the full controller graph.
abstract final class SalesLiveMapFilterNormalizer {
  /// Drops a previously persisted branch selection when restoring a filter
  /// from disk. The available branches may have changed since last session
  /// (catalog rotated, agent removed), so the safest behaviour is to clear
  /// the selection on first paint and let the user re-pick if needed.
  static SalesLiveMapFilter normalizeRestoredFilter(
    SalesLiveMapFilter filter,
  ) {
    if (filter.selectedBranchIds == null && filter.selectedAgentIds == null) {
      return filter;
    }
    return filter.copyWith(selectedAgentIds: null, selectedBranchIds: null);
  }

  /// Ensures `selectedAgentIds` is in sync with `selectedBranchIds`:
  ///
  /// - When the branch selection is null/empty, drops `selectedAgentIds`
  ///   so the next load runs against all branches the agent surfaces;
  /// - Otherwise looks up the agents owning the selected branches via
  ///   [SalesLiveMapLoadResult.agentIdsByBranchRef] and rewrites
  ///   `selectedAgentIds` to that subset â€” preserves the invariant that
  ///   the agent scope of an SQL call always covers every selected branch.
  static SalesLiveMapFilter normalizeForSelectedBranches({
    required SalesLiveMapFilter filter,
    required SalesLiveMapLoadResult? result,
  }) {
    final selectedBranchIds = filter.selectedBranchIds;
    if (selectedBranchIds == null || selectedBranchIds.isEmpty) {
      return filter.copyWith(selectedAgentIds: null);
    }

    final branchOptions =
        result?.branchOptions ?? const <SalesLiveMapBranchOption>[];
    if (branchOptions.isEmpty) {
      return filter;
    }
    final agentIndex =
        result?.agentIdsByBranchRef ?? <SalesLiveMapBranchRef, String>{};
    final selectedAgents = <String>{
      for (final branchRef in selectedBranchIds) ?agentIndex[branchRef],
    };
    if (selectedAgents.isEmpty) {
      return filter.copyWith(selectedAgentIds: null, selectedBranchIds: null);
    }

    return filter.copyWith(
      selectedAgentIds: Set<String>.unmodifiable(selectedAgents),
    );
  }

  /// Reconciles an explicit agent selection against the current approved list.
  ///
  /// Returns `null` when there is no explicit selection (query all approved
  /// agents and let the agent-query plan apply token/presence gates, same as
  /// overview home). Does **not** materialize token-backed ids into an
  /// explicit set â€” that would shrink the agent query target resolver and catalog
  /// scope to a subset while the UI still reads as "all".
  static Set<String>? normalizeSelectedAgentIds({
    required List<DashboardAgentOption> agents,
    required Set<String>? selectedAgentIds,
  }) {
    final tokenBacked = agents.tokenBackedAgentIds();
    if (selectedAgentIds == null) {
      return null;
    }

    final reconciled = selectedAgentIds.where(tokenBacked.contains).toSet();
    if (reconciled.isEmpty) {
      return tokenBacked.isEmpty ? null : Set<String>.unmodifiable(tokenBacked);
    }
    if (reconciled.length == tokenBacked.length) {
      return tokenBacked.length == agents.length
          ? null
          : Set<String>.unmodifiable(reconciled);
    }
    return Set<String>.unmodifiable(reconciled);
  }
}

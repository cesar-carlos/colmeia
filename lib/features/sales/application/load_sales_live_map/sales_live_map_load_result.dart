import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_load_failure_reason.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_location_diagnostics.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_branch_ref.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_filter.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_point.dart';

/// Identity-keyed cache for [SalesLiveMapLoadResult.agentIdsByBranchRef].
/// Lets the index be computed on demand without breaking the existing
/// `const` constructor and is reclaimed with the owning result.
final Expando<Map<SalesLiveMapBranchRef, String>>
_agentIdsByBranchRefExpando =
    Expando<Map<SalesLiveMapBranchRef, String>>(
      'SalesLiveMapLoadResult.agentIdsByBranchRef',
    );

/// Result returned by `LoadSalesLiveMapUseCase` after a full or progressive
/// run. Captures the rendered points, branch/agent counts, diagnostics for
/// logging, and whether the run was cancelled or partially failed.
class SalesLiveMapLoadResult {
  const SalesLiveMapLoadResult({
    required this.points,
    required this.branchOptions,
    required this.totalRevenue,
    required this.totalSalesCount,
    required this.totalBranchCount,
    required this.mappedBranchCount,
    required this.mappedMunicipalityCount,
    required this.queriedAgentCount,
    required this.plannedAgentCount,
    required this.failedAgentCount,
    required this.missingClientTokenAgentCount,
    required this.skippedOfflineAgentCount,
    required this.rowCapReachedAgentCount,
    required this.refreshedAt,
    this.paginationStalledAgentCount = 0,
    this.salesAgentCount = 0,
    this.catalogBranchCount = 0,
    this.salesBranchCount = 0,
    this.zeroedBranchCount = 0,
    this.noSalesBranchCount = 0,
    this.salesUnavailableBranchCount = 0,
    this.salesDataPending = false,
    this.salesPendingBranchCount = 0,
    this.failedCatalogAgentCount = 0,
    this.failedSalesAgentCount = 0,
    this.noSalesAgentOptions = const <SalesLiveMapAgentOption>[],
    this.failedAgentOptions = const <SalesLiveMapAgentOption>[],
    this.missingClientTokenAgentOptions = const <SalesLiveMapAgentOption>[],
    this.skippedOfflineAgentOptions = const <SalesLiveMapAgentOption>[],
    this.unmappedBranchOptions = const <SalesLiveMapBranchOption>[],
    this.locationDiagnostics = const SalesLiveMapLocationDiagnostics(),
    this.loadFailed = false,
    this.loadFailureReason,
    this.loadFailure,
    this.loadFailureMessage,
    this.cancelled = false,
    this.partialGeoReuseCount = 0,
    this.hubPresenceOnlineAgentIdsSnapshot,
    this.agentQueryFailures = const <AppFailure>[],
  });

  final List<SalesLiveMapPoint> points;
  final List<SalesLiveMapBranchOption> branchOptions;
  final List<SalesLiveMapBranchOption> unmappedBranchOptions;
  final double totalRevenue;
  final int totalSalesCount;
  final int totalBranchCount;
  final int mappedBranchCount;
  final int mappedMunicipalityCount;
  final int queriedAgentCount;
  final int plannedAgentCount;
  final int failedAgentCount;
  final int missingClientTokenAgentCount;
  final int skippedOfflineAgentCount;
  final int rowCapReachedAgentCount;
  final int paginationStalledAgentCount;
  final int salesAgentCount;
  final int catalogBranchCount;
  final int salesBranchCount;
  final int zeroedBranchCount;
  final int noSalesBranchCount;
  final int salesUnavailableBranchCount;
  final bool salesDataPending;
  final int salesPendingBranchCount;
  final int failedCatalogAgentCount;
  final int failedSalesAgentCount;
  final List<SalesLiveMapAgentOption> noSalesAgentOptions;
  final List<SalesLiveMapAgentOption> failedAgentOptions;
  final List<SalesLiveMapAgentOption> missingClientTokenAgentOptions;
  final List<SalesLiveMapAgentOption> skippedOfflineAgentOptions;
  final SalesLiveMapLocationDiagnostics locationDiagnostics;
  final bool loadFailed;
  final SalesLiveMapLoadFailureReason? loadFailureReason;
  final AppFailure? loadFailure;
  final String? loadFailureMessage;
  final DateTime? refreshedAt;
  final bool cancelled;
  final int partialGeoReuseCount;

  /// Hub `/client/me/agents` online ids captured at target resolution time.
  ///
  /// `null` when presence was not loaded — UI must treat connection as unknown.
  final Set<String>? hubPresenceOnlineAgentIdsSnapshot;

  /// Per-agent SQL failures from catalog/sales reports (for retry-after arming).
  final List<AppFailure> agentQueryFailures;

  bool get hasPartialIssue =>
      failedAgentCount > 0 ||
      missingClientTokenAgentCount > 0 ||
      skippedOfflineAgentCount > 0 ||
      rowCapReachedAgentCount > 0 ||
      paginationStalledAgentCount > 0 ||
      failedCatalogAgentCount > 0 ||
      failedSalesAgentCount > 0 ||
      noSalesAgentOptions.isNotEmpty ||
      unmappedBranchOptions.isNotEmpty ||
      mappedBranchCount < totalBranchCount;

  /// Which [hasPartialIssue] predicates are true (stable keys for logs / E2E).
  Map<String, bool> get partialIssueFlagBreakdown => <String, bool>{
    'failedAgentCount': failedAgentCount > 0,
    'missingClientTokenAgentCount': missingClientTokenAgentCount > 0,
    'skippedOfflineAgentCount': skippedOfflineAgentCount > 0,
    'rowCapReachedAgentCount': rowCapReachedAgentCount > 0,
    'paginationStalledAgentCount': paginationStalledAgentCount > 0,
    'failedCatalogAgentCount': failedCatalogAgentCount > 0,
    'failedSalesAgentCount': failedSalesAgentCount > 0,
    'noSalesAgentOptions': noSalesAgentOptions.isNotEmpty,
    'unmappedBranchOptions': unmappedBranchOptions.isNotEmpty,
    'mappedBranchCountBelowTotal': mappedBranchCount < totalBranchCount,
  };

  List<String> get partialIssueActiveKeys => partialIssueFlagBreakdown.entries
      .where((e) => e.value)
      .map((e) => e.key)
      .toList(growable: false);

  /// Lookup map from each [SalesLiveMapBranchRef] to the agent id that
  /// owns it. Computed lazily from [branchOptions] on first access and
  /// memoized for the rest of this result's lifetime.
  ///
  /// Consumers can use this to avoid O(n·m) scans when reconciling a
  /// branch selection against the agents that should be queried (e.g.
  /// `SalesLiveMapFilterNormalizer.normalizeForSelectedBranches`).
  Map<SalesLiveMapBranchRef, String> get agentIdsByBranchRef {
    final cached = _agentIdsByBranchRefExpando[this];
    if (cached != null) {
      return cached;
    }
    final computed = <SalesLiveMapBranchRef, String>{
      for (final branch in branchOptions) branch.branchRef: branch.agentId,
    };
    final indexed = Map<SalesLiveMapBranchRef, String>.unmodifiable(computed);
    _agentIdsByBranchRefExpando[this] = indexed;
    return indexed;
  }
}

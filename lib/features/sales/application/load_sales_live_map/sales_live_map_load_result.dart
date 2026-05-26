import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_load_failure_reason.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_location_diagnostics.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_filter.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_point.dart';

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
    this.unmappedBranchOptions = const <SalesLiveMapBranchOption>[],
    this.locationDiagnostics = const SalesLiveMapLocationDiagnostics(),
    this.loadFailed = false,
    this.loadFailureReason,
    this.loadFailureMessage,
    this.cancelled = false,
    this.partialGeoReuseCount = 0,
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
  final SalesLiveMapLocationDiagnostics locationDiagnostics;
  final bool loadFailed;
  final SalesLiveMapLoadFailureReason? loadFailureReason;
  final String? loadFailureMessage;
  final DateTime? refreshedAt;
  final bool cancelled;
  final int partialGeoReuseCount;

  bool get hasPartialIssue =>
      failedAgentCount > 0 ||
      missingClientTokenAgentCount > 0 ||
      skippedOfflineAgentCount > 0 ||
      rowCapReachedAgentCount > 0 ||
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
}

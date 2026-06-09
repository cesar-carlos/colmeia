import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_load_failure_reason.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_load_result.dart';
import 'package:flutter/foundation.dart';

/// Value snapshot of load-result fields that drive live-map presentation
/// outside the map point payload (KPIs, subtitles, attention panel, load
/// errors). Selector slices compare this fingerprint so progressive operational
/// updates rebuild even when the map digest stays stable.
@immutable
class SalesLiveMapOperationalFingerprint {
  factory SalesLiveMapOperationalFingerprint.from(
    SalesLiveMapLoadResult? result,
  ) {
    if (result == null) {
      return empty;
    }
    return SalesLiveMapOperationalFingerprint._(
      salesDataPending: result.salesDataPending,
      loadFailed: result.loadFailed,
      hasPartialIssue: result.hasPartialIssue,
      failedAgentCount: result.failedAgentCount,
      queriedAgentCount: result.queriedAgentCount,
      plannedAgentCount: result.plannedAgentCount,
      totalRevenue: result.totalRevenue,
      totalSalesCount: result.totalSalesCount,
      totalBranchCount: result.totalBranchCount,
      mappedBranchCount: result.mappedBranchCount,
      refreshedAt: result.refreshedAt,
      loadFailureIdentity: identityHashCode(result.loadFailure),
      loadFailureReason: result.loadFailureReason,
      loadFailureMessage: result.loadFailureMessage,
      missingClientTokenAgentCount: result.missingClientTokenAgentCount,
      skippedOfflineAgentCount: result.skippedOfflineAgentCount,
      rowCapReachedAgentCount: result.rowCapReachedAgentCount,
      paginationStalledAgentCount: result.paginationStalledAgentCount,
      noSalesAgentOptionCount: result.noSalesAgentOptions.length,
      noSalesBranchCount: result.noSalesBranchCount,
      salesUnavailableBranchCount: result.salesUnavailableBranchCount,
    );
  }

  const SalesLiveMapOperationalFingerprint._({
    required this.salesDataPending,
    required this.loadFailed,
    required this.hasPartialIssue,
    required this.failedAgentCount,
    required this.queriedAgentCount,
    required this.plannedAgentCount,
    required this.totalRevenue,
    required this.totalSalesCount,
    required this.totalBranchCount,
    required this.mappedBranchCount,
    required this.refreshedAt,
    required this.loadFailureIdentity,
    required this.loadFailureReason,
    required this.loadFailureMessage,
    required this.missingClientTokenAgentCount,
    required this.skippedOfflineAgentCount,
    required this.rowCapReachedAgentCount,
    required this.paginationStalledAgentCount,
    required this.noSalesAgentOptionCount,
    required this.noSalesBranchCount,
    required this.salesUnavailableBranchCount,
  });

  static const SalesLiveMapOperationalFingerprint empty =
      SalesLiveMapOperationalFingerprint._(
        salesDataPending: false,
        loadFailed: false,
        hasPartialIssue: false,
        failedAgentCount: 0,
        queriedAgentCount: 0,
        plannedAgentCount: 0,
        totalRevenue: 0,
        totalSalesCount: 0,
        totalBranchCount: 0,
        mappedBranchCount: 0,
        refreshedAt: null,
        loadFailureIdentity: 0,
        loadFailureReason: null,
        loadFailureMessage: null,
        missingClientTokenAgentCount: 0,
        skippedOfflineAgentCount: 0,
        rowCapReachedAgentCount: 0,
        paginationStalledAgentCount: 0,
        noSalesAgentOptionCount: 0,
        noSalesBranchCount: 0,
        salesUnavailableBranchCount: 0,
      );

  final bool salesDataPending;
  final bool loadFailed;
  final bool hasPartialIssue;
  final int failedAgentCount;
  final int queriedAgentCount;
  final int plannedAgentCount;
  final double totalRevenue;
  final int totalSalesCount;
  final int totalBranchCount;
  final int mappedBranchCount;
  final DateTime? refreshedAt;
  final int loadFailureIdentity;
  final SalesLiveMapLoadFailureReason? loadFailureReason;
  final String? loadFailureMessage;
  final int missingClientTokenAgentCount;
  final int skippedOfflineAgentCount;
  final int rowCapReachedAgentCount;
  final int paginationStalledAgentCount;
  final int noSalesAgentOptionCount;
  final int noSalesBranchCount;
  final int salesUnavailableBranchCount;

  @override
  bool operator ==(Object other) {
    return other is SalesLiveMapOperationalFingerprint &&
        other.salesDataPending == salesDataPending &&
        other.loadFailed == loadFailed &&
        other.hasPartialIssue == hasPartialIssue &&
        other.failedAgentCount == failedAgentCount &&
        other.queriedAgentCount == queriedAgentCount &&
        other.plannedAgentCount == plannedAgentCount &&
        other.totalRevenue == totalRevenue &&
        other.totalSalesCount == totalSalesCount &&
        other.totalBranchCount == totalBranchCount &&
        other.mappedBranchCount == mappedBranchCount &&
        other.refreshedAt == refreshedAt &&
        other.loadFailureIdentity == loadFailureIdentity &&
        other.loadFailureReason == loadFailureReason &&
        other.loadFailureMessage == loadFailureMessage &&
        other.missingClientTokenAgentCount == missingClientTokenAgentCount &&
        other.skippedOfflineAgentCount == skippedOfflineAgentCount &&
        other.rowCapReachedAgentCount == rowCapReachedAgentCount &&
        other.paginationStalledAgentCount == paginationStalledAgentCount &&
        other.noSalesAgentOptionCount == noSalesAgentOptionCount &&
        other.noSalesBranchCount == noSalesBranchCount &&
        other.salesUnavailableBranchCount == salesUnavailableBranchCount;
  }

  @override
  int get hashCode => Object.hash(
    Object.hash(
      salesDataPending,
      loadFailed,
      hasPartialIssue,
      failedAgentCount,
      queriedAgentCount,
      plannedAgentCount,
      totalRevenue,
      totalSalesCount,
      totalBranchCount,
      mappedBranchCount,
    ),
    Object.hash(
      refreshedAt,
      loadFailureIdentity,
      loadFailureReason,
      loadFailureMessage,
      missingClientTokenAgentCount,
      skippedOfflineAgentCount,
      rowCapReachedAgentCount,
      paginationStalledAgentCount,
      noSalesAgentOptionCount,
      noSalesBranchCount,
      salesUnavailableBranchCount,
    ),
  );
}

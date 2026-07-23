import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_load_failure_reason.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_filter.dart';
import 'package:colmeia/features/sales/presentation/state/sales_live_map_presentation_state.dart';
import 'package:flutter/foundation.dart';

/// Fields that drive live-map chrome outside the point payload: chart
/// subtitle, export header summaries, and failure-placeholder copy.
///
/// Intentionally excludes KPI-only counters (`totalRevenue`,
/// `totalSalesCount`, agent failure tallies) so progressive operational
/// ticks do not rebuild the Brazil map chart when the digest and chrome
/// stay stable.
@immutable
class SalesLiveMapMapChromeFingerprint {
  factory SalesLiveMapMapChromeFingerprint.from(
    SalesLiveMapPresentationState state,
  ) {
    final result = state.result;
    final customRange = state.filter.customDateRange;
    return SalesLiveMapMapChromeFingerprint._(
      salesDataPending: result?.salesDataPending ?? false,
      mappedBranchCount: result?.mappedBranchCount ?? 0,
      totalBranchCount: result?.totalBranchCount ?? 0,
      branchOptionCount: result?.branchOptions.length ?? 0,
      isLoading: state.isLoading,
      loadFailed: result?.loadFailed ?? false,
      loadFailureIdentity: identityHashCode(result?.loadFailure),
      loadFailureReason: result?.loadFailureReason,
      loadFailureMessage: result?.loadFailureMessage,
      periodMode: state.filter.periodMode,
      customRangeStart: customRange?.startInclusive,
      customRangeEnd: customRange?.endInclusive,
      filterDetailLevel: state.filter.detailLevel,
      selectedBranchCount: state.filter.selectedBranchIds?.length ?? 0,
    );
  }

  const SalesLiveMapMapChromeFingerprint._({
    required this.salesDataPending,
    required this.mappedBranchCount,
    required this.totalBranchCount,
    required this.branchOptionCount,
    required this.isLoading,
    required this.loadFailed,
    required this.loadFailureIdentity,
    required this.loadFailureReason,
    required this.loadFailureMessage,
    required this.periodMode,
    required this.customRangeStart,
    required this.customRangeEnd,
    required this.filterDetailLevel,
    required this.selectedBranchCount,
  });

  static const SalesLiveMapMapChromeFingerprint empty =
      SalesLiveMapMapChromeFingerprint._(
        salesDataPending: false,
        mappedBranchCount: 0,
        totalBranchCount: 0,
        branchOptionCount: 0,
        isLoading: false,
        loadFailed: false,
        loadFailureIdentity: 0,
        loadFailureReason: null,
        loadFailureMessage: null,
        periodMode: SalesLiveMapPeriodMode.today,
        customRangeStart: null,
        customRangeEnd: null,
        filterDetailLevel: SalesLiveMapMapDetail.branches,
        selectedBranchCount: 0,
      );

  final bool salesDataPending;
  final int mappedBranchCount;
  final int totalBranchCount;
  final int branchOptionCount;
  final bool isLoading;
  final bool loadFailed;
  final int loadFailureIdentity;
  final SalesLiveMapLoadFailureReason? loadFailureReason;
  final String? loadFailureMessage;
  final SalesLiveMapPeriodMode periodMode;
  final DateTime? customRangeStart;
  final DateTime? customRangeEnd;
  final SalesLiveMapMapDetail filterDetailLevel;
  final int selectedBranchCount;

  @override
  bool operator ==(Object other) {
    return other is SalesLiveMapMapChromeFingerprint &&
        other.salesDataPending == salesDataPending &&
        other.mappedBranchCount == mappedBranchCount &&
        other.totalBranchCount == totalBranchCount &&
        other.branchOptionCount == branchOptionCount &&
        other.isLoading == isLoading &&
        other.loadFailed == loadFailed &&
        other.loadFailureIdentity == loadFailureIdentity &&
        other.loadFailureReason == loadFailureReason &&
        other.loadFailureMessage == loadFailureMessage &&
        other.periodMode == periodMode &&
        other.customRangeStart == customRangeStart &&
        other.customRangeEnd == customRangeEnd &&
        other.filterDetailLevel == filterDetailLevel &&
        other.selectedBranchCount == selectedBranchCount;
  }

  @override
  int get hashCode => Object.hash(
    Object.hash(
      salesDataPending,
      mappedBranchCount,
      totalBranchCount,
      branchOptionCount,
      isLoading,
      loadFailed,
      loadFailureIdentity,
    ),
    Object.hash(
      loadFailureReason,
      loadFailureMessage,
      periodMode,
      customRangeStart,
      customRangeEnd,
      filterDetailLevel,
      selectedBranchCount,
    ),
  );
}

import 'package:colmeia/features/sales/domain/entities/sales_live_map_branch_ref.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_branch_ref_codec.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_filter.dart';
import 'package:colmeia/shared/filters/dashboard_filter.dart';
import 'package:colmeia/shared/utils/app_unordered_set_equality.dart';
import 'package:flutter/foundation.dart';

/// SQL-driving slice of [SalesLiveMapFilter] (agents, period, persisted branch scope).
///
/// Visual-only fields (map detail level, marker visual, chart metric) are
/// intentionally excluded.
@immutable
class SalesLiveMapDataFilter {
  const SalesLiveMapDataFilter({
    this.selectedAgentIds,
    this.selectedBranchIds,
    this.periodMode = SalesLiveMapPeriodMode.today,
    this.customDateRange,
  });

  factory SalesLiveMapDataFilter.fromLiveMapFilter(SalesLiveMapFilter filter) {
    return SalesLiveMapDataFilter(
      selectedAgentIds: filter.selectedAgentIds,
      selectedBranchIds: filter.selectedBranchIds,
      periodMode: filter.periodMode,
      customDateRange: filter.customDateRange,
    );
  }

  final Set<String>? selectedAgentIds;
  final Set<SalesLiveMapBranchRef>? selectedBranchIds;
  final SalesLiveMapPeriodMode periodMode;
  final DashboardDateRange? customDateRange;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is SalesLiveMapDataFilter &&
        appSetEquals(other.selectedAgentIds, selectedAgentIds) &&
        appSetEquals(other.selectedBranchIds, selectedBranchIds) &&
        other.periodMode == periodMode &&
        other.customDateRange == customDateRange;
  }

  @override
  int get hashCode => Object.hash(
    periodMode,
    customDateRange,
    appOrderedSetHash<String>(selectedAgentIds, _identityKey),
    appOrderedSetHash<SalesLiveMapBranchRef>(
      selectedBranchIds,
      SalesLiveMapBranchRefCodec.encode,
    ),
  );
}

String _identityKey(String value) => value;

extension SalesLiveMapFilterDataSlice on SalesLiveMapFilter {
  SalesLiveMapDataFilter get dataFilter =>
      SalesLiveMapDataFilter.fromLiveMapFilter(this);
}

import 'package:colmeia/features/overview/domain/entities/overview_filter.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_filter.dart';
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
  final Set<String>? selectedBranchIds;
  final SalesLiveMapPeriodMode periodMode;
  final OverviewDateRange? customDateRange;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is SalesLiveMapDataFilter &&
        _setEquals(other.selectedAgentIds, selectedAgentIds) &&
        _setEquals(other.selectedBranchIds, selectedBranchIds) &&
        other.periodMode == periodMode &&
        other.customDateRange == customDateRange;
  }

  @override
  int get hashCode => Object.hash(
    periodMode,
    customDateRange,
    _orderedHash(selectedAgentIds),
    _orderedHash(selectedBranchIds),
  );

  static bool _setEquals(Set<String>? a, Set<String>? b) {
    if (identical(a, b)) {
      return true;
    }
    if (a == null || b == null) {
      return a == null && b == null;
    }
    if (a.length != b.length) {
      return false;
    }
    for (final value in a) {
      if (!b.contains(value)) {
        return false;
      }
    }
    return true;
  }

  static int? _orderedHash(Set<String>? value) {
    if (value == null) {
      return null;
    }
    final sorted = value.toList(growable: false)..sort();
    return Object.hashAll(sorted);
  }
}

extension SalesLiveMapFilterDataSlice on SalesLiveMapFilter {
  SalesLiveMapDataFilter get dataFilter =>
      SalesLiveMapDataFilter.fromLiveMapFilter(this);
}

import 'dart:collection';

import 'package:colmeia/features/sales/application/sales_live_map_catalog_scope.dart';
import 'package:colmeia/features/sales/application/sales_live_map_reload_reason.dart';
import 'package:flutter/foundation.dart';

const int _kSalesLiveMapRefreshMetricsMaxEntries = 100;
const int _kSalesLiveMapRefreshMetricsDefaultLimit = 20;

enum SalesLiveMapCatalogSource {
  memory,
  disk,
  broaderCacheFiltered,
  remote,
}

@immutable
class SalesLiveMapRefreshMetricEvent {
  SalesLiveMapRefreshMetricEvent({
    required this.recordedAt,
    required this.reloadReason,
    required this.catalogScopeKind,
    required this.catalogSource,
    required this.selectedAgentCount,
    required this.selectedBranchCount,
    required this.resolveDurationMs,
    required this.catalogDurationMs,
    required this.salesDurationMs,
    required this.mapDurationMs,
    required this.geoDurationMs,
    required this.plannedAgentCount,
    required this.queriedAgentCount,
    required this.rowCapReachedAgentCount,
    required Set<String> paginationStalledAgentIds,
    required this.partialFailure,
    required this.loadFailed,
    this.catalogSalesBatchMerged = false,
    this.mergeWaveSize = 0,
    List<String>? partialIssueBreakdown,
  }) : paginationStalledAgentIds = Set<String>.unmodifiable(
         paginationStalledAgentIds,
       ),
       partialIssueBreakdown = partialIssueBreakdown == null
           ? null
           : List<String>.unmodifiable(partialIssueBreakdown);

  final DateTime recordedAt;
  final SalesLiveMapReloadReason reloadReason;
  final SalesLiveMapCatalogScopeKind catalogScopeKind;
  final SalesLiveMapCatalogSource catalogSource;
  final int selectedAgentCount;
  final int selectedBranchCount;
  final int resolveDurationMs;
  final int catalogDurationMs;
  final int salesDurationMs;
  final int mapDurationMs;
  final int geoDurationMs;
  final int plannedAgentCount;
  final int queriedAgentCount;
  final int rowCapReachedAgentCount;
  final Set<String> paginationStalledAgentIds;
  final bool partialFailure;
  final bool loadFailed;
  final bool catalogSalesBatchMerged;
  final int mergeWaveSize;

  /// When [partialFailure] is true, lists which load-result flags contributed
  /// (same keys as `partialIssueFlagBreakdown` on the live-map load result).
  final List<String>? partialIssueBreakdown;

  Map<String, Object?> toLogContext() {
    return <String, Object?>{
      'reloadReason': reloadReason.name,
      'catalogScopeKind': catalogScopeKind.name,
      'catalogSource': catalogSource.name,
      'selectedAgentCount': selectedAgentCount,
      'selectedBranchCount': selectedBranchCount,
      'resolveDurationMs': resolveDurationMs,
      'catalogDurationMs': catalogDurationMs,
      'salesDurationMs': salesDurationMs,
      'mapDurationMs': mapDurationMs,
      'geoDurationMs': geoDurationMs,
      'plannedAgentCount': plannedAgentCount,
      'queriedAgentCount': queriedAgentCount,
      'rowCapReachedAgentCount': rowCapReachedAgentCount,
      'paginationStalledAgentIds': paginationStalledAgentIds.toList(
        growable: false,
      ),
      'partialFailure': partialFailure,
      'loadFailed': loadFailed,
      'catalogSalesBatchMerged': catalogSalesBatchMerged,
      'mergeWaveSize': mergeWaveSize,
      if (partialIssueBreakdown != null && partialIssueBreakdown!.isNotEmpty)
        'partialIssueBreakdown': partialIssueBreakdown,
    };
  }
}

class SalesLiveMapRefreshMetrics {
  SalesLiveMapRefreshMetrics({
    this.maxEntries = _kSalesLiveMapRefreshMetricsMaxEntries,
  });

  final int maxEntries;
  // ListQueue gives O(1) push/pop on both ends so the bounded buffer trims
  // older entries without the O(n) shift of `List.removeAt(0)`.
  final ListQueue<SalesLiveMapRefreshMetricEvent> _events =
      ListQueue<SalesLiveMapRefreshMetricEvent>();

  void record(SalesLiveMapRefreshMetricEvent event) {
    _events.addLast(event);
    while (_events.length > maxEntries) {
      _events.removeFirst();
    }
  }

  List<SalesLiveMapRefreshMetricEvent> getRecentEvents({
    int limit = _kSalesLiveMapRefreshMetricsDefaultLimit,
  }) {
    return _events.toList(growable: false).reversed.take(limit).toList(
      growable: false,
    );
  }

  SalesLiveMapRefreshMetricEvent? get latest =>
      _events.isEmpty ? null : _events.last;

  void clear() {
    _events.clear();
  }
}

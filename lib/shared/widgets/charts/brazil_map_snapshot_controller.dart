import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_data.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_models.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_snapshot.dart';
import 'package:colmeia/shared/widgets/charts/brazil_map_chart_visual_snapshot.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Caches and builds snapshot data and visual snapshots for the Brazil map chart.
class BrazilMapSnapshotController {
  AppBrazilStoreSalesMapSnapshotData? _snapshotData;
  BrazilMapChartVisualSnapshot? _snapshot;
  List<AppBrazilStoreSalesPoint>? _cachedPointsDigestSource;
  int? _cachedPointsDigest;

  AppBrazilStoreSalesMapSnapshotData? get snapshotData => _snapshotData;

  BrazilMapChartVisualSnapshot? get snapshot => _snapshot;

  Object? get snapshotDataIdentityForTesting => _snapshotData;

  Object? get snapshotMapPointsIdentityForTesting => _snapshot?.mapPoints;

  void invalidateData() {
    _snapshotData = null;
    _snapshot = null;
  }

  void invalidateVisual() {
    _snapshot = null;
  }

  void invalidatePointsDigestIfSourceChanged(
    List<AppBrazilStoreSalesPoint> points,
  ) {
    if (identical(_cachedPointsDigestSource, points)) {
      _cachedPointsDigest = null;
    } else {
      _cachedPointsDigestSource = null;
    }
  }

  int resolvePointsDigest(List<AppBrazilStoreSalesPoint> points) {
    if (identical(_cachedPointsDigestSource, points) &&
        _cachedPointsDigest != null) {
      return _cachedPointsDigest!;
    }
    final digest = AppBrazilStoreSalesMapData.pointsContentDigest(points);
    _cachedPointsDigestSource = points;
    _cachedPointsDigest = digest;
    return digest;
  }

  String computeDataReuseKey({
    required List<AppBrazilStoreSalesPoint> points,
    required Set<String> fixedBranchIds,
    required Set<String> filterBranchIds,
    required AppBrazilStoreSalesMapStyle style,
    required AppBrazilStoreSalesMapMetric metric,
    required String? activeRegionKey,
    required double zoomLevel,
    required bool includeVisibleBranchListItems,
  }) {
    final pointsDigest = resolvePointsDigest(points);
    return AppBrazilStoreSalesMapSnapshotBuilder.buildReuseKey(
      points: points,
      fixedBranchIds: fixedBranchIds,
      filterBranchIds: filterBranchIds,
      style: style,
      metric: metric,
      activeRegionKey: activeRegionKey,
      zoomLevel: zoomLevel,
      includeVisibleBranchListItems: includeVisibleBranchListItems,
      pointsDigest: pointsDigest,
    );
  }

  AppBrazilStoreSalesMapSnapshotData resolveData({
    required BuildContext context,
    required BrazilMapSnapshotBuildInput input,
  }) {
    final reuseKey = computeDataReuseKey(
      points: input.points,
      fixedBranchIds: input.fixedBranchIds,
      filterBranchIds: input.filterBranchIds,
      style: input.style,
      metric: input.metric,
      activeRegionKey: input.activeRegionKey,
      zoomLevel: input.zoomLevel,
      includeVisibleBranchListItems: input.includeVisibleBranchListItems,
    );
    final snapshotData = _snapshotData;
    if (snapshotData != null && snapshotData.cachedReuseKey == reuseKey) {
      return snapshotData;
    }

    final stopwatch = kDebugMode || kProfileMode
        ? (Stopwatch()..start())
        : null;
    final nextSnapshotData = AppBrazilStoreSalesMapSnapshotBuilder.buildData(
      AppBrazilStoreSalesMapSnapshotInput(
        points: input.points,
        metric: input.metric,
        activeRegionKey: input.activeRegionKey,
        zoomLevel: input.zoomLevel,
        style: input.style,
        includeVisibleBranchListItems: input.includeVisibleBranchListItems,
      ),
      cachedReuseKey: reuseKey,
      defaultBranchName: AppLocalizations.of(
        context,
      ).brazilStoreSalesMapDefaultBranchName,
    );
    if (stopwatch != null) {
      AppLogger.debug(
        'Brazil store sales map snapshot data built',
        context: <String, Object?>{
          'operation': 'AppBrazilStoreSalesMapChart',
          'elapsedMs': stopwatch.elapsedMilliseconds,
          'inputPointCount': input.points.length,
          'validPointCount': nextSnapshotData.validPointCount,
          'bucketCount': nextSnapshotData.buckets.length,
          'markerGroupCount': nextSnapshotData.markerGroups.length,
          'visibleBranchListItemCount':
              nextSnapshotData.visibleBranchListItems.length,
          'includeVisibleBranchListItems': input.includeVisibleBranchListItems,
          'aggregation': input.style.markerAggregation.name,
          'activeRegionKey': input.activeRegionKey,
        },
      );
    }
    _snapshotData = nextSnapshotData;
    return nextSnapshotData;
  }

  BrazilMapChartVisualSnapshot resolveVisual({
    required BuildContext context,
    required AppBrazilStoreSalesMapSnapshotData data,
    required String? selectedStoreId,
    required AppBrazilStoreSalesMapStyle style,
    required bool autoFocusSelectedStore,
  }) {
    final visualReuseKey = autoFocusSelectedStore
        ? [
            data.cachedReuseKey,
            'ss=',
            'rs=',
            'pv=',
          ].join(';')
        : data.cachedReuseKey;
    final snapshot = _snapshot;
    if (snapshot != null && snapshot.visualReuseKey == visualReuseKey) {
      return snapshot;
    }

    final nextSnapshot = BrazilMapChartVisualSnapshot.fromData(
      context: context,
      data: data,
      selectedStoreId: selectedStoreId,
      requestedStateKey: null,
      style: style,
      visualReuseKey: visualReuseKey,
    );
    _snapshot = nextSnapshot;
    return nextSnapshot;
  }

  BrazilMapChartVisualSnapshot resolve({
    required BuildContext context,
    required BrazilMapSnapshotBuildInput input,
    required String? selectedStoreId,
    required String? requestedStateKey,
  }) {
    final data = resolveData(context: context, input: input);
    final visualReuseKey = input.style.autoFocusSelectedStore
        ? [
            data.cachedReuseKey,
            'ss=',
            'rs=',
            'pv=',
          ].join(';')
        : data.cachedReuseKey;
    final snapshot = _snapshot;
    if (snapshot != null && snapshot.visualReuseKey == visualReuseKey) {
      return snapshot;
    }

    final nextSnapshot = BrazilMapChartVisualSnapshot.fromData(
      context: context,
      data: data,
      selectedStoreId: selectedStoreId,
      requestedStateKey: requestedStateKey,
      style: input.style,
      visualReuseKey: visualReuseKey,
    );
    _snapshot = nextSnapshot;
    return nextSnapshot;
  }
}

class BrazilMapSnapshotBuildInput {
  const BrazilMapSnapshotBuildInput({
    required this.points,
    required this.metric,
    required this.activeRegionKey,
    required this.zoomLevel,
    required this.style,
    required this.fixedBranchIds,
    required this.filterBranchIds,
    required this.includeVisibleBranchListItems,
  });

  final List<AppBrazilStoreSalesPoint> points;
  final AppBrazilStoreSalesMapMetric metric;
  final String? activeRegionKey;
  final double zoomLevel;
  final AppBrazilStoreSalesMapStyle style;
  final Set<String> fixedBranchIds;
  final Set<String> filterBranchIds;
  final bool includeVisibleBranchListItems;
}

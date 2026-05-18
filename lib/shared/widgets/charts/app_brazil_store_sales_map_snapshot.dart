import 'package:colmeia/shared/maps/app_location_lookup_normalizer.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_data.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_models.dart';

enum AppBrazilStoreSalesVisibleBranchListItemState {
  regular,
  loading,
  unavailable,
  zeroSales,
}

class AppBrazilStoreSalesVisibleBranchListItem {
  const AppBrazilStoreSalesVisibleBranchListItem({
    required this.id,
    required this.point,
    required this.displayName,
    required this.cityUfLabel,
    required this.searchIndexText,
    required this.salesAmount,
    required this.isSelected,
    required this.state,
  });

  final String id;
  final AppBrazilStoreSalesPoint point;
  final String displayName;
  final String cityUfLabel;
  final String searchIndexText;
  final double salesAmount;
  final bool isSelected;
  final AppBrazilStoreSalesVisibleBranchListItemState state;
}

class AppBrazilStoreSalesMapSnapshotInput {
  const AppBrazilStoreSalesMapSnapshotInput({
    required this.points,
    required this.metric,
    required this.zoomLevel,
    required this.style,
    this.selectedStoreId,
    this.requestedStateKey,
    this.activeRegionKey,
  });

  final List<AppBrazilStoreSalesPoint> points;
  final AppBrazilStoreSalesMapMetric metric;
  final String? selectedStoreId;
  final String? requestedStateKey;
  final String? activeRegionKey;
  final double zoomLevel;
  final AppBrazilStoreSalesMapStyle style;
}

class AppBrazilStoreSalesMapSnapshotData {
  const AppBrazilStoreSalesMapSnapshotData({
    required this.metric,
    required this.selectedStoreId,
    required this.requestedStateKey,
    required this.activeRegionKey,
    required this.zoomLevel,
    required this.visiblePoints,
    required this.visibleBranchListItems,
    required this.buckets,
    required this.markerGroups,
    required this.stateBubbleBuckets,
    required this.selectedPoint,
    required this.selectedMarkerGroup,
    required this.selectedStateKey,
    required this.selectedStateBucket,
    required this.minMarkerValue,
    required this.maxMarkerValue,
    required this.diagnostics,
    required this.validPointCount,
    required this.cachedReuseKey,
  });

  final AppBrazilStoreSalesMapMetric metric;
  final String? selectedStoreId;
  final String? requestedStateKey;
  final String? activeRegionKey;
  final double zoomLevel;
  final List<AppBrazilStoreSalesPoint> visiblePoints;
  final List<AppBrazilStoreSalesVisibleBranchListItem> visibleBranchListItems;
  final List<AppBrazilStoreSalesStateBucket> buckets;
  final List<AppBrazilStoreSalesMarkerGroup> markerGroups;
  final List<AppBrazilStoreSalesStateBucket> stateBubbleBuckets;
  final AppBrazilStoreSalesPoint? selectedPoint;
  final AppBrazilStoreSalesMarkerGroup? selectedMarkerGroup;
  final String? selectedStateKey;
  final AppBrazilStoreSalesStateBucket? selectedStateBucket;
  final num minMarkerValue;
  final num maxMarkerValue;
  final AppBrazilStoreSalesMapDiagnostics diagnostics;
  final int validPointCount;
  final String cachedReuseKey;
}

abstract final class AppBrazilStoreSalesMapSnapshotBuilder {
  static AppBrazilStoreSalesMapSnapshotData buildData(
    AppBrazilStoreSalesMapSnapshotInput input, {
    required String cachedReuseKey,
    required String defaultBranchName,
  }) {
    return _build(
      input,
      cachedReuseKey: cachedReuseKey,
      defaultBranchName: defaultBranchName,
      resolveSelectionState: false,
    );
  }

  static AppBrazilStoreSalesMapSnapshotData build(
    AppBrazilStoreSalesMapSnapshotInput input, {
    required String cachedReuseKey,
    required String defaultBranchName,
  }) {
    return _build(
      input,
      cachedReuseKey: cachedReuseKey,
      defaultBranchName: defaultBranchName,
      resolveSelectionState: true,
    );
  }

  static AppBrazilStoreSalesMapSnapshotData _build(
    AppBrazilStoreSalesMapSnapshotInput input, {
    required String cachedReuseKey,
    required String defaultBranchName,
    required bool resolveSelectionState,
  }) {
    final preparedData = AppBrazilStoreSalesMapData.prepareSnapshotData(
      input.points,
      includeEmptyStates: input.style.includeEmptyStates,
      regionKey: input.activeRegionKey,
    );
    final diagnostics = preparedData.diagnostics;
    final buckets = preparedData.buckets;
    final markerGroups = _showsStoreMarkers(input.style.markerAggregation)
        ? AppBrazilStoreSalesMapData.buildMarkerGroupsFromValidPoints(
            preparedData.validPoints,
            collapseSameCoordinateMarkers:
                input.style.collapseSameCoordinateMarkers,
            enableProximityCluster: input.style.enableProximityCluster,
            proximityClusterDistanceDegrees:
                AppBrazilStoreSalesMapData.proximityClusterDistanceForZoom(
                  baseDistanceDegrees:
                      input.style.proximityClusterDistanceDegrees,
                  zoomLevel: input.zoomLevel,
                ),
            coordinatePrecision: input.style.clusterCoordinatePrecision,
            markerAggregation: input.style.markerAggregation,
          )
        : const <AppBrazilStoreSalesMarkerGroup>[];
    final stateBubbleBuckets = _stateBubbleBuckets(
      buckets,
      input.metric,
      input.style.markerAggregation,
    );
    final (minValue, maxValue) = _markerValueRange(
      markerGroups: markerGroups,
      stateBubbleBuckets: stateBubbleBuckets,
      metric: input.metric,
    );

    AppBrazilStoreSalesPoint? selectedPoint;
    AppBrazilStoreSalesMarkerGroup? selectedMarkerGroup;
    var selectedStateKey = input.requestedStateKey;
    if (resolveSelectionState && input.selectedStoreId != null) {
      for (final point in preparedData.validPoints) {
        if (point.id == input.selectedStoreId) {
          selectedPoint = point;
          selectedStateKey = AppBrazilStoreSalesMapData.normalizeUf(point.uf);
          break;
        }
      }
    }

    if (resolveSelectionState) {
      for (final group in markerGroups) {
        final selected = group.points.any(
          (point) => point.id == input.selectedStoreId,
        );
        if (!selected) {
          continue;
        }
        selectedMarkerGroup = group;
        selectedPoint = group.points.firstWhere(
          (point) => point.id == input.selectedStoreId,
          orElse: () => group.primaryPoint,
        );
        selectedStateKey = AppBrazilStoreSalesMapData.normalizeUf(
          selectedPoint.uf,
        );
        break;
      }
    }

    AppBrazilStoreSalesStateBucket? selectedStateBucket;
    if (resolveSelectionState && selectedStateKey != null) {
      for (final bucket in buckets) {
        if (bucket.uf == selectedStateKey) {
          selectedStateBucket = bucket;
          break;
        }
      }
    }

    final visibleBranchListItems = _buildVisibleBranchListItems(
      points: preparedData.validPoints,
      selectedStoreId: input.selectedStoreId,
      defaultBranchName: defaultBranchName,
    );

    return AppBrazilStoreSalesMapSnapshotData(
      metric: input.metric,
      selectedStoreId: input.selectedStoreId,
      requestedStateKey: input.requestedStateKey,
      activeRegionKey: input.activeRegionKey,
      zoomLevel: input.zoomLevel,
      visiblePoints: preparedData.validPoints,
      visibleBranchListItems: visibleBranchListItems,
      buckets: buckets,
      markerGroups: markerGroups,
      stateBubbleBuckets: stateBubbleBuckets,
      selectedPoint: selectedPoint,
      selectedMarkerGroup: selectedMarkerGroup,
      selectedStateKey: selectedStateKey,
      selectedStateBucket: selectedStateBucket,
      minMarkerValue: minValue,
      maxMarkerValue: maxValue,
      diagnostics: diagnostics,
      validPointCount: preparedData.validPoints.length,
      cachedReuseKey: cachedReuseKey,
    );
  }

  static String buildReuseKey({
    required List<AppBrazilStoreSalesPoint> points,
    required Set<String> fixedBranchIds,
    required Set<String> filterBranchIds,
    required AppBrazilStoreSalesMapStyle style,
    required AppBrazilStoreSalesMapMetric metric,
    required String? activeRegionKey,
    required double zoomLevel,
    String? selectedStoreId,
    String? requestedStateKey,
  }) {
    final parts = <String>[
      'fx=${_sortedSetJoin(fixedBranchIds)}',
      'fl=${_sortedSetJoin(filterBranchIds)}',
      style.markerAggregation.name,
      style.markerVisual.name,
      style.enableProximityCluster.toString(),
      style.collapseSameCoordinateMarkers.toString(),
      '${style.clusterCoordinatePrecision}',
      '${style.proximityClusterDistanceDegrees}',
      style.includeEmptyStates.toString(),
      style.showTooltip.toString(),
      '${style.markerMinSize}|${style.markerMaxSize}|${style.height}',
      'm=${metric.name}',
      'ak=$activeRegionKey',
      'z=$zoomLevel',
      'pts=${AppBrazilStoreSalesMapData.pointsContentDigest(points)}',
    ];
    return parts.join(';');
  }

  static String _sortedSetJoin(Set<String> values) {
    if (values.isEmpty) {
      return '';
    }
    final sorted = values.toList(growable: false)..sort();
    return sorted.join(',');
  }

  static (num, num) _markerValueRange({
    required List<AppBrazilStoreSalesMarkerGroup> markerGroups,
    required List<AppBrazilStoreSalesStateBucket> stateBubbleBuckets,
    required AppBrazilStoreSalesMapMetric metric,
  }) {
    final values = <num>[
      for (final group in markerGroups) group.valueForMetric(metric),
      for (final bucket in stateBubbleBuckets) metric.valueForBucket(bucket),
    ];

    if (values.isEmpty) {
      return (0, 0);
    }

    var minValue = values.first;
    var maxValue = values.first;
    for (final value in values.skip(1)) {
      if (value < minValue) {
        minValue = value;
      }
      if (value > maxValue) {
        maxValue = value;
      }
    }

    return (minValue, maxValue);
  }

  static bool _showsStoreMarkers(
    AppBrazilStoreSalesMarkerAggregation aggregation,
  ) {
    return switch (aggregation) {
      AppBrazilStoreSalesMarkerAggregation.stores => true,
      AppBrazilStoreSalesMarkerAggregation.municipalities => true,
      AppBrazilStoreSalesMarkerAggregation.states => false,
      AppBrazilStoreSalesMarkerAggregation.storesAndStates => true,
    };
  }

  static List<AppBrazilStoreSalesStateBucket> _stateBubbleBuckets(
    List<AppBrazilStoreSalesStateBucket> buckets,
    AppBrazilStoreSalesMapMetric metric,
    AppBrazilStoreSalesMarkerAggregation aggregation,
  ) {
    final showStateBubbles = switch (aggregation) {
      AppBrazilStoreSalesMarkerAggregation.stores => false,
      AppBrazilStoreSalesMarkerAggregation.municipalities => false,
      AppBrazilStoreSalesMarkerAggregation.states => true,
      AppBrazilStoreSalesMarkerAggregation.storesAndStates => true,
    };
    if (!showStateBubbles) {
      return const <AppBrazilStoreSalesStateBucket>[];
    }

    return [
      for (final bucket in buckets)
        if (metric.valueForBucket(bucket) > 0) bucket,
    ];
  }

  static List<AppBrazilStoreSalesVisibleBranchListItem>
  _buildVisibleBranchListItems({
    required List<AppBrazilStoreSalesPoint> points,
    required String? selectedStoreId,
    required String defaultBranchName,
  }) {
    final entries = <AppBrazilStoreSalesVisibleBranchListItem>[
      for (final point in points)
        () {
          final displayName = _displayNameForPoint(
            point,
            defaultBranchName: defaultBranchName,
          );
          final cityUfLabel = _cityUfLabelForPoint(point);
          return AppBrazilStoreSalesVisibleBranchListItem(
            id: point.id,
            point: point,
            displayName: displayName,
            cityUfLabel: cityUfLabel,
            searchIndexText:
                AppLocationLookupNormalizer.normalizeAddressLine(
                  '$displayName $cityUfLabel',
                ) ??
                point.id,
            salesAmount: point.salesAmount,
            isSelected: point.id == selectedStoreId,
            state: _branchItemStateFor(point),
          );
        }(),
    ];
    return entries..sort(_compareVisibleBranchListItems);
  }

  static int _compareVisibleBranchListItems(
    AppBrazilStoreSalesVisibleBranchListItem left,
    AppBrazilStoreSalesVisibleBranchListItem right,
  ) {
    final amount = right.salesAmount.compareTo(left.salesAmount);
    if (amount != 0) {
      return amount;
    }
    return left.displayName.compareTo(right.displayName);
  }

  static AppBrazilStoreSalesVisibleBranchListItemState _branchItemStateFor(
    AppBrazilStoreSalesPoint point,
  ) {
    if (point.salesDataLoading) {
      return AppBrazilStoreSalesVisibleBranchListItemState.loading;
    }
    if (point.salesDataUnavailable) {
      return AppBrazilStoreSalesVisibleBranchListItemState.unavailable;
    }
    if (point.salesAmount <= 0 && point.salesCount <= 0) {
      return AppBrazilStoreSalesVisibleBranchListItemState.zeroSales;
    }
    return AppBrazilStoreSalesVisibleBranchListItemState.regular;
  }

  static String _displayNameForPoint(
    AppBrazilStoreSalesPoint point, {
    required String defaultBranchName,
  }) {
    return _trimmedOrNull(point.fantasyName) ??
        _trimmedOrNull(point.name) ??
        defaultBranchName;
  }

  static String _cityUfLabelForPoint(AppBrazilStoreSalesPoint point) {
    return switch (_trimmedOrNull(point.city)) {
      final city? =>
        '$city / ${AppBrazilStoreSalesMapData.normalizeUf(point.uf)}',
      _ => AppBrazilStoreSalesMapData.normalizeUf(point.uf),
    };
  }

  static String? _trimmedOrNull(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }
}

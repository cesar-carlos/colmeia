import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_map_static_data.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_data.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_models.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_snapshot.dart';
import 'package:colmeia/shared/widgets/charts/app_map_models.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

String brazilMapChartFormatSalesCount(BuildContext context, num value) {
  final locale = Localizations.localeOf(context);
  return NumberFormat('#,##0', locale.toLanguageTag()).format(value.round());
}

/// Visual layer snapshot: map points and selection-derived view state.
class BrazilMapChartVisualSnapshot {
  const BrazilMapChartVisualSnapshot({
    required this.data,
    required this.mapPoints,
    required this.visualReuseKey,
    required this.selectedStoreId,
    required this.requestedStateKey,
    required this.selectedPoint,
    required this.selectedMarkerGroup,
    required this.selectedStateKey,
    required this.selectedStateBucket,
  });

  factory BrazilMapChartVisualSnapshot.fromData({
    required BuildContext context,
    required AppBrazilStoreSalesMapSnapshotData data,
    required String? selectedStoreId,
    required String? requestedStateKey,
    required AppBrazilStoreSalesMapStyle style,
    required String visualReuseKey,
  }) {
    final stopwatch = kDebugMode || kProfileMode
        ? (Stopwatch()..start())
        : null;
    final selectedState = _resolveSelectedState(
      data: data,
      selectedStoreId: selectedStoreId,
      requestedStateKey: requestedStateKey,
    );
    final mapPoints = _buildMapPoints(
      context: context,
      data: data,
      style: style,
    );

    final snapshot = BrazilMapChartVisualSnapshot(
      data: data,
      mapPoints: mapPoints,
      visualReuseKey: visualReuseKey,
      selectedStoreId: selectedStoreId,
      requestedStateKey: requestedStateKey,
      selectedPoint: selectedState.selectedPoint,
      selectedMarkerGroup: selectedState.selectedMarkerGroup,
      selectedStateKey: selectedState.selectedStateKey,
      selectedStateBucket: selectedState.selectedStateBucket,
    );
    if (stopwatch != null) {
      AppLogger.debug(
        'Brazil store sales map snapshot built',
        context: <String, Object?>{
          'operation': 'AppBrazilStoreSalesMapChart',
          'elapsedMs': stopwatch.elapsedMilliseconds,
          'inputPointCount': data.validPointCount,
          'validPointCount': data.validPointCount,
          'bucketCount': data.buckets.length,
          'markerGroupCount': data.markerGroups.length,
          'mapPointCount': mapPoints.length,
          'aggregation': style.markerAggregation.name,
          'activeRegionKey': data.activeRegionKey,
        },
      );
    }
    return snapshot;
  }

  final AppBrazilStoreSalesMapSnapshotData data;
  final List<AppMapPoint> mapPoints;
  final String visualReuseKey;
  final String? selectedStoreId;
  final String? requestedStateKey;
  final AppBrazilStoreSalesPoint? selectedPoint;
  final AppBrazilStoreSalesMarkerGroup? selectedMarkerGroup;
  final String? selectedStateKey;
  final AppBrazilStoreSalesStateBucket? selectedStateBucket;

  AppBrazilStoreSalesMapMetric get metric => data.metric;
  String? get activeRegionKey => data.activeRegionKey;
  double get zoomLevel => data.zoomLevel;
  List<AppBrazilStoreSalesPoint> get visiblePoints => data.visiblePoints;
  List<AppBrazilStoreSalesVisibleBranchListItem> get visibleBranchListItems =>
      data.visibleBranchListItems;
  List<AppBrazilStoreSalesStateBucket> get buckets => data.buckets;
  num get minMarkerValue => data.minMarkerValue;
  num get maxMarkerValue => data.maxMarkerValue;
  AppBrazilStoreSalesMapDiagnostics get diagnostics => data.diagnostics;
  String get cachedReuseKey => data.cachedReuseKey;

  bool get hasMarkers => mapPoints.isNotEmpty;

  static List<AppMapPoint> _buildMapPoints({
    required BuildContext context,
    required AppBrazilStoreSalesMapSnapshotData data,
    required AppBrazilStoreSalesMapStyle style,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final markerColor = style.markerColor ?? context.appColors.tertiary;
    final markerStrokeColor = style.markerStrokeColor ?? colorScheme.surface;
    final pendingMarkerColor = context.appColors.secondary;
    final unavailableMarkerColor = colorScheme.onSurfaceVariant;
    final mapPoints = <AppMapPoint>[];

    for (final bucket in data.stateBubbleBuckets) {
      final centroid = AppBrazilMapStaticData.stateCentroidsByUf[bucket.uf];
      if (centroid == null) {
        continue;
      }

      final value = data.metric.valueForBucket(bucket);
      final markerSize = _effectiveMarkerSize(
        size: AppBrazilStoreSalesMapData.markerSizeFor(
          value: value,
          minValue: data.minMarkerValue,
          maxValue: data.maxMarkerValue,
          minSize: style.markerMinSize,
          maxSize: style.markerMaxSize,
        ),
        isCluster: false,
        visual: AppBrazilStoreSalesMarkerVisual.bubble,
      );

      mapPoints.add(
        AppMapPoint(
          latitude: centroid.latitude,
          longitude: centroid.longitude,
          label: style.showTooltip ? bucket.uf : null,
          tooltip: style.showTooltip
              ? _stateBubbleTooltip(context, bucket)
              : null,
          payload: AppBrazilStoreSalesStateBubble(bucket: bucket),
          style: AppMapMarkerStyle(
            size: markerSize,
            color: markerColor,
            strokeColor: markerStrokeColor,
          ),
        ),
      );
    }

    for (final group in data.markerGroups) {
      final size = AppBrazilStoreSalesMapData.markerSizeFor(
        value: group.valueForMetric(data.metric),
        minValue: data.minMarkerValue,
        maxValue: data.maxMarkerValue,
        minSize: style.markerMinSize,
        maxSize: style.markerMaxSize,
      );
      final markerSize = _effectiveMarkerSize(
        size: size,
        isCluster: group.isCluster,
        visual: style.markerVisual,
      );
      final hasLoadingSales = group.points.any(
        (point) => point.salesDataLoading,
      );
      final hasUnavailableSales =
          !hasLoadingSales &&
          group.points.any((point) => point.salesDataUnavailable);
      final effectiveMarkerColor = hasLoadingSales
          ? pendingMarkerColor
          : hasUnavailableSales
          ? unavailableMarkerColor
          : markerColor;
      final effectiveStrokeColor = hasLoadingSales
          ? colorScheme.surface
          : markerStrokeColor;
      mapPoints.add(
        AppMapPoint(
          latitude: group.latitude,
          longitude: group.longitude,
          payload: group,
          style: AppMapMarkerStyle(
            size: markerSize,
            color: effectiveMarkerColor,
            strokeColor: effectiveStrokeColor,
            strokeWidth: hasLoadingSales ? 2.4 : 1.5,
          ),
        ),
      );
    }

    return mapPoints;
  }

  static ({
    AppBrazilStoreSalesPoint? selectedPoint,
    AppBrazilStoreSalesMarkerGroup? selectedMarkerGroup,
    String? selectedStateKey,
    AppBrazilStoreSalesStateBucket? selectedStateBucket,
  })
  _resolveSelectedState({
    required AppBrazilStoreSalesMapSnapshotData data,
    required String? selectedStoreId,
    required String? requestedStateKey,
  }) {
    AppBrazilStoreSalesPoint? selectedPoint;
    AppBrazilStoreSalesMarkerGroup? selectedMarkerGroup;
    var selectedStateKey = requestedStateKey;
    if (selectedStoreId != null) {
      for (final group in data.markerGroups) {
        final selected = group.points.any(
          (point) => point.id == selectedStoreId,
        );
        if (!selected) {
          continue;
        }
        selectedMarkerGroup = group;
        selectedPoint = group.points.firstWhere(
          (point) => point.id == selectedStoreId,
          orElse: () => group.primaryPoint,
        );
        selectedStateKey = AppBrazilStoreSalesMapData.normalizeUf(
          selectedPoint.uf,
        );
        break;
      }

      if (selectedPoint == null) {
        for (final point in data.visiblePoints) {
          if (point.id == selectedStoreId) {
            selectedPoint = point;
            break;
          }
        }
      }
      if (selectedPoint != null) {
        selectedStateKey = AppBrazilStoreSalesMapData.normalizeUf(
          selectedPoint.uf,
        );
      }
    }

    AppBrazilStoreSalesStateBucket? selectedStateBucket;
    if (selectedStateKey != null) {
      for (final bucket in data.buckets) {
        if (bucket.uf == selectedStateKey) {
          selectedStateBucket = bucket;
          break;
        }
      }
    }

    return (
      selectedPoint: selectedPoint,
      selectedMarkerGroup: selectedMarkerGroup,
      selectedStateKey: selectedStateKey,
      selectedStateBucket: selectedStateBucket,
    );
  }

  static double _effectiveMarkerSize({
    required double size,
    required bool isCluster,
    required AppBrazilStoreSalesMarkerVisual visual,
  }) {
    final minimumSize = switch (visual) {
      AppBrazilStoreSalesMarkerVisual.dot => isCluster ? 22.0 : size,
      AppBrazilStoreSalesMarkerVisual.bubble => 30.0,
      AppBrazilStoreSalesMarkerVisual.storeIcon => 26.0,
    };

    return size.clamp(minimumSize, double.infinity);
  }

  static String _stateBubbleTooltip(
    BuildContext context,
    AppBrazilStoreSalesStateBucket bucket,
  ) {
    final l10n = AppLocalizations.of(context);
    return l10n.brazilStoreSalesMapStateBucketTooltip(
      bucket.stateName,
      bucket.uf,
      AppBrFormatters.currency(bucket.salesAmount),
      brazilMapChartFormatSalesCount(context, bucket.salesCount),
      brazilMapChartFormatSalesCount(context, bucket.storeCount),
    );
  }
}

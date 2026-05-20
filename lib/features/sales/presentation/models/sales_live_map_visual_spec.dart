import 'package:colmeia/features/sales/domain/entities/sales_live_map_filter.dart';
import 'package:flutter/foundation.dart';

const double kSalesLiveMapOperationalHeight = 560;

@immutable
class SalesLiveMapVisualSpec {
  const SalesLiveMapVisualSpec({
    required this.detailLevel,
    required this.markerVisual,
    this.height = kSalesLiveMapOperationalHeight,
    this.showRegionFilter = false,
  });

  const SalesLiveMapVisualSpec.operational({
    this.detailLevel = SalesLiveMapMapDetail.branches,
    this.markerVisual = SalesLiveMapMarkerVisual.dot,
    this.height = kSalesLiveMapOperationalHeight,
    this.showRegionFilter = false,
  });

  final SalesLiveMapMapDetail detailLevel;
  final SalesLiveMapMarkerVisual markerVisual;
  final double height;
  final bool showRegionFilter;

  SalesLiveMapMarkerVisual get resolvedMarkerVisual =>
      detailLevel == SalesLiveMapMapDetail.states
      ? SalesLiveMapMarkerVisual.bubble
      : markerVisual;

  bool get showStoreDetail => detailLevel != SalesLiveMapMapDetail.states;

  bool get enableProximityCluster =>
      detailLevel == SalesLiveMapMapDetail.branches;

  int get maxClusterTooltipStores =>
      detailLevel == SalesLiveMapMapDetail.municipalities ? 8 : 5;

  SalesLiveMapVisualSpec copyWith({
    SalesLiveMapMapDetail? detailLevel,
    SalesLiveMapMarkerVisual? markerVisual,
    double? height,
    bool? showRegionFilter,
  }) {
    return SalesLiveMapVisualSpec(
      detailLevel: detailLevel ?? this.detailLevel,
      markerVisual: markerVisual ?? this.markerVisual,
      height: height ?? this.height,
      showRegionFilter: showRegionFilter ?? this.showRegionFilter,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SalesLiveMapVisualSpec &&
        other.detailLevel == detailLevel &&
        other.markerVisual == markerVisual &&
        other.height == height &&
        other.showRegionFilter == showRegionFilter;
  }

  @override
  int get hashCode => Object.hash(
    detailLevel,
    markerVisual,
    height,
    showRegionFilter,
  );
}

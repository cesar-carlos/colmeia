import 'package:colmeia/features/sales/domain/entities/sales_live_map_filter.dart';
import 'package:flutter/foundation.dart';

const double kSalesLiveMapOperationalHeight = 560;
const int _kSalesLiveMapMunicipalityClusterTooltipStores = 8;
const int _kSalesLiveMapDefaultClusterTooltipStores = 5;

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

  /// Forces [SalesLiveMapMarkerVisual.bubble] when rendering at state-level
  /// granularity; otherwise returns the user-selected [markerVisual].
  static SalesLiveMapMarkerVisual resolveMarkerVisual({
    required SalesLiveMapMapDetail detailLevel,
    required SalesLiveMapMarkerVisual markerVisual,
  }) {
    if (detailLevel == SalesLiveMapMapDetail.states) {
      return SalesLiveMapMarkerVisual.bubble;
    }
    return markerVisual;
  }

  SalesLiveMapMarkerVisual get resolvedMarkerVisual => resolveMarkerVisual(
    detailLevel: detailLevel,
    markerVisual: markerVisual,
  );

  bool get showStoreDetail => detailLevel != SalesLiveMapMapDetail.states;

  bool get enableProximityCluster =>
      detailLevel == SalesLiveMapMapDetail.branches;

  int get maxClusterTooltipStores =>
      detailLevel == SalesLiveMapMapDetail.municipalities
      ? _kSalesLiveMapMunicipalityClusterTooltipStores
      : _kSalesLiveMapDefaultClusterTooltipStores;

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

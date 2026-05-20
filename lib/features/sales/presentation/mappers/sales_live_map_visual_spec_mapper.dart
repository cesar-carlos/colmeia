import 'package:colmeia/features/sales/domain/entities/sales_live_map_filter.dart';
import 'package:colmeia/features/sales/presentation/models/sales_live_map_visual_spec.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_models.dart';

abstract final class SalesLiveMapVisualSpecMapper {
  static AppBrazilStoreSalesMapStyle toChartStyle(
    SalesLiveMapVisualSpec spec,
  ) {
    final appMarkerVisual = switch (spec.resolvedMarkerVisual) {
      SalesLiveMapMarkerVisual.dot => AppBrazilStoreSalesMarkerVisual.dot,
      SalesLiveMapMarkerVisual.bubble => AppBrazilStoreSalesMarkerVisual.bubble,
      SalesLiveMapMarkerVisual.storeIcon =>
        AppBrazilStoreSalesMarkerVisual.storeIcon,
    };
    final aggregation = switch (spec.detailLevel) {
      SalesLiveMapMapDetail.branches =>
        AppBrazilStoreSalesMarkerAggregation.stores,
      SalesLiveMapMapDetail.municipalities =>
        AppBrazilStoreSalesMarkerAggregation.municipalities,
      SalesLiveMapMapDetail.states =>
        AppBrazilStoreSalesMarkerAggregation.states,
    };
    final (minSize, maxSize) = switch (spec.resolvedMarkerVisual) {
      SalesLiveMapMarkerVisual.dot => (10.0, 24.0),
      SalesLiveMapMarkerVisual.bubble =>
        spec.detailLevel == SalesLiveMapMapDetail.states
            ? (30.0, 76.0)
            : (34.0, 82.0),
      SalesLiveMapMarkerVisual.storeIcon => (24.0, 34.0),
    };

    return AppBrazilStoreSalesMapStyle(
      height: spec.height,
      markerVisual: appMarkerVisual,
      markerAggregation: aggregation,
      markerMinSize: minSize,
      markerMaxSize: maxSize,
      maxClusterTooltipStores: spec.maxClusterTooltipStores,
      showStoreDetail: spec.showStoreDetail,
      showRegionFilter: spec.showRegionFilter,
      enableProximityCluster: spec.enableProximityCluster,
    );
  }
}

import 'package:colmeia/features/sales/domain/entities/sales_live_map_filter.dart';
import 'package:colmeia/features/sales/presentation/models/sales_live_map_visual_spec.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_models.dart';

const double _kSalesLiveMapDotMarkerMinSize = 10;
const double _kSalesLiveMapDotMarkerMaxSize = 24;
const double _kSalesLiveMapStateBubbleMinSize = 30;
const double _kSalesLiveMapStateBubbleMaxSize = 76;
const double _kSalesLiveMapBubbleMinSize = 34;
const double _kSalesLiveMapBubbleMaxSize = 82;
const double _kSalesLiveMapStoreIconMinSize = 24;
const double _kSalesLiveMapStoreIconMaxSize = 34;

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
      SalesLiveMapMarkerVisual.dot => (
        _kSalesLiveMapDotMarkerMinSize,
        _kSalesLiveMapDotMarkerMaxSize,
      ),
      SalesLiveMapMarkerVisual.bubble =>
        spec.detailLevel == SalesLiveMapMapDetail.states
            ? (
                _kSalesLiveMapStateBubbleMinSize,
                _kSalesLiveMapStateBubbleMaxSize,
              )
            : (_kSalesLiveMapBubbleMinSize, _kSalesLiveMapBubbleMaxSize),
      SalesLiveMapMarkerVisual.storeIcon => (
        _kSalesLiveMapStoreIconMinSize,
        _kSalesLiveMapStoreIconMaxSize,
      ),
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
      // Intentionally false: autoFocusSelectedStore: true triggers camera zoom
      // animation + layout shift simultaneously, causing Syncfusion to emit
      // dozens of viewport events that each rebuild snapshot data synchronously
      // and freeze the UI. Keep false until the Syncfusion rendering pipeline
      // is isolated from layout-shift on selection.
      autoFocusSelectedStore: false,
      enableProximityCluster: spec.enableProximityCluster,
    );
  }
}

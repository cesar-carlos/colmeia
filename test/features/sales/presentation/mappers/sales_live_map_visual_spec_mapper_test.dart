import 'package:colmeia/features/sales/domain/entities/sales_live_map_filter.dart';
import 'package:colmeia/features/sales/presentation/mappers/sales_live_map_visual_spec_mapper.dart';
import 'package:colmeia/features/sales/presentation/models/sales_live_map_visual_spec.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SalesLiveMapVisualSpecMapper', () {
    test('maps branches + dot to operational store markers', () {
      const spec = SalesLiveMapVisualSpec.operational();

      final style = SalesLiveMapVisualSpecMapper.toChartStyle(spec);

      expect(style.height, kSalesLiveMapOperationalHeight);
      expect(style.markerVisual, AppBrazilStoreSalesMarkerVisual.dot);
      expect(
        style.markerAggregation,
        AppBrazilStoreSalesMarkerAggregation.stores,
      );
      expect(style.markerMinSize, 10);
      expect(style.markerMaxSize, 24);
      expect(style.enableProximityCluster, isTrue);
      expect(style.enableZoomPan, isTrue);
      expect(style.showStoreDetail, isTrue);
      expect(style.showRegionFilter, isFalse);
      expect(style.autoFocusSelectedStore, isFalse);
      expect(
        style.selectedMarkerDetailPlacement,
        AppBrazilStoreSalesSelectedMarkerDetailPlacement.overlay,
      );
    });

    test('maps municipalities + bubble with municipality tooltip budget', () {
      const spec = SalesLiveMapVisualSpec.operational(
        detailLevel: SalesLiveMapMapDetail.municipalities,
        markerVisual: SalesLiveMapMarkerVisual.bubble,
      );

      final style = SalesLiveMapVisualSpecMapper.toChartStyle(spec);

      expect(style.markerVisual, AppBrazilStoreSalesMarkerVisual.bubble);
      expect(
        style.markerAggregation,
        AppBrazilStoreSalesMarkerAggregation.municipalities,
      );
      expect(style.markerMinSize, 34);
      expect(style.markerMaxSize, 82);
      expect(style.maxClusterTooltipStores, 8);
      expect(style.enableProximityCluster, isFalse);
    });

    test('forces state maps to bubble visual and disables store detail', () {
      const spec = SalesLiveMapVisualSpec.operational(
        detailLevel: SalesLiveMapMapDetail.states,
        markerVisual: SalesLiveMapMarkerVisual.storeIcon,
      );

      final style = SalesLiveMapVisualSpecMapper.toChartStyle(spec);

      expect(style.markerVisual, AppBrazilStoreSalesMarkerVisual.bubble);
      expect(
        style.markerAggregation,
        AppBrazilStoreSalesMarkerAggregation.states,
      );
      expect(style.markerMinSize, 30);
      expect(style.markerMaxSize, 76);
      expect(style.showStoreDetail, isFalse);
      expect(style.enableProximityCluster, isFalse);
    });
  });
}

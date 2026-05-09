import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppBrazilStoreSalesMapPreset', () {
    test('builds expected standard style', () {
      final style = AppBrazilStoreSalesMapPreset.standard.style(
        height: 520,
        enableProximityCluster: true,
      );

      expect(style.height, 520);
      expect(style.enableProximityCluster, isTrue);
      expect(style.markerVisual, AppBrazilStoreSalesMarkerVisual.dot);
      expect(
        style.markerAggregation,
        AppBrazilStoreSalesMarkerAggregation.stores,
      );
      expect(
        style.stateLabelMode,
        AppBrazilStoreSalesStateLabelMode.responsive,
      );
    });

    test('builds expected state bubble style', () {
      final style = AppBrazilStoreSalesMapPreset.stateBubbles.style(
        height: 430,
        showMarkerScaleLegend: false,
      );

      expect(style.height, 430);
      expect(style.showMarkerScaleLegend, isFalse);
      expect(style.showStoreDetail, isFalse);
      expect(style.markerVisual, AppBrazilStoreSalesMarkerVisual.bubble);
      expect(
        style.markerAggregation,
        AppBrazilStoreSalesMarkerAggregation.states,
      );
    });
  });

  group('AppBrazilStoreSalesMapStyle.copyWith', () {
    test('keeps existing values when overrides are omitted', () {
      const style = AppBrazilStoreSalesMapStyle.bubble(
        height: 500,
        showStoreDetail: false,
        showMarkerScaleLegend: false,
      );

      final copied = style.copyWith();

      expect(copied.height, style.height);
      expect(copied.showStoreDetail, style.showStoreDetail);
      expect(copied.showMarkerScaleLegend, style.showMarkerScaleLegend);
      expect(copied.markerVisual, style.markerVisual);
      expect(copied.markerAggregation, style.markerAggregation);
      expect(copied.markerMinSize, style.markerMinSize);
      expect(copied.markerMaxSize, style.markerMaxSize);
    });

    test('applies provided overrides', () {
      const style = AppBrazilStoreSalesMapStyle.standard();

      final copied = style.copyWith(
        height: 360,
        showLegend: false,
        markerAggregation: AppBrazilStoreSalesMarkerAggregation.storesAndStates,
        markerMaxSize: 44,
      );

      expect(copied.height, 360);
      expect(copied.showLegend, isFalse);
      expect(
        copied.markerAggregation,
        AppBrazilStoreSalesMarkerAggregation.storesAndStates,
      );
      expect(copied.markerMaxSize, 44);
      expect(copied.markerVisual, style.markerVisual);
    });
  });
}

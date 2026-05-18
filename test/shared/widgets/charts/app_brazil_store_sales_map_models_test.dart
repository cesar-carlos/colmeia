import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

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
        style.selectedMarkerDetailPlacement,
        AppBrazilStoreSalesSelectedMarkerDetailPlacement.overlay,
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

    test('builds expected municipality bubble style', () {
      final style = AppBrazilStoreSalesMapPreset.municipalityBubbles.style(
        height: 510,
        showMarkerScaleLegend: false,
      );

      expect(style.height, 510);
      expect(style.showMarkerScaleLegend, isFalse);
      expect(style.showStoreDetail, isTrue);
      expect(style.markerVisual, AppBrazilStoreSalesMarkerVisual.bubble);
      expect(
        style.markerAggregation,
        AppBrazilStoreSalesMarkerAggregation.municipalities,
      );
      expect(style.maxClusterTooltipStores, 8);
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
        selectedMarkerDetailPlacement:
            AppBrazilStoreSalesSelectedMarkerDetailPlacement.belowMap,
        markerMaxSize: 44,
      );

      expect(copied.height, 360);
      expect(copied.showLegend, isFalse);
      expect(
        copied.markerAggregation,
        AppBrazilStoreSalesMarkerAggregation.storesAndStates,
      );
      expect(
        copied.selectedMarkerDetailPlacement,
        AppBrazilStoreSalesSelectedMarkerDetailPlacement.belowMap,
      );
      expect(copied.markerMaxSize, 44);
      expect(copied.markerVisual, style.markerVisual);
    });

    test('allows clearing nullable visual overrides back to null', () {
      final style = const AppBrazilStoreSalesMapStyle.standard().copyWith(
        lowValueColor: const Color(0xFF123456),
        markerColor: const Color(0xFF654321),
        legendNumberFormat: NumberFormat.compact(),
      );

      final copied = style.copyWith(
        lowValueColor: null,
        markerColor: null,
        legendNumberFormat: null,
      );

      expect(copied.lowValueColor, isNull);
      expect(copied.markerColor, isNull);
      expect(copied.legendNumberFormat, isNull);
    });
  });

  group('AppBrazilStoreSalesMapStyle equality', () {
    test('compares structurally equivalent styles', () {
      const first = AppBrazilStoreSalesMapStyle(
        height: 560,
        markerVisual: AppBrazilStoreSalesMarkerVisual.bubble,
        markerAggregation: AppBrazilStoreSalesMarkerAggregation.municipalities,
      );
      const second = AppBrazilStoreSalesMapStyle(
        height: 560,
        markerVisual: AppBrazilStoreSalesMarkerVisual.bubble,
        markerAggregation: AppBrazilStoreSalesMarkerAggregation.municipalities,
      );

      expect(first, second);
      expect(first.hashCode, second.hashCode);
    });
  });
}

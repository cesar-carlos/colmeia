import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_models.dart';
import 'package:colmeia/shared/widgets/charts/brazil_map_chart_chrome.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BrazilMapChartChrome.resolve', () {
    test('enables inline operational floating controls', () {
      const style = AppBrazilStoreSalesMapStyle(
        
      );

      final chrome = BrazilMapChartChrome.resolve(
        style: style,
        presentationMode: AppBrazilStoreSalesMapPresentationMode.inlineOperational,
        useCleanFullscreenChrome: false,
        showDesktopBranchSidebar: false,
      );

      expect(chrome.usesInlineOperationalChrome, isTrue);
      expect(chrome.usesCleanFullscreenChrome, isFalse);
      expect(chrome.usesFloatingMapControls, isTrue);
      expect(chrome.showsFloatingMetricSelector, isTrue);
      expect(chrome.showsFloatingScopeSelector, isTrue);
      expect(chrome.effectiveShowLegend, isFalse);
      expect(chrome.effectiveShowMarkerScaleLegend, isFalse);
      expect(chrome.includeVisibleBranchListItems, isFalse);
    });

    test('hides legend and branch list in clean fullscreen mode', () {
      const style = AppBrazilStoreSalesMapStyle(
        
      );

      final chrome = BrazilMapChartChrome.resolve(
        style: style,
        presentationMode: AppBrazilStoreSalesMapPresentationMode.cleanFullscreen,
        useCleanFullscreenChrome: false,
        showDesktopBranchSidebar: true,
      );

      expect(chrome.usesCleanFullscreenChrome, isTrue);
      expect(chrome.effectiveShowLegend, isFalse);
      expect(chrome.showsFloatingMetricSelector, isTrue);
      expect(chrome.includeVisibleBranchListItems, isTrue);
    });

    test('keeps standard legend visibility outside inline and clean modes', () {
      const style = AppBrazilStoreSalesMapStyle(
        showMetricSelector: false,
        showRegionFilter: false,
      );

      final chrome = BrazilMapChartChrome.resolve(
        style: style,
        presentationMode: AppBrazilStoreSalesMapPresentationMode.standard,
        useCleanFullscreenChrome: false,
        showDesktopBranchSidebar: false,
      );

      expect(chrome.usesFloatingMapControls, isFalse);
      expect(chrome.effectiveShowLegend, isTrue);
      expect(chrome.effectiveShowMarkerScaleLegend, isTrue);
      expect(chrome.showsFloatingMetricSelector, isFalse);
    });

    test('maps overlay placement to below-map detail on Windows', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      const style = AppBrazilStoreSalesMapStyle(
        
      );

      final chrome = BrazilMapChartChrome.resolve(
        style: style,
        presentationMode: AppBrazilStoreSalesMapPresentationMode.standard,
        useCleanFullscreenChrome: false,
        showDesktopBranchSidebar: false,
      );

      expect(chrome.useWindowsSafeMarkerDetails, isTrue);
      expect(chrome.showBelowMapMarkerDetail, isTrue);
    });

    test('keeps overlay detail off below-map path on non-Windows platforms', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      const style = AppBrazilStoreSalesMapStyle(
        
      );

      final chrome = BrazilMapChartChrome.resolve(
        style: style,
        presentationMode: AppBrazilStoreSalesMapPresentationMode.standard,
        useCleanFullscreenChrome: false,
        showDesktopBranchSidebar: false,
      );

      expect(chrome.useWindowsSafeMarkerDetails, isFalse);
      expect(chrome.showBelowMapMarkerDetail, isFalse);
    });
  });
}

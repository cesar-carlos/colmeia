import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_models.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Presentation-mode derived flags for the Brazil store-sales map, computed
/// purely from widget configuration (no [BuildContext]). Context-dependent
/// decisions (e.g. compact branch sheet on mobile) use layout helpers.
@immutable
class BrazilMapChartChrome {
  const BrazilMapChartChrome({
    required this.usesInlineOperationalChrome,
    required this.usesCleanFullscreenChrome,
    required this.includeVisibleBranchListItems,
    required this.showsFloatingMetricSelector,
    required this.showsFloatingScopeSelector,
    required this.effectiveShowLegend,
    required this.effectiveShowMarkerScaleLegend,
    required this.effectiveShowDataQualityNotice,
    required this.useWindowsSafeMarkerDetails,
    required this.showBelowMapMarkerDetail,
  });

  factory BrazilMapChartChrome.resolve({
    required AppBrazilStoreSalesMapStyle style,
    required AppBrazilStoreSalesMapPresentationMode presentationMode,
    required bool useCleanFullscreenChrome,
    required bool showDesktopBranchSidebar,
  }) {
    final usesInline =
        presentationMode ==
        AppBrazilStoreSalesMapPresentationMode.inlineOperational;
    final usesClean =
        presentationMode ==
            AppBrazilStoreSalesMapPresentationMode.cleanFullscreen ||
        useCleanFullscreenChrome;
    final usesFloating = usesInline || usesClean;
    return BrazilMapChartChrome(
      usesInlineOperationalChrome: usesInline,
      usesCleanFullscreenChrome: usesClean,
      includeVisibleBranchListItems: showDesktopBranchSidebar,
      showsFloatingMetricSelector:
          usesFloating &&
          style.showMetricSelector &&
          AppBrazilStoreSalesMapMetric.values.length > 1,
      showsFloatingScopeSelector: usesFloating && style.showRegionFilter,
      effectiveShowLegend: style.showLegend && !usesClean && !usesInline,
      effectiveShowMarkerScaleLegend:
          style.showMarkerScaleLegend && !usesInline,
      effectiveShowDataQualityNotice: style.showDataQualityNotice,
      useWindowsSafeMarkerDetails:
          defaultTargetPlatform == TargetPlatform.windows,
      showBelowMapMarkerDetail:
          style.showStoreDetail &&
          (style.selectedMarkerDetailPlacement ==
                  AppBrazilStoreSalesSelectedMarkerDetailPlacement.belowMap ||
              (defaultTargetPlatform == TargetPlatform.windows &&
                  style.selectedMarkerDetailPlacement ==
                      AppBrazilStoreSalesSelectedMarkerDetailPlacement
                          .overlay)),
    );
  }

  final bool usesInlineOperationalChrome;
  final bool usesCleanFullscreenChrome;
  final bool includeVisibleBranchListItems;
  final bool showsFloatingMetricSelector;
  final bool showsFloatingScopeSelector;
  final bool effectiveShowLegend;
  final bool effectiveShowMarkerScaleLegend;
  final bool effectiveShowDataQualityNotice;
  final bool useWindowsSafeMarkerDetails;
  final bool showBelowMapMarkerDetail;

  bool get usesFloatingMapControls =>
      usesInlineOperationalChrome || usesCleanFullscreenChrome;
}

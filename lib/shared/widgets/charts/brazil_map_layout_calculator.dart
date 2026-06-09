import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_data.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_models.dart';
import 'package:colmeia/shared/widgets/charts/brazil_map_chart_chrome.dart';
import 'package:colmeia/shared/widgets/charts/brazil_map_chart_visual_snapshot.dart';
import 'package:colmeia/shared/widgets/charts/brazil_map_layout_constants.dart';
import 'package:flutter/material.dart';

/// Pure(ish) layout geometry for the Brazil store-sales map tile: resolves the
/// map height by deducting header/footer reserves from the available space.
class BrazilMapLayoutCalculator {
  const BrazilMapLayoutCalculator({
    required this.chrome,
    required this.style,
  });

  final BrazilMapChartChrome chrome;
  final AppBrazilStoreSalesMapStyle style;

  /// When the parent supplies a finite max height, the map column uses [Expanded]
  /// and below-map selection detail uses its intrinsic height. Fixed footer
  /// reserves for those details would leave empty space under the detail bar.
  static bool usesBoundedVerticalLayout(BoxConstraints constraints) {
    final maxHeight = constraints.maxHeight;
    return maxHeight.isFinite && maxHeight < double.infinity;
  }

  /// Small shrink of the map tile when height is bounded: real layout (labels,
  /// chips, legend padding) can exceed our header/footer estimates by a few
  /// logical pixels and cause a [Column] overflow.
  static const double _boundedSafetyPx =
      BrazilMapLayoutConstants.boundedLayoutSafetyPx;
  static const double _cleanFullscreenExtraSafetyPx =
      BrazilMapLayoutConstants.cleanFullscreenExtraSafetyPx;
  static const double _inlineOperationalExtraMapHeight =
      BrazilMapLayoutConstants.inlineOperationalExtraMapHeight;

  double mapTileHeight({
    required BuildContext context,
    required BoxConstraints constraints,
    required BrazilMapChartVisualSnapshot snapshot,
    required bool usesCompactMapChrome,
    AppBrazilStoreSalesPoint? detailPoint,
    AppBrazilStoreSalesMarkerGroup? detailGroup,
    bool reserveBelowMapSelectionDetail = true,
  }) {
    final requested = _effectiveRequestedHeight(style.height);
    final maxParent = constraints.maxHeight;
    if (!maxParent.isFinite || maxParent >= double.infinity) {
      return requested;
    }

    return regionMapStyleHeightForMapArea(
      context: context,
      mapAreaHeight: mapAreaHeight(
        context: context,
        constraints: constraints,
        snapshot: snapshot,
        usesCompactMapChrome: usesCompactMapChrome,
        detailPoint: detailPoint,
        detailGroup: detailGroup,
        reserveBelowMapSelectionDetail: reserveBelowMapSelectionDetail,
      ),
    );
  }

  /// Syncfusion map tile height for a fixed vertical area that may also contain
  /// in-chart metric/scope controls above the tile.
  double regionMapStyleHeightForMapArea({
    required BuildContext context,
    required double mapAreaHeight,
  }) {
    final headerReserve = _headerReserve(context);
    return (mapAreaHeight - headerReserve).clamp(
      BrazilMapLayoutConstants.regionMapMinHeight,
      BrazilMapLayoutConstants.regionMapMaxHeight,
    );
  }

  /// Vertical space for the full region map chart column (controls + tile).
  double mapAreaHeight({
    required BuildContext context,
    required BoxConstraints constraints,
    required BrazilMapChartVisualSnapshot snapshot,
    required bool usesCompactMapChrome,
    AppBrazilStoreSalesPoint? detailPoint,
    AppBrazilStoreSalesMarkerGroup? detailGroup,
    AppBrazilStoreSalesStateBucket? detailStateBucket,
    bool reserveBelowMapSelectionDetail = true,
  }) {
    final maxParent = constraints.maxHeight;
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final footerReserve = _footerReserve(
      context: context,
      snapshot: snapshot,
      tokens: tokens,
      maxWidth: constraints.maxWidth,
      usesCompactMapChrome: usesCompactMapChrome,
      detailPoint: detailPoint,
      detailGroup: detailGroup,
      detailStateBucket: detailStateBucket,
      reserveBelowMapSelectionDetail: reserveBelowMapSelectionDetail,
    );
    final spare = maxParent - footerReserve;
    if (!spare.isFinite) {
      return _effectiveRequestedHeight(style.height);
    }
    final safetyPx =
        _boundedSafetyPx +
        (chrome.usesCleanFullscreenChrome ? _cleanFullscreenExtraSafetyPx : 0);
    return (spare - safetyPx).clamp(
      BrazilMapLayoutConstants.regionMapMinHeight,
      BrazilMapLayoutConstants.regionMapMaxHeight,
    );
  }

  double _effectiveRequestedHeight(double requestedHeight) {
    if (chrome.usesInlineOperationalChrome) {
      return requestedHeight + _inlineOperationalExtraMapHeight;
    }
    return requestedHeight;
  }

  double _headerReserve(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final scaler = MediaQuery.textScalerOf(context);
    final textTheme = Theme.of(context).textTheme;
    final overlineBlock = chrome.usesCleanFullscreenChrome
        ? scaler.scale((textTheme.bodySmall?.fontSize ?? 12) * 1.25 + 6)
        : scaler.scale((textTheme.labelSmall?.fontSize ?? 11) * 1.3) +
              tokens.gapXs +
              scaler.scale((textTheme.bodySmall?.fontSize ?? 12) * 1.35 + 8);
    var reserve = 0.0;
    if (!chrome.showsFloatingMetricSelector &&
        style.showMetricSelector &&
        AppBrazilStoreSalesMapMetric.values.length > 1) {
      reserve +=
          overlineBlock +
          (chrome.usesCleanFullscreenChrome ? tokens.gapXs : tokens.gapMd);
    }
    if (!chrome.showsFloatingScopeSelector && style.showRegionFilter) {
      reserve +=
          overlineBlock +
          (chrome.usesCleanFullscreenChrome ? tokens.gapXs : tokens.gapMd);
    }
    return reserve.clamp(0.0, BrazilMapLayoutConstants.headerReserveMax);
  }

  double _footerReserve({
    required BuildContext context,
    required BrazilMapChartVisualSnapshot snapshot,
    required AppThemeTokens tokens,
    required double maxWidth,
    required bool usesCompactMapChrome,
    AppBrazilStoreSalesPoint? detailPoint,
    AppBrazilStoreSalesMarkerGroup? detailGroup,
    AppBrazilStoreSalesStateBucket? detailStateBucket,
    bool reserveBelowMapSelectionDetail = true,
  }) {
    final scaler = MediaQuery.textScalerOf(context);
    var reserve = 0.0;
    if (style.showDataQualityNotice &&
        snapshot.diagnostics.hasDiscardedPoints) {
      reserve +=
          tokens.gapSm +
          scaler.scale(BrazilMapLayoutConstants.dataQualityNoticeReserve);
    }
    if (chrome.effectiveShowMarkerScaleLegend && snapshot.hasMarkers) {
      final compactLegend = shouldUseCompactMarkerLegend(
        usesCompactMapChrome: usesCompactMapChrome,
        maxWidth: maxWidth,
      );
      reserve +=
          tokens.gapMd +
          scaler.scale(
            compactLegend
                ? BrazilMapLayoutConstants.markerLegendCompactReserve
                : BrazilMapLayoutConstants.markerLegendStandardReserve,
          );
    }
    if (reserveBelowMapSelectionDetail) {
      final selectedMarkerGroup = detailGroup ?? snapshot.selectedMarkerGroup;
      final selectedPoint = detailPoint ?? snapshot.selectedPoint;
      if (chrome.showBelowMapMarkerDetail &&
          selectedMarkerGroup != null &&
          (selectedMarkerGroup.isMunicipalityAggregate ||
              selectedMarkerGroup.isCluster)) {
        reserve +=
            tokens.gapMd +
            scaler.scale(BrazilMapLayoutConstants.belowMapClusterDetailReserve);
      } else if (chrome.showBelowMapMarkerDetail && selectedPoint != null) {
        reserve +=
            tokens.gapMd +
            scaler.scale(
              BrazilMapLayoutConstants.belowMapSingleStoreDetailReserve,
            );
      }
      if (selectedPoint == null &&
          selectedMarkerGroup == null &&
          detailStateBucket != null) {
        reserve +=
            tokens.gapMd +
            scaler.scale(BrazilMapLayoutConstants.belowMapStateDetailReserve);
      }
    }
    return reserve;
  }

  bool shouldUseCompactMarkerLegend({
    required bool usesCompactMapChrome,
    required double maxWidth,
  }) {
    return usesCompactMapChrome ||
        (maxWidth.isFinite &&
            maxWidth < BrazilMapLayoutConstants.compactMarkerLegendMaxWidth);
  }

  double floatingMapControlsHeight(
    BuildContext context, {
    required bool cleanMode,
  }) {
    final scaler = MediaQuery.textScalerOf(context);
    var height = 0.0;
    if (chrome.showsFloatingMetricSelector) {
      height += scaler.scale(
        cleanMode
            ? BrazilMapLayoutConstants.floatingMetricSelectorHeightClean
            : BrazilMapLayoutConstants.floatingMetricSelectorHeightStandard,
      );
    }
    if (chrome.showsFloatingScopeSelector) {
      if (height > 0) {
        height += cleanMode
            ? BrazilMapLayoutConstants.floatingMapOverlayGap
            : BrazilMapLayoutConstants.floatingScopeSelectorGapStandard;
      }
      height += scaler.scale(
        cleanMode
            ? BrazilMapLayoutConstants.floatingScopeSelectorHeightClean
            : BrazilMapLayoutConstants.floatingScopeSelectorHeightStandard,
      );
    }
    return height;
  }
}

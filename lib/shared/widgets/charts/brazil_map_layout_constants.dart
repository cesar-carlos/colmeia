/// Layout and interaction constants for the Brazil store-sales map module.
abstract final class BrazilMapLayoutConstants {
  static const double regionMapMinHeight = 200;
  static const double regionMapMaxHeight = 4000;
  static const double headerReserveMax = 260;

  static const double boundedLayoutSafetyPx = 6;
  static const double cleanFullscreenExtraSafetyPx = 14;
  static const double inlineOperationalExtraMapHeight = 116;

  static const double belowMapSingleStoreDetailReserve = 220;
  static const double belowMapClusterDetailReserve = 300;
  static const double belowMapStateDetailReserve = 96;

  static const double dataQualityNoticeReserve = 56;
  static const double markerLegendCompactReserve = 46;
  static const double markerLegendStandardReserve = 40;

  static const double compactMarkerLegendMaxWidth = 420;

  static const double floatingMapOverlayGap = 8;
  static const double floatingMapOverlaySurfaceRadius = 16;
  static const double floatingMapControlsTopInset = 12;
  static const double floatingMapControlsLeftInset = 12;

  static const double floatingMetricSelectorHeightClean = 48;
  static const double floatingMetricSelectorHeightStandard = 56;
  static const double floatingScopeSelectorHeightClean = 50;
  static const double floatingScopeSelectorHeightStandard = 58;
  static const double floatingScopeSelectorGapStandard = 10;

  static const double desktopSidebarMinHeight = 240;
  static const double desktopSidebarBottomInset = 24;
  static const double desktopSidebarProportionalCapFactor = 0.9;

  /// Width below which compact UF labels are used instead of full state names
  /// when the map is in a bounded-height layout.
  static const double compactStateLabelsMaxWidth = 900;

  /// Internal padding of the floating control surface (segmented control /
  /// scope chip container) and cluster count badge circles. Smaller than any
  /// token gap intentionally — the surface needs only a thin halo to visually
  /// separate the control from the material edge.
  static const double tightInternalPadding = 3;

  /// Minimum delta before applying a debounced viewport clustering sample.
  static const double viewportClusterZoomEpsilon = 0.25;

  /// Minimum delta before re-applying a programmatic preferred viewport.
  static const double preferredViewportZoomEpsilon = 0.001;

  /// Minimum delta (degrees) before re-centering the map on a store.
  static const double preferredViewportCenterEpsilon = 0.0001;
}

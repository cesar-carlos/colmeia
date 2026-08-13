/// Visual density presets for hub navigation cards and their responsive grids.
enum AppHubNavigationCardDensity {
  /// Full hub tiles (e.g. sales hub) with large icon and aspect-ratio sizing.
  standard,

  /// Home/overview chart navigation (~98px tiles, icon above label).
  overview,

  /// In-feature chart switcher (sales trend; compact vertical tiles).
  chartNav,
}

/// Default minimum width for hub navigation cards in responsive grids.
const double kAppHubNavigationCardMinWidth = 104;

/// Minimum height for overview chart navigation tiles.
const double kAppHubNavigationOverviewCardMinHeight = 98;

/// Minimum height for in-feature chart navigation tiles (sales trend).
const double kAppHubNavigationChartNavCardMinHeight = 60;

/// Default aspect ratio for standard-density hub cards (sales hub).
const double kAppHubNavigationStandardCardAspectRatio = 1.08;

/// Vertical gap between icon and label on chart-nav tiles.
const double kAppHubNavigationChartNavIconLabelGap = 2;

/// Extra width (px) above [kAppHubNavigationCardMinWidth] before narrow label style drops.
const double kAppHubNavigationNarrowLabelWidthThreshold = 4;

/// Narrow-label font size for overview and standard grid tiles.
const double kAppHubNavigationNarrowLabelFontSizeDefault = 10.5;

/// Narrow-label font size for chart-nav grid tiles.
const double kAppHubNavigationNarrowLabelFontSizeChartNav = 11.5;

extension AppHubNavigationCardDensityGridMetrics
    on AppHubNavigationCardDensity {
  double get gridMinCardWidth => kAppHubNavigationCardMinWidth;

  double? get gridMinCardHeight => switch (this) {
    AppHubNavigationCardDensity.standard => null,
    AppHubNavigationCardDensity.overview =>
      kAppHubNavigationOverviewCardMinHeight,
    AppHubNavigationCardDensity.chartNav =>
      kAppHubNavigationChartNavCardMinHeight,
  };
}

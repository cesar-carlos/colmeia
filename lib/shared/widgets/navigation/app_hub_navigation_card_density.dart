/// Visual density presets for hub navigation cards and their responsive grids.
enum AppHubNavigationCardDensity {
  /// Full hub tiles (e.g. sales hub) with large icon and aspect-ratio sizing.
  standard,

  /// Home/overview chart navigation (~90px tiles, icon above label).
  overview,

  /// In-feature chart switcher (sales trend; compact horizontal tiles).
  chartNav,
}

/// Default minimum width for hub navigation cards in responsive grids.
const double kAppHubNavigationCardMinWidth = 104;

/// Minimum height for overview chart navigation tiles.
const double kAppHubNavigationOverviewCardMinHeight = 90;

/// Minimum height for in-feature chart navigation tiles (sales trend).
const double kAppHubNavigationChartNavCardMinHeight = 38;

extension AppHubNavigationCardDensityGridMetrics on AppHubNavigationCardDensity {
  double get gridMinCardWidth => kAppHubNavigationCardMinWidth;

  double? get gridMinCardHeight => switch (this) {
        AppHubNavigationCardDensity.standard => null,
        AppHubNavigationCardDensity.overview =>
          kAppHubNavigationOverviewCardMinHeight,
        AppHubNavigationCardDensity.chartNav =>
          kAppHubNavigationChartNavCardMinHeight,
      };
}

enum AppChartEngine {
  syncfusion,
  flChart,
  graphic,
}

enum AppChartUseCase {
  dashboardTimeSeries,
  compactKpi,
  analyticComposition,
}

extension AppChartEngineMatrix on AppChartUseCase {
  AppChartEngine get preferredEngine => switch (this) {
    AppChartUseCase.dashboardTimeSeries => AppChartEngine.syncfusion,
    AppChartUseCase.compactKpi => AppChartEngine.flChart,
    AppChartUseCase.analyticComposition => AppChartEngine.graphic,
  };
}

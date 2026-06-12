/// Scroll behavior tokens shared across dashboard and chart-heavy lists.
abstract final class AppScrollTokens {
  /// Off-screen paint cache for long dashboard lists with multiple charts.
  ///
  /// Keeps chart sections mounted while scrolling so Syncfusion surfaces do
  /// not pay a full rebuild when re-entering the viewport.
  static const double chartDashboardListCacheExtent = 5000;
}

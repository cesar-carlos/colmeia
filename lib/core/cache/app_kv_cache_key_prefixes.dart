/// Logical key prefixes for app cache entries from local datasources.
///
/// TTL and invalidation remain owned by repositories and use cases.
abstract final class AppKvCacheKeyPrefixes {
  static const String dashboardOverview = 'dashboard_overview_';
  static const String reportsOverview = 'reports_overview_';
  static const String reportDetail = 'report_detail_';
  static const String reportDetailFilters = 'report_detail_filters_';
}

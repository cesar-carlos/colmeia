/// Logical key prefixes for app cache entries from local datasources.
///
/// TTL and invalidation remain owned by repositories and use cases.
abstract final class AppKvCacheKeyPrefixes {
  static const String dashboardOverview = 'dashboard_overview_';
}

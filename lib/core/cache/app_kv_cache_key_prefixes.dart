/// Logical key prefixes for app cache entries from local datasources.
///
/// TTL and invalidation remain owned by repositories and use cases.
abstract final class AppKvCacheKeyPrefixes {
  static const String dashboardOverview = 'dashboard_overview_';
  static const String clientAgentsCatalog = 'client_agents_catalog_';
  static const String clientAgentsApproved = 'client_agents_approved_';
  static const String clientAgentsRequests = 'client_agents_requests_';
  static const String clientAgentsDetail = 'client_agents_detail_';
  static const String clientAgentsPendingActions = 'client_agents_pending_';
  static const String clientAgentsOnline = 'client_agents_online_';
}

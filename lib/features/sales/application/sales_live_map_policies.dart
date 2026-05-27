import 'package:colmeia/features/sales/application/ports/sales_live_map_catalog_cache.dart';

/// Tunables for `LoadSalesLiveMapUseCase` and its collaborators.
///
/// Centralizes timeouts, concurrency, default catalog scope and cache limits
/// so the use case body stays focused on orchestration and tests can override
/// each tunable explicitly.
abstract final class SalesLiveMapPolicies {
  static const int bridgeTimeoutMs = 120000;
  static const int geolocationMaxConcurrency = 6;
  static const int primaryCompanyCode = 1;
  static const int primaryBranchCode = 1;
  static const int branchLocationCacheMaxEntries = 5000;
  static const int branchCatalogCacheMaxEntries = 200;
  static const Duration branchLocationCacheTtl = Duration(minutes: 10);
  static const Duration branchCatalogCacheTtl = SalesLiveMapCatalogCache.ttl;
}

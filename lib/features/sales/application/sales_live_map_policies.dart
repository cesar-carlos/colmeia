import 'package:colmeia/features/sales/application/ports/sales_live_map_catalog_cache.dart';

/// Tunables for `LoadSalesLiveMapUseCase` and its collaborators.
///
/// Centralizes timeouts, concurrency, default catalog scope and cache limits
/// so the use case body stays focused on orchestration and tests can override
/// each tunable explicitly.
abstract final class SalesLiveMapPolicies {
  static const int bridgeTimeoutMs = 120000;
  static const int geolocationMaxConcurrency = 6;

  /// Default `(cod_empresa, cod_filial)` of the "primary" branch used by the
  /// live map aggregator to filter out non-primary rows.
  ///
  /// **Assumption**: every Colmeia tenant we ship to today follows the
  /// Se7e default schema where `cod_empresa = 1` and `cod_filial = 1`
  /// identifies the primary branch each agent reports for. If a future
  /// tenant uses different codes the live map will silently show no rows
  /// from that tenant. When that becomes a real case, plumb these values
  /// through `AppEnvironment` (or per-agent metadata returned by the
  /// resolver) and inject them into `SalesLiveMapBranchAggregator` instead
  /// of consuming the static constants directly.
  static const int primaryCompanyCode = 1;
  static const int primaryBranchCode = 1;

  static const int branchLocationCacheMaxEntries = 5000;
  static const int branchCatalogCacheMaxEntries = 200;
  static const Duration branchLocationCacheTtl = Duration(minutes: 10);
  static const Duration branchCatalogCacheTtl = SalesLiveMapCatalogCache.ttl;
}

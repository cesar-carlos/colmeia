import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/features/sales/application/ports/sales_live_map_catalog_cache.dart';

/// Tunables for `LoadSalesLiveMapUseCase` and its collaborators.
///
/// Centralizes timeouts, concurrency, default catalog scope and cache limits
/// so the use case body stays focused on orchestration and tests can override
/// each tunable explicitly.
abstract final class SalesLiveMapPolicies {
  /// Bridge wait for period sales SQL and catalog loads.
  ///
  /// Uses [AppEnvironment.salesLiveMapBridgeTimeoutMs], which falls back to
  /// [AppEnvironment.agentSqlBridgeMediumTimeoutMs] when
  /// `SALES_LIVE_MAP_BRIDGE_TIMEOUT_MS` is unset.
  static int get bridgeTimeoutMs => AppEnvironment.salesLiveMapBridgeTimeoutMs;

  /// Concurrent geolocation lookups during map load. Override via
  /// `SALES_LIVE_MAP_GEOLOCATION_MAX_CONCURRENCY` (default 8).
  static int get geolocationMaxConcurrency =>
      AppEnvironment.salesLiveMapGeolocationMaxConcurrency;

  /// `(cod_empresa, cod_filial)` of the "primary" branch used by the live map
  /// aggregator. Defaults to `1/1`; override via `AppEnvironment`.
  static int get primaryCompanyCode =>
      AppEnvironment.salesLiveMapPrimaryCompanyCode;

  static int get primaryBranchCode => AppEnvironment.salesLiveMapPrimaryBranchCode;

  static const int branchLocationCacheMaxEntries = 5000;
  static const int branchCatalogCacheMaxEntries = 200;
  static const Duration branchLocationCacheTtl = Duration(minutes: 10);
  static const Duration branchCatalogCacheTtl = SalesLiveMapCatalogCache.ttl;
}

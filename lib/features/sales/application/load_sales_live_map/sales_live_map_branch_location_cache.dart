import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_branch_aggregate.dart';
import 'package:colmeia/features/sales/application/sales_live_map_point_factory.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_point.dart';

/// Snapshot of a previously resolved branch location, keyed by the
/// `sourceSignature` that produced it. Used to skip re-geocoding when the
/// same branch comes back from sales/catalog with unchanged location
/// signals.
class SalesLiveMapCachedBranchLocation {
  const SalesLiveMapCachedBranchLocation({
    required this.sourceSignature,
    required this.cachedAt,
    required this.resolved,
    this.uf,
    this.latitude,
    this.longitude,
    this.municipalityCode,
    this.city,
    this.locationResolution,
  });

  factory SalesLiveMapCachedBranchLocation.fromResolved({
    required String sourceSignature,
    required DateTime cachedAt,
    required SalesLiveMapResolvedPoint resolved,
  }) {
    final point = resolved.point;
    return SalesLiveMapCachedBranchLocation(
      sourceSignature: sourceSignature,
      cachedAt: cachedAt,
      resolved: true,
      uf: point.uf,
      latitude: point.latitude,
      longitude: point.longitude,
      municipalityCode: point.municipalityCode,
      city: point.city,
      locationResolution: point.locationResolution,
    );
  }

  const SalesLiveMapCachedBranchLocation.unresolved({
    required this.sourceSignature,
    required this.cachedAt,
  }) : resolved = false,
       uf = null,
       latitude = null,
       longitude = null,
       municipalityCode = null,
       city = null,
       locationResolution = null;

  final String sourceSignature;
  final DateTime cachedAt;
  final bool resolved;
  final String? uf;
  final double? latitude;
  final double? longitude;
  final String? municipalityCode;
  final String? city;
  final SalesLiveMapLocationResolution? locationResolution;

  bool isExpired(DateTime now, {required Duration ttl}) {
    return now.difference(cachedAt) > ttl;
  }

  /// Materializes the cached location together with [aggregate]'s sales data
  /// into a `SalesLiveMapPoint`. Returns `null` when this entry is marked
  /// `unresolved` (cached negative result).
  SalesLiveMapPoint? toPoint(
    SalesLiveMapBranchAggregate aggregate, {
    required SalesLiveMapPointFactory pointFactory,
  }) {
    final resolvedUf = uf;
    final resolvedLatitude = latitude;
    final resolvedLongitude = longitude;
    if (!resolved ||
        resolvedUf == null ||
        resolvedLatitude == null ||
        resolvedLongitude == null) {
      return null;
    }

    return pointFactory.createPoint(
      id: aggregate.id,
      name: aggregate.name,
      uf: resolvedUf,
      latitude: resolvedLatitude,
      longitude: resolvedLongitude,
      salesAmount: aggregate.totalVenda,
      salesCount: aggregate.qtdVendas,
      municipalityCode: municipalityCode,
      city: city,
      fantasyName: salesLiveMapTrimmedOrNull(aggregate.nomeFantasiaFilial),
      branchName: salesLiveMapTrimmedOrNull(aggregate.nomeFilial),
      companyCode: aggregate.codEmpresa,
      branchCode: aggregate.codFilial,
      agentName: salesLiveMapTrimmedOrNull(aggregate.agentName),
      salesDataLoading: aggregate.salesDataLoading,
      salesDataUnavailable: aggregate.salesDataUnavailable,
      salesDataStatusLabel: salesLiveMapTrimmedOrNull(
        aggregate.salesDataStatusLabel,
      ),
      locationResolution: locationResolution,
      subtitle: null,
      payload: aggregate,
    );
  }
}

/// In-memory cache of resolved/unresolved branch locations keyed by the
/// aggregate id. Entries expire after [ttl] and are invalidated when the
/// `locationSourceSignature` of an aggregate changes (i.e. the branch row
/// reported different geo signals).
///
/// Mirrors the shape of `SalesLiveMapInMemoryCatalogCache` to keep cache
/// semantics consistent across the use case.
class SalesLiveMapBranchLocationCache {
  SalesLiveMapBranchLocationCache({
    required this.maxEntries,
    required this.ttl,
  });

  final int maxEntries;
  final Duration ttl;
  final Map<String, SalesLiveMapCachedBranchLocation> _entries =
      <String, SalesLiveMapCachedBranchLocation>{};

  /// Returns the cached location for [aggregate] when one exists, is still
  /// fresh and was produced from the same `locationSourceSignature`. Stale
  /// or signature-mismatched entries are evicted on access. Successful reads
  /// promote the entry to the most-recent position so eviction follows true
  /// LRU semantics (last touched, not last written).
  SalesLiveMapCachedBranchLocation? read(
    SalesLiveMapBranchAggregate aggregate, {
    required DateTime now,
  }) {
    final cached = _entries[aggregate.id];
    if (cached == null) {
      return null;
    }
    if (cached.isExpired(now, ttl: ttl) ||
        cached.sourceSignature != aggregate.locationSourceSignature) {
      _entries.remove(aggregate.id);
      return null;
    }
    _entries
      ..remove(aggregate.id)
      ..[aggregate.id] = cached;
    return cached;
  }

  /// Stores [location] as the latest cached snapshot for [aggregate].
  /// Existing entries for the same id are replaced (preserving recency).
  void write(
    SalesLiveMapBranchAggregate aggregate,
    SalesLiveMapCachedBranchLocation location,
  ) {
    _entries.remove(aggregate.id);
    _entries[aggregate.id] = location;
    while (_entries.length > maxEntries) {
      _entries.remove(_entries.keys.first);
    }
  }
}

import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_branch_aggregate.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_branch_location_cache.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_diagnostics_logger.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_load_cancel_token.dart';
import 'package:colmeia/features/sales/application/sales_live_map_point_factory.dart';
import 'package:colmeia/features/sales/domain/contracts/sales_live_map_point_resolver.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_point.dart';

/// Outcome of a single [SalesLiveMapGeolocator.resolveBranchPoints] call.
/// Carries the resolved point list and the underlying cache / resolver
/// counters so the use case can fold them into the refresh metric.
class SalesLiveMapGeolocationResult {
  const SalesLiveMapGeolocationResult({
    this.points = const <SalesLiveMapPoint>[],
    this.cacheHitCount = 0,
    this.cacheMissCount = 0,
    this.cacheUnresolvedHitCount = 0,
    this.resolvedAndCachedCount = 0,
    this.unresolvedAndCachedCount = 0,
    this.partialGeoReuseCount = 0,
    this.cancelled = false,
  });

  final List<SalesLiveMapPoint> points;
  final int cacheHitCount;
  final int cacheMissCount;
  final int cacheUnresolvedHitCount;
  final int resolvedAndCachedCount;
  final int unresolvedAndCachedCount;
  final int partialGeoReuseCount;
  final bool cancelled;
}

/// Resolves geographic coordinates for the branches surfaced by a live
/// map load.
///
/// Coordinates the in-memory [SalesLiveMapBranchLocationCache], the
/// [SalesLiveMapPointResolver] (which itself bridges to the geocoders)
/// and a per-load partial-geo snapshot used to keep partial emissions
/// stable while sales data is still in flight.
///
/// Extracted from `LoadSalesLiveMapUseCase` so the geolocation flow can
/// be unit-tested and reasoned about without pulling in the SQL bridge
/// or the report aggregator.
class SalesLiveMapGeolocator {
  SalesLiveMapGeolocator({
    required SalesLiveMapBranchLocationCache locationCache,
    required SalesLiveMapPointResolver pointResolver,
    required SalesLiveMapPointFactory pointFactory,
    required SalesLiveMapDiagnosticsLogger diagnosticsLogger,
    required int maxConcurrency,
  }) : _locationCache = locationCache,
       _pointResolver = pointResolver,
       _pointFactory = pointFactory,
       _diagnosticsLogger = diagnosticsLogger,
       _maxConcurrency = maxConcurrency;

  final SalesLiveMapBranchLocationCache _locationCache;
  final SalesLiveMapPointResolver _pointResolver;
  final SalesLiveMapPointFactory _pointFactory;
  final SalesLiveMapDiagnosticsLogger _diagnosticsLogger;
  final int _maxConcurrency;

  final Map<String, String> _partialLocationSignatureByBranchId =
      <String, String>{};
  final Map<String, SalesLiveMapPoint> _partialGeoPointsByBranchId =
      <String, SalesLiveMapPoint>{};

  /// Clears the partial-geo snapshot so a new progressive load starts
  /// without inheriting the previous run's pending points. Called once
  /// at the top of each `loadProgressive`.
  void resetPartialGeoSnapshot() {
    _partialLocationSignatureByBranchId.clear();
    _partialGeoPointsByBranchId.clear();
  }

  /// Records the partial geo snapshot captured while sales data was
  /// still pending so the next iteration can reuse stable points for the
  /// same branches (no flicker).
  void recordPartialGeoSnapshot({
    required Iterable<SalesLiveMapBranchAggregate> aggregates,
    required Iterable<SalesLiveMapPoint> points,
  }) {
    _partialLocationSignatureByBranchId
      ..clear()
      ..addEntries(
        aggregates.map(
          (aggregate) =>
              MapEntry(aggregate.id, aggregate.locationSourceSignature),
        ),
      );
    _partialGeoPointsByBranchId
      ..clear()
      ..addEntries(
        points.map((point) => MapEntry(point.id, point)),
      );
  }

  /// Resolves geographic points for [aggregates], honouring the cache
  /// hierarchy (partial snapshot → memory cache → remote resolver). When
  /// [allowPartialGeoReuse] is `true`, points captured by the previous
  /// pending emission for the same `locationSourceSignature` are reused
  /// verbatim and only re-stamped with the latest sales counters via the
  /// [SalesLiveMapPointFactory].
  Future<SalesLiveMapGeolocationResult> resolveBranchPoints(
    List<SalesLiveMapBranchAggregate> aggregates, {
    required DateTime refreshedAt,
    SalesLiveMapLoadCancelToken? cancelToken,
    bool allowPartialGeoReuse = false,
  }) async {
    if (aggregates.isEmpty) {
      return const SalesLiveMapGeolocationResult();
    }

    final pointsByIndex = List<SalesLiveMapPoint?>.filled(
      aggregates.length,
      null,
    );
    final pending = <({int index, SalesLiveMapBranchAggregate aggregate})>[];
    var cacheHitCount = 0;
    var cacheUnresolvedHitCount = 0;
    var partialGeoReuseCount = 0;

    for (var i = 0; i < aggregates.length; i++) {
      if (cancelToken?.isCancelled ?? false) {
        return const SalesLiveMapGeolocationResult(cancelled: true);
      }

      final aggregate = aggregates[i];
      if (allowPartialGeoReuse) {
        final prev = _partialGeoPointsByBranchId[aggregate.id];
        final prevSig = _partialLocationSignatureByBranchId[aggregate.id];
        if (prev != null &&
            prevSig != null &&
            prevSig == aggregate.locationSourceSignature) {
          pointsByIndex[i] = _mergePartialGeoIntoAggregate(prev, aggregate);
          partialGeoReuseCount += 1;
          continue;
        }
      }

      final cached = _locationCache.read(aggregate, now: refreshedAt);
      if (cached == null) {
        pending.add((index: i, aggregate: aggregate));
        continue;
      }

      if (cached.resolved) {
        cacheHitCount += 1;
        pointsByIndex[i] = cached.toPoint(
          aggregate,
          pointFactory: _pointFactory,
        );
      } else {
        cacheUnresolvedHitCount += 1;
      }
    }

    var resolvedAndCachedCount = 0;
    var unresolvedAndCachedCount = 0;
    if (pending.isNotEmpty) {
      final resolved = await _pointResolver.resolveAllWithDetails(
        pending.map((item) => item.aggregate.toPointSource(_pointFactory)),
        maxConcurrent: _concurrencyFor(pending.length),
      );
      if (cancelToken?.isCancelled ?? false) {
        return const SalesLiveMapGeolocationResult(cancelled: true);
      }

      final resolvedById = <String, SalesLiveMapResolvedPoint>{
        for (final item in resolved) item.point.id: item,
      };
      for (final item in pending) {
        final resolvedPoint = resolvedById[item.aggregate.id];
        if (resolvedPoint == null) {
          unresolvedAndCachedCount += 1;
          _locationCache.write(
            item.aggregate,
            SalesLiveMapCachedBranchLocation.unresolved(
              sourceSignature: item.aggregate.locationSourceSignature,
              cachedAt: refreshedAt,
            ),
          );
          _diagnosticsLogger.logBranchGeolocation(item.aggregate, null);
          continue;
        }

        resolvedAndCachedCount += 1;
        final cachedLocation = SalesLiveMapCachedBranchLocation.fromResolved(
          sourceSignature: item.aggregate.locationSourceSignature,
          cachedAt: refreshedAt,
          resolved: resolvedPoint,
        );
        _locationCache.write(item.aggregate, cachedLocation);
        pointsByIndex[item.index] = cachedLocation.toPoint(
          item.aggregate,
          pointFactory: _pointFactory,
        );
      }
    }

    return SalesLiveMapGeolocationResult(
      points: pointsByIndex.whereType<SalesLiveMapPoint>().toList(
        growable: false,
      ),
      cacheHitCount: cacheHitCount,
      cacheMissCount: pending.length,
      cacheUnresolvedHitCount: cacheUnresolvedHitCount,
      resolvedAndCachedCount: resolvedAndCachedCount,
      unresolvedAndCachedCount: unresolvedAndCachedCount,
      partialGeoReuseCount: partialGeoReuseCount,
    );
  }

  int _concurrencyFor(int branchCount) {
    if (branchCount <= 1) {
      return 1;
    }
    return branchCount < _maxConcurrency ? branchCount : _maxConcurrency;
  }

  SalesLiveMapPoint _mergePartialGeoIntoAggregate(
    SalesLiveMapPoint base,
    SalesLiveMapBranchAggregate aggregate,
  ) {
    return _pointFactory.mergeAggregateOntoResolvedBase(
      base: base,
      name: aggregate.name,
      salesAmount: aggregate.totalVenda,
      salesCount: aggregate.qtdVendas,
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
      subtitle:
          'Agente ${aggregate.agentName} - Empresa ${aggregate.codEmpresa} - Filial ${aggregate.codFilial}',
      payload: aggregate,
    );
  }
}

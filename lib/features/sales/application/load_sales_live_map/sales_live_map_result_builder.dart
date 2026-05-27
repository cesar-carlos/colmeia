import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_branch_aggregate.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_load_result.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_filter.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_point.dart';

/// Builders for the well-known `SalesLiveMapLoadResult` shapes emitted by
/// `LoadSalesLiveMapUseCase` outside the happy-path mapping: failed loads,
/// pending baselines and cancelled outcomes.
///
/// Also hosts the small derivations used to fill the final result:
/// unmapped branch options (catalog branches without a geo point) and the
/// distinct municipality count behind a mapped points list.
abstract final class SalesLiveMapResultBuilder {
  /// Empty result with `loadFailed = true` and the failure message attached.
  static SalesLiveMapLoadResult failed(
    AppFailure failure, {
    required DateTime refreshedAt,
  }) {
    return SalesLiveMapLoadResult(
      points: const <SalesLiveMapPoint>[],
      branchOptions: const <SalesLiveMapBranchOption>[],
      totalRevenue: 0,
      totalSalesCount: 0,
      totalBranchCount: 0,
      mappedBranchCount: 0,
      mappedMunicipalityCount: 0,
      queriedAgentCount: 0,
      plannedAgentCount: 0,
      failedAgentCount: 0,
      missingClientTokenAgentCount: 0,
      skippedOfflineAgentCount: 0,
      rowCapReachedAgentCount: 0,
      loadFailed: true,
      loadFailureMessage: failure.userMessage,
      refreshedAt: refreshedAt,
    );
  }

  /// Empty pending baseline emitted while sales data is still in-flight but
  /// the use case wants to surface that the load has begun.
  static SalesLiveMapLoadResult pendingBase({required DateTime refreshedAt}) {
    return SalesLiveMapLoadResult(
      points: const <SalesLiveMapPoint>[],
      branchOptions: const <SalesLiveMapBranchOption>[],
      totalRevenue: 0,
      totalSalesCount: 0,
      totalBranchCount: 0,
      mappedBranchCount: 0,
      mappedMunicipalityCount: 0,
      queriedAgentCount: 0,
      plannedAgentCount: 0,
      failedAgentCount: 0,
      missingClientTokenAgentCount: 0,
      skippedOfflineAgentCount: 0,
      rowCapReachedAgentCount: 0,
      salesDataPending: true,
      refreshedAt: refreshedAt,
    );
  }

  /// Empty result flagged as `cancelled = true`. Pure builder — callers that
  /// also want to log the cancellation should do so explicitly before or
  /// after yielding this result.
  static SalesLiveMapLoadResult cancelled({required DateTime refreshedAt}) {
    return SalesLiveMapLoadResult(
      points: const <SalesLiveMapPoint>[],
      branchOptions: const <SalesLiveMapBranchOption>[],
      totalRevenue: 0,
      totalSalesCount: 0,
      totalBranchCount: 0,
      mappedBranchCount: 0,
      mappedMunicipalityCount: 0,
      queriedAgentCount: 0,
      plannedAgentCount: 0,
      failedAgentCount: 0,
      missingClientTokenAgentCount: 0,
      skippedOfflineAgentCount: 0,
      rowCapReachedAgentCount: 0,
      refreshedAt: refreshedAt,
      cancelled: true,
    );
  }

  /// Branch options for branches that appear in [visibleAggregates] but have
  /// no matching `SalesLiveMapPoint` in [points] — i.e. catalog/sales rows
  /// without a resolved geo location.
  static List<SalesLiveMapBranchOption> unmappedBranchOptions({
    required List<SalesLiveMapBranchAggregate> visibleAggregates,
    required List<SalesLiveMapPoint> points,
  }) {
    final mappedBranchIds = points.map((point) => point.id).toSet();
    return visibleAggregates
        .where((aggregate) => !mappedBranchIds.contains(aggregate.id))
        .map((aggregate) => aggregate.toBranchOption())
        .toList(growable: false);
  }

  /// Distinct municipality count among [points]. Uses IBGE code when
  /// available, falls back to city/UF, and finally to lat/lng/UF.
  static int mappedMunicipalityCount(Iterable<SalesLiveMapPoint> points) {
    return points.map(_keyForPoint).toSet().length;
  }

  static String _keyForPoint(SalesLiveMapPoint point) {
    final municipalityCode = point.municipalityCode?.trim();
    if (municipalityCode != null && municipalityCode.isNotEmpty) {
      return 'ibge:${municipalityCode.toUpperCase()}';
    }

    final city = point.city?.trim();
    if (city != null && city.isNotEmpty) {
      return 'city:${city.toUpperCase()}:${point.uf.trim().toUpperCase()}';
    }

    return 'coordinate:${point.latitude}:${point.longitude}:${point.uf.trim().toUpperCase()}';
  }
}

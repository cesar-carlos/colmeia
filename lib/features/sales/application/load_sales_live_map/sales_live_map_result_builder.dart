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
    return _empty(
      refreshedAt: refreshedAt,
      loadFailed: true,
      loadFailure: failure,
    );
  }

  /// Empty pending baseline emitted while sales data is still in-flight but
  /// the use case wants to surface that the load has begun.
  static SalesLiveMapLoadResult pendingBase({required DateTime refreshedAt}) {
    return _empty(refreshedAt: refreshedAt, salesDataPending: true);
  }

  /// Empty result flagged as `cancelled = true`. Pure builder — callers that
  /// also want to log the cancellation should do so explicitly before or
  /// after yielding this result.
  static SalesLiveMapLoadResult cancelled({required DateTime refreshedAt}) {
    return _empty(refreshedAt: refreshedAt, cancelled: true);
  }

  /// Empty result for the "session expired" state surfaced by the
  /// controller when the user logs out while the map is open. Reuses the
  /// shared empty shape (with `loadFailed = true`) so the presentation
  /// layer can render the same error panel it uses for transport failures.
  static SalesLiveMapLoadResult sessionExpired({
    required DateTime refreshedAt,
  }) {
    return _empty(refreshedAt: refreshedAt, loadFailed: true);
  }

  /// Plain empty result — no flags set. Used by callers that already
  /// reported the load outcome separately (e.g. the use case mapping
  /// step when neither catalog nor sales reports were available).
  static SalesLiveMapLoadResult empty({required DateTime refreshedAt}) {
    return _empty(refreshedAt: refreshedAt);
  }

  /// Single source of truth for "empty" `SalesLiveMapLoadResult` shapes
  /// shared by `failed` / `pendingBase` / `cancelled`. Keeps the counter
  /// zero defaults in one place so adding a new numeric field to
  /// `SalesLiveMapLoadResult` only requires updating this builder once.
  static SalesLiveMapLoadResult _empty({
    required DateTime refreshedAt,
    bool loadFailed = false,
    AppFailure? loadFailure,
    String? loadFailureMessage,
    bool salesDataPending = false,
    bool cancelled = false,
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
      loadFailed: loadFailed,
      loadFailure: loadFailure,
      loadFailureMessage: loadFailureMessage,
      salesDataPending: salesDataPending,
      cancelled: cancelled,
      refreshedAt: refreshedAt,
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

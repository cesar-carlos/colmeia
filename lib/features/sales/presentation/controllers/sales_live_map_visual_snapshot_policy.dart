import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/domain/agent_sql_rpc_failure_ui_key.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map_use_case.dart';
import 'package:colmeia/features/sales/presentation/mappers/sales_live_map_chart_mapper.dart';

/// Decides which `SalesLiveMapLoadResult` should be used as the visible map
/// snapshot when the use case emits a new partial/complete result, and
/// computes a stable digest over the map payload so the controller can skip
/// no-op state emissions.
///
/// Pure helpers — no state. The controller owns lifecycle and `setState`
/// flow; this policy isolates the rules around snapshot selection and
/// delta detection.
abstract final class SalesLiveMapVisualSnapshotPolicy {
  /// Returns the next visible snapshot:
  ///
  /// - The fresh [incomingResult] when it is either fully loaded
  ///   (`!salesDataPending`) or already carries some renderable data
  ///   (`points`/`branchOptions` non-empty);
  /// - Otherwise the [previousVisualResult] is kept on screen to avoid
  ///   flashing an empty map while sales data is in flight.
  static SalesLiveMapLoadResult? resolveNextVisualResult({
    required SalesLiveMapLoadResult incomingResult,
    required SalesLiveMapLoadResult? previousVisualResult,
  }) {
    if (_shouldUseAsSnapshot(
      incomingResult,
      previousVisualResult: previousVisualResult,
    )) {
      return incomingResult;
    }
    return previousVisualResult;
  }

  /// Merges [incomingResult] with geo fields from the best established
  /// snapshot when a progressive/catalog-shell emission would regress mapped
  /// coordinates while the visible map still carries resolved points.
  ///
  /// The controller stores this as `result` so attention-panel partial issues
  /// stay aligned with `visualResult.points`.
  static SalesLiveMapLoadResult resolveNextOperationalResult({
    required SalesLiveMapLoadResult incomingResult,
    required SalesLiveMapLoadResult? previousResult,
    required SalesLiveMapLoadResult? nextVisualResult,
  }) {
    if (isTransportTimeoutFailure(incomingResult.loadFailure)) {
      final geoSource = nextVisualResult ?? previousResult;
      if (geoSource != null && geoSource.mappedBranchCount > 0) {
        return withPreservedGeoFields(
          operational: incomingResult,
          geo: geoSource,
        );
      }
    }
    final geoSource = _geoPreservationSource(
      incoming: incomingResult,
      previous: previousResult,
      visual: nextVisualResult,
    );
    if (geoSource == null) {
      return incomingResult;
    }
    return withPreservedGeoFields(
      operational: incomingResult,
      geo: geoSource,
    );
  }

  /// True when [incoming] would drop mapped coordinates that [preservedVisual]
  /// already exposes on screen. Used to ignore late catalog-shell emissions
  /// during auto-refresh while a preserved visual snapshot is active.
  static bool isRegressiveGeoEmission({
    required SalesLiveMapLoadResult incoming,
    required SalesLiveMapLoadResult preservedVisual,
  }) {
    return regressesMappedGeo(incoming, preservedVisual);
  }

  /// Copies geo-related fields from [geo] onto [operational] while keeping
  /// sales/catalog counters and agent diagnostics from [operational].
  static SalesLiveMapLoadResult withPreservedGeoFields({
    required SalesLiveMapLoadResult operational,
    required SalesLiveMapLoadResult geo,
  }) {
    return SalesLiveMapLoadResult(
      points: geo.points,
      branchOptions: operational.branchOptions,
      unmappedBranchOptions: geo.unmappedBranchOptions,
      totalRevenue: operational.totalRevenue,
      totalSalesCount: operational.totalSalesCount,
      totalBranchCount: operational.totalBranchCount,
      mappedBranchCount: geo.mappedBranchCount,
      mappedMunicipalityCount: geo.mappedMunicipalityCount,
      queriedAgentCount: operational.queriedAgentCount,
      plannedAgentCount: operational.plannedAgentCount,
      failedAgentCount: operational.failedAgentCount,
      missingClientTokenAgentCount: operational.missingClientTokenAgentCount,
      skippedOfflineAgentCount: operational.skippedOfflineAgentCount,
      rowCapReachedAgentCount: operational.rowCapReachedAgentCount,
      refreshedAt: operational.refreshedAt,
      paginationStalledAgentCount: operational.paginationStalledAgentCount,
      salesAgentCount: operational.salesAgentCount,
      catalogBranchCount: operational.catalogBranchCount,
      salesBranchCount: operational.salesBranchCount,
      zeroedBranchCount: operational.zeroedBranchCount,
      noSalesBranchCount: operational.noSalesBranchCount,
      salesUnavailableBranchCount: operational.salesUnavailableBranchCount,
      salesDataPending: operational.salesDataPending,
      salesPendingBranchCount: operational.salesPendingBranchCount,
      failedCatalogAgentCount: operational.failedCatalogAgentCount,
      failedSalesAgentCount: operational.failedSalesAgentCount,
      noSalesAgentOptions: operational.noSalesAgentOptions,
      failedAgentOptions: operational.failedAgentOptions,
      missingClientTokenAgentOptions: operational.missingClientTokenAgentOptions,
      skippedOfflineAgentOptions: operational.skippedOfflineAgentOptions,
      locationDiagnostics: geo.locationDiagnostics,
      loadFailed: operational.loadFailed,
      loadFailureReason: operational.loadFailureReason,
      loadFailure: operational.loadFailure,
      loadFailureMessage: operational.loadFailureMessage,
      cancelled: operational.cancelled,
      partialGeoReuseCount: geo.partialGeoReuseCount,
      hubPresenceOnlineAgentIdsSnapshot:
          operational.hubPresenceOnlineAgentIdsSnapshot,
      agentQueryFailures: operational.agentQueryFailures,
    );
  }

  /// Stable digest of the map payload (points list) inside [visualResult].
  /// Used by the controller to detect that nothing visible changed and skip
  /// emitting redundant state updates. Returns `0` when there is no visual
  /// result yet.
  static int payloadDigestFor(SalesLiveMapLoadResult? visualResult) {
    if (visualResult == null) {
      return 0;
    }
    return SalesLiveMapChartMapper.pointsContentDigest(visualResult.points);
  }

  /// True when [next] would change something the page actually renders
  /// compared to [previous]. Compares the map payload digest, the cached
  /// visual snapshot identity, and the status flags (`salesDataPending`,
  /// `loadFailed`, `refreshedAt`).
  ///
  /// Callers use this to skip `setState` when only a stable retry passed
  /// through the use case stream without surfacing new data.
  static bool hasObservableDelta({
    required SalesLiveMapLoadResult previous,
    required SalesLiveMapLoadResult next,
    required SalesLiveMapLoadResult? previousVisualResult,
    required SalesLiveMapLoadResult? nextVisualResult,
    required int previousDigest,
    required int nextDigest,
  }) {
    if (previousDigest != nextDigest) {
      return true;
    }
    if (!identical(previousVisualResult, nextVisualResult)) {
      return true;
    }
    if (previous.salesDataPending != next.salesDataPending) {
      return true;
    }
    if (previous.loadFailed != next.loadFailed) {
      return true;
    }
    if (previous.hasPartialIssue != next.hasPartialIssue) {
      return true;
    }
    if (previous.refreshedAt != next.refreshedAt) {
      return true;
    }
    return false;
  }

  /// True when [failure] is a bridge transport timeout (refresh should keep
  /// the last good map snapshot and surface the error as a banner only).
  static bool isTransportTimeoutFailure(AppFailure? failure) {
    if (failure == null) {
      return false;
    }
    return failure.context[AgentSqlRpcFailureUiKey.field] ==
        AgentSqlRpcFailureUiKey.transportTimeout;
  }

  static bool _shouldUseAsSnapshot(
    SalesLiveMapLoadResult result, {
    SalesLiveMapLoadResult? previousVisualResult,
  }) {
    if (result.loadFailed) {
      return false;
    }
    if (!result.salesDataPending) {
      if (regressesMappedGeo(result, previousVisualResult)) {
        return false;
      }
      return true;
    }
    if (regressesMappedGeo(result, previousVisualResult)) {
      return false;
    }
    return result.points.isNotEmpty || result.branchOptions.isNotEmpty;
  }

  static bool regressesMappedGeo(
    SalesLiveMapLoadResult incoming,
    SalesLiveMapLoadResult? established,
  ) {
    if (established == null || established.mappedBranchCount <= 0) {
      return false;
    }
    return incoming.mappedBranchCount < established.mappedBranchCount ||
        (incoming.points.isEmpty && established.points.isNotEmpty);
  }

  static SalesLiveMapLoadResult? _geoPreservationSource({
    required SalesLiveMapLoadResult incoming,
    required SalesLiveMapLoadResult? previous,
    required SalesLiveMapLoadResult? visual,
  }) {
    if (!regressesMappedGeo(incoming, visual ?? previous)) {
      return null;
    }
    if (visual != null && visual.mappedBranchCount > 0) {
      return visual;
    }
    if (previous != null && previous.mappedBranchCount > 0) {
      return previous;
    }
    return null;
  }
}

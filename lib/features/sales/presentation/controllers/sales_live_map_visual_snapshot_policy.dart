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
    if (_shouldUseAsSnapshot(incomingResult)) {
      return incomingResult;
    }
    return previousVisualResult;
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

  static bool _shouldUseAsSnapshot(SalesLiveMapLoadResult result) {
    if (result.loadFailed) {
      return false;
    }
    if (!result.salesDataPending) {
      return true;
    }
    return result.points.isNotEmpty || result.branchOptions.isNotEmpty;
  }
}

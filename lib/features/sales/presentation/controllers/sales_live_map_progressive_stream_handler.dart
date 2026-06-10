import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_visual_snapshot_policy.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map_use_case.dart';
import 'package:colmeia/features/sales/presentation/controllers/sales_live_map_reload_outcome.dart';
import 'package:colmeia/features/sales/presentation/state/sales_live_map_presentation_state.dart';
import 'package:colmeia/shared/filters/dashboard_filter.dart';

/// Context for a single progressive reload consumed by
/// [SalesLiveMapProgressiveStreamHandler].
class SalesLiveMapProgressiveStreamSession {
  const SalesLiveMapProgressiveStreamSession({
    required this.preservedVisualResult,
    required this.cancelToken,
    required this.isGenerationStale,
    required this.readState,
    required this.applyState,
    required this.clearActiveCancelTokenIfMatching,
    required this.onLoadResultReceived,
    required this.rehydrateAvailableAgents,
  });

  final SalesLiveMapLoadResult? preservedVisualResult;
  final SalesLiveMapLoadCancelToken cancelToken;
  final bool Function() isGenerationStale;
  final SalesLiveMapPresentationState Function() readState;
  final void Function(SalesLiveMapPresentationState nextState) applyState;
  final void Function() clearActiveCancelTokenIfMatching;
  final void Function(SalesLiveMapLoadResult result) onLoadResultReceived;
  final List<DashboardAgentOption>? Function(SalesLiveMapLoadResult result)
  rehydrateAvailableAgents;
}

/// Consumes progressive load emissions and applies visual-snapshot policy
/// during a controller reload.
class SalesLiveMapProgressiveStreamHandler {
  const SalesLiveMapProgressiveStreamHandler();

  Future<SalesLiveMapReloadOutcome> handle({
    required Stream<SalesLiveMapLoadResult> stream,
    required SalesLiveMapProgressiveStreamSession session,
  }) async {
    var emittedAnyResult = false;
    await for (final result in stream) {
      if (session.isGenerationStale()) {
        return SalesLiveMapReloadOutcome.superseded(session.readState().result);
      }
      emittedAnyResult = true;
      if (result.cancelled) {
        session.clearActiveCancelTokenIfMatching();
        session.applyState(session.readState().copyWith(isLoading: false));
        return SalesLiveMapReloadOutcome.cancelled(result);
      }

      final state = session.readState();
      final establishedVisualSnapshot =
          state.visualResult ?? session.preservedVisualResult;
      final softRefreshPreservesVisual =
          session.preservedVisualResult != null && result.salesDataPending;
      if (establishedVisualSnapshot != null &&
          SalesLiveMapVisualSnapshotPolicy.isRegressiveGeoEmission(
            incoming: result,
            preservedVisual: establishedVisualSnapshot,
          ) &&
          !softRefreshPreservesVisual) {
        continue;
      }

      final previousResult = state.result;
      final nextVisualResult = softRefreshPreservesVisual
          ? establishedVisualSnapshot
          : SalesLiveMapVisualSnapshotPolicy.resolveNextVisualResult(
              incomingResult: result,
              previousVisualResult: state.visualResult,
            );
      final nextResult =
          SalesLiveMapVisualSnapshotPolicy.resolveNextOperationalResult(
            incomingResult: result,
            previousResult: previousResult,
            nextVisualResult: nextVisualResult,
          );
      final nextMapPayloadDigest =
          SalesLiveMapVisualSnapshotPolicy.payloadDigestFor(nextVisualResult);
      if (previousResult != null &&
          !SalesLiveMapVisualSnapshotPolicy.hasObservableDelta(
            previous: previousResult,
            next: nextResult,
            previousVisualResult: state.visualResult,
            nextVisualResult: nextVisualResult,
            previousDigest: state.mapPayloadDigest,
            nextDigest: nextMapPayloadDigest,
          )) {
        if (state.isLoading != nextResult.salesDataPending) {
          session.applyState(
            state.copyWith(isLoading: nextResult.salesDataPending),
          );
        }
        continue;
      }

      session.onLoadResultReceived(result);
      final nextAvailableAgents = session.rehydrateAvailableAgents(nextResult);
      session.applyState(
        state.copyWith(
          result: nextResult,
          visualResult: nextVisualResult,
          mapPayloadDigest: nextMapPayloadDigest,
          isLoading: nextResult.salesDataPending,
          sessionExpired: false,
          availableAgents: nextAvailableAgents ?? state.availableAgents,
        ),
      );
    }

    if (session.isGenerationStale()) {
      return SalesLiveMapReloadOutcome.superseded(session.readState().result);
    }
    session.clearActiveCancelTokenIfMatching();
    if (!emittedAnyResult) {
      session.applyState(session.readState().copyWith(isLoading: false));
    }
    return SalesLiveMapReloadOutcome.completed(session.readState().result);
  }
}

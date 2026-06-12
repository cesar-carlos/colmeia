part of '../app_brazil_store_sales_map_chart.dart';

class _BrazilMapSnapshotLifecycleCoordinator {
  _BrazilMapSnapshotLifecycleCoordinator(this._state);

  final _AppBrazilStoreSalesMapChartState _state;

  void scheduleConsumeCameraFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_state.mounted || !_state._selection.focusCameraOnSelectedStore) {
        return;
      }
      _state._runStateUpdate(_state._selection.consumeCameraFocus);
    });
  }

  void invalidateResolvedSnapshotData() {
    _state._snapshots.invalidateData();
    scheduleSnapshotRefresh();
  }

  void invalidateResolvedSnapshotVisual() {
    _state._snapshots.invalidateVisual();
    scheduleSnapshotRefresh();
  }

  void scheduleSnapshotRefresh() {
    if (_state._snapshotRefreshScheduled) {
      return;
    }
    _state._snapshotRefreshScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _state._snapshotRefreshScheduled = false;
      if (!_state.mounted) {
        return;
      }
      syncDisplaySnapshot(notify: true);
    });
  }

  void syncDisplaySnapshot({required bool notify}) {
    if (!_state.mounted) {
      return;
    }
    final snapshot = _state._snapshots.resolve(
      context: _state.context,
      input: snapshotBuildInput,
      selectedStoreId: _state._selectedStoreId,
      requestedStateKey: _state._selection.internalSelectedStateKey,
    );
    emitDiagnosticsIfNeeded(snapshot.diagnostics);
    if (identical(_state._displaySnapshot, snapshot)) {
      return;
    }
    _state._displaySnapshot = snapshot;
    if (notify) {
      _state._runStateUpdate(() {});
    }
  }

  BrazilMapSnapshotBuildInput get snapshotBuildInput =>
      BrazilMapSnapshotBuildInput(
        points: _state.widget.points,
        metric: _state._selectedMetric,
        activeRegionKey: _state._activeRegionKey,
        zoomLevel: _state._zoom.clusteringZoomLevel,
        style: _state.widget.style,
        fixedBranchIds: _state.widget.fixedBranchIds,
        filterBranchIds: _state.widget.filterBranchIds,
        includeVisibleBranchListItems: _state._includeVisibleBranchListItems,
      );

  void emitDiagnosticsIfNeeded(
    AppBrazilStoreSalesMapDiagnostics diagnostics,
  ) {
    final callback = _state.widget.onDiagnosticsChanged;
    if (callback == null || _state._lastEmittedDiagnostics == diagnostics) {
      return;
    }

    _state._lastEmittedDiagnostics = diagnostics;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_state.mounted) {
        return;
      }
      callback(diagnostics);
    });
  }
}

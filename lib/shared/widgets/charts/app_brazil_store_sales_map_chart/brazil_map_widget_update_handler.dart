part of '../app_brazil_store_sales_map_chart.dart';

class _BrazilMapWidgetUpdateHandler {
  _BrazilMapWidgetUpdateHandler(this._state);

  final _AppBrazilStoreSalesMapChartState _state;

  AppBrazilStoreSalesMapChart get _widget => _state.widget;

  BrazilMapSelectionPolicy get _selection => _state._selection;

  BrazilMapZoomController get _zoom => _state._zoom;

  BrazilMapViewportCoordinator get _viewport => _state._viewport;

  RegionMapViewportController get _viewportController =>
      _state._viewportController;

  BrazilMapMarkerSelectionController get _markerHighlight =>
      _state._markerHighlight;

  BrazilMapSnapshotController get _snapshots => _state._snapshots;

  _BrazilMapPointInteractionHandler get _pointInteraction =>
      _state._pointInteraction;

  void handleDidUpdateWidget(AppBrazilStoreSalesMapChart oldWidget) {
    _state._chrome = BrazilMapChartChrome.resolve(
      style: _widget.style,
      presentationMode: _widget.presentationMode,
      useCleanFullscreenChrome: _widget.useCleanFullscreenChrome,
      showDesktopBranchSidebar: _widget.showDesktopBranchSidebar,
    );
    if (oldWidget.initialMetric != _widget.initialMetric) {
      _state._selectedMetric = _widget.initialMetric;
      _state._invalidateResolvedSnapshotData();
    }

    if (oldWidget.selectedStoreId != _widget.selectedStoreId ||
        oldWidget.style != _widget.style) {
      if (_widget.selectedStoreId == null) {
        _viewportController.reset();
      } else if (!_widget.style.autoFocusSelectedStore) {
        _viewportController.withdrawPreferredViewportForStoreSelection();
      }
      _selection.syncControlledSelection(
        previousControlledId: oldWidget.selectedStoreId,
        nextControlledId: _widget.selectedStoreId,
        selectedStoreZoomLevel: _widget.style.selectedStoreZoomLevel,
        onAdoptControlledSelection: () {
          if (_widget.style.autoFocusSelectedStore) {
            _zoom.clusteringZoomLevel = _widget.style.selectedStoreZoomLevel;
          }
          _viewport.cancelPendingViewportClusterSampling();
        },
        onReleaseControlledSelection: () {
          if (oldWidget.style.autoFocusSelectedStore ||
              _widget.style.autoFocusSelectedStore) {
            _zoom.resetToBrazilDefault();
          }
          _viewport.cancelPendingViewportClusterSampling();
        },
      );
      if (oldWidget.style != _widget.style) {
        _state._invalidateResolvedSnapshotData();
      }
      if (_widget.selectedStoreId != null &&
          _widget.style.autoFocusSelectedStore &&
          _selection.focusCameraOnSelectedStore) {
        _state._scheduleConsumeCameraFocus();
      }
      _state._publishMarkerSelection();
    }

    if (oldWidget.filterBranchIds != _widget.filterBranchIds ||
        oldWidget.fixedBranchIds != _widget.fixedBranchIds) {
      _state._invalidateResolvedSnapshotData();
    }

    if (oldWidget.showDesktopBranchSidebar !=
            _widget.showDesktopBranchSidebar ||
        oldWidget.presentationMode != _widget.presentationMode ||
        oldWidget.useCleanFullscreenChrome !=
            _widget.useCleanFullscreenChrome) {
      if (!_widget.showDesktopBranchSidebar) {
        _state._desktopBranchSidebarCollapsed = false;
      }
      _state._invalidateResolvedSnapshotVisual();
    }

    if (oldWidget.style.markerAggregation != _widget.style.markerAggregation) {
      _viewport.resetManualViewport();
    }

    if (!identical(oldWidget.points, _widget.points)) {
      _snapshots.invalidatePointsDigestIfSourceChanged(_widget.points);
      _viewport.cachedPreferredViewport = null;
      final selectedStoreId = _selection.resolveSelectedStoreId(
        _widget.selectedStoreId,
      );
      if (selectedStoreId != null &&
          _pointInteraction.pointById(selectedStoreId) == null) {
        _selection.clearStoreSelection(
          controlledSelectedStoreId: _widget.selectedStoreId,
        );
        _markerHighlight.previewedStoreId = null;
        if (_widget.style.autoFocusSelectedStore) {
          _zoom.resetToBrazilDefault();
        }
        _viewport.cancelPendingViewportClusterSampling();
        _state._invalidateResolvedSnapshotData();
      }
    }

    final previewedStoreId = _markerHighlight.previewedStoreId;
    if (previewedStoreId != null &&
        (_pointInteraction.pointById(previewedStoreId) == null ||
            !_pointInteraction.pointMatchesActiveRegion(previewedStoreId))) {
      _markerHighlight.previewedStoreId = null;
    }

    if (_widget.lifecycleRecoveryRequestId > 0 &&
        oldWidget.lifecycleRecoveryRequestId !=
            _widget.lifecycleRecoveryRequestId) {
      _recoverAfterHiddenLifecycle();
    }
  }

  void _recoverAfterHiddenLifecycle() {
    _viewport.invalidatePreferredViewport();
    _state
      .._invalidateResolvedSnapshotData()
      .._publishMarkerSelection();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_state.mounted) {
        return;
      }
      _state._runStateUpdate(() {});
    });
  }
}

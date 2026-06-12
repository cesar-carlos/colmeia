part of '../app_brazil_store_sales_map_chart.dart';

class _BrazilMapViewportNavigationHandler {
  _BrazilMapViewportNavigationHandler(this._state);

  final _AppBrazilStoreSalesMapChartState _state;

  AppBrazilStoreSalesMapChart get _widget => _state.widget;

  BrazilMapSelectionPolicy get _selection => _state._selection;

  BrazilMapZoomController get _zoom => _state._zoom;

  BrazilMapViewportCoordinator get _viewport => _state._viewport;

  RegionMapViewportController get _viewportController =>
      _state._viewportController;

  BrazilMapMarkerSelectionController get _markerHighlight =>
      _state._markerHighlight;

  _BrazilMapPointInteractionHandler get _pointInteraction =>
      _state._pointInteraction;

  bool get _blocksViewportDrivenClustering =>
      _selection.blocksViewportDrivenClustering(_widget.selectedStoreId);

  String? get _selectedStoreId =>
      _selection.resolveSelectedStoreId(_widget.selectedStoreId);

  void handleRegionMapViewportChanged(AppMapViewportChangedEvent event) {
    final filtered = _viewport.filterViewportChangedEvent(
      event,
      blocksViewportDrivenClusteringOnWindows: _selection
          .blocksViewportDrivenClustering(_widget.selectedStoreId),
    );
    if (filtered == null) {
      return;
    }
    handleViewportChanged(filtered);
  }

  AppMapViewport? resolvePreferredViewportForBuild(
    BrazilMapChartVisualSnapshot snapshot,
  ) {
    return _viewport.preferredViewportForBuild(
      BrazilMapPreferredViewportRequest(
        userHasManualMapViewport: _viewport.userHasManualMapViewport,
        cachedBindingKey: _viewport.cachedPreferredViewportBinding,
        regionBindingKey: _viewport.regionBindingKey(_state._activeRegionKey),
        selectedStoreId: _selectedStoreId,
        selectedPoint:
            snapshot.selectedPoint ??
            _pointInteraction.pointById(_selectedStoreId),
        shouldFocusCameraOnSelectedStore: _selection
            .shouldFocusCameraOnSelectedStore(
              controlledSelectedStoreId: _widget.selectedStoreId,
              autoFocusSelectedStore: _widget.style.autoFocusSelectedStore,
            ),
        selectedStoreZoomLevel: _widget.style.selectedStoreZoomLevel,
        activeRegionKey: _state._activeRegionKey,
      ),
    );
  }

  AppMapViewport resetTargetViewportForScope() =>
      _viewport.resetTargetViewportForScope(_state._activeRegionKey);

  void handleResetViewport() {
    _state._runStateUpdate(() {
      _viewportController.reset();
      _viewport.resetManualViewport();
      _zoom.applyScopeZoom(resetTargetViewportForScope().zoomLevel);
    });
  }

  void handleMetricChanged(AppMapMetricChangedEvent event) {
    final metric = AppBrazilStoreSalesMapMetric.values.firstWhere(
      (candidate) => candidate.key == event.metricKey,
      orElse: () => _state._selectedMetric,
    );

    if (metric == _state._selectedMetric) {
      return;
    }

    _state._runStateUpdate(() {
      _state._selectedMetric = metric;
      _state._invalidateResolvedSnapshotData();
    });
    _widget.onMetricChanged?.call(metric);
  }

  void handleScopeChanged(AppMapScopeChangedEvent event) {
    _state._runStateUpdate(() {
      _viewportController.reset();
      _viewport.resetManualViewport();
      _state._activeRegionKey = event.currentScopeKey;
      _zoom.applyScopeZoom(
        (event.currentScopeKey == null
                ? AppBrazilMapStaticData.brazilViewport
                : AppBrazilMapStaticData.regionViewports[event.currentScopeKey])
            ?.zoomLevel,
      );
      _selection.clearStoreIfOutsideActiveRegion(
        activeRegionKey: _state._activeRegionKey,
        controlledSelectedStoreId: _widget.selectedStoreId,
        pointById: _pointInteraction.pointById,
      );
      if (!_pointInteraction.pointMatchesActiveRegion(
        _markerHighlight.previewedStoreId,
      )) {
        _markerHighlight.previewedStoreId = null;
      }
      _state
        .._publishMarkerSelection()
        .._invalidateResolvedSnapshotData();
    });
  }

  void handleStateTap(
    AppMapRegionTapEvent<AppBrazilStoreSalesStateBucket> event,
  ) {
    final preserveStoreSelection = _selection
        .shouldPreserveStoreSelectionForRegionTap(
          regionKey: event.regionKey,
          controlledSelectedStoreId: _widget.selectedStoreId,
          pointById: _pointInteraction.pointById,
        );
    if (_selection.shouldSkipRedundantRegionTap(
      regionKey: event.regionKey,
      preserveStoreSelection: preserveStoreSelection,
      controlledSelectedStoreId: _widget.selectedStoreId,
    )) {
      _widget.onStateTap?.call(event);
      return;
    }

    _state._runStateUpdate(() {
      _selection.applyRegionTap(
        regionKey: event.regionKey,
        preserveStoreSelection: preserveStoreSelection,
      );
      if (!preserveStoreSelection) {
        _markerHighlight.previewedStoreId = null;
        _viewportController.reset();
      }
      _state
        .._invalidateResolvedSnapshotVisual()
        .._publishMarkerSelection();
    });
    _widget.onStateTap?.call(event);
  }

  void handleViewportChanged(AppMapViewportChangedEvent event) {
    _viewport.handleViewportChanged(
      event: event,
      enableProximityCluster: _widget.style.enableProximityCluster,
      blocksViewportDrivenClustering: _blocksViewportDrivenClustering,
      enableZoomPan: _widget.style.enableZoomPan,
      zoom: _zoom,
      onMarkManualViewport: () {
        if (!_state.mounted) {
          return;
        }
        _state._runStateUpdate(() {
          _viewport.userHasManualMapViewport = true;
        });
      },
      shouldClearStoreDetailOnUserViewportChange:
          _widget.style.showStoreDetail &&
          _selectedStoreId != null &&
          !_markerHighlight.selectedDetailIsClusterOrMunicipality,
      onClearStoreDetail: _pointInteraction.clearSelectedMarkerDetail,
      onApplyClusterZoom: applyViewportClusterZoomLevel,
      pointCount: _widget.points.length,
      activeRegionKey: _state._activeRegionKey,
    );
  }

  void applyViewportClusterZoomLevel(double nextZoomLevel) {
    if (!_state.mounted) {
      return;
    }
    if (_blocksViewportDrivenClustering) {
      return;
    }
    if (!_zoom.shouldApplyViewportClusterSample(
      nextZoomLevel,
      blocksViewportDrivenClustering: _blocksViewportDrivenClustering,
    )) {
      return;
    }

    _state._runStateUpdate(() {
      _zoom.clusteringZoomLevel = nextZoomLevel;
      _state._invalidateResolvedSnapshotData();
    });
  }
}

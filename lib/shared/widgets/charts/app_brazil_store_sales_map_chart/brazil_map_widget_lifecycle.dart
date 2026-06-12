part of '../app_brazil_store_sales_map_chart.dart';

class _BrazilMapWidgetLifecycleCoordinator {
  _BrazilMapWidgetLifecycleCoordinator(this._state);

  final _AppBrazilStoreSalesMapChartState _state;

  bool _brazilShapeSourcePrecacheAttemptComplete =
      AppBrazilMapStaticData.brazilUfGeoJsonBytesOrNull != null;

  bool get isBrazilMapShapeSourceLoading =>
      !_brazilShapeSourcePrecacheAttemptComplete;

  void initialize() {
    _state._selectedMetric = _state.widget.initialMetric;
    _state._chrome = BrazilMapChartChrome.resolve(
      style: _state.widget.style,
      presentationMode: _state.widget.presentationMode,
      useCleanFullscreenChrome: _state.widget.useCleanFullscreenChrome,
      showDesktopBranchSidebar: _state.widget.showDesktopBranchSidebar,
    );
    _state._markerHighlight.publishWithControlledId(
      _state._selection,
      _state.widget.selectedStoreId,
    );
    AppBrazilMapStaticData.brazilUfGeoJsonReadiness.addListener(
      _handleBrazilUfGeoJsonReadinessChanged,
    );
    _state._markerSelection.addListener(_state._scheduleSnapshotRefresh);
    _startBrazilShapeSourcePrecacheIfNeeded();
    if (_state.widget.selectedStoreId != null &&
        _state.widget.style.autoFocusSelectedStore) {
      _state._selection.adoptControlledSelectionOnInit();
      _state._zoom.clusteringZoomLevel =
          _state.widget.style.selectedStoreZoomLevel;
      _state._scheduleConsumeCameraFocus();
    }
  }

  void dispose() {
    _state._markerSelection.removeListener(_state._scheduleSnapshotRefresh);
    AppBrazilMapStaticData.brazilUfGeoJsonReadiness.removeListener(
      _handleBrazilUfGeoJsonReadinessChanged,
    );
    _state._viewport.dispose();
    _state._markerHighlight.dispose();
  }

  void _handleBrazilUfGeoJsonReadinessChanged() {
    if (!_state.mounted) {
      return;
    }
    _state._runStateUpdate(() {});
  }

  void _startBrazilShapeSourcePrecacheIfNeeded() {
    if (_brazilShapeSourcePrecacheAttemptComplete) {
      return;
    }
    unawaited(
      AppBrazilMapStaticData.precacheBrazilUfGeoJsonAsset().whenComplete(() {
        if (!_state.mounted) {
          return;
        }
        _state._runStateUpdate(() {
          _brazilShapeSourcePrecacheAttemptComplete = true;
        });
      }),
    );
  }
}

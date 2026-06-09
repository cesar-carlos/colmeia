part of '../app_brazil_store_sales_map_chart.dart';

/// Handles marker and state-bubble tap flows for the Brazil store-sales map.
class _BrazilMapPointInteractionHandler {
  _BrazilMapPointInteractionHandler(this._state);

  final _AppBrazilStoreSalesMapChartState _state;

  AppBrazilStoreSalesMapChart get _widget => _state.widget;

  AppBrazilStoreSalesMapMetric get _selectedMetric => _state._selectedMetric;

  String? get _activeRegionKey => _state._activeRegionKey;

  BrazilMapSelectionPolicy get _selection => _state._selection;

  BrazilMapMarkerSelectionController get _markerHighlight =>
      _state._markerHighlight;

  BrazilMapViewportCoordinator get _viewport => _state._viewport;

  BrazilMapZoomController get _zoom => _state._zoom;

  RegionMapViewportController get _viewportController =>
      _state._viewportController;

  void handlePointTap(AppMapPointTapEvent event) {
    final payload = event.point.payload;
    if (payload is AppBrazilStoreSalesStateBubble) {
      handleStateBubbleTap(payload, event.index);
      return;
    }

    if (payload is! AppBrazilStoreSalesMarkerGroup) {
      return;
    }

    final point = payload.primaryPoint;
    final focusSelectedStore =
        !payload.isCluster && !payload.isMunicipalityAggregate;
    _markerHighlight.selectedDetailIsClusterOrMunicipality =
        payload.isCluster || payload.isMunicipalityAggregate;
    selectPoint(point, focusStore: focusSelectedStore);
    if (BrazilMapCompactBranchSheetLayout.shouldUse(
      showStoreDetail: _widget.style.showStoreDetail,
      maxWidth: MediaQuery.sizeOf(_state.context).width,
    )) {
      unawaited(
        openCompactBranchDetailSheet(
          group: payload,
          initialStoreId: point.id,
          markerIndex: event.index,
        ),
      );
    }

    if (payload.isMunicipalityAggregate) {
      _widget.onMunicipalityTap?.call(
        AppBrazilStoreSalesMunicipalityTapEvent(
          points: payload.points,
          index: event.index,
          metric: _selectedMetric,
          latitude: payload.latitude,
          longitude: payload.longitude,
          salesAmount: payload.salesAmount,
          salesCount: payload.salesCount,
        ),
      );
      return;
    }

    if (payload.isCluster) {
      _widget.onStoreClusterTap?.call(
        AppBrazilStoreSalesPointClusterTapEvent(
          points: payload.points,
          index: event.index,
          metric: _selectedMetric,
          latitude: payload.latitude,
          longitude: payload.longitude,
          salesAmount: payload.salesAmount,
          salesCount: payload.salesCount,
        ),
      );
      return;
    }

    emitStoreTap(point: point, index: event.index);
  }

  void selectPoint(
    AppBrazilStoreSalesPoint point, {
    bool focusStore = true,
  }) {
    _markerHighlight.cancelPendingPreviewClear();
    _viewport.cancelPendingViewportClusterSampling();
    final shouldAutoFocusStore =
        focusStore && _widget.style.autoFocusSelectedStore;

    if (!shouldAutoFocusStore) {
      _viewportController.withdrawPreferredViewportForStoreSelection();
      _selection.applyStoreSelection(
        point,
        focusStore: false,
        linkRegionHighlight: false,
      );
      _markerHighlight.previewedStoreId = null;
      _state._publishMarkerSelection();
      return;
    }

    _viewportController.reset();
    _state
      .._runStateUpdate(() {
        _selection.applyStoreSelection(
          point,
          focusStore: true,
        );
        _markerHighlight.previewedStoreId = null;
        _viewport.invalidatePreferredViewport();
        _zoom.clusteringZoomLevel = _widget.style.selectedStoreZoomLevel;
        _state._invalidateResolvedSnapshotData();
      })
      .._publishMarkerSelection()
      .._scheduleConsumeCameraFocus();
  }

  void emitStoreTap({
    required AppBrazilStoreSalesPoint point,
    required int index,
  }) {
    _widget.onStoreTap?.call(
      AppBrazilStoreSalesPointTapEvent(
        point: point,
        index: index,
        metric: _selectedMetric,
      ),
    );
  }

  int mapPointIndexFor(
    AppBrazilStoreSalesPoint point,
    BrazilMapChartVisualSnapshot snapshot,
  ) {
    final index = snapshot.mapPoints.indexWhere((mapPoint) {
      final payload = mapPoint.payload;
      return payload is AppBrazilStoreSalesMarkerGroup &&
          payload.points.any((groupPoint) => groupPoint.id == point.id);
    });
    return index < 0 ? 0 : index;
  }

  void handleMarkerBranchAction({
    required AppBrazilStoreSalesPoint point,
    required int index,
  }) {
    if (!_state.mounted) {
      return;
    }
    selectPoint(point);
    emitStoreTap(point: point, index: index);
  }

  Future<void> openCompactBranchDetailSheet({
    required AppBrazilStoreSalesMarkerGroup group,
    required String initialStoreId,
    required int markerIndex,
  }) async {
    final l10nContext = _state.context;
    await showModalBottomSheet<void>(
      context: l10nContext,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final tokens = Theme.of(sheetContext).extension<AppThemeTokens>()!;
        return Padding(
          padding: EdgeInsets.fromLTRB(
            tokens.gapMd,
            0,
            tokens.gapMd,
            tokens.gapMd,
          ),
          child: BrazilMapChartSelectedMarkerGroupDetailCard(
            group: group,
            metric: _selectedMetric,
            initialStoreId: initialStoreId,
            onDismiss: () => unawaited(Navigator.of(sheetContext).maybePop()),
            onClose: () => unawaited(Navigator.of(sheetContext).maybePop()),
            onClearSelection: () {
              clearSelectedMarkerDetail();
              unawaited(Navigator.of(sheetContext).maybePop());
            },
            onSelectBranch: (point) {
              unawaited(Navigator.of(sheetContext).maybePop());
              handleMarkerBranchAction(point: point, index: markerIndex);
            },
            selectBranchLabelBuilder: (_) => AppLocalizations.of(
              sheetContext,
            ).brazilStoreSalesMapShowBranchOnMapAction,
          ),
        );
      },
    );
  }

  void clearSelectedMarkerDetail() {
    _markerHighlight.cancelPendingPreviewClear();
    _viewportController.reset();
    _markerHighlight.selectedDetailIsClusterOrMunicipality = false;
    _state._runStateUpdate(() {
      _selection.clearStoreSelection(
        controlledSelectedStoreId: _widget.selectedStoreId,
      );
      _markerHighlight.previewedStoreId = null;
      _viewport.invalidatePreferredViewport();
      _state._publishMarkerSelection();
    });
  }

  void handleStateBubbleTap(
    AppBrazilStoreSalesStateBubble bubble,
    int index,
  ) {
    final bucket = bubble.bucket;
    _state._runStateUpdate(() {
      _viewportController.reset();
      _selection.clearStoreAndStateSelection();
      _markerHighlight.previewedStoreId = null;
      _selection.internalSelectedStateKey = bucket.uf;
      _state._publishMarkerSelection();
    });

    _widget.onStateTap?.call(
      AppMapRegionTapEvent<AppBrazilStoreSalesStateBucket>(
        item: bucket,
        regionKey: bucket.uf,
        regionLabel: _state._stateLabelFor(bucket),
        metricKey: _selectedMetric.key,
        metricValue: _selectedMetric.valueForBucket(bucket),
        index: index,
      ),
    );
  }

  AppBrazilStoreSalesPoint? pointById(String? selectedStoreId) {
    if (selectedStoreId == null) {
      return null;
    }

    for (final point in _widget.points) {
      if (point.id == selectedStoreId) {
        return point;
      }
    }

    return null;
  }

  bool pointMatchesActiveRegion(String? pointId) {
    final point = pointById(pointId);
    if (point == null) {
      return false;
    }
    return AppBrazilStoreSalesMapData.pointMatchesRegion(
      point,
      _activeRegionKey,
    );
  }

  void setPreviewedPoint(AppBrazilStoreSalesPoint point) {
    _markerHighlight.setPreviewedPoint(
      context: _state.context,
      point: point,
      selection: _selection,
      controlledSelectedStoreId: _widget.selectedStoreId,
      pointMatchesActiveRegion: pointMatchesActiveRegion,
      onChanged: () {
        if (!_state.mounted) {
          return;
        }
        _state._runStateUpdate(_state._publishMarkerSelection);
      },
    );
  }

  void clearPreviewedPoint() {
    _markerHighlight.clearPreviewedPoint(
      selection: _selection,
      controlledSelectedStoreId: _widget.selectedStoreId,
      onChanged: () {
        if (!_state.mounted) {
          return;
        }
        _state._runStateUpdate(_state._publishMarkerSelection);
      },
    );
  }
}

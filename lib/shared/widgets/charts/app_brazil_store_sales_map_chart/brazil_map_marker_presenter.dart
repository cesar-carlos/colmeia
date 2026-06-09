part of '../app_brazil_store_sales_map_chart.dart';

/// Builds map markers, tooltips, and marker chrome for the Brazil store-sales map.
class _BrazilMapMarkerPresenter {
  _BrazilMapMarkerPresenter(this._state);

  final _AppBrazilStoreSalesMapChartState _state;

  AppBrazilStoreSalesMapChart get _widget => _state.widget;

  BrazilMapChartChrome get _chrome => _state._chrome;

  AppBrazilStoreSalesMapMetric get _selectedMetric => _state._selectedMetric;

  Color markerColor(BuildContext context) {
    return _widget.style.markerColor ?? context.appColors.tertiary;
  }

  Color markerStrokeColor(BuildContext context) {
    return _widget.style.markerStrokeColor ??
        Theme.of(context).colorScheme.surface;
  }

  bool showOverlayMarkerDetail({required bool usesCompactBranchSheet}) =>
      _widget.style.showStoreDetail &&
      !usesCompactBranchSheet &&
      _widget.style.selectedMarkerDetailPlacement ==
          AppBrazilStoreSalesSelectedMarkerDetailPlacement.overlay &&
      !_chrome.useWindowsSafeMarkerDetails;

  bool showBelowMapMarkerDetail({required bool usesCompactBranchSheet}) =>
      _chrome.showBelowMapMarkerDetail && !usesCompactBranchSheet;

  Widget buildMarker(
    BuildContext context,
    AppMapPoint point,
    int index,
    BrazilMapMarkerSelection selection, {
    required bool usesCompactBranchSheet,
  }) {
    final payload = point.payload;
    if (payload is AppBrazilStoreSalesStateBubble) {
      final baseStyle = point.style ?? const AppMapMarkerStyle();
      return _StateBubbleMarker(
        bucket: payload.bucket,
        metric: _selectedMetric,
        style: resolveStateBubbleMarkerStyle(
          context,
          baseStyle,
          payload.bucket,
        ),
        semanticLabel: stateBubbleSemanticLabel(context, payload.bucket),
      );
    }

    final group = payload is AppBrazilStoreSalesMarkerGroup ? payload : null;
    final baseStyle = point.style ?? const AppMapMarkerStyle();
    final style = group == null
        ? baseStyle
        : resolveStoreGroupMarkerStyle(context, baseStyle, group, selection);
    final marker = _StoreMapMarker(
      key: ValueKey<String>('brazil-store-sales-map-marker-$index'),
      style: style,
      count: group?.points.length ?? 1,
      visual: _widget.style.markerVisual,
      semanticLabel: markerSemanticLabel(context, group),
    );
    final selectedStoreId = selection.selectedStoreId;
    final previewedStoreId = selection.previewedStoreId;
    final showDetailOverlay =
        showOverlayMarkerDetail(usesCompactBranchSheet: usesCompactBranchSheet) &&
        previewedStoreId == null &&
        group != null &&
        selectedStoreId != null &&
        group.points.any((point) => point.id == selectedStoreId);
    final showPreviewOverlay =
        !showDetailOverlay &&
        showOverlayMarkerDetail(usesCompactBranchSheet: usesCompactBranchSheet) &&
        group != null &&
        previewedStoreId != null &&
        group.points.any((point) => point.id == previewedStoreId);

    if (!showDetailOverlay && !showPreviewOverlay) {
      if (group == null ||
          !_widget.style.showTooltip ||
          _chrome.useWindowsSafeMarkerDetails) {
        return marker;
      }

      return AppBrazilStoreSalesBranchHoverDetailAnchor(
        group: group,
        metric: _selectedMetric,
        marker: marker,
      );
    }

    if (showPreviewOverlay && !_chrome.useWindowsSafeMarkerDetails) {
      return AppBrazilStoreSalesBranchHoverDetailAnchor(
        group: group,
        metric: _selectedMetric,
        marker: marker,
        forceVisible: true,
        initialStoreId: previewedStoreId,
      );
    }

    if (showDetailOverlay) {
      return AppBrazilStoreSalesSelectedMarkerDetailAnchor(
        group: group,
        selectedStoreId: selectedStoreId,
        metric: _selectedMetric,
        marker: marker,
        onClose: _state._pointInteraction.clearSelectedMarkerDetail,
        onClearSelection: _state._pointInteraction.clearSelectedMarkerDetail,
        onSelectBranch: (point) => _state._pointInteraction.handleMarkerBranchAction(
          point: point,
          index: index,
        ),
        selectBranchLabelBuilder: (_) => AppLocalizations.of(
          context,
        ).brazilStoreSalesMapShowBranchOnMapAction,
      );
    }

    return marker;
  }

  Widget buildMarkerTooltip(
    BuildContext context,
    AppMapPoint point,
    int index,
  ) {
    if ((point.tooltip == null || point.tooltip!.isEmpty) &&
        (point.label == null || point.label!.isEmpty)) {
      return const SizedBox.shrink();
    }

    final payload = point.payload;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final maxWidth = (screenWidth - 32).clamp(260.0, 360.0);

    final Widget child;
    if (payload is AppBrazilStoreSalesMarkerGroup) {
      child = payload.isCluster || payload.isMunicipalityAggregate
          ? _SelectedMarkerGroupDetailCard(
              group: payload,
              metric: _selectedMetric,
            )
          : _SelectedMarkerStoreDetailCard(
              point: payload.primaryPoint,
              metric: _selectedMetric,
              showTechnicalLocationDetails: false,
            );
    } else if (payload is AppBrazilStoreSalesStateBubble) {
      child = _StateBubbleTooltipCard(
        bucket: payload.bucket,
        metric: _selectedMetric,
      );
    } else {
      final text = point.tooltip ?? point.label;
      child = text == null || text.isEmpty
          ? const SizedBox.shrink()
          : _PlainMapTooltipCard(text: text);
    }

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    );
  }

  Widget buildBelowMapSelectionDetail({
    required BuildContext context,
    required BrazilMapChartVisualSnapshot snapshot,
    required BrazilMapMarkerSelection selection,
    required bool usesCompactBranchSheet,
  }) {
    final markerDetail = BrazilMapMarkerSelectionController
        .resolveMarkerDetailSelection(
      snapshot,
      selection,
      _state._pointInteraction.pointById,
    );
    final selectedPoint = markerDetail.point;
    final selectedMarkerGroup = markerDetail.group;
    final selectedStateBucket =
        BrazilMapMarkerSelectionController.resolveSelectedStateBucket(
      snapshot,
      selection,
    );

    if (showBelowMapMarkerDetail(usesCompactBranchSheet: usesCompactBranchSheet) &&
        selectedMarkerGroup != null &&
        (selectedMarkerGroup.isMunicipalityAggregate ||
            selectedMarkerGroup.isCluster)) {
      return _SelectedMunicipalityDetail(
        group: selectedMarkerGroup,
        metric: _selectedMetric,
        selectedStoreId: selection.selectedStoreId,
        onSelectBranch: (point) => _state._pointInteraction.handleMarkerBranchAction(
          point: point,
          index: _state._pointInteraction.mapPointIndexFor(point, snapshot),
        ),
        selectBranchLabelBuilder: (_) => AppLocalizations.of(
          context,
        ).brazilStoreSalesMapShowBranchOnMapAction,
      );
    }
    if (showBelowMapMarkerDetail(usesCompactBranchSheet: usesCompactBranchSheet) &&
        selectedPoint != null) {
      return _SelectedStoreDetail(
        point: selectedPoint,
        metric: _selectedMetric,
      );
    }
    if (selectedPoint == null &&
        selectedMarkerGroup == null &&
        selectedStateBucket != null) {
      return _SelectedStateDetail(
        bucket: selectedStateBucket,
        metric: _selectedMetric,
      );
    }
    return const SizedBox.shrink();
  }

  AppMapMarkerStyle resolveStateBubbleMarkerStyle(
    BuildContext context,
    AppMapMarkerStyle base,
    AppBrazilStoreSalesStateBucket bucket,
  ) {
    final selectedStateKey = _state._selection.internalSelectedStateKey;
    if (selectedStateKey == null || bucket.uf != selectedStateKey) {
      return base;
    }

    final colorScheme = Theme.of(context).colorScheme;
    final selectedMarkerColor =
        _widget.style.selectedMarkerColor ?? context.appColors.secondary;
    final selectedMarkerStrokeColor =
        _widget.style.selectedMarkerStrokeColor ?? colorScheme.surface;
    return base.copyWith(
      size: base.size + 4,
      color: selectedMarkerColor,
      strokeColor: selectedMarkerStrokeColor,
      strokeWidth: 2.4,
    );
  }

  AppMapMarkerStyle resolveStoreGroupMarkerStyle(
    BuildContext context,
    AppMapMarkerStyle base,
    AppBrazilStoreSalesMarkerGroup group,
    BrazilMapMarkerSelection selection,
  ) {
    final selectedStoreId = selection.selectedStoreId;
    final previewedStoreId = selection.previewedStoreId;
    final selected =
        selectedStoreId != null &&
        group.points.any((point) => point.id == selectedStoreId);
    final previewed =
        previewedStoreId != null &&
        group.points.any((point) => point.id == previewedStoreId);
    if (!selected && !previewed) {
      return base;
    }

    final colorScheme = Theme.of(context).colorScheme;
    final selectedMarkerColor =
        _widget.style.selectedMarkerColor ?? context.appColors.secondary;
    final selectedMarkerStrokeColor =
        _widget.style.selectedMarkerStrokeColor ?? colorScheme.surface;
    return base.copyWith(
      size: previewed ? base.size + 8 : base.size + 4,
      color: selectedMarkerColor,
      strokeColor: selectedMarkerStrokeColor,
      strokeWidth: previewed ? 3 : 2.4,
    );
  }

  String markerSemanticLabel(
    BuildContext context,
    AppBrazilStoreSalesMarkerGroup? group,
  ) {
    final l10n = AppLocalizations.of(context);
    if (group == null) {
      return l10n.brazilStoreSalesMapSemanticsStoreOnMap;
    }

    final salesStatus = group.points.any((point) => point.salesDataLoading)
        ? l10n.brazilStoreSalesMapSemanticsSalesLoadingSuffix
        : group.points.any((point) => point.salesDataUnavailable)
        ? l10n.brazilStoreSalesMapSemanticsSalesUnavailableSuffix
        : '';

    if (group.isCluster) {
      return l10n.brazilStoreSalesMapSemanticsClusterStores(
        _formatSalesCount(context, group.points.length),
        group.cityLabel,
        AppBrFormatters.currency(group.salesAmount),
        _formatSalesCount(context, group.salesCount),
        salesStatus,
      );
    }

    final point = group.primaryPoint;
    return l10n.brazilStoreSalesMapSemanticsSingleStore(
      point.name,
      group.cityLabel,
      AppBrFormatters.currency(point.salesAmount),
      _formatSalesCount(context, point.salesCount),
      salesStatus,
    );
  }

  String stateBubbleSemanticLabel(
    BuildContext context,
    AppBrazilStoreSalesStateBucket bucket,
  ) {
    final l10n = AppLocalizations.of(context);
    return l10n.brazilStoreSalesMapSemanticsStateAggregate(
      bucket.stateName,
      AppBrFormatters.currency(bucket.salesAmount),
      _formatSalesCount(context, bucket.salesCount),
      _formatSalesCount(context, bucket.storeCount),
    );
  }
}

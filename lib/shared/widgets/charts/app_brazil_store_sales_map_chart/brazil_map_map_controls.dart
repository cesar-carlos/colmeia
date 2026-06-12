part of '../app_brazil_store_sales_map_chart.dart';

class _BrazilMapMapControlsBuilder {
  _BrazilMapMapControlsBuilder(this._state);

  final _AppBrazilStoreSalesMapChartState _state;

  bool get _showsFloatingMetricSelector => _state._showsFloatingMetricSelector;

  bool get _showsFloatingScopeSelector => _state._showsFloatingScopeSelector;

  bool get _usesCleanFullscreenChrome => _state._usesCleanFullscreenChrome;

  void toggleDesktopBranchSidebarCollapsed() {
    _state._runStateUpdate(() {
      _state._desktopBranchSidebarCollapsed =
          !_state._desktopBranchSidebarCollapsed;
    });
  }

  List<AppMapMetric<AppBrazilStoreSalesStateBucket>> buildMetrics(
    AppLocalizations l10n,
  ) => <AppMapMetric<AppBrazilStoreSalesStateBucket>>[
    AppMapMetric<AppBrazilStoreSalesStateBucket>(
      key: AppBrazilStoreSalesMapMetric.revenue.key,
      label: l10n.brazilStoreSalesMapMetricRevenueShort,
      legendLabel: l10n.brazilStoreSalesMapLegendRevenuePerState,
      valueBuilder: (bucket) => bucket.salesAmount,
      tooltipBuilder: _stateTooltipSubtitle,
    ),
    AppMapMetric<AppBrazilStoreSalesStateBucket>(
      key: AppBrazilStoreSalesMapMetric.salesCount.key,
      label: l10n.brazilStoreSalesMapMetricSalesShort,
      legendLabel: l10n.brazilStoreSalesMapLegendSalesPerState,
      valueBuilder: (bucket) => bucket.salesCount,
      tooltipBuilder: _stateTooltipSubtitle,
    ),
  ];

  Widget? buildMapOverlay({
    required double mapTileHeight,
    required bool showsDesktopBranchSidebar,
    required double sidebarWidth,
    required double sidebarTopInset,
    required double sidebarHorizontalInset,
    required List<AppBrazilStoreSalesVisibleBranchListItem> entries,
    required String? selectedStoreId,
    required AppLocalizations l10n,
    required BrazilMapChartVisualSnapshot snapshot,
  }) {
    final overlays = <Widget>[];
    if (_showsFloatingMetricSelector || _showsFloatingScopeSelector) {
      overlays.add(
        BrazilMapChartFloatingMapControlsOverlay(
          topInset: BrazilMapLayoutConstants.floatingMapControlsTopInset,
          leftInset: BrazilMapLayoutConstants.floatingMapControlsLeftInset,
          metrics: _showsFloatingMetricSelector ? buildMetrics(l10n) : null,
          selectedMetricKey: _state._selectedMetric.key,
          onMetricChanged: _state._navigation.handleMetricChanged,
          scopeOptions: _showsFloatingScopeSelector
              ? AppBrazilStoreSalesMapLocalizations.regionScopeOptions(l10n)
              : const <AppMapScopeOption>[],
          activeScopeKey: _state._activeRegionKey,
          scopeRootLabel: l10n.brazilStoreSalesMapCountryLabel,
          onScopeChanged: _showsFloatingScopeSelector
              ? _state._navigation.handleScopeChanged
              : null,
        ),
      );
    }
    if (showsDesktopBranchSidebar) {
      final sidebarMaxHeight = BrazilMapDesktopSidebarLayout.maxHeight(
        mapTileHeight: mapTileHeight,
        topInset: sidebarTopInset,
      );
      if (sidebarMaxHeight > 0) {
        overlays.add(
          _state._desktopBranchSidebarCollapsed
              ? BrazilMapChartDesktopBranchSidebarCollapsedOverlay(
                  topInset: sidebarTopInset,
                  horizontalInset: sidebarHorizontalInset,
                  onExpand: toggleDesktopBranchSidebarCollapsed,
                )
              : BrazilMapChartDesktopBranchSidebarOverlay(
                  width: sidebarWidth,
                  maxHeight: sidebarMaxHeight,
                  topInset: sidebarTopInset,
                  horizontalInset: sidebarHorizontalInset,
                  entries: entries,
                  selectedStoreId: selectedStoreId,
                  allowCollapse: _usesCleanFullscreenChrome,
                  onToggleCollapsed: toggleDesktopBranchSidebarCollapsed,
                  onSelectBranch: (point) =>
                      _state._pointInteraction.handleMarkerBranchAction(
                        point: point,
                        index: _state._pointInteraction.mapPointIndexFor(
                          point,
                          snapshot,
                        ),
                      ),
                  onPreviewBranchStart:
                      _state._pointInteraction.setPreviewedPoint,
                  onPreviewBranchEnd:
                      _state._pointInteraction.clearPreviewedPoint,
                ),
        );
      }
    }
    if (overlays.isEmpty) {
      return null;
    }
    if (overlays.length == 1) {
      return overlays.first;
    }
    return Positioned.fill(
      child: Stack(
        clipBehavior: Clip.none,
        children: overlays,
      ),
    );
  }

  String _stateTooltipSubtitle(AppBrazilStoreSalesStateBucket bucket) {
    final l10n = AppLocalizations.of(_state.context);
    final revenue = AppBrFormatters.currency(bucket.salesAmount);
    final salesCount = brazilMapChartFormatSalesCount(
      _state.context,
      bucket.salesCount,
    );
    final stores = brazilMapChartFormatSalesCount(
      _state.context,
      bucket.storeCount,
    );
    return l10n.brazilStoreSalesMapStateInlineTooltip(
      bucket.stateName,
      bucket.uf,
      revenue,
      salesCount,
      stores,
    );
  }
}

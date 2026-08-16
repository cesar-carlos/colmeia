part of 'app_brazil_store_sales_map_chart.dart';

class _BrazilMapChartScaffold extends StatelessWidget {
  const _BrazilMapChartScaffold({
    required this.state,
    required this.snapshot,
    required this.markerSelection,
    required this.layoutSelectionPoint,
    required this.layoutSelectionGroup,
    required this.layoutSelectionStateBucket,
    required this.selectedRegionKey,
    required this.preferredViewport,
    required this.resetViewport,
  });

  final _AppBrazilStoreSalesMapChartState state;
  final BrazilMapChartVisualSnapshot snapshot;
  final BrazilMapMarkerSelection markerSelection;
  final AppBrazilStoreSalesPoint? layoutSelectionPoint;
  final AppBrazilStoreSalesMarkerGroup? layoutSelectionGroup;
  final AppBrazilStoreSalesStateBucket? layoutSelectionStateBucket;
  final String? selectedRegionKey;
  final AppMapViewport? preferredViewport;
  final AppMapViewport resetViewport;

  AppBrazilStoreSalesMapChart get chart => state.widget;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final usesCompactBranchSheet =
            BrazilMapCompactBranchSheetLayout.shouldUse(
              showStoreDetail: chart.style.showStoreDetail,
              maxWidth: constraints.maxWidth,
            );
        final l10n = AppLocalizations.of(context);
        final tokens = Theme.of(context).extension<AppThemeTokens>()!;
        final usesCompactMapChrome = constraints.hasBoundedHeight;
        final usesCompactStateLabels =
            usesCompactMapChrome &&
            constraints.maxWidth <
                BrazilMapLayoutConstants.compactStateLabelsMaxWidth;
        final stateLabels = BrazilMapChartStateLabelResolver(
          context: context,
          style: chart.style,
        );
        final stateDataLabelTextStyle = stateLabels.dataLabelTextStyle(
          compact: usesCompactStateLabels,
          maxWidth: constraints.maxWidth,
        );
        final useCompactMarkerLegend = state._layout
            .shouldUseCompactMarkerLegend(
              usesCompactMapChrome: usesCompactMapChrome,
              maxWidth: constraints.maxWidth,
            );
        final sidebarWidth = BrazilMapDesktopSidebarLayout.width(
          constraints.maxWidth,
        );
        final sidebarHorizontalInset = tokens.gapMd;
        final showsDesktopBranchSidebar =
            BrazilMapDesktopSidebarLayout.shouldShow(
              enabled: chart.showDesktopBranchSidebar,
              availableWidth: constraints.maxWidth,
              sidebarWidth: sidebarWidth,
              horizontalInset: sidebarHorizontalInset,
            );
        final sidebarTopInset = state._resolvedDesktopBranchSidebarTopInset(
          context,
          tokens,
          cleanMode: state._usesCleanFullscreenChrome,
        );
        final usesBoundedVerticalLayout =
            BrazilMapLayoutCalculator.usesBoundedVerticalLayout(constraints);
        final reserveBelowMapSelectionDetail = !usesBoundedVerticalLayout;
        final mapAreaHeight = state._layout.mapAreaHeight(
          context: context,
          constraints: constraints,
          snapshot: snapshot,
          usesCompactMapChrome: usesCompactMapChrome,
          detailPoint: layoutSelectionPoint,
          detailGroup: layoutSelectionGroup,
          detailStateBucket: layoutSelectionStateBucket,
          reserveBelowMapSelectionDetail:
              reserveBelowMapSelectionDetail &&
              !state._suppressMapLayoutShiftOnStoreSelection,
        );
        final mapTileHeight = state._layout.regionMapStyleHeightForMapArea(
          context: context,
          mapAreaHeight: mapAreaHeight,
        );
        final sidebarMapAreaHeight = usesBoundedVerticalLayout
            ? state._layout.mapAreaHeight(
                context: context,
                constraints: constraints,
                snapshot: snapshot,
                usesCompactMapChrome: usesCompactMapChrome,
                detailPoint: layoutSelectionPoint,
                detailGroup: layoutSelectionGroup,
                detailStateBucket: layoutSelectionStateBucket,
                reserveBelowMapSelectionDetail: false,
              )
            : mapAreaHeight;
        Widget buildRegionMap(double height) {
          return _BrazilMapChartRegionMap(
            state: state,
            snapshot: snapshot,
            height: height,
            l10n: l10n,
            tokens: tokens,
            selectedRegionKey: selectedRegionKey,
            preferredViewport: preferredViewport,
            resetViewport: resetViewport,
            usesCompactBranchSheet: usesCompactBranchSheet,
            usesCompactStateLabels: usesCompactStateLabels,
            usesCompactMapChrome: usesCompactMapChrome,
            stateLabels: stateLabels,
            stateDataLabelTextStyle: stateDataLabelTextStyle,
          );
        }

        final mapContent = BrazilMapChartStoreSalesMapContent(
          key: const ValueKey<String>('brazil-store-sales-map-content'),
          expandMapVertically: usesBoundedVerticalLayout,
          regionMapBuilder: buildRegionMap,
          fixedRegionMapHeight: mapTileHeight,
          regionMapStyleHeightForAvailableArea: usesBoundedVerticalLayout
              ? (availableMapAreaHeight) =>
                    state._layout.regionMapStyleHeightForMapArea(
                      context: context,
                      mapAreaHeight: availableMapAreaHeight,
                    )
              : null,
          mapOverlay: state._buildMapOverlay(
            mapTileHeight: sidebarMapAreaHeight,
            showsDesktopBranchSidebar: showsDesktopBranchSidebar,
            sidebarWidth: sidebarWidth,
            sidebarTopInset: sidebarTopInset,
            sidebarHorizontalInset: sidebarHorizontalInset,
            entries: snapshot.visibleBranchListItems,
            selectedStoreId: state._selectedStoreId,
            l10n: l10n,
            snapshot: snapshot,
          ),
          diagnostics:
              state._effectiveShowDataQualityNotice &&
                  snapshot.diagnostics.hasDiscardedPoints
              ? BrazilMapChartDataQualityNotice(
                  diagnostics: snapshot.diagnostics,
                )
              : null,
          markerLegend: _BrazilMapChartScaffoldMarkerLegend(
            state: state,
            chart: chart,
            snapshot: snapshot,
            useCompactMarkerLegend: useCompactMarkerLegend,
            l10n: l10n,
          ).build(context),
          detail: ValueListenableBuilder<BrazilMapMarkerSelection>(
            valueListenable: state._markerSelection,
            builder: (context, selection, _) {
              return state._markerPresenter.buildBelowMapSelectionDetail(
                context: context,
                snapshot: snapshot,
                selection: selection,
                usesCompactBranchSheet: usesCompactBranchSheet,
              );
            },
          ),
        );

        if (chart.title == null && chart.subtitle == null) {
          return mapContent;
        }

        return AppChartShell(
          title: chart.title ?? '',
          subtitle: chart.subtitle,
          titleTrailing: chart.titleTrailing,
          belowSubtitle: chart.belowSubtitle,
          onShare: chart.onShare,
          openShareTooltip: chart.openShareTooltip,
          openShareSemanticLabel: chart.openShareSemanticLabel,
          onOpenFullscreen: chart.onOpenFullscreen,
          cardPadding: state._usesCleanFullscreenChrome
              ? EdgeInsets.fromLTRB(
                  tokens.contentSpacing,
                  tokens.gapMd,
                  tokens.contentSpacing,
                  tokens.gapSm,
                )
              : null,
          child: mapContent,
        );
      },
    );
  }
}

class _BrazilMapChartRegionMap extends StatelessWidget {
  const _BrazilMapChartRegionMap({
    required this.state,
    required this.snapshot,
    required this.height,
    required this.l10n,
    required this.tokens,
    required this.selectedRegionKey,
    required this.preferredViewport,
    required this.resetViewport,
    required this.usesCompactBranchSheet,
    required this.usesCompactStateLabels,
    required this.usesCompactMapChrome,
    required this.stateLabels,
    required this.stateDataLabelTextStyle,
  });

  final _AppBrazilStoreSalesMapChartState state;
  final BrazilMapChartVisualSnapshot snapshot;
  final double height;
  final AppLocalizations l10n;
  final AppThemeTokens tokens;
  final String? selectedRegionKey;
  final AppMapViewport? preferredViewport;
  final AppMapViewport resetViewport;
  final bool usesCompactBranchSheet;
  final bool usesCompactStateLabels;
  final bool usesCompactMapChrome;
  final BrazilMapChartStateLabelResolver stateLabels;
  final TextStyle? stateDataLabelTextStyle;

  AppBrazilStoreSalesMapChart get chart => state.widget;

  @override
  Widget build(BuildContext context) {
    return state._wrapRegionMapForTouchGestures(
      RepaintBoundary(
        child: AppRegionMapChart<AppBrazilStoreSalesStateBucket>(
          mapDefinition: AppBrazilMapStaticData.resolveBrazilUfMapDefinition(),
          items: snapshot.buckets,
          metrics: state._buildMetrics(l10n),
          selectedMetricKey: state._selectedMetric.key,
          selectedRegionKey: selectedRegionKey,
          regionKeyBuilder: (bucket) => bucket.uf,
          regionLabelBuilder: (bucket) => stateLabels.labelFor(
            bucket,
            compact: usesCompactStateLabels,
          ),
          scopeOptions: chart.style.showRegionFilter
              ? AppBrazilStoreSalesMapLocalizations.regionScopeOptions(l10n)
              : const <AppMapScopeOption>[],
          activeScopeKey: state._activeRegionKey,
          preferredViewport: preferredViewport,
          resetViewport: resetViewport,
          onResetViewport: state._handleResetViewport,
          lifecycleRecoveryRequestId: chart.lifecycleRecoveryRequestId,
          points: snapshot.mapPoints,
          markerStyle: AppMapMarkerStyle(
            size: chart.style.markerMinSize,
            color: state._markerPresenter.markerColor(context),
            strokeColor: state._markerPresenter.markerStrokeColor(context),
          ),
          markerBuilder: (context, point, index) {
            return ValueListenableBuilder<BrazilMapMarkerSelection>(
              valueListenable: state._markerSelection,
              builder: (context, selection, _) {
                return state._markerPresenter.buildMarker(
                  context,
                  point,
                  index,
                  selection,
                  usesCompactBranchSheet: usesCompactBranchSheet,
                );
              },
            );
          },
          markerTooltipBuilder: state._useWindowsSafeMarkerDetails
              ? null
              : state._markerPresenter.buildMarkerTooltip,
          onMetricChanged: state._showsFloatingMetricSelector
              ? null
              : state._handleMetricChanged,
          onScopeChanged: state._showsFloatingScopeSelector
              ? null
              : chart.style.showRegionFilter
              ? state._handleScopeChanged
              : null,
          onRegionTapEvent: state._handleStateTap,
          onPointTap: state._pointInteraction.handlePointTap,
          onViewportChanged: state._handleRegionMapViewportChanged,
          viewportController: state._viewportController,
          preset: chart.style.enableZoomPan
              ? AppChartPreset.explorable
              : AppChartPreset.standard,
          style: AppRegionMapChartStyle(
            height: height,
            chartPadding: usesCompactMapChrome
                ? EdgeInsets.all(tokens.gapSm)
                : null,
            showLegend: state._effectiveShowLegend,
            showTooltip:
                chart.style.showTooltip && !state._useWindowsSafeMarkerDetails,
            showShapeTooltip: false,
            showDataLabels: chart.style.showDataLabels,
            showMetricSelector:
                chart.style.showMetricSelector &&
                !state._showsFloatingMetricSelector,
            enableZoomPan: chart.style.enableZoomPan,
            scopeRootLabel: l10n.brazilStoreSalesMapCountryLabel,
            lowValueColor:
                chart.style.lowValueColor ?? state._lowColor(context),
            highValueColor:
                chart.style.highValueColor ?? state._highColor(context),
            dataLabelTextStyle: stateDataLabelTextStyle,
            metricSelectorPadding: usesCompactMapChrome
                ? EdgeInsets.zero
                : null,
            legendNumberFormat: state._legendFormat,
            emptyStateMessage: state._resolvedEmptyStateMessage(l10n),
            metricGroupLabel: l10n.brazilStoreSalesMapMetricGroupLabel,
            scopeGroupLabel: l10n.brazilStoreSalesMapRegionGroupLabel,
            mapLoadingMessage: l10n.brazilStoreSalesMapLoadingMessage,
            showGroupLabels:
                !state._usesCleanFullscreenChrome && !usesCompactMapChrome,
          ),
          isRefreshing: chart.isRefreshing,
          isLoading: state._isBrazilMapShapeSourceLoading,
        ),
      ),
    );
  }
}

class _BrazilMapChartScaffoldMarkerLegend {
  const _BrazilMapChartScaffoldMarkerLegend({
    required this.state,
    required this.chart,
    required this.snapshot,
    required this.useCompactMarkerLegend,
    required this.l10n,
  });

  final _AppBrazilStoreSalesMapChartState state;
  final AppBrazilStoreSalesMapChart chart;
  final BrazilMapChartVisualSnapshot snapshot;
  final bool useCompactMarkerLegend;
  final AppLocalizations l10n;

  Widget? build(BuildContext context) {
    if (!state._effectiveShowMarkerScaleLegend || !snapshot.hasMarkers) {
      return null;
    }
    final legendProps = (
      sizeLegendLabel: l10n.brazilStoreSalesMapMarkerSizeLegend,
      metric: state._selectedMetric,
      minValue: snapshot.minMarkerValue,
      maxValue: snapshot.maxMarkerValue,
      minSize: chart.style.markerMinSize,
      maxSize: chart.style.markerMaxSize,
      color: state._markerPresenter.markerColor(context),
      strokeColor: state._markerPresenter.markerStrokeColor(context),
      visual: chart.style.markerVisual,
    );
    if (useCompactMarkerLegend) {
      return BrazilMapChartMarkerScaleLegendMenuButton(
        sizeLegendLabel: legendProps.sizeLegendLabel,
        metric: legendProps.metric,
        minValue: legendProps.minValue,
        maxValue: legendProps.maxValue,
        minSize: legendProps.minSize,
        maxSize: legendProps.maxSize,
        color: legendProps.color,
        strokeColor: legendProps.strokeColor,
        visual: legendProps.visual,
      );
    }
    return BrazilMapChartMarkerScaleLegend(
      sizeLegendLabel: legendProps.sizeLegendLabel,
      metric: legendProps.metric,
      minValue: legendProps.minValue,
      maxValue: legendProps.maxValue,
      minSize: legendProps.minSize,
      maxSize: legendProps.maxSize,
      color: legendProps.color,
      strokeColor: legendProps.strokeColor,
      visual: legendProps.visual,
    );
  }
}

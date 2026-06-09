import 'dart:async';

import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/core/layout/app_breakpoints.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/maps/app_location_lookup_normalizer.dart';
import 'package:colmeia/shared/utils/app_branch_display_model.dart';
import 'package:colmeia/shared/utils/app_branch_display_name.dart';
import 'package:colmeia/shared/widgets/app_section_card.dart';
import 'package:colmeia/shared/widgets/app_tag_chip.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_map_static_data.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_data.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_localizations.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_models.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_overlay_chrome.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_snapshot.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_shell.dart';
import 'package:colmeia/shared/widgets/charts/app_region_map_chart.dart';
import 'package:colmeia/shared/widgets/charts/brazil_map_chart_chrome.dart';
import 'package:colmeia/shared/widgets/charts/brazil_map_chart_visual_snapshot.dart';
import 'package:colmeia/shared/widgets/charts/brazil_map_compact_branch_sheet_layout.dart';
import 'package:colmeia/shared/widgets/charts/brazil_map_desktop_sidebar_layout.dart';
import 'package:colmeia/shared/widgets/charts/brazil_map_layout_calculator.dart';
import 'package:colmeia/shared/widgets/charts/brazil_map_layout_constants.dart';
import 'package:colmeia/shared/widgets/charts/brazil_map_marker_selection_controller.dart';
import 'package:colmeia/shared/widgets/charts/brazil_map_selection_policy.dart';
import 'package:colmeia/shared/widgets/charts/brazil_map_snapshot_controller.dart';
import 'package:colmeia/shared/widgets/charts/brazil_map_viewport_coordinator.dart';
import 'package:colmeia/shared/widgets/charts/brazil_map_zoom_controller.dart';
import 'package:colmeia/shared/widgets/charts/region_map_viewport_sync_policy.dart';
import 'package:colmeia/shared/widgets/forms/app_choice_chip.dart';
import 'package:colmeia/shared/widgets/forms/app_segmented_control.dart';
import 'package:colmeia/shared/widgets/forms/app_text_field.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

part 'app_brazil_store_sales_map_chart_auxiliary.dart';
part 'app_brazil_store_sales_map_chart_details.dart';
part 'app_brazil_store_sales_map_chart_overlay.dart';
part 'app_brazil_store_sales_map_chart_scaffold.dart';
part 'app_brazil_store_sales_map_chart_sidebar.dart';
part 'app_brazil_store_sales_map_chart/brazil_map_marker_presenter.dart';
part 'app_brazil_store_sales_map_chart/brazil_map_point_interaction_handler.dart';

String _formatSalesCount(BuildContext context, num value) =>
    brazilMapChartFormatSalesCount(context, value);

class AppBrazilStoreSalesMapChart extends StatefulWidget {
  const AppBrazilStoreSalesMapChart({
    required this.points,
    super.key,
    this.title,
    this.subtitle,
    this.titleTrailing,
    this.belowSubtitle,
    this.initialMetric = AppBrazilStoreSalesMapMetric.revenue,
    this.selectedStoreId,
    this.filterBranchIds = const <String>{},
    this.fixedBranchIds = const <String>{},
    this.style = const AppBrazilStoreSalesMapStyle(),
    this.isRefreshing = false,
    this.onStoreTap,
    this.onStoreClusterTap,
    this.onMunicipalityTap,
    this.onStateTap,
    this.onMetricChanged,
    this.onDiagnosticsChanged,
    this.onShare,
    this.openShareTooltip,
    this.openShareSemanticLabel,
    this.onOpenFullscreen,
    this.showDesktopBranchSidebar = false,
    this.presentationMode = AppBrazilStoreSalesMapPresentationMode.standard,
    this.useCleanFullscreenChrome = false,
    this.lifecycleRecoveryRequestId = 0,
  });

  final List<AppBrazilStoreSalesPoint> points;
  final String? title;
  final String? subtitle;
  final Widget? titleTrailing;
  final Widget? belowSubtitle;
  final AppBrazilStoreSalesMapMetric initialMetric;

  /// Optional externally controlled selection (e.g. deep-link); when set and
  /// not dismissed, overrides internal marker selection.
  final String? selectedStoreId;

  /// Branch ids selected outside the map (e.g. sheet filter).
  final Set<String> filterBranchIds;

  /// Union of external highlights (e.g. filter); drives reuse keys and cleanup.
  final Set<String> fixedBranchIds;
  final AppBrazilStoreSalesMapStyle style;
  final bool isRefreshing;
  final ValueChanged<AppBrazilStoreSalesPointTapEvent>? onStoreTap;
  final ValueChanged<AppBrazilStoreSalesPointClusterTapEvent>?
  onStoreClusterTap;
  final ValueChanged<AppBrazilStoreSalesMunicipalityTapEvent>?
  onMunicipalityTap;
  final ValueChanged<AppMapRegionTapEvent<AppBrazilStoreSalesStateBucket>>?
  onStateTap;
  final ValueChanged<AppBrazilStoreSalesMapMetric>? onMetricChanged;
  final ValueChanged<AppBrazilStoreSalesMapDiagnostics>? onDiagnosticsChanged;
  final VoidCallback? onShare;
  final String? openShareTooltip;
  final String? openShareSemanticLabel;
  final VoidCallback? onOpenFullscreen;
  final bool showDesktopBranchSidebar;
  final AppBrazilStoreSalesMapPresentationMode presentationMode;
  final bool useCleanFullscreenChrome;

  /// Monotonic recovery signal when the inline map was hidden (Offstage) and
  /// becomes visible again without disposing this widget.
  final int lifecycleRecoveryRequestId;

  @override
  State<AppBrazilStoreSalesMapChart> createState() =>
      _AppBrazilStoreSalesMapChartState();
}

abstract interface class AppBrazilStoreSalesMapChartPreviewTestHandle {
  void previewBranchForTesting(AppBrazilStoreSalesPoint point);

  void clearPreviewBranchForTesting();

  Object? get snapshotDataIdentityForTesting;

  Object? get snapshotMapPointsIdentityForTesting;

  String? get previewedStoreIdForTesting;

  bool get suppressPreferredViewportForTesting;
}

class _AppBrazilStoreSalesMapChartState
    extends State<AppBrazilStoreSalesMapChart>
    implements AppBrazilStoreSalesMapChartPreviewTestHandle {
  late AppBrazilStoreSalesMapMetric _selectedMetric;

  /// Presentation-mode derived flags (config-pure). Context-dependent flags
  /// such as [BrazilMapCompactBranchSheetLayout] use layout helpers.
  late BrazilMapChartChrome _chrome;
  final BrazilMapSelectionPolicy _selection = BrazilMapSelectionPolicy();
  final BrazilMapZoomController _zoom = BrazilMapZoomController();
  final RegionMapViewportController _viewportController =
      RegionMapViewportController();
  final BrazilMapMarkerSelectionController _markerHighlight =
      BrazilMapMarkerSelectionController();
  final BrazilMapSnapshotController _snapshots = BrazilMapSnapshotController();
  final BrazilMapViewportCoordinator _viewport = BrazilMapViewportCoordinator();
  late final _BrazilMapMarkerPresenter _markerPresenter =
      _BrazilMapMarkerPresenter(this);
  late final _BrazilMapPointInteractionHandler _pointInteraction =
      _BrazilMapPointInteractionHandler(this);
  String? _activeRegionKey;
  bool _desktopBranchSidebarCollapsed = false;
  AppBrazilStoreSalesMapDiagnostics? _lastEmittedDiagnostics;
  BrazilMapChartVisualSnapshot? _displaySnapshot;
  bool _snapshotRefreshScheduled = false;
  bool _brazilShapeSourcePrecacheAttemptComplete =
      AppBrazilMapStaticData.brazilUfGeoJsonBytesOrNull != null;

  ValueNotifier<BrazilMapMarkerSelection> get _markerSelection =>
      _markerHighlight.notifier;

  Widget _wrapRegionMapForTouchGestures(Widget regionMap) {
    if (!_shouldDeferViewportClusteringDuringGesture) {
      return regionMap;
    }

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _viewport.handleMapPointerDown(
        deferDuringGesture: _shouldDeferViewportClusteringDuringGesture,
      ),
      onPointerUp: (_) => _viewport.handleMapPointerUp(
        deferDuringGesture: _shouldDeferViewportClusteringDuringGesture,
        onApplyClusterZoom: _applyViewportClusterZoomLevel,
      ),
      onPointerCancel: (_) => _viewport.handleMapPointerUp(
        deferDuringGesture: _shouldDeferViewportClusteringDuringGesture,
        onApplyClusterZoom: _applyViewportClusterZoomLevel,
      ),
      child: regionMap,
    );
  }

  bool get _shouldDeferViewportClusteringDuringGesture =>
      BrazilMapViewportCoordinator.shouldDebounceTouchViewportClustering(
        enableZoomPan: widget.style.enableZoomPan,
      );

  void _scheduleConsumeCameraFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_selection.focusCameraOnSelectedStore) {
        return;
      }
      setState(_selection.consumeCameraFocus);
    });
  }

  void _invalidateResolvedSnapshotData() {
    _snapshots.invalidateData();
    _scheduleSnapshotRefresh();
  }

  void _invalidateResolvedSnapshotVisual() {
    _snapshots.invalidateVisual();
    _scheduleSnapshotRefresh();
  }

  void _scheduleSnapshotRefresh() {
    if (_snapshotRefreshScheduled) {
      return;
    }
    _snapshotRefreshScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _snapshotRefreshScheduled = false;
      if (!mounted) {
        return;
      }
      _syncDisplaySnapshot(notify: true);
    });
  }

  void _syncDisplaySnapshot({required bool notify}) {
    if (!mounted) {
      return;
    }
    final snapshot = _snapshots.resolve(
      context: context,
      input: _snapshotBuildInput,
      selectedStoreId: _selectedStoreId,
      requestedStateKey: _selection.internalSelectedStateKey,
    );
    _emitDiagnosticsIfNeeded(snapshot.diagnostics);
    if (identical(_displaySnapshot, snapshot)) {
      return;
    }
    _displaySnapshot = snapshot;
    if (notify) {
      setState(() {});
    }
  }

  BrazilMapLayoutCalculator get _layout =>
      BrazilMapLayoutCalculator(chrome: _chrome, style: widget.style);

  void _publishMarkerSelection() {
    _markerHighlight.publishWithControlledId(_selection, widget.selectedStoreId);
  }

  void _runStateUpdate(VoidCallback update) {
    setState(update);
  }

  BrazilMapSnapshotBuildInput get _snapshotBuildInput =>
      BrazilMapSnapshotBuildInput(
        points: widget.points,
        metric: _selectedMetric,
        activeRegionKey: _activeRegionKey,
        zoomLevel: _zoom.clusteringZoomLevel,
        style: widget.style,
        fixedBranchIds: widget.fixedBranchIds,
        filterBranchIds: widget.filterBranchIds,
        includeVisibleBranchListItems: _includeVisibleBranchListItems,
      );

  bool get _suppressMapLayoutShiftOnStoreSelection =>
      !widget.style.autoFocusSelectedStore ||
      defaultTargetPlatform == TargetPlatform.windows;

  void _handleRegionMapViewportChanged(AppMapViewportChangedEvent event) {
    final filtered = _viewport.filterViewportChangedEvent(
      event,
      blocksViewportDrivenClusteringOnWindows:
          _selection.blocksViewportDrivenClustering(widget.selectedStoreId),
    );
    if (filtered == null) {
      return;
    }
    _handleViewportChanged(filtered);
  }

  void _handleBrazilUfGeoJsonReadinessChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  void _startBrazilShapeSourcePrecacheIfNeeded() {
    if (_brazilShapeSourcePrecacheAttemptComplete) {
      return;
    }
    unawaited(
      AppBrazilMapStaticData.precacheBrazilUfGeoJsonAsset().whenComplete(() {
        if (!mounted) {
          return;
        }
        setState(() {
          _brazilShapeSourcePrecacheAttemptComplete = true;
        });
      }),
    );
  }

  bool get _isBrazilMapShapeSourceLoading =>
      !_brazilShapeSourcePrecacheAttemptComplete;

  @override
  void initState() {
    super.initState();
    _selectedMetric = widget.initialMetric;
    _chrome = BrazilMapChartChrome.resolve(
      style: widget.style,
      presentationMode: widget.presentationMode,
      useCleanFullscreenChrome: widget.useCleanFullscreenChrome,
      showDesktopBranchSidebar: widget.showDesktopBranchSidebar,
    );
    _markerHighlight.publishWithControlledId(_selection, widget.selectedStoreId);
    AppBrazilMapStaticData.brazilUfGeoJsonReadiness.addListener(
      _handleBrazilUfGeoJsonReadinessChanged,
    );
    _markerSelection.addListener(_scheduleSnapshotRefresh);
    _startBrazilShapeSourcePrecacheIfNeeded();
    if (widget.selectedStoreId != null && widget.style.autoFocusSelectedStore) {
      _selection.adoptControlledSelectionOnInit();
      _zoom.clusteringZoomLevel = widget.style.selectedStoreZoomLevel;
      _scheduleConsumeCameraFocus();
    }
  }

  @override
  void didUpdateWidget(covariant AppBrazilStoreSalesMapChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    _chrome = BrazilMapChartChrome.resolve(
      style: widget.style,
      presentationMode: widget.presentationMode,
      useCleanFullscreenChrome: widget.useCleanFullscreenChrome,
      showDesktopBranchSidebar: widget.showDesktopBranchSidebar,
    );
    if (oldWidget.initialMetric != widget.initialMetric) {
      _selectedMetric = widget.initialMetric;
      _invalidateResolvedSnapshotData();
    }

    if (oldWidget.selectedStoreId != widget.selectedStoreId ||
        oldWidget.style != widget.style) {
      if (widget.selectedStoreId == null) {
        _viewportController.reset();
      } else if (!widget.style.autoFocusSelectedStore) {
        _viewportController.withdrawPreferredViewportForStoreSelection();
      }
      _selection.syncControlledSelection(
        previousControlledId: oldWidget.selectedStoreId,
        nextControlledId: widget.selectedStoreId,
        selectedStoreZoomLevel: widget.style.selectedStoreZoomLevel,
        onAdoptControlledSelection: () {
          if (widget.style.autoFocusSelectedStore) {
            _zoom.clusteringZoomLevel = widget.style.selectedStoreZoomLevel;
          }
          _viewport.cancelPendingViewportClusterSampling();
        },
        onReleaseControlledSelection: () {
          if (oldWidget.style.autoFocusSelectedStore ||
              widget.style.autoFocusSelectedStore) {
            _zoom.resetToBrazilDefault();
          }
          _viewport.cancelPendingViewportClusterSampling();
        },
      );
      if (oldWidget.style != widget.style) {
        _invalidateResolvedSnapshotData();
      }
      if (widget.selectedStoreId != null &&
          widget.style.autoFocusSelectedStore &&
          _selection.focusCameraOnSelectedStore) {
        _scheduleConsumeCameraFocus();
      }
      _publishMarkerSelection();
    }

    if (oldWidget.filterBranchIds != widget.filterBranchIds ||
        oldWidget.fixedBranchIds != widget.fixedBranchIds) {
      _invalidateResolvedSnapshotData();
    }

    if (oldWidget.showDesktopBranchSidebar != widget.showDesktopBranchSidebar ||
        oldWidget.presentationMode != widget.presentationMode ||
        oldWidget.useCleanFullscreenChrome != widget.useCleanFullscreenChrome) {
      if (!widget.showDesktopBranchSidebar) {
        _desktopBranchSidebarCollapsed = false;
      }
      _invalidateResolvedSnapshotVisual();
    }

    if (oldWidget.style.markerAggregation != widget.style.markerAggregation) {
      _viewport.resetManualViewport();
    }

    if (!identical(oldWidget.points, widget.points)) {
      _snapshots.invalidatePointsDigestIfSourceChanged(widget.points);
      _viewport.cachedPreferredViewport = null;
      final selectedStoreId = _selection.resolveSelectedStoreId(
        widget.selectedStoreId,
      );
      if (selectedStoreId != null &&
          _pointInteraction.pointById(selectedStoreId) == null) {
        _selection.clearStoreSelection(
          controlledSelectedStoreId: widget.selectedStoreId,
        );
        _markerHighlight.previewedStoreId = null;
        if (widget.style.autoFocusSelectedStore) {
          _zoom.resetToBrazilDefault();
        }
        _viewport.cancelPendingViewportClusterSampling();
        _invalidateResolvedSnapshotData();
      }
    }

    final previewedStoreId = _markerHighlight.previewedStoreId;
    if (previewedStoreId != null &&
        (_pointInteraction.pointById(previewedStoreId) == null ||
            !_pointInteraction.pointMatchesActiveRegion(previewedStoreId))) {
      _markerHighlight.previewedStoreId = null;
    }

    if (widget.lifecycleRecoveryRequestId > 0 &&
        oldWidget.lifecycleRecoveryRequestId !=
            widget.lifecycleRecoveryRequestId) {
      _recoverAfterHiddenLifecycle();
    }
  }

  void _recoverAfterHiddenLifecycle() {
    _viewport.invalidatePreferredViewport();
    _invalidateResolvedSnapshotData();
    _publishMarkerSelection();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncDisplaySnapshot(notify: false);
  }

  @override
  void dispose() {
    _markerSelection.removeListener(_scheduleSnapshotRefresh);
    AppBrazilMapStaticData.brazilUfGeoJsonReadiness.removeListener(
      _handleBrazilUfGeoJsonReadinessChanged,
    );
    _viewport.dispose();
    _markerHighlight.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _displaySnapshot;
    if (snapshot == null) {
      return const SizedBox.shrink();
    }

    final markerSelection = _markerSelection.value;
    final markerDetail = BrazilMapMarkerSelectionController
        .resolveMarkerDetailSelection(
      snapshot,
      markerSelection,
      _pointInteraction.pointById,
    );
    final layoutSelectionPoint = _suppressMapLayoutShiftOnStoreSelection
        ? null
        : markerDetail.point;
    final layoutSelectionGroup = _suppressMapLayoutShiftOnStoreSelection
        ? null
        : markerDetail.group;
    final layoutSelectionStateBucket = _suppressMapLayoutShiftOnStoreSelection
        ? null
        : BrazilMapMarkerSelectionController.resolveSelectedStateBucket(
            snapshot,
            markerSelection,
          );
    final selectedRegionKey = widget.style.highlightSelectedState
        ? markerSelection.shapeHighlightRegionKey
        : null;

    return _BrazilMapChartScaffold(
      state: this,
      snapshot: snapshot,
      markerSelection: markerSelection,
      layoutSelectionPoint: layoutSelectionPoint,
      layoutSelectionGroup: layoutSelectionGroup,
      layoutSelectionStateBucket: layoutSelectionStateBucket,
      selectedRegionKey: selectedRegionKey,
      preferredViewport: _resolvePreferredViewportForBuild(snapshot),
      resetViewport: _resetTargetViewportForScope(),
    );
  }

  NumberFormat? get _legendFormat {
    if (widget.style.legendNumberFormat != null) {
      return widget.style.legendNumberFormat;
    }

    return switch (_selectedMetric) {
      AppBrazilStoreSalesMapMetric.revenue =>
        AppBrFormatters.compactCurrencyFormat,
      AppBrazilStoreSalesMapMetric.salesCount => null,
    };
  }

  String _resolvedEmptyStateMessage(AppLocalizations l10n) {
    if (widget.style.emptyStateMessage ==
        AppBrazilStoreSalesMapStyle.defaultEmptyStateMessage) {
      return l10n.brazilStoreSalesMapEmptyState;
    }
    return widget.style.emptyStateMessage;
  }

  double _resolvedDesktopBranchSidebarTopInset(
    BuildContext context,
    AppThemeTokens tokens, {
    required bool cleanMode,
  }) {
    return BrazilMapDesktopSidebarLayout.topInsetBase +
        (cleanMode ? 0 : tokens.gapXs) +
        _layout.floatingMapControlsHeight(
          context,
          cleanMode: cleanMode,
        );
  }

  bool get _useWindowsSafeMarkerDetails => _chrome.useWindowsSafeMarkerDetails;

  bool get _blocksViewportDrivenClustering =>
      _selection.blocksViewportDrivenClustering(widget.selectedStoreId);

  bool get _usesCleanFullscreenChrome => _chrome.usesCleanFullscreenChrome;

  bool get _includeVisibleBranchListItems =>
      _chrome.includeVisibleBranchListItems;

  bool get _showsFloatingMetricSelector => _chrome.showsFloatingMetricSelector;

  bool get _showsFloatingScopeSelector => _chrome.showsFloatingScopeSelector;

  bool get _effectiveShowLegend => _chrome.effectiveShowLegend;

  bool get _effectiveShowMarkerScaleLegend =>
      _chrome.effectiveShowMarkerScaleLegend;

  bool get _effectiveShowDataQualityNotice =>
      _chrome.effectiveShowDataQualityNotice;

  Widget? _buildMapOverlay({
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
        _FloatingMapControlsOverlay(
          topInset: BrazilMapLayoutConstants.floatingMapControlsTopInset,
          leftInset: BrazilMapLayoutConstants.floatingMapControlsLeftInset,
          metrics: _showsFloatingMetricSelector ? _buildMetrics(l10n) : null,
          selectedMetricKey: _selectedMetric.key,
          onMetricChanged: _handleMetricChanged,
          scopeOptions: _showsFloatingScopeSelector
              ? AppBrazilStoreSalesMapLocalizations.regionScopeOptions(l10n)
              : const <AppMapScopeOption>[],
          activeScopeKey: _activeRegionKey,
          scopeRootLabel: l10n.brazilStoreSalesMapCountryLabel,
          onScopeChanged: _showsFloatingScopeSelector
              ? _handleScopeChanged
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
          _desktopBranchSidebarCollapsed
              ? _DesktopBranchSidebarCollapsedOverlay(
                  topInset: sidebarTopInset,
                  horizontalInset: sidebarHorizontalInset,
                  onExpand: _toggleDesktopBranchSidebarCollapsed,
                )
              : _DesktopBranchSidebarOverlay(
                  width: sidebarWidth,
                  maxHeight: sidebarMaxHeight,
                  topInset: sidebarTopInset,
                  horizontalInset: sidebarHorizontalInset,
                  entries: entries,
                  selectedStoreId: selectedStoreId,
                  allowCollapse: _usesCleanFullscreenChrome,
                  onToggleCollapsed: _toggleDesktopBranchSidebarCollapsed,
                  onSelectBranch: (point) => _pointInteraction.handleMarkerBranchAction(
                    point: point,
                    index: _pointInteraction.mapPointIndexFor(point, snapshot),
                  ),
                  onPreviewBranchStart: _pointInteraction.setPreviewedPoint,
                  onPreviewBranchEnd: _pointInteraction.clearPreviewedPoint,
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

  void _toggleDesktopBranchSidebarCollapsed() {
    setState(() {
      _desktopBranchSidebarCollapsed = !_desktopBranchSidebarCollapsed;
    });
  }

  List<AppMapMetric<AppBrazilStoreSalesStateBucket>> _buildMetrics(
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

  AppMapViewport? _resolvePreferredViewportForBuild(
    BrazilMapChartVisualSnapshot snapshot,
  ) {
    return _viewport.preferredViewportForBuild(
      BrazilMapPreferredViewportRequest(
        userHasManualMapViewport: _viewport.userHasManualMapViewport,
        cachedBindingKey: _viewport.cachedPreferredViewportBinding,
        regionBindingKey: _viewport.regionBindingKey(_activeRegionKey),
        selectedStoreId: _selectedStoreId,
        selectedPoint:
            snapshot.selectedPoint ?? _pointInteraction.pointById(_selectedStoreId),
        shouldFocusCameraOnSelectedStore:
            _selection.shouldFocusCameraOnSelectedStore(
          controlledSelectedStoreId: widget.selectedStoreId,
          autoFocusSelectedStore: widget.style.autoFocusSelectedStore,
        ),
        selectedStoreZoomLevel: widget.style.selectedStoreZoomLevel,
        activeRegionKey: _activeRegionKey,
      ),
    );
  }

  AppMapViewport _resetTargetViewportForScope() =>
      _viewport.resetTargetViewportForScope(_activeRegionKey);

  void _handleResetViewport() {
    setState(() {
      _viewportController.reset();
      _viewport.resetManualViewport();
      _zoom.applyScopeZoom(_resetTargetViewportForScope().zoomLevel);
    });
  }

  String _stateLabelFor(
    AppBrazilStoreSalesStateBucket bucket, {
    bool compact = false,
  }) {
    return _BrazilMapStateLabelResolver(
      context: context,
      style: widget.style,
    ).labelFor(bucket, compact: compact);
  }

  String? get _selectedStoreId =>
      _selection.resolveSelectedStoreId(widget.selectedStoreId);

  void _handleMetricChanged(AppMapMetricChangedEvent event) {
    final metric = AppBrazilStoreSalesMapMetric.values.firstWhere(
      (candidate) => candidate.key == event.metricKey,
      orElse: () => _selectedMetric,
    );

    if (metric == _selectedMetric) {
      return;
    }

    setState(() {
      _selectedMetric = metric;
      _invalidateResolvedSnapshotData();
    });
    widget.onMetricChanged?.call(metric);
  }

  void _handleScopeChanged(AppMapScopeChangedEvent event) {
    setState(() {
      _viewportController.reset();
      _viewport.resetManualViewport();
      _activeRegionKey = event.currentScopeKey;
      _zoom.applyScopeZoom(
        (event.currentScopeKey == null
                ? AppBrazilMapStaticData.brazilViewport
                : AppBrazilMapStaticData.regionViewports[event.currentScopeKey])
            ?.zoomLevel,
      );
      _selection.clearStoreIfOutsideActiveRegion(
        activeRegionKey: _activeRegionKey,
        controlledSelectedStoreId: widget.selectedStoreId,
        pointById: _pointInteraction.pointById,
      );
      if (!_pointInteraction.pointMatchesActiveRegion(
        _markerHighlight.previewedStoreId,
      )) {
        _markerHighlight.previewedStoreId = null;
      }
      _publishMarkerSelection();
      _invalidateResolvedSnapshotData();
    });
  }

  void _handleStateTap(
    AppMapRegionTapEvent<AppBrazilStoreSalesStateBucket> event,
  ) {
    final preserveStoreSelection = _selection
        .shouldPreserveStoreSelectionForRegionTap(
          regionKey: event.regionKey,
          controlledSelectedStoreId: widget.selectedStoreId,
          pointById: _pointInteraction.pointById,
        );
    if (_selection.shouldSkipRedundantRegionTap(
      regionKey: event.regionKey,
      preserveStoreSelection: preserveStoreSelection,
      controlledSelectedStoreId: widget.selectedStoreId,
    )) {
      widget.onStateTap?.call(event);
      return;
    }

    setState(() {
      _selection.applyRegionTap(
        regionKey: event.regionKey,
        preserveStoreSelection: preserveStoreSelection,
      );
      if (!preserveStoreSelection) {
        _markerHighlight.previewedStoreId = null;
        _viewportController.reset();
      }
      _invalidateResolvedSnapshotVisual();
      _publishMarkerSelection();
    });
    widget.onStateTap?.call(event);
  }

  void _handleViewportChanged(AppMapViewportChangedEvent event) {
    _viewport.handleViewportChanged(
      event: event,
      enableProximityCluster: widget.style.enableProximityCluster,
      blocksViewportDrivenClustering: _blocksViewportDrivenClustering,
      enableZoomPan: widget.style.enableZoomPan,
      zoom: _zoom,
      onMarkManualViewport: () {
        if (!mounted) {
          return;
        }
        setState(() {
          _viewport.userHasManualMapViewport = true;
        });
      },
      shouldClearStoreDetailOnUserViewportChange:
          widget.style.showStoreDetail &&
          _selectedStoreId != null &&
          !_markerHighlight.selectedDetailIsClusterOrMunicipality,
      onClearStoreDetail: _pointInteraction.clearSelectedMarkerDetail,
      onApplyClusterZoom: _applyViewportClusterZoomLevel,
      pointCount: widget.points.length,
      activeRegionKey: _activeRegionKey,
    );
  }

  void _applyViewportClusterZoomLevel(double nextZoomLevel) {
    if (!mounted) {
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

    setState(() {
      _zoom.clusteringZoomLevel = nextZoomLevel;
      _invalidateResolvedSnapshotData();
    });
  }

  void _emitDiagnosticsIfNeeded(
    AppBrazilStoreSalesMapDiagnostics diagnostics,
  ) {
    final callback = widget.onDiagnosticsChanged;
    if (callback == null || _lastEmittedDiagnostics == diagnostics) {
      return;
    }

    _lastEmittedDiagnostics = diagnostics;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      callback(diagnostics);
    });
  }

  @override
  @visibleForTesting
  void previewBranchForTesting(AppBrazilStoreSalesPoint point) {
    _markerHighlight.previewBranchForTesting(point);
    _publishMarkerSelection();
  }

  @override
  @visibleForTesting
  void clearPreviewBranchForTesting() {
    _markerHighlight.clearPreviewBranchForTesting();
    _publishMarkerSelection();
  }

  @override
  @visibleForTesting
  Object? get snapshotDataIdentityForTesting =>
      _snapshots.snapshotDataIdentityForTesting;

  @override
  @visibleForTesting
  Object? get snapshotMapPointsIdentityForTesting =>
      _snapshots.snapshotMapPointsIdentityForTesting;

  @override
  @visibleForTesting
  String? get previewedStoreIdForTesting => _markerHighlight.previewedStoreId;

  @override
  @visibleForTesting
  bool get suppressPreferredViewportForTesting =>
      _viewportController.suppressPreferredViewport;

  String _stateTooltipSubtitle(AppBrazilStoreSalesStateBucket bucket) {
    final l10n = AppLocalizations.of(context);
    final revenue = AppBrFormatters.currency(bucket.salesAmount);
    final salesCount = _formatSalesCount(context, bucket.salesCount);
    final stores = _formatSalesCount(context, bucket.storeCount);
    return l10n.brazilStoreSalesMapStateInlineTooltip(
      bucket.stateName,
      bucket.uf,
      revenue,
      salesCount,
      stores,
    );
  }

  Color _lowColor(BuildContext context) {
    return Theme.of(context).colorScheme.surfaceContainerHighest;
  }

  Color _highColor(BuildContext context) {
    return context.appColors.secondary;
  }
}

String _formatMetricValue(
  BuildContext context,
  AppBrazilStoreSalesMapMetric metric,
  num value,
) {
  return switch (metric) {
    AppBrazilStoreSalesMapMetric.revenue => AppBrFormatters.compactCurrency(
      value,
    ),
    AppBrazilStoreSalesMapMetric.salesCount => _formatSalesCount(
      context,
      value,
    ),
  };
}

String _metricShortLabel(
  AppLocalizations l10n,
  AppBrazilStoreSalesMapMetric metric,
) {
  return switch (metric) {
    AppBrazilStoreSalesMapMetric.revenue =>
      l10n.brazilStoreSalesMapMetricRevenueShort,
    AppBrazilStoreSalesMapMetric.salesCount =>
      l10n.brazilStoreSalesMapMetricSalesShort,
  };
}

String _cityLabelFor(AppBrazilStoreSalesPoint point) {
  return switch (point.city) {
    final city? when city.trim().isNotEmpty =>
      '${city.trim()} / ${AppBrazilStoreSalesMapData.normalizeUf(point.uf)}',
    _ => AppBrazilStoreSalesMapData.normalizeUf(point.uf),
  };
}

Alignment _followerAnchorFor({
  required double screenWidth,
  required double maxWidth,
  required double? markerGlobalDx,
}) {
  final markerDx = markerGlobalDx;
  if (markerDx == null) {
    return Alignment.bottomCenter;
  }

  const margin = 16.0;
  final halfWidth = maxWidth / 2;
  if (markerDx < halfWidth + margin) {
    return Alignment.bottomLeft;
  }
  if (markerDx > screenWidth - halfWidth - margin) {
    return Alignment.bottomRight;
  }
  return Alignment.bottomCenter;
}

Offset _followerOffsetFor(Alignment followerAnchor) {
  if (followerAnchor == Alignment.bottomLeft) {
    return const Offset(8, -10);
  }
  if (followerAnchor == Alignment.bottomRight) {
    return const Offset(-8, -10);
  }
  return const Offset(0, -10);
}

List<AppBrazilStoreSalesPoint> _orderedBranchPoints(
  AppBrazilStoreSalesMarkerGroup group, {
  required String? initialStoreId,
}) {
  final selected = <AppBrazilStoreSalesPoint>[];
  final remaining = <AppBrazilStoreSalesPoint>[];

  for (final point in group.points) {
    if (initialStoreId != null && point.id == initialStoreId) {
      selected.add(point);
    } else {
      remaining.add(point);
    }
  }

  remaining.sort(_compareBranchPoints);
  return <AppBrazilStoreSalesPoint>[...selected, ...remaining];
}

int _compareBranchPoints(
  AppBrazilStoreSalesPoint left,
  AppBrazilStoreSalesPoint right,
) {
  final amount = right.salesAmount.compareTo(left.salesAmount);
  if (amount != 0) {
    return amount;
  }

  final salesCount = right.salesCount.compareTo(left.salesCount);
  if (salesCount != 0) {
    return salesCount;
  }

  return _branchOrdinalName(left).compareTo(_branchOrdinalName(right));
}

String _branchOrdinalName(AppBrazilStoreSalesPoint point) {
  return _branchDisplayModel(point).primaryName;
}

String _branchDisplayNameUi(
  BuildContext context,
  AppBrazilStoreSalesPoint point,
) {
  return resolveAppBranchDisplayModel(
    registrationName: point.branchName,
    fantasyName: point.fantasyName,
    fallbackName:
        _trimmedOrNull(point.name) ??
        AppLocalizations.of(context).brazilStoreSalesMapDefaultBranchName,
  ).primaryName;
}

String? _branchNameLabel(AppBrazilStoreSalesPoint point) {
  return _branchDisplayModel(point).secondaryName;
}

AppBranchDisplayModel _branchDisplayModel(AppBrazilStoreSalesPoint point) {
  return resolveAppBranchDisplayModel(
    registrationName: point.branchName,
    fantasyName: point.fantasyName,
    fallbackName: _trimmedOrNull(point.name) ?? point.id,
  );
}

String _agentChipLabel(AppLocalizations l10n, String agentName) {
  return l10n.brazilStoreSalesMapAgentChipWithName(
    appBranchDisplayName(agentName),
  );
}

String? _trimmedOrNull(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}

String _locationResolutionLabel(
  AppLocalizations l10n,
  AppBrazilStoreSalesLocationResolution? resolution,
) {
  return switch (resolution) {
    AppBrazilStoreSalesLocationResolution.providedGeoPoint =>
      l10n.brazilStoreSalesMapLocationProvidedGeoPoint,
    AppBrazilStoreSalesLocationResolution.ibgeMunicipalityCode =>
      l10n.brazilStoreSalesMapLocationIbge,
    AppBrazilStoreSalesLocationResolution.cep =>
      l10n.brazilStoreSalesMapLocationCep,
    AppBrazilStoreSalesLocationResolution.cityUf =>
      l10n.brazilStoreSalesMapLocationCityUf,
    AppBrazilStoreSalesLocationResolution.capitalUf =>
      l10n.brazilStoreSalesMapLocationCapitalUf,
    AppBrazilStoreSalesLocationResolution.stateUf =>
      l10n.brazilStoreSalesMapLocationStateUf,
    null => l10n.brazilStoreSalesMapLocationUnknown,
  };
}

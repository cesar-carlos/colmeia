import 'dart:async';

import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_map_static_data.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_chart/brazil_map_chart_auxiliary_widgets.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_chart/brazil_map_chart_detail_widgets.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_chart/brazil_map_chart_overlay_widgets.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_chart/brazil_map_chart_sidebar_widgets.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_data.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_localizations.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_models.dart';
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
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

export 'app_brazil_store_sales_map_chart/brazil_map_chart_overlay_widgets.dart'
    show
        AppBrazilStoreSalesBranchHoverDetailAnchor,
        AppBrazilStoreSalesSelectedMarkerDetailAnchor;

part 'app_brazil_store_sales_map_chart/brazil_map_map_controls.dart';
part 'app_brazil_store_sales_map_chart/brazil_map_marker_presenter.dart';
part 'app_brazil_store_sales_map_chart/brazil_map_point_interaction_handler.dart';
part 'app_brazil_store_sales_map_chart/brazil_map_snapshot_lifecycle.dart';
part 'app_brazil_store_sales_map_chart/brazil_map_viewport_navigation_handler.dart';
part 'app_brazil_store_sales_map_chart/brazil_map_widget_lifecycle.dart';
part 'app_brazil_store_sales_map_chart/brazil_map_widget_update_handler.dart';
part 'app_brazil_store_sales_map_chart_scaffold.dart';

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
  late final _BrazilMapMapControlsBuilder _mapControls =
      _BrazilMapMapControlsBuilder(this);
  late final _BrazilMapViewportNavigationHandler _navigation =
      _BrazilMapViewportNavigationHandler(this);
  late final _BrazilMapWidgetUpdateHandler _widgetUpdate =
      _BrazilMapWidgetUpdateHandler(this);
  late final _BrazilMapSnapshotLifecycleCoordinator _snapshotLifecycle =
      _BrazilMapSnapshotLifecycleCoordinator(this);
  late final _BrazilMapWidgetLifecycleCoordinator _lifecycle =
      _BrazilMapWidgetLifecycleCoordinator(this);
  String? _activeRegionKey;
  bool _desktopBranchSidebarCollapsed = false;
  AppBrazilStoreSalesMapDiagnostics? _lastEmittedDiagnostics;
  BrazilMapChartVisualSnapshot? _displaySnapshot;
  bool _snapshotRefreshScheduled = false;

  ValueNotifier<BrazilMapMarkerSelection> get _markerSelection =>
      _markerHighlight.notifier;

  Widget _wrapRegionMapForTouchGestures(Widget regionMap) {
    return BrazilMapTouchGestureViewportWrapper(
      deferDuringGesture: _shouldDeferViewportClusteringDuringGesture,
      onPointerDown: () => _viewport.handleMapPointerDown(
        deferDuringGesture: _shouldDeferViewportClusteringDuringGesture,
      ),
      onPointerUp: () => _viewport.handleMapPointerUp(
        deferDuringGesture: _shouldDeferViewportClusteringDuringGesture,
        onApplyClusterZoom: _navigation.applyViewportClusterZoomLevel,
      ),
      onPointerCancel: () => _viewport.handleMapPointerUp(
        deferDuringGesture: _shouldDeferViewportClusteringDuringGesture,
        onApplyClusterZoom: _navigation.applyViewportClusterZoomLevel,
      ),
      child: regionMap,
    );
  }

  bool get _shouldDeferViewportClusteringDuringGesture =>
      BrazilMapViewportCoordinator.shouldDebounceTouchViewportClustering(
        enableZoomPan: widget.style.enableZoomPan,
      );

  BrazilMapLayoutCalculator get _layout =>
      BrazilMapLayoutCalculator(chrome: _chrome, style: widget.style);

  void _publishMarkerSelection() {
    _markerHighlight.publishWithControlledId(
      _selection,
      widget.selectedStoreId,
    );
  }

  void _runStateUpdate(VoidCallback update) {
    setState(update);
  }

  void _scheduleConsumeCameraFocus() =>
      _snapshotLifecycle.scheduleConsumeCameraFocus();

  void _invalidateResolvedSnapshotData() =>
      _snapshotLifecycle.invalidateResolvedSnapshotData();

  void _invalidateResolvedSnapshotVisual() =>
      _snapshotLifecycle.invalidateResolvedSnapshotVisual();

  void _scheduleSnapshotRefresh() => _snapshotLifecycle.scheduleSnapshotRefresh();

  void _syncDisplaySnapshot({required bool notify}) =>
      _snapshotLifecycle.syncDisplaySnapshot(notify: notify);

  bool get _suppressMapLayoutShiftOnStoreSelection =>
      !widget.style.autoFocusSelectedStore ||
      defaultTargetPlatform == TargetPlatform.windows;

  bool get _isBrazilMapShapeSourceLoading =>
      _lifecycle.isBrazilMapShapeSourceLoading;

  @override
  void initState() {
    super.initState();
    _lifecycle.initialize();
  }

  @override
  void didUpdateWidget(covariant AppBrazilStoreSalesMapChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    _widgetUpdate.handleDidUpdateWidget(oldWidget);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncDisplaySnapshot(notify: false);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _displaySnapshot;
    if (snapshot == null) {
      return const SizedBox.shrink();
    }

    final markerSelection = _markerSelection.value;
    final markerDetail =
        BrazilMapMarkerSelectionController.resolveMarkerDetailSelection(
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
      preferredViewport: _navigation.resolvePreferredViewportForBuild(snapshot),
      resetViewport: _navigation.resetTargetViewportForScope(),
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
  }) =>
      _mapControls.buildMapOverlay(
        mapTileHeight: mapTileHeight,
        showsDesktopBranchSidebar: showsDesktopBranchSidebar,
        sidebarWidth: sidebarWidth,
        sidebarTopInset: sidebarTopInset,
        sidebarHorizontalInset: sidebarHorizontalInset,
        entries: entries,
        selectedStoreId: selectedStoreId,
        l10n: l10n,
        snapshot: snapshot,
      );

  List<AppMapMetric<AppBrazilStoreSalesStateBucket>> _buildMetrics(
    AppLocalizations l10n,
  ) =>
      _mapControls.buildMetrics(l10n);

  void _handleResetViewport() => _navigation.handleResetViewport();

  void _handleMetricChanged(AppMapMetricChangedEvent event) =>
      _navigation.handleMetricChanged(event);

  void _handleScopeChanged(AppMapScopeChangedEvent event) =>
      _navigation.handleScopeChanged(event);

  void _handleStateTap(
    AppMapRegionTapEvent<AppBrazilStoreSalesStateBucket> event,
  ) =>
      _navigation.handleStateTap(event);

  void _handleRegionMapViewportChanged(AppMapViewportChangedEvent event) =>
      _navigation.handleRegionMapViewportChanged(event);

  String _stateLabelFor(
    AppBrazilStoreSalesStateBucket bucket, {
    bool compact = false,
  }) {
    return BrazilMapChartStateLabelResolver(
      context: context,
      style: widget.style,
    ).labelFor(bucket, compact: compact);
  }

  String? get _selectedStoreId =>
      _selection.resolveSelectedStoreId(widget.selectedStoreId);

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

  Color _lowColor(BuildContext context) {
    return Theme.of(context).colorScheme.surfaceContainerHighest;
  }

  Color _highColor(BuildContext context) {
    return context.appColors.secondary;
  }
}

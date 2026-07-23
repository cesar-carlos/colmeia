import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_theme.dart';
import 'package:colmeia/shared/widgets/charts/app_region_map_chart.dart';
import 'package:colmeia/shared/widgets/charts/engines/syncfusion_region_map_chart_placeholder_states.dart';
import 'package:colmeia/shared/widgets/charts/engines/syncfusion_region_map_chart_widgets.dart';
import 'package:colmeia/shared/widgets/charts/engines/syncfusion_region_map_marker_builder.dart';
import 'package:colmeia/shared/widgets/charts/engines/syncfusion_region_map_marker_overlay_coordinator.dart';
import 'package:colmeia/shared/widgets/charts/engines/syncfusion_region_map_pointer_wheel_policy.dart';
import 'package:colmeia/shared/widgets/charts/engines/syncfusion_region_map_region_selection_handler.dart';
import 'package:colmeia/shared/widgets/charts/engines/syncfusion_region_map_semantics.dart';
import 'package:colmeia/shared/widgets/charts/engines/syncfusion_region_map_shape_source_cache.dart';
import 'package:colmeia/shared/widgets/charts/engines/syncfusion_region_map_surface_lifecycle.dart';
import 'package:colmeia/shared/widgets/charts/engines/syncfusion_region_map_viewport_coordinator.dart';
import 'package:colmeia/shared/widgets/charts/region_map_marker_overlay_policy.dart';
import 'package:colmeia/shared/widgets/charts/region_map_viewport_sync_policy.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_maps/maps.dart';

class SyncfusionRegionMapChart<T> extends StatefulWidget {
  const SyncfusionRegionMapChart({
    required this.items,
    required this.mapDefinition,
    required this.metric,
    required this.regionKeyBuilder,
    required this.regionLabelBuilder,
    required this.currentDrillLevel,
    required this.style,
    required this.preset,
    super.key,
    this.preferredViewport,
    this.selectedRegionKey,
    this.onRegionTap,
    this.onRegionTapEvent,
    this.onSelectionChanged,
    this.onDrillDownRequested,
    this.onViewportChanged,
    this.isLoading = false,
    this.isRefreshing = false,
    this.emptyPlaceholder,
    this.points = const <AppMapPoint>[],
    this.markerStyle = const AppMapMarkerStyle(),
    this.markerBuilder,
    this.markerTooltipBuilder,
    this.onPointTap,
    this.viewportController,
    this.resetViewport,
    this.onResetViewport,
    this.lifecycleRecoveryRequestId = 0,
  });

  final List<T> items;
  final AppMapDefinition mapDefinition;
  final AppMapMetric<T> metric;
  final String Function(T item) regionKeyBuilder;
  final String Function(T item) regionLabelBuilder;
  final AppMapViewport? preferredViewport;
  final String? selectedRegionKey;
  final AppMapDrillLevel currentDrillLevel;
  final void Function(T item, String regionKey)? onRegionTap;
  final ValueChanged<AppMapRegionTapEvent<T>>? onRegionTapEvent;
  final ValueChanged<AppMapSelectionChangedEvent<T>>? onSelectionChanged;
  final ValueChanged<AppMapDrillDownEvent<T>>? onDrillDownRequested;

  /// Fired when the user pans or zooms. Prefer post-frame scheduling over
  /// synchronous navigation or dropping this widget inside the handler.
  final ValueChanged<AppMapViewportChangedEvent>? onViewportChanged;
  final AppRegionMapChartStyle style;
  final AppChartPreset preset;

  /// Full loading state: replaces map with a centered spinner.
  final bool isLoading;

  /// Soft refresh: keeps the map visible and shows a thin progress bar.
  /// Use when reloading with an existing snapshot so the user retains
  /// spatial context.
  final bool isRefreshing;

  final Widget? emptyPlaceholder;

  final List<AppMapPoint> points;
  final AppMapMarkerStyle markerStyle;
  final Widget Function(BuildContext context, AppMapPoint point, int index)?
  markerBuilder;
  final Widget Function(BuildContext context, AppMapPoint point, int index)?
  markerTooltipBuilder;
  final ValueChanged<AppMapPointTapEvent>? onPointTap;
  final RegionMapViewportController? viewportController;

  /// Fallback camera target for "Centralizar mapa" when [preferredViewport] is
  /// withheld (manual zoom, store selection suppress).
  final AppMapViewport? resetViewport;

  /// Notifies the parent to clear manual-viewport state before re-applying
  /// [resetViewport] or [preferredViewport].
  final VoidCallback? onResetViewport;

  /// Monotonic id from parents that hid this map (e.g. Offstage fullscreen).
  /// When it changes, the engine reschedules marker overlay paint and reapplies
  /// the current viewport without remounting [SfMaps].
  final int lifecycleRecoveryRequestId;

  @override
  State<SyncfusionRegionMapChart<T>> createState() =>
      _SyncfusionRegionMapChartState<T>();
}

class _SyncfusionRegionMapChartState<T>
    extends State<SyncfusionRegionMapChart<T>> {
  late final SyncfusionRegionMapViewportCoordinator _viewportCoordinator;
  final SyncfusionRegionMapMarkerOverlayCoordinator _markerOverlayCoordinator =
      SyncfusionRegionMapMarkerOverlayCoordinator();
  final SyncfusionRegionMapShapeSourceCache _shapeSourceCache =
      SyncfusionRegionMapShapeSourceCache();
  final SyncfusionRegionMapSurfaceLifecycle _surfaceLifecycle =
      SyncfusionRegionMapSurfaceLifecycle();

  @override
  void initState() {
    super.initState();
    _viewportCoordinator = SyncfusionRegionMapViewportCoordinator(
      operationLabel: 'SyncfusionRegionMapChart',
    );
    _syncViewportCoordinatorConfig();
    final zoomPanBehavior = _viewportCoordinator.buildZoomPanBehavior();
    _viewportCoordinator.initFromZoomPanBehavior(zoomPanBehavior);
    _applyPreferredViewport();
  }

  @override
  void didUpdateWidget(covariant SyncfusionRegionMapChart<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.isLoading && !widget.isLoading) {
      _surfaceLifecycle.noteLoadingEnded();
      _markerOverlayCoordinator.reset();
    }
    if (!oldWidget.isLoading && widget.isLoading) {
      _markerOverlayCoordinator.reset();
    }
    if (oldWidget.points.isNotEmpty && widget.points.isEmpty) {
      _markerOverlayCoordinator.cancelSchedule();
    }
    if (widget.lifecycleRecoveryRequestId > 0 &&
        oldWidget.lifecycleRecoveryRequestId !=
            widget.lifecycleRecoveryRequestId) {
      _recoverAfterHiddenLifecycle();
    }

    _syncViewportCoordinatorConfig();
    _viewportCoordinator.updateZoomPanBehaviorFlags(
      enableDoubleTapZooming:
          widget.style.enableDoubleTapZooming ||
          widget.preset == AppChartPreset.explorable,
      showToolbar: widget.preset == AppChartPreset.explorable,
    );
    // Remount after loading/geometry change owns viewport re-seed; applying
    // against a behavior still holding Syncfusion's disposed controller crashes.
    final remountPending = _surfaceLifecycle.pendingRemountReason != null;
    if (!remountPending &&
        !_isPreferredViewportSuppressed &&
        RegionMapViewportSyncPolicy.shouldApplyPreferredViewportOnWidgetUpdate(
          previousPreferred: oldWidget.preferredViewport,
          nextPreferred: widget.preferredViewport,
          userHasManualViewport:
              _viewportCoordinator.state.userHasManualViewport,
        )) {
      _applyPreferredViewport();
    } else if (!remountPending &&
        !_isPreferredViewportSuppressed &&
        RegionMapViewportSyncPolicy.shouldSyncZoomPanBehaviorOnWidgetUpdate(
          hasPreferredViewport: widget.preferredViewport != null,
          userHasManualViewport:
              _viewportCoordinator.state.userHasManualViewport,
          lockPreferredViewportReapply:
              _viewportCoordinator.lockPreferredViewportReapply,
          behaviorZoomLevel: _viewportCoordinator.zoomPanBehavior.zoomLevel,
          behaviorCenterLatitude:
              _viewportCoordinator.zoomPanBehavior.focalLatLng?.latitude,
          behaviorCenterLongitude:
              _viewportCoordinator.zoomPanBehavior.focalLatLng?.longitude,
          stateZoomLevel: _viewportCoordinator.state.zoomLevel,
          stateCenterLatitude: _viewportCoordinator.state.centerLatitude,
          stateCenterLongitude: _viewportCoordinator.state.centerLongitude,
        )) {
      _viewportCoordinator.applyZoomPanBehaviorViewport(
        reason: 'widget_update_sync',
        mounted: mounted,
        isLoading: widget.isLoading,
        shouldLog: false,
        suppressViewportCallbacks: true,
      );
    }
  }

  @override
  void dispose() {
    _shapeSourceCache.dispose();
    super.dispose();
  }

  void _syncViewportCoordinatorConfig() {
    _viewportCoordinator.updateConfig(
      minZoomLevel: widget.style.minZoomLevel,
      maxZoomLevel: widget.style.maxZoomLevel,
      isZoomPanEnabled:
          widget.style.enableZoomPan &&
          widget.preset == AppChartPreset.explorable,
      enableDoubleTapZooming:
          widget.style.enableDoubleTapZooming ||
          widget.preset == AppChartPreset.explorable,
      showToolbar: widget.preset == AppChartPreset.explorable,
    );
  }

  bool get _isPointerWheelZoomEnabled =>
      SyncfusionRegionMapPointerWheelPolicy.isEnabled(
        zoomPanEnabled: _viewportCoordinator.isZoomPanEnabled,
      );

  bool get _isPreferredViewportSuppressed =>
      widget.viewportController?.suppressPreferredViewport ?? false;

  bool get _showResetViewportButton =>
      _viewportCoordinator.isZoomPanEnabled &&
      RegionMapViewportSyncPolicy.shouldShowResetViewportButton(
        hasPreferredViewport:
            widget.preferredViewport != null || widget.resetViewport != null,
        userHasManualViewport: _viewportCoordinator.state.userHasManualViewport,
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final chartTheme = AppChartTheme.fromContext(
      context,
      preset: widget.preset,
    );
    final colors = Theme.of(context).appColors;
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final chrome = resolveSyncfusionRegionMapChrome(
      context: context,
      chartTheme: chartTheme,
      styleHeight: widget.style.height,
    );
    final resolvedHeight = chrome.height;
    final mapBackground = chrome.background;
    final mapBorderRadius = chrome.borderRadius;

    if (widget.isLoading) {
      _viewportCoordinator.markMapSurfaceDetached();
      return buildSyncfusionRegionMapLoadingState(
        context: context,
        height: resolvedHeight,
        mapBackground: mapBackground,
        mapBorderRadius: mapBorderRadius,
        loadingLabel: resolveSyncfusionRegionMapLoadingLabel(
          l10n: l10n,
          styleMessage: widget.style.mapLoadingMessage,
        ),
        indicatorColor: chartTheme.primaryColor,
      );
    }

    if (widget.items.isEmpty && widget.emptyPlaceholder != null) {
      _viewportCoordinator.markMapSurfaceDetached();
      return buildSyncfusionRegionMapEmptyPlaceholderState(
        context: context,
        height: resolvedHeight,
        mapBackground: mapBackground,
        mapBorderRadius: mapBorderRadius,
        placeholder: widget.emptyPlaceholder!,
      );
    }

    if (widget.items.isEmpty) {
      _viewportCoordinator.markMapSurfaceDetached();
      return buildSyncfusionRegionMapDefaultEmptyState(
        context: context,
        height: resolvedHeight,
        mapBackground: mapBackground,
        mapBorderRadius: mapBorderRadius,
        emptyLabel: resolveSyncfusionRegionMapEmptyLabel(
          l10n: l10n,
          styleMessage: widget.style.emptyStateMessage,
        ),
      );
    }

    final regionKeys = widget.items
        .map(widget.regionKeyBuilder)
        .toList(growable: false);
    final regionLabels = widget.items
        .map(widget.regionLabelBuilder)
        .toList(growable: false);
    final metricValues = widget.items
        .map((item) => widget.metric.valueBuilder(item).toDouble())
        .toList(growable: false);

    final selectedIndex = widget.selectedRegionKey == null
        ? -1
        : regionKeys.indexOf(widget.selectedRegionKey!);

    final lowColor =
        widget.style.lowValueColor ??
        chartTheme.primaryColor.withValues(alpha: 0.18);
    final highColor = widget.style.highValueColor ?? chartTheme.primaryColor;
    final metricRange = resolveMetricRange(metricValues);

    _shapeSourceCache.updateMetricBuffer(
      metricValues: metricValues,
      lowColor: lowColor,
      highColor: highColor,
      metricMinValue: metricRange.minValue,
      metricRange: metricRange.range,
    );

    final geometryFingerprint = _shapeSourceCache.geometryFingerprint(
      mapDefinition: widget.mapDefinition,
      itemCount: widget.items.length,
      regionKeys: regionKeys,
      regionLabels: regionLabels,
      showDataLabels: widget.style.showDataLabels,
    );
    final mapSurfaceStableKey = geometryFingerprint;
    final stableKeyChanged =
        _surfaceLifecycle.cachedMapSurfaceStableKey != null &&
        _surfaceLifecycle.cachedMapSurfaceStableKey != mapSurfaceStableKey;
    _surfaceLifecycle.handleNextStableKey(
      nextMapSurfaceStableKey: mapSurfaceStableKey,
      stableKeyChanged: stableKeyChanged,
      markerOverlay: _markerOverlayCoordinator,
      viewport: _viewportCoordinator,
      shapeSourceCache: _shapeSourceCache,
      mounted: mounted,
      preferredViewport: widget.preferredViewport,
      hasPreferredViewport: widget.preferredViewport != null,
      pointCount: widget.points.length,
      itemCount: widget.items.length,
    );
    _viewportCoordinator.markMapSurfaceAttached();

    final shapeSource = _shapeSourceCache.resolve(
      geometryFingerprint: geometryFingerprint,
      mapDefinition: widget.mapDefinition,
      itemCount: widget.items.length,
      regionKeys: regionKeys,
      regionLabels: regionLabels,
      showDataLabels: widget.style.showDataLabels,
    );

    final tooltipTextStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: colors.inverseOnSurface,
      fontWeight: FontWeight.w600,
    );
    final mapBuilderContext = context;
    final deferMarkers = RegionMapMarkerOverlayPolicy.shouldDeferMarkers(
      isLoading: widget.isLoading,
      markersOverlayReady: _markerOverlayCoordinator.markersOverlayReady,
      pointCount: widget.points.length,
      itemCount: widget.items.length,
    );
    final mapSurfaceKey = ValueKey<int>(
      RegionMapMarkerOverlayPolicy.mapSurfaceKeyFingerprint(
        geometryFingerprint: mapSurfaceStableKey,
        markerOverlayMountGeneration:
            _markerOverlayCoordinator.markerOverlayMountGeneration,
      ),
    );
    final markerPoints = RegionMapMarkerOverlayPolicy.effectivePoints(
      points: widget.points,
      deferMarkers: deferMarkers,
    );
    if (deferMarkers) {
      _scheduleMarkersOverlayReady(mapSurfaceStableKey);
    }

    final legend = widget.style.showLegend
        ? SyncfusionRegionMapValueLegend(
            title: widget.metric.legendLabel,
            values: metricValues,
            lowColor: lowColor,
            highColor: highColor,
            numberFormat: widget.style.legendNumberFormat,
            gapSm: tokens.gapSm,
            gapXs: tokens.gapXs,
            textStyle:
                widget.style.legendLabelTextStyle ??
                Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
          )
        : null;

    return SyncfusionRegionMapSurface(
      height: resolvedHeight,
      background: mapBackground,
      borderRadius: mapBorderRadius,
      padding: widget.style.chartPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (widget.isRefreshing)
            LinearProgressIndicator(
              backgroundColor: Colors.transparent,
              color: chartTheme.primaryColor.withValues(alpha: 0.6),
              minHeight: 2,
            ),
          Expanded(
            child: _wrapWithPointerWheelZoom(
              RepaintBoundary(
                child: Stack(
                  children: <Widget>[
                    Positioned.fill(
                      child: SyncfusionMapsSemanticsBoundary(
                        excludeOnWindows:
                            widget.style.excludeNativeMapSemanticsOnWindows,
                        label: SyncfusionRegionMapSemantics.mapLabel(
                          l10n: l10n,
                          metricLabel: widget.metric.label,
                          regionCount: regionKeys.length,
                          markerCount: markerPoints.length,
                          selectedIndex: selectedIndex,
                          regionLabels: regionLabels,
                          customSemanticsLabel: widget.style.mapSemanticsLabel,
                        ),
                        child: SfMaps(
                          key: mapSurfaceKey,
                          layers: <MapLayer>[
                            MapShapeLayer(
                              source: shapeSource,
                              selectedIndex: selectedIndex,
                              zoomPanBehavior:
                                  _viewportCoordinator.isZoomPanEnabled
                                  ? _viewportCoordinator.zoomPanBehavior
                                  : null,
                              showDataLabels: widget.style.showDataLabels,
                              dataLabelSettings: MapDataLabelSettings(
                                textStyle:
                                    widget.style.dataLabelTextStyle ??
                                    Theme.of(
                                      context,
                                    ).textTheme.labelSmall?.copyWith(
                                      color: colors.onSurfaceVariant,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              strokeColor:
                                  widget.style.shapeStrokeColor ??
                                  colors.outlineVariant.withValues(alpha: 0.8),
                              strokeWidth: widget.style.shapeStrokeWidth,
                              shapeTooltipBuilder:
                                  !widget.style.showTooltip ||
                                      !widget.style.showShapeTooltip
                                  ? null
                                  : (context, index) {
                                      final item = widget.items[index];
                                      final fallbackMetric = metricValues[index]
                                          .toStringAsFixed(1);
                                      final tooltipText =
                                          widget.metric.tooltipBuilder?.call(
                                            item,
                                          ) ??
                                          '${regionLabels[index]}: $fallbackMetric';
                                      return Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: Text(
                                          tooltipText,
                                          style: tooltipTextStyle,
                                        ),
                                      );
                                    },
                              tooltipSettings: MapTooltipSettings(
                                color: colors.inverseSurface,
                                strokeColor: colors.outlineVariant,
                                strokeWidth: 1,
                              ),
                              selectionSettings: MapSelectionSettings(
                                color:
                                    widget.style.selectionColor ??
                                    chartTheme.primaryColor.withValues(
                                      alpha: 0.25,
                                    ),
                                strokeColor:
                                    widget.style.selectionStrokeColor ??
                                    chartTheme.primaryColor,
                                strokeWidth: widget.style.selectionStrokeWidth,
                              ),
                              initialMarkersCount: markerPoints.length,
                              markerBuilder: markerPoints.isEmpty
                                  ? null
                                  : (context, index) {
                                      final point = markerPoints[index];
                                      return SyncfusionRegionMapMarkerBuilder.build(
                                        mapBuilderContext: mapBuilderContext,
                                        point: point,
                                        index: index,
                                        defaultMarkerStyle: widget.markerStyle,
                                        defaultColor: chartTheme.primaryColor,
                                        defaultStrokeColor: colors.surface,
                                        markerBuilder: widget.markerBuilder,
                                        onPointTap: widget.onPointTap,
                                      );
                                    },
                              markerTooltipBuilder:
                                  markerPoints.isEmpty ||
                                      widget.markerTooltipBuilder == null
                                  ? null
                                  : (context, index) {
                                      final point = markerPoints[index];
                                      return widget.markerTooltipBuilder!(
                                        mapBuilderContext,
                                        point,
                                        index,
                                      );
                                    },
                              onSelectionChanged: (index) =>
                                  _handleRegionSelection(
                                    index: index,
                                    regionKeys: regionKeys,
                                    regionLabels: regionLabels,
                                    metricValues: metricValues,
                                  ),
                              onWillZoom: (details) {
                                if (_viewportCoordinator
                                    .shouldIgnoreGestureViewportFeedback()) {
                                  return true;
                                }
                                _viewportCoordinator.handleWillZoom(
                                  newZoomLevel: details.newZoomLevel,
                                  newVisibleBounds: details.newVisibleBounds,
                                  onViewportChanged: widget.onViewportChanged,
                                  scheduleManualViewportState:
                                      _scheduleManualViewportState,
                                );
                                return true;
                              },
                              onWillPan: (details) {
                                if (_viewportCoordinator
                                    .shouldIgnoreGestureViewportFeedback()) {
                                  return true;
                                }
                                _viewportCoordinator.handleWillPan(
                                  zoomLevel: details.zoomLevel,
                                  newVisibleBounds: details.newVisibleBounds,
                                  onViewportChanged: widget.onViewportChanged,
                                  scheduleManualViewportState:
                                      _scheduleManualViewportState,
                                );
                                return true;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_showResetViewportButton)
                      Positioned(
                        right: tokens.gapSm,
                        bottom: tokens.gapSm,
                        child: SyncfusionRegionMapResetViewportButton(
                          onPressed: _resetPreferredViewport,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (legend != null) ...<Widget>[
            SizedBox(height: tokens.gapSm),
            legend,
          ],
        ],
      ),
    );
  }

  Widget _wrapWithPointerWheelZoom(Widget child) {
    if (!_isPointerWheelZoomEnabled) {
      return child;
    }

    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerSignal: _handlePointerSignal,
      child: child,
    );
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (!_isPointerWheelZoomEnabled || event is! PointerScrollEvent) {
      return;
    }

    _viewportCoordinator.handlePointerScrollZoom(
      event: event,
      mounted: () => mounted,
      isLoading: widget.isLoading,
      onViewportChanged: widget.onViewportChanged,
      scheduleManualViewportState: _scheduleManualViewportState,
    );
    GestureBinding.instance.pointerSignalResolver.register(event, (_) {});
  }

  void _resetPreferredViewport() {
    _viewportCoordinator.resetPreferredViewport(
      resetViewport: widget.resetViewport,
      preferredViewport: widget.preferredViewport,
      onResetViewport: widget.onResetViewport,
      mounted: mounted,
      isLoading: widget.isLoading,
      isPreferredViewportSuppressed: _isPreferredViewportSuppressed,
      pointCount: widget.points.length,
      itemCount: widget.items.length,
      scheduleState: () => setState(() {}),
    );
  }

  void _scheduleManualViewportState() {
    _viewportCoordinator.scheduleManualViewportState(
      mounted: () => mounted,
      scheduleState: () => setState(() {}),
    );
  }

  void _applyPreferredViewport({
    bool overrideManualViewport = false,
    AppMapViewport? viewportOverride,
  }) {
    _viewportCoordinator.applyPreferredViewport(
      mounted: mounted,
      isLoading: widget.isLoading,
      isPreferredViewportSuppressed: _isPreferredViewportSuppressed,
      preferredViewport: widget.preferredViewport,
      pointCount: widget.points.length,
      itemCount: widget.items.length,
      overrideManualViewport: overrideManualViewport,
      viewportOverride: viewportOverride,
    );
  }

  void _recoverAfterHiddenLifecycle() {
    _markerOverlayCoordinator.recoverAfterHiddenLifecycle(
      cachedMapSurfaceStableKey: _surfaceLifecycle.cachedMapSurfaceStableKey,
      mounted: () => mounted,
      canCommit: _canCommitMarkersOverlayReady,
      onOverlayReady: () => setState(() {}),
    );
    _viewportCoordinator.applyZoomPanBehaviorViewport(
      reason: 'hidden_lifecycle_recovery',
      mounted: mounted,
      isLoading: widget.isLoading,
    );
  }

  bool _canCommitMarkersOverlayReady(int mapSurfaceStableKey) {
    return widget.points.isNotEmpty &&
        _markerOverlayCoordinator.isScheduledFor(mapSurfaceStableKey) &&
        _surfaceLifecycle.cachedMapSurfaceStableKey == mapSurfaceStableKey;
  }

  void _scheduleMarkersOverlayReady(int mapSurfaceStableKey) {
    _markerOverlayCoordinator.scheduleReady(
      mapSurfaceStableKey: mapSurfaceStableKey,
      mounted: () => mounted,
      canCommit: _canCommitMarkersOverlayReady,
      onOverlayReady: () => setState(() {}),
    );
  }

  void _handleRegionSelection({
    required int index,
    required List<String> regionKeys,
    required List<String> regionLabels,
    required List<double> metricValues,
  }) {
    SyncfusionRegionMapRegionSelectionHandler<T>(
      items: widget.items,
      metric: widget.metric,
      selectedRegionKey: widget.selectedRegionKey,
      currentDrillLevel: widget.currentDrillLevel,
      style: widget.style,
      onRegionTap: widget.onRegionTap,
      onRegionTapEvent: widget.onRegionTapEvent,
      onSelectionChanged: widget.onSelectionChanged,
      onDrillDownRequested: widget.onDrillDownRequested,
    ).handle(
      index: index,
      regionKeys: regionKeys,
      regionLabels: regionLabels,
      metricValues: metricValues,
    );
  }
}

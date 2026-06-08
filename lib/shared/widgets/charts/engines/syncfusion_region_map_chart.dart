import 'dart:math' as math;

import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_theme.dart';
import 'package:colmeia/shared/widgets/charts/app_region_map_chart.dart';
import 'package:colmeia/shared/widgets/charts/brazil_map_layout_constants.dart';
import 'package:colmeia/shared/widgets/charts/region_map_viewport_sync_policy.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

  @override
  State<SyncfusionRegionMapChart<T>> createState() =>
      _SyncfusionRegionMapChartState<T>();
}

class _SyncfusionRegionMapChartState<T>
    extends State<SyncfusionRegionMapChart<T>> {
  static const double _mouseWheelZoomStep = 0.35;

  // Not final: must be recreated when SfMaps remounts after a loading cycle,
  // because Syncfusion disposes the behavior's internal AnimationController
  // when SfMaps unmounts, making it unsafe to reuse the same instance.
  late MapZoomPanBehavior _zoomPanBehavior;
  late _RegionMapViewportState _viewportState;
  _MapSurfaceRemountReason? _pendingMapSurfaceRemountReason;

  MapShapeSource? _cachedMapShapeSource;
  int? _cachedGeometryShapeFingerprint;
  AppMapViewport? _lastAppliedPreferredViewport;
  bool _lockPreferredViewportReapply = false;

  /// Stable identity for [SfMaps] and for deciding when to drop the cached
  /// [MapShapeSource]. Must not depend on marker lat/lng: remounting [SfMaps]
  /// with the same [MapShapeSource] instance breaks GeoJSON data labels until
  /// the source is recreated (e.g. first markers arriving after layout).
  int? _cachedMapSurfaceStableKey;

  /// [MapShapeSource] is cached by geometry only; colors follow the latest metric
  /// via this buffer so metric toggles do not recreate the source (avoids GeoJSON
  /// re-parse on every metric change).
  final List<double> _liveShapeMetricValues = <double>[];
  Color _liveShapeLowColor = Colors.transparent;
  Color _liveShapeHighColor = Colors.transparent;
  double _liveShapeMetricMinValue = 0;
  double _liveShapeMetricRange = 1;

  @override
  void initState() {
    super.initState();
    _zoomPanBehavior = _buildZoomPanBehavior();
    _viewportState = _RegionMapViewportState(
      zoomLevel: _clampZoomLevel(_zoomPanBehavior.zoomLevel),
      centerLatitude: _zoomPanBehavior.focalLatLng?.latitude,
      centerLongitude: _zoomPanBehavior.focalLatLng?.longitude,
    );
    _applyPreferredViewport();
  }

  @override
  void didUpdateWidget(covariant SyncfusionRegionMapChart<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    // SfMaps was absent while isLoading=true. Its disposal invalidates the
    // internal AnimationController inside MapZoomPanBehavior. Recreate it
    // before SfMaps remounts so we start from a clean internal state.
    if (oldWidget.isLoading && !widget.isLoading) {
      _pendingMapSurfaceRemountReason = _MapSurfaceRemountReason.loadingEnded;
    }

    _zoomPanBehavior
      ..enablePanning = _isZoomPanEnabled
      ..enablePinching = _isZoomPanEnabled
      ..enableDoubleTapZooming =
          _isZoomPanEnabled &&
          (widget.style.enableDoubleTapZooming ||
              widget.preset == AppChartPreset.explorable)
      ..minZoomLevel = widget.style.minZoomLevel
      ..maxZoomLevel = widget.style.maxZoomLevel
      ..showToolbar = widget.preset == AppChartPreset.explorable;
    _viewportState = _clampedViewportState(_viewportState);
    if (!_isPreferredViewportSuppressed &&
        RegionMapViewportSyncPolicy.shouldApplyPreferredViewportOnWidgetUpdate(
          previousPreferred: oldWidget.preferredViewport,
          nextPreferred: widget.preferredViewport,
          userHasManualViewport: _viewportState.userHasManualViewport,
        )) {
      _applyPreferredViewport();
    } else if (!_isPreferredViewportSuppressed &&
        RegionMapViewportSyncPolicy.shouldSyncZoomPanBehaviorOnWidgetUpdate(
      hasPreferredViewport: widget.preferredViewport != null,
      userHasManualViewport: _viewportState.userHasManualViewport,
      lockPreferredViewportReapply: _lockPreferredViewportReapply,
      behaviorZoomLevel: _zoomPanBehavior.zoomLevel,
      behaviorCenterLatitude: _zoomPanBehavior.focalLatLng?.latitude,
      behaviorCenterLongitude: _zoomPanBehavior.focalLatLng?.longitude,
      stateZoomLevel: _viewportState.zoomLevel,
      stateCenterLatitude: _viewportState.centerLatitude,
      stateCenterLongitude: _viewportState.centerLongitude,
    )) {
      _applyZoomPanBehaviorViewport(
        reason: 'widget_update_sync',
        shouldLog: false,
        suppressViewportCallbacks: true,
      );
    }
  }

  @override
  void dispose() {
    _cachedMapShapeSource = null;
    _cachedGeometryShapeFingerprint = null;
    _cachedMapSurfaceStableKey = null;
    super.dispose();
  }

  bool get _isZoomPanEnabled =>
      widget.style.enableZoomPan && widget.preset == AppChartPreset.explorable;

  bool get _isPreferredViewportSuppressed =>
      widget.viewportController?.suppressPreferredViewport ?? false;

  bool get _isPointerWheelZoomEnabled {
    if (!_isZoomPanEnabled) {
      return false;
    }
    if (kIsWeb) {
      return true;
    }
    return switch (defaultTargetPlatform) {
      TargetPlatform.linux ||
      TargetPlatform.macOS ||
      TargetPlatform.windows => true,
      TargetPlatform.android ||
      TargetPlatform.fuchsia ||
      TargetPlatform.iOS => false,
    };
  }

  bool get _showResetViewportButton =>
      _isZoomPanEnabled &&
      RegionMapViewportSyncPolicy.shouldShowResetViewportButton(
        hasPreferredViewport: widget.preferredViewport != null,
        userHasManualViewport: _viewportState.userHasManualViewport,
      );

  bool get _renderLegacyResetViewportButton => false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final chartTheme = AppChartTheme.fromContext(
      context,
      preset: widget.preset,
    );
    final colors = Theme.of(context).appColors;
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final resolvedHeight = widget.style.height ?? chartTheme.height;

    final mapBackground = Theme.of(
      context,
    ).colorScheme.surfaceContainerLow.withValues(alpha: 0.5);
    final mapBorderRadius = BorderRadius.circular(tokens.cardRadius);

    if (widget.isLoading) {
      // Loading state: apenas spinner + mensagem dentro do _MapSurface.
      // Nao renderizamos um SfMaps "warmup" em Offstage porque ter dois
      // SfMaps simultaneos (warmup + render) baixava o GeoJSON em duplicidade
      // e podia causar OOM/crash nativo em mobile com mapas grandes (Brasil
      // completo). A Syncfusion mantem cache de GeoJSON parseado por URL
      // dentro do MapShapeSource, entao o primeiro mount do SfMaps real ja
      // cobre o caso quente em reaberturas seguintes da mesma view.
      final loadingLabel =
          widget.style.mapLoadingMessage ?? l10n.regionMapLoadingMessage;
      return _MapSurface(
        height: resolvedHeight,
        background: mapBackground,
        borderRadius: mapBorderRadius,
        child: Center(
          child: Semantics(
            label: loadingLabel,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: chartTheme.primaryColor,
                  ),
                ),
                SizedBox(height: tokens.gapMd),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: tokens.gapMd),
                  child: Text(
                    loadingLabel,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (widget.items.isEmpty && widget.emptyPlaceholder != null) {
      return _MapSurface(
        height: resolvedHeight,
        background: mapBackground,
        borderRadius: mapBorderRadius,
        child: Center(child: widget.emptyPlaceholder),
      );
    }

    if (widget.items.isEmpty) {
      final emptyLabel =
          widget.style.emptyStateMessage ?? l10n.regionMapEmptyStateMessage;
      return _MapSurface(
        height: resolvedHeight,
        background: mapBackground,
        borderRadius: mapBorderRadius,
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(tokens.gapMd * 2),
            child: Semantics(
              label: emptyLabel,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    Icons.map_outlined,
                    size: 40,
                    color: colors.onSurfaceVariant,
                  ),
                  SizedBox(height: tokens.gapMd),
                  Text(
                    emptyLabel,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
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
    final metricRange = _resolveMetricRange(metricValues);

    _liveShapeLowColor = lowColor;
    _liveShapeHighColor = highColor;
    _liveShapeMetricValues
      ..clear()
      ..addAll(metricValues);
    _liveShapeMetricMinValue = metricRange.minValue;
    _liveShapeMetricRange = metricRange.range;

    final geometryFingerprint = _geometryShapeSourceFingerprint(
      regionKeys: regionKeys,
      regionLabels: regionLabels,
    );
    // Keyed remount is reserved for structural changes in the map base.
    // Marker/value updates should flow through the existing surface so the
    // user keeps spatial context during refreshes.
    final mapSurfaceStableKey = geometryFingerprint;
    final stableKeyChanged =
        _cachedMapSurfaceStableKey != null &&
        _cachedMapSurfaceStableKey != mapSurfaceStableKey;
    _handleMapSurfaceRemount(
      nextMapSurfaceStableKey: mapSurfaceStableKey,
      stableKeyChanged: stableKeyChanged,
    );

    final MapShapeSource shapeSource;
    if (_cachedGeometryShapeFingerprint == geometryFingerprint &&
        _cachedMapShapeSource != null) {
      shapeSource = _cachedMapShapeSource!;
    } else {
      shapeSource = _buildShapeSource(
        regionKeys: regionKeys,
        regionLabels: regionLabels,
      );
      _cachedMapShapeSource = shapeSource;
      _cachedGeometryShapeFingerprint = geometryFingerprint;
    }

    final tooltipTextStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: colors.inverseOnSurface,
      fontWeight: FontWeight.w600,
    );
    final mapBuilderContext = context;
    final mapSurfaceKey = ValueKey<int>(mapSurfaceStableKey);

    final legend = widget.style.showLegend
        ? _MapValueLegend(
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

    return _MapSurface(
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
                      child: _SyncfusionMapsSemanticsBoundary(
                        excludeOnWindows:
                            widget.style.excludeNativeMapSemanticsOnWindows,
                        label: _mapSemanticsLabel(
                          regionCount: regionKeys.length,
                          markerCount: widget.points.length,
                          selectedIndex: selectedIndex,
                          regionLabels: regionLabels,
                        ),
                        child: SfMaps(
                          key: mapSurfaceKey,
                          layers: <MapLayer>[
                            MapShapeLayer(
                              source: shapeSource,
                              selectedIndex: selectedIndex,
                              zoomPanBehavior: _isZoomPanEnabled
                                  ? _zoomPanBehavior
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
                              initialMarkersCount: widget.points.length,
                              markerBuilder: widget.points.isEmpty
                                  ? null
                                  : (context, index) {
                                      final point = widget.points[index];
                                      final effectiveStyle =
                                          point.style ?? widget.markerStyle;
                                      final fallbackChild = _MarkerShape(
                                        style: effectiveStyle,
                                        defaultColor: chartTheme.primaryColor,
                                        defaultStrokeColor: colors.surface,
                                      );
                                      final builtChild =
                                          widget.markerBuilder?.call(
                                            mapBuilderContext,
                                            point,
                                            index,
                                          ) ??
                                          fallbackChild;
                                      final tapWrappedChild =
                                          widget.onPointTap == null
                                          ? builtChild
                                          : GestureDetector(
                                              behavior: HitTestBehavior.opaque,
                                              onTap: () =>
                                                  widget.onPointTap!.call(
                                                    AppMapPointTapEvent(
                                                      point: point,
                                                      index: index,
                                                    ),
                                                  ),
                                              child: builtChild,
                                            );
                                      return MapMarker(
                                        latitude: point.latitude,
                                        longitude: point.longitude,
                                        size: Size.square(effectiveStyle.size),
                                        child: tapWrappedChild,
                                      );
                                    },
                              markerTooltipBuilder:
                                  widget.points.isEmpty ||
                                      widget.markerTooltipBuilder == null
                                  ? null
                                  : (context, index) {
                                      final point = widget.points[index];
                                      return widget.markerTooltipBuilder!(
                                        mapBuilderContext,
                                        point,
                                        index,
                                      );
                                    },
                              onSelectionChanged: (index) {
                                if (index < 0 || index >= widget.items.length) {
                                  return;
                                }

                                final item = widget.items[index];
                                final regionKey = regionKeys[index];
                                final regionLabel = regionLabels[index];
                                final metricValue = metricValues[index];
                                final previousRegionKey =
                                    widget.selectedRegionKey;
                                final previousIndex = previousRegionKey == null
                                    ? -1
                                    : regionKeys.indexOf(previousRegionKey);
                                final previousItem = previousIndex >= 0
                                    ? widget.items[previousIndex]
                                    : null;

                                // Re-tap on already-selected region: deselect,
                                // unless a drill-down would be triggered by this tap.
                                if (regionKey == widget.selectedRegionKey) {
                                  final nextDrill = _nextDrillLevel(
                                    widget.currentDrillLevel,
                                  );
                                  final canDrillFurther =
                                      widget.style.enableAutoDrillOnTap &&
                                      nextDrill != null &&
                                      _shouldAutoDrillTo(nextDrill);
                                  if (!canDrillFurther) {
                                    widget.onSelectionChanged?.call(
                                      AppMapSelectionChangedEvent<T>(
                                        previousRegionKey: previousRegionKey,
                                        currentRegionKey: null,
                                        previousItem: item,
                                        metricKey: widget.metric.key,
                                        metricLabel: widget.metric.label,
                                      ),
                                    );
                                    return;
                                  }
                                }

                                widget.onRegionTap?.call(item, regionKey);
                                widget.onRegionTapEvent?.call(
                                  AppMapRegionTapEvent<T>(
                                    item: item,
                                    regionKey: regionKey,
                                    regionLabel: regionLabel,
                                    metricKey: widget.metric.key,
                                    metricValue: metricValue,
                                    index: index,
                                  ),
                                );
                                widget.onSelectionChanged?.call(
                                  AppMapSelectionChangedEvent<T>(
                                    previousRegionKey: previousRegionKey,
                                    currentRegionKey: regionKey,
                                    previousItem: previousItem,
                                    currentItem: item,
                                    metricKey: widget.metric.key,
                                    metricLabel: widget.metric.label,
                                  ),
                                );

                                if (widget.style.enableAutoDrillOnTap) {
                                  final nextDrillLevel = _nextDrillLevel(
                                    widget.currentDrillLevel,
                                  );
                                  if (nextDrillLevel != null &&
                                      _shouldAutoDrillTo(nextDrillLevel)) {
                                    widget.onDrillDownRequested?.call(
                                      AppMapDrillDownEvent<T>(
                                        item: item,
                                        regionKey: regionKey,
                                        fromLevel: widget.currentDrillLevel,
                                        toLevel: nextDrillLevel,
                                      ),
                                    );
                                  }
                                }
                              },
                              onWillZoom: (details) {
                                if (_shouldIgnoreGestureViewportFeedback()) {
                                  return true;
                                }
                                _viewportState = _viewportState.copyWith(
                                  zoomLevel: _clampZoomLevel(
                                    details.newZoomLevel ??
                                        _viewportState.zoomLevel,
                                  ),
                                );
                                _emitViewportChanged(
                                  source: RegionMapViewportSyncPolicy
                                      .changeSourceForUserPinchOrPan(),
                                  bounds: details.newVisibleBounds,
                                );
                                return true;
                              },
                              onWillPan: (details) {
                                if (_shouldIgnoreGestureViewportFeedback()) {
                                  return true;
                                }
                                _viewportState = _viewportState.copyWith(
                                  zoomLevel: _clampZoomLevel(
                                    details.zoomLevel ??
                                        _viewportState.zoomLevel,
                                  ),
                                );
                                _emitViewportChanged(
                                  source: RegionMapViewportSyncPolicy
                                      .changeSourceForUserPinchOrPan(),
                                  bounds: details.newVisibleBounds,
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
                        child: _MapResetViewportButton(
                          onPressed: _resetPreferredViewport,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (_renderLegacyResetViewportButton &&
              _showResetViewportButton) ...<Widget>[
            SizedBox(height: tokens.gapXs),
            Align(
              alignment: Alignment.centerRight,
              child: Semantics(
                label: 'Restaurar visão original do mapa',
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _viewportState = _viewportState.copyWith(
                        userHasManualViewport: false,
                      );
                    });
                    _applyPreferredViewport();
                  },
                  icon: const Icon(Icons.fit_screen_rounded, size: 16),
                  label: const Text('Restaurar visão'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ],
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

    _applyPointerScrollZoom(event);
    GestureBinding.instance.pointerSignalResolver.register(event, (_) {});
  }

  void _applyPointerScrollZoom(PointerScrollEvent event) {
    if (!mounted ||
        event.scrollDelta.dy == 0 ||
        !RegionMapViewportSyncPolicy.allowsPointerWheelZoom(
          isZoomPanEnabled: _isZoomPanEnabled,
        )) {
      return;
    }

    final currentZoom = _viewportState.zoomLevel;
    final direction = event.scrollDelta.dy < 0 ? 1.0 : -1.0;
    final nextZoom = _clampZoomLevel(
      currentZoom + direction * _mouseWheelZoomStep,
    );

    if ((nextZoom - currentZoom).abs() < 0.001) {
      return;
    }

    _viewportState = _viewportState.copyWith(zoomLevel: nextZoom);
    final applied = _applyZoomPanBehaviorViewport(reason: 'pointer_wheel_zoom');
    if (!applied) {
      return;
    }
    _scheduleManualViewportState();
    _emitViewportChanged(
      source: AppMapViewportChangeSource.user,
    );
  }

  void _resetPreferredViewport() {
    widget.onResetViewport?.call();
    setState(() {
      _viewportState = _viewportState.copyWith(userHasManualViewport: false);
    });
    _lastAppliedPreferredViewport = null;
    _lockPreferredViewportReapply = false;
    final target = widget.resetViewport ?? widget.preferredViewport;
    if (target == null) {
      return;
    }
    _applyPreferredViewport(
      overrideManualViewport: true,
      viewportOverride: target,
    );
  }

  bool _shouldIgnoreGestureViewportFeedback() {
    if (_viewportState.suppressProgrammaticViewportEvents) {
      return true;
    }
    return defaultTargetPlatform == TargetPlatform.windows &&
        widget.preferredViewport == null;
  }

  MapZoomPanBehavior _buildZoomPanBehavior() {
    return MapZoomPanBehavior(
      enablePanning: _isZoomPanEnabled,
      enablePinching: _isZoomPanEnabled,
      enableDoubleTapZooming:
          _isZoomPanEnabled &&
          (widget.style.enableDoubleTapZooming ||
              widget.preset == AppChartPreset.explorable),
      minZoomLevel: widget.style.minZoomLevel,
      maxZoomLevel: widget.style.maxZoomLevel,
      showToolbar: widget.preset == AppChartPreset.explorable,
    );
  }

  void _applyPreferredViewport({
    bool overrideManualViewport = false,
    AppMapViewport? viewportOverride,
  }) {
    if (!mounted || widget.isLoading) {
      _logViewportGuard('preferred_viewport_skipped');
      return;
    }

    if (_isPreferredViewportSuppressed && viewportOverride == null) {
      _logViewportGuard('preferred_viewport_skipped_store_selection');
      return;
    }

    final viewport = viewportOverride ?? widget.preferredViewport;
    if (viewport == null) {
      _viewportState = _viewportState.copyWith(userHasManualViewport: false);
      return;
    }

    if (!overrideManualViewport && _viewportState.userHasManualViewport) {
      _logViewportGuard('preferred_viewport_skipped_manual');
      return;
    }

    if (_preferredViewportMatches(_lastAppliedPreferredViewport, viewport)) {
      _logViewportGuard('preferred_viewport_skipped_unchanged');
      return;
    }

    _viewportState = _clampedViewportState(
      _viewportState.copyWith(
        zoomLevel: viewport.zoomLevel,
        centerLatitude: viewport.centerLatitude,
        centerLongitude: viewport.centerLongitude,
        userHasManualViewport:
            !overrideManualViewport && _viewportState.userHasManualViewport,
        suppressProgrammaticViewportEvents: true,
      ),
    );
    _logViewportLifecycle(
      'Applying preferred viewport',
      context: <String, Object?>{
        'operation': 'SyncfusionRegionMapChart',
        'zoomLevel': _viewportState.zoomLevel,
        'centerLatitude': _viewportState.centerLatitude,
        'centerLongitude': _viewportState.centerLongitude,
        'pointCount': widget.points.length,
        'itemCount': widget.items.length,
      },
    );
    _applyZoomPanBehaviorViewport(reason: 'preferred_viewport');
    _lastAppliedPreferredViewport = viewport;
    _lockPreferredViewportReapply = true;
    _releaseProgrammaticViewportSuppressionAfterFrame();
  }

  bool _preferredViewportMatches(
    AppMapViewport? previous,
    AppMapViewport next,
  ) {
    if (previous == null) {
      return false;
    }
    if ((previous.zoomLevel - next.zoomLevel).abs() >=
        BrazilMapLayoutConstants.preferredViewportZoomEpsilon) {
      return false;
    }
    final previousLat = previous.centerLatitude;
    final previousLng = previous.centerLongitude;
    final nextLat = next.centerLatitude;
    final nextLng = next.centerLongitude;
    if (previousLat == null ||
        previousLng == null ||
        nextLat == null ||
        nextLng == null) {
      return previousLat == nextLat && previousLng == nextLng;
    }
    return (previousLat - nextLat).abs() <
            BrazilMapLayoutConstants.preferredViewportCenterEpsilon &&
        (previousLng - nextLng).abs() <
            BrazilMapLayoutConstants.preferredViewportCenterEpsilon;
  }

  double _clampZoomLevel(double zoomLevel) {
    return zoomLevel.clamp(
      widget.style.minZoomLevel,
      widget.style.maxZoomLevel,
    );
  }

  _RegionMapViewportState _clampedViewportState(
    _RegionMapViewportState state,
  ) {
    return state.copyWith(zoomLevel: _clampZoomLevel(state.zoomLevel));
  }

  void _handleMapSurfaceRemount({
    required int nextMapSurfaceStableKey,
    required bool stableKeyChanged,
  }) {
    if (stableKeyChanged) {
      _pendingMapSurfaceRemountReason ??=
          _MapSurfaceRemountReason.stableKeyChanged;
    }

    final remountReason = _pendingMapSurfaceRemountReason;
    if (remountReason == null) {
      _cachedMapSurfaceStableKey = nextMapSurfaceStableKey;
      return;
    }

    if (remountReason == _MapSurfaceRemountReason.loadingEnded &&
        widget.preferredViewport != null) {
      _viewportState = _clampedViewportState(
        _viewportState.copyWith(
          zoomLevel: widget.preferredViewport!.zoomLevel,
          centerLatitude: widget.preferredViewport!.centerLatitude,
          centerLongitude: widget.preferredViewport!.centerLongitude,
          userHasManualViewport: false,
          suppressProgrammaticViewportEvents: true,
        ),
      );
      _releaseProgrammaticViewportSuppressionAfterFrame();
    }

    _logViewportLifecycle(
      'Recreating zoom pan behavior',
      context: <String, Object?>{
        'operation': 'SyncfusionRegionMapChart',
        'reason': remountReason.name,
        'stableKeyChanged': stableKeyChanged,
        'nextMapSurfaceStableKey': nextMapSurfaceStableKey,
        'zoomLevel': _viewportState.zoomLevel,
        'hasPreferredViewport': widget.preferredViewport != null,
        'userHasManualViewport': _viewportState.userHasManualViewport,
        'pointCount': widget.points.length,
        'itemCount': widget.items.length,
      },
    );

    _zoomPanBehavior = _buildZoomPanBehavior();
    _applyZoomPanBehaviorViewport(
      reason: 'map_surface_remount_${remountReason.name}',
      shouldLog: false,
    );
    _cachedMapShapeSource = null;
    _cachedGeometryShapeFingerprint = null;
    _cachedMapSurfaceStableKey = nextMapSurfaceStableKey;
    _pendingMapSurfaceRemountReason = null;
  }

  bool _applyZoomPanBehaviorViewport({
    required String reason,
    bool shouldLog = true,
    bool suppressViewportCallbacks = false,
  }) {
    if (!mounted || widget.isLoading) {
      _logViewportGuard(reason);
      return false;
    }

    if (!RegionMapViewportSyncPolicy.zoomPanBehaviorDriftsFromViewportState(
      behaviorZoomLevel: _zoomPanBehavior.zoomLevel,
      behaviorCenterLatitude: _zoomPanBehavior.focalLatLng?.latitude,
      behaviorCenterLongitude: _zoomPanBehavior.focalLatLng?.longitude,
      stateZoomLevel: _viewportState.zoomLevel,
      stateCenterLatitude: _viewportState.centerLatitude,
      stateCenterLongitude: _viewportState.centerLongitude,
    )) {
      return false;
    }

    final previousSuppression = _viewportState.suppressProgrammaticViewportEvents;
    if (suppressViewportCallbacks) {
      _viewportState = _viewportState.copyWith(
        suppressProgrammaticViewportEvents: true,
      );
    }

    _viewportState = _clampedViewportState(_viewportState);
    _zoomPanBehavior.zoomLevel = _viewportState.zoomLevel;
    if (_viewportState.centerLatitude != null &&
        _viewportState.centerLongitude != null) {
      _zoomPanBehavior.focalLatLng = MapLatLng(
        _viewportState.centerLatitude!,
        _viewportState.centerLongitude!,
      );
    }
    if (shouldLog) {
      _logViewportLifecycle(
        'Applied zoom pan behavior viewport',
        context: <String, Object?>{
          'operation': 'SyncfusionRegionMapChart',
          'reason': reason,
          'zoomLevel': _viewportState.zoomLevel,
          'centerLatitude': _viewportState.centerLatitude,
          'centerLongitude': _viewportState.centerLongitude,
        },
      );
    }

    if (suppressViewportCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _viewportState = _viewportState.copyWith(
          suppressProgrammaticViewportEvents: previousSuppression,
        );
      });
    }
    return true;
  }

  int _geometryShapeSourceFingerprint({
    required List<String> regionKeys,
    required List<String> regionLabels,
  }) {
    final def = widget.mapDefinition;
    final bytes = def.bytes;
    final int bytesTag;
    if (bytes == null || bytes.isEmpty) {
      bytesTag = 0;
    } else {
      final mid = bytes.length ~/ 2;
      bytesTag = Object.hash(
        bytes.length,
        bytes[0] ^ bytes[mid] ^ bytes[bytes.length - 1],
      );
    }

    return Object.hash(
      def.sourceType,
      def.pathOrUrl,
      bytesTag,
      def.shapeDataField,
      def.regionLevel,
      widget.items.length,
      Object.hashAll(regionKeys),
      widget.style.showDataLabels ? Object.hashAll(regionLabels) : 0,
    );
  }

  ({double minValue, double maxValue, double range}) _resolveMetricRange(
    List<double> values,
  ) {
    if (values.isEmpty) {
      return (minValue: 0, maxValue: 0, range: 1);
    }

    var minValue = values.first;
    var maxValue = values.first;
    for (final value in values.skip(1)) {
      if (value < minValue) {
        minValue = value;
      }
      if (value > maxValue) {
        maxValue = value;
      }
    }

    final rawRange = maxValue - minValue;
    return (
      minValue: minValue,
      maxValue: maxValue,
      range: rawRange.abs() < 0.0001 ? 1.0 : rawRange,
    );
  }

  Color _shapeColorValueForIndex(int index) {
    final values = _liveShapeMetricValues;
    if (values.isEmpty || index < 0 || index >= values.length) {
      return _liveShapeLowColor;
    }
    final normalized =
        ((values[index] - _liveShapeMetricMinValue) / _liveShapeMetricRange)
            .clamp(
              0.0,
              1.0,
            );
    return Color.lerp(_liveShapeLowColor, _liveShapeHighColor, normalized)!;
  }

  MapShapeSource _buildShapeSource({
    required List<String> regionKeys,
    required List<String> regionLabels,
  }) {
    final shapeDataField = widget.mapDefinition.shapeDataField;
    final def = widget.mapDefinition;
    return switch (def.sourceType) {
      AppMapSourceType.asset => MapShapeSource.asset(
        def.pathOrUrl!,
        shapeDataField: shapeDataField,
        dataCount: widget.items.length,
        primaryValueMapper: regionKeys.elementAt,
        dataLabelMapper: widget.style.showDataLabels
            ? regionLabels.elementAt
            : null,
        shapeColorValueMapper: _shapeColorValueForIndex,
      ),
      AppMapSourceType.network => MapShapeSource.network(
        widget.mapDefinition.pathOrUrl!,
        shapeDataField: shapeDataField,
        dataCount: widget.items.length,
        primaryValueMapper: regionKeys.elementAt,
        dataLabelMapper: widget.style.showDataLabels
            ? regionLabels.elementAt
            : null,
        shapeColorValueMapper: _shapeColorValueForIndex,
      ),
      AppMapSourceType.memory => MapShapeSource.memory(
        widget.mapDefinition.bytes!,
        shapeDataField: shapeDataField,
        dataCount: widget.items.length,
        primaryValueMapper: regionKeys.elementAt,
        dataLabelMapper: widget.style.showDataLabels
            ? regionLabels.elementAt
            : null,
        shapeColorValueMapper: _shapeColorValueForIndex,
      ),
    };
  }

  AppMapDrillLevel? _nextDrillLevel(AppMapDrillLevel level) {
    return switch (level) {
      AppMapDrillLevel.region => AppMapDrillLevel.state,
      AppMapDrillLevel.state => AppMapDrillLevel.city,
      AppMapDrillLevel.city => AppMapDrillLevel.custom,
      AppMapDrillLevel.custom => null,
    };
  }

  bool _shouldAutoDrillTo(AppMapDrillLevel nextLevel) {
    final ceiling = widget.style.autoDrillCeiling;
    if (ceiling == null) {
      return true;
    }
    return nextLevel.index <= ceiling.index;
  }

  String _mapSemanticsLabel({
    required int regionCount,
    required int markerCount,
    required int selectedIndex,
    required List<String> regionLabels,
  }) {
    final customLabel = widget.style.mapSemanticsLabel?.trim();
    if (customLabel != null && customLabel.isNotEmpty) {
      return customLabel;
    }

    final buffer = StringBuffer()
      ..write('Mapa territorial. ')
      ..write('Metrica: ${widget.metric.label}. ')
      ..write('$regionCount regioes.');
    if (markerCount > 0) {
      buffer.write(' $markerCount pontos no mapa.');
    }
    if (selectedIndex >= 0 && selectedIndex < regionLabels.length) {
      buffer.write(' Selecionado: ${regionLabels[selectedIndex]}.');
    }

    return buffer.toString();
  }

  void _emitViewportChanged({
    required AppMapViewportChangeSource source,
    MapLatLngBounds? bounds,
  }) {
    if (_viewportState.suppressProgrammaticViewportEvents) {
      return;
    }

    final centerLatitude = bounds == null
        ? _viewportState.centerLatitude
        : (bounds.northeast.latitude + bounds.southwest.latitude) / 2;
    final centerLongitude = bounds == null
        ? _viewportState.centerLongitude
        : (bounds.northeast.longitude + bounds.southwest.longitude) / 2;

    _viewportState = _clampedViewportState(
      _viewportState.copyWith(
        centerLatitude: centerLatitude,
        centerLongitude: centerLongitude,
      ),
    );
    if (source == AppMapViewportChangeSource.user) {
      _scheduleManualViewportState();
    }

    final callback = widget.onViewportChanged;
    if (callback == null) {
      return;
    }

    callback(
      AppMapViewportChangedEvent(
        viewport: AppMapViewport(
          zoomLevel: _viewportState.zoomLevel,
          centerLatitude: _viewportState.centerLatitude,
          centerLongitude: _viewportState.centerLongitude,
          bounds: bounds == null
              ? null
              : AppMapViewportBounds(
                  north: bounds.northeast.latitude,
                  south: bounds.southwest.latitude,
                  east: bounds.northeast.longitude,
                  west: bounds.southwest.longitude,
                ),
        ),
        source: source,
      ),
    );
  }

  void _scheduleManualViewportState() {
    // Reveal the reset-viewport button after the first user interaction.
    // Uses addPostFrameCallback because Syncfusion calls the pan/zoom hooks
    // during its own layout pass.
    if (_viewportState.userHasManualViewport) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _viewportState = _viewportState.copyWith(userHasManualViewport: true);
      });
    });
  }

  void _releaseProgrammaticViewportSuppressionAfterFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _viewportState = _viewportState.copyWith(
        suppressProgrammaticViewportEvents: false,
      );
    });
  }

  void _logViewportGuard(String reason) {
    _logViewportLifecycle(
      'Skipping viewport behavior update',
      context: <String, Object?>{
        'operation': 'SyncfusionRegionMapChart',
        'reason': reason,
        'mounted': mounted,
        'isLoading': widget.isLoading,
      },
    );
  }

  void _logViewportLifecycle(
    String message, {
    required Map<String, Object?> context,
  }) {
    if (!kDebugMode && !kProfileMode) {
      return;
    }
    AppLogger.debug(message, context: context);
  }
}

enum _MapSurfaceRemountReason {
  loadingEnded,
  stableKeyChanged,
}

@immutable
class _RegionMapViewportState {
  const _RegionMapViewportState({
    required this.zoomLevel,
    this.centerLatitude,
    this.centerLongitude,
    this.userHasManualViewport = false,
    this.suppressProgrammaticViewportEvents = false,
  });

  final double zoomLevel;
  final double? centerLatitude;
  final double? centerLongitude;
  final bool userHasManualViewport;
  final bool suppressProgrammaticViewportEvents;

  _RegionMapViewportState copyWith({
    double? zoomLevel,
    Object? centerLatitude = _regionMapViewportUnset,
    Object? centerLongitude = _regionMapViewportUnset,
    bool? userHasManualViewport,
    bool? suppressProgrammaticViewportEvents,
  }) {
    return _RegionMapViewportState(
      zoomLevel: zoomLevel ?? this.zoomLevel,
      centerLatitude: identical(centerLatitude, _regionMapViewportUnset)
          ? this.centerLatitude
          : centerLatitude as double?,
      centerLongitude: identical(centerLongitude, _regionMapViewportUnset)
          ? this.centerLongitude
          : centerLongitude as double?,
      userHasManualViewport:
          userHasManualViewport ?? this.userHasManualViewport,
      suppressProgrammaticViewportEvents:
          suppressProgrammaticViewportEvents ??
          this.suppressProgrammaticViewportEvents,
    );
  }
}

const Object _regionMapViewportUnset = Object();

class _MapValueLegend extends StatelessWidget {
  const _MapValueLegend({
    required this.values,
    required this.lowColor,
    required this.highColor,
    required this.gapSm,
    required this.gapXs,
    this.title,
    this.numberFormat,
    this.textStyle,
  });

  final List<double> values;
  final Color lowColor;
  final Color highColor;
  final double gapSm;
  final double gapXs;
  final String? title;
  final NumberFormat? numberFormat;
  final TextStyle? textStyle;

  static String _formatEndpoint(double value, NumberFormat? format) {
    if (format != null) {
      return format.format(value);
    }
    return value.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final minValue = values.isEmpty ? 0.0 : values.reduce(math.min);
    final maxValue = values.isEmpty ? 0.0 : values.reduce(math.max);

    final row = Row(
      children: <Widget>[
        Text(
          _formatEndpoint(minValue, numberFormat),
          style: textStyle,
        ),
        SizedBox(width: gapSm),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: <Color>[lowColor, highColor]),
              borderRadius: const BorderRadius.all(Radius.circular(999)),
            ),
            child: const SizedBox(height: 10),
          ),
        ),
        SizedBox(width: gapSm),
        Text(
          _formatEndpoint(maxValue, numberFormat),
          style: textStyle,
        ),
      ],
    );

    if (title == null || title!.isEmpty) {
      return Semantics(
        label: 'Legenda do mapa, de $minValue a $maxValue',
        child: _MapLegendSurface(child: row),
      );
    }

    return Semantics(
      label: 'Legenda: $title, de $minValue a $maxValue',
      child: _MapLegendSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(title!, style: textStyle),
            SizedBox(height: gapXs),
            row,
          ],
        ),
      ),
    );
  }
}

class _MapLegendSurface extends StatelessWidget {
  const _MapLegendSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(tokens.formFieldRadius),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: tokens.gapMd,
          vertical: tokens.gapSm,
        ),
        child: child,
      ),
    );
  }
}

class _MapResetViewportButton extends StatelessWidget {
  const _MapResetViewportButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final colors = theme.appColors;

    return Tooltip(
      message: 'Centralizar mapa',
      child: Semantics(
        button: true,
        label: 'Centralizar mapa',
        child: Material(
          color: colors.surface.withValues(alpha: 0.92),
          elevation: 2,
          borderRadius: BorderRadius.circular(tokens.formFieldRadius),
          child: InkWell(
            borderRadius: BorderRadius.circular(tokens.formFieldRadius),
            onTap: onPressed,
            child: Padding(
              padding: EdgeInsets.all(tokens.gapSm),
              child: Icon(
                Icons.my_location_rounded,
                size: 18,
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Default marker visual: a colored shape with a thin contrasting stroke.
/// Used when no custom [SyncfusionRegionMapChart.markerBuilder] is provided.
class _MarkerShape extends StatelessWidget {
  const _MarkerShape({
    required this.style,
    required this.defaultColor,
    required this.defaultStrokeColor,
  });

  final AppMapMarkerStyle style;
  final Color defaultColor;
  final Color defaultStrokeColor;

  @override
  Widget build(BuildContext context) {
    final fill = style.color ?? defaultColor;
    final stroke = style.strokeColor ?? defaultStrokeColor;
    final size = style.size;

    switch (style.iconType) {
      case AppMapMarkerIcon.circle:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: fill,
            shape: BoxShape.circle,
            border: Border.all(color: stroke, width: style.strokeWidth),
          ),
        );
      case AppMapMarkerIcon.rectangle:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: fill,
            border: Border.all(color: stroke, width: style.strokeWidth),
          ),
        );
      case AppMapMarkerIcon.diamond:
      case AppMapMarkerIcon.triangle:
        return SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _MarkerPolygonPainter(
              iconType: style.iconType,
              fill: fill,
              stroke: stroke,
              strokeWidth: style.strokeWidth,
            ),
          ),
        );
    }
  }
}

class _MarkerPolygonPainter extends CustomPainter {
  _MarkerPolygonPainter({
    required this.iconType,
    required this.fill,
    required this.stroke,
    required this.strokeWidth,
  });

  final AppMapMarkerIcon iconType;
  final Color fill;
  final Color stroke;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;
    switch (iconType) {
      case AppMapMarkerIcon.diamond:
        path
          ..moveTo(w / 2, 0)
          ..lineTo(w, h / 2)
          ..lineTo(w / 2, h)
          ..lineTo(0, h / 2)
          ..close();
      case AppMapMarkerIcon.triangle:
        path
          ..moveTo(w / 2, 0)
          ..lineTo(w, h)
          ..lineTo(0, h)
          ..close();
      case AppMapMarkerIcon.circle:
      case AppMapMarkerIcon.rectangle:
        return;
    }
    final fillPaint = Paint()
      ..color = fill
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeJoin = StrokeJoin.round;
    canvas
      ..drawPath(path, fillPaint)
      ..drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _MarkerPolygonPainter old) {
    return old.iconType != iconType ||
        old.fill != fill ||
        old.stroke != stroke ||
        old.strokeWidth != strokeWidth;
  }
}

class _SyncfusionMapsSemanticsBoundary extends StatelessWidget {
  const _SyncfusionMapsSemanticsBoundary({
    required this.child,
    required this.excludeOnWindows,
    required this.label,
  });

  final Widget child;
  final bool excludeOnWindows;
  final String label;

  @override
  Widget build(BuildContext context) {
    if (!excludeOnWindows || defaultTargetPlatform != TargetPlatform.windows) {
      return child;
    }

    // Syncfusion Maps 33.x can emit transient semantics nodes that Windows'
    // accessibility bridge rejects while the layer mounts or remounts.
    return Semantics(
      container: true,
      label: label,
      child: ExcludeSemantics(child: child),
    );
  }
}

/// Slot visual fixo para o mapa: garante background sutil e cantos arredondados
/// mesmo enquanto o engine baixa/parsa o GeoJSON. Evita area "branca quebrada"
/// no momento entre a chegada dos dados e o primeiro paint do SfMaps.
///
/// Importante: NAO usa ClipRRect porque a Syncfusion 33.x apresenta um bug
/// onde `_GeoJSONLayerState.initState()` acessa `Theme.of(context)` antes
/// de completar o mount, e isso e disparado quando o SfMaps esta dentro de
/// um RenderClipRRect. O fundo arredondado e suficiente visualmente porque
/// o SfMaps pinta com canvas transparente sobre ele e a area do mapa cobre
/// quase toda a superficie em viewports realistas.
class _MapSurface extends StatelessWidget {
  const _MapSurface({
    required this.height,
    required this.background,
    required this.borderRadius,
    required this.child,
    this.padding,
  });

  final double height;
  final Color background;
  final BorderRadius borderRadius;
  final EdgeInsets? padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: borderRadius,
        ),
        child: padding == null
            ? child
            : Padding(padding: padding!, child: child),
      ),
    );
  }
}

import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/core/layout/app_breakpoints.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_tag_chip.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_map_static_data.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_data.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_models.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_shell.dart';
import 'package:colmeia/shared/widgets/charts/app_region_map_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

final NumberFormat _integerFormat = NumberFormat.decimalPattern('pt_BR');

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
    this.style = const AppBrazilStoreSalesMapStyle(),
    this.onStoreTap,
    this.onStoreClusterTap,
    this.onMunicipalityTap,
    this.onStateTap,
    this.onMetricChanged,
    this.onDiagnosticsChanged,
    this.onOpenFullscreen,
  });

  final List<AppBrazilStoreSalesPoint> points;
  final String? title;
  final String? subtitle;
  final Widget? titleTrailing;
  final Widget? belowSubtitle;
  final AppBrazilStoreSalesMapMetric initialMetric;
  final String? selectedStoreId;
  final AppBrazilStoreSalesMapStyle style;
  final ValueChanged<AppBrazilStoreSalesPointTapEvent>? onStoreTap;
  final ValueChanged<AppBrazilStoreSalesPointClusterTapEvent>?
  onStoreClusterTap;
  final ValueChanged<AppBrazilStoreSalesMunicipalityTapEvent>?
  onMunicipalityTap;
  final ValueChanged<AppMapRegionTapEvent<AppBrazilStoreSalesStateBucket>>?
  onStateTap;
  final ValueChanged<AppBrazilStoreSalesMapMetric>? onMetricChanged;
  final ValueChanged<AppBrazilStoreSalesMapDiagnostics>? onDiagnosticsChanged;
  final VoidCallback? onOpenFullscreen;

  @override
  State<AppBrazilStoreSalesMapChart> createState() =>
      _AppBrazilStoreSalesMapChartState();
}

class _AppBrazilStoreSalesMapChartState
    extends State<AppBrazilStoreSalesMapChart> {
  late AppBrazilStoreSalesMapMetric _selectedMetric;
  String? _internalSelectedStoreId;
  String? _internalSelectedStateKey;
  String? _dismissedControlledSelectedStoreId;
  String? _activeRegionKey;
  late double _currentZoomLevel;
  AppBrazilStoreSalesMapDiagnostics? _lastEmittedDiagnostics;
  _BrazilStoreSalesMapSnapshot? _snapshot;

  /// Small shrink of the map tile when height is bounded: real layout (labels,
  /// chips, legend padding) can exceed our header/footer estimates by a few
  /// logical pixels and cause a [Column] overflow.
  static const double _boundedMapTileLayoutSafetyPx = 6;

  @override
  void initState() {
    super.initState();
    _selectedMetric = widget.initialMetric;
    _currentZoomLevel = widget.selectedStoreId == null
        ? AppBrazilMapStaticData.brazilViewport.zoomLevel
        : widget.style.selectedStoreZoomLevel;
  }

  @override
  void didUpdateWidget(covariant AppBrazilStoreSalesMapChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialMetric != widget.initialMetric) {
      _selectedMetric = widget.initialMetric;
      _snapshot = null;
    }

    if (!identical(oldWidget.points, widget.points) ||
        oldWidget.selectedStoreId != widget.selectedStoreId ||
        oldWidget.style != widget.style) {
      if (oldWidget.selectedStoreId != widget.selectedStoreId &&
          widget.selectedStoreId != null) {
        _currentZoomLevel = widget.style.selectedStoreZoomLevel;
        _dismissedControlledSelectedStoreId = null;
      }
      _snapshot = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _resolveSnapshot(context);
    _emitDiagnosticsIfNeeded(snapshot.diagnostics);
    final selectedPoint = snapshot.selectedPoint;
    final selectedMarkerGroup = snapshot.selectedMarkerGroup;
    final selectedRegionKey = widget.style.highlightSelectedState
        ? snapshot.selectedStateKey ?? _internalSelectedStateKey
        : null;
    final preferredViewport = _preferredViewport(snapshot);

    return LayoutBuilder(
      builder: (context, constraints) {
        final l10n = AppLocalizations.of(context);
        final tokens = Theme.of(context).extension<AppThemeTokens>()!;
        final usesCompactMapChrome = constraints.hasBoundedHeight;
        final usesCompactStateLabels =
            usesCompactMapChrome && constraints.maxWidth < 900;
        final mapTileHeight = _resolvedMapTileHeight(
          context: context,
          constraints: constraints,
          style: widget.style,
          snapshot: snapshot,
        );
        final content = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppRegionMapChart<AppBrazilStoreSalesStateBucket>(
              mapDefinition: AppBrazilMapStaticData.brazilUfMapDefinition,
              items: snapshot.buckets,
              metrics: _buildMetrics(l10n),
              selectedMetricKey: _selectedMetric.key,
              selectedRegionKey: selectedRegionKey,
              regionKeyBuilder: (bucket) => bucket.uf,
              regionLabelBuilder: (bucket) => _stateLabelFor(
                bucket,
                compact: usesCompactStateLabels,
              ),
              scopeOptions: widget.style.showRegionFilter
                  ? AppBrazilMapStaticData.regionScopeOptions
                  : const <AppMapScopeOption>[],
              activeScopeKey: _activeRegionKey,
              preferredViewport: preferredViewport,
              points: snapshot.mapPoints,
              markerStyle: AppMapMarkerStyle(
                size: widget.style.markerMinSize,
                color: _markerColor(context),
                strokeColor: _markerStrokeColor(context),
              ),
              markerBuilder: _buildMarker,
              markerTooltipBuilder: _buildMarkerTooltip,
              onMetricChanged: _handleMetricChanged,
              onScopeChanged: widget.style.showRegionFilter
                  ? _handleScopeChanged
                  : null,
              onRegionTapEvent: _handleStateTap,
              onPointTap: _handlePointTap,
              onViewportChanged: _handleViewportChanged,
              preset: widget.style.enableZoomPan
                  ? AppChartPreset.explorable
                  : AppChartPreset.standard,
              style: AppRegionMapChartStyle(
                height: mapTileHeight,
                chartPadding: usesCompactMapChrome
                    ? EdgeInsets.all(tokens.gapSm)
                    : null,
                showLegend: widget.style.showLegend,
                showTooltip: widget.style.showTooltip,
                showDataLabels: widget.style.showDataLabels,
                showMetricSelector: widget.style.showMetricSelector,
                enableZoomPan: widget.style.enableZoomPan,
                lowValueColor: widget.style.lowValueColor ?? _lowColor(context),
                highValueColor:
                    widget.style.highValueColor ?? _highColor(context),
                dataLabelTextStyle: Theme.of(context).textTheme.labelSmall
                    ?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                      fontSize: usesCompactMapChrome ? 10 : null,
                    ),
                metricSelectorPadding: usesCompactMapChrome
                    ? EdgeInsets.zero
                    : null,
                legendNumberFormat: _legendFormat,
                emptyStateMessage: widget.style.emptyStateMessage,
                metricGroupLabel: l10n.brazilStoreSalesMapMetricGroupLabel,
                scopeGroupLabel: l10n.brazilStoreSalesMapRegionGroupLabel,
                mapLoadingMessage: l10n.brazilStoreSalesMapLoadingMessage,
                showGroupLabels: !usesCompactMapChrome,
              ),
            ),
            if (widget.style.showDataQualityNotice &&
                snapshot.diagnostics.hasDiscardedPoints)
              _MapDataQualityNotice(diagnostics: snapshot.diagnostics),
            if (widget.style.showMarkerScaleLegend && snapshot.hasMarkers)
              _MarkerScaleLegend(
                sizeLegendLabel: l10n.brazilStoreSalesMapMarkerSizeLegend,
                metric: _selectedMetric,
                minValue: snapshot.minMarkerValue,
                maxValue: snapshot.maxMarkerValue,
                minSize: widget.style.markerMinSize,
                maxSize: widget.style.markerMaxSize,
                color: _markerColor(context),
                strokeColor: _markerStrokeColor(context),
                visual: widget.style.markerVisual,
              ),
            if (_showBelowMapMarkerDetail &&
                selectedMarkerGroup != null &&
                (selectedMarkerGroup.isMunicipalityAggregate ||
                    selectedMarkerGroup.isCluster))
              _SelectedMunicipalityDetail(
                group: selectedMarkerGroup,
                metric: _selectedMetric,
              )
            else if (_showBelowMapMarkerDetail && selectedPoint != null)
              _SelectedStoreDetail(
                point: selectedPoint,
                metric: _selectedMetric,
              )
            else if (selectedPoint == null &&
                selectedMarkerGroup == null &&
                snapshot.selectedStateBucket != null)
              _SelectedStateDetail(
                bucket: snapshot.selectedStateBucket!,
                metric: _selectedMetric,
              ),
          ],
        );

        if (widget.title == null && widget.subtitle == null) {
          return content;
        }

        return AppChartShell(
          title: widget.title ?? '',
          subtitle: widget.subtitle,
          titleTrailing: widget.titleTrailing,
          belowSubtitle: widget.belowSubtitle,
          onOpenFullscreen: widget.onOpenFullscreen,
          child: content,
        );
      },
    );
  }

  /// [AppRegionMapChart] adds metric/scope controls above the map tile; this
  /// chart adds optional notices and marker legend below. When the parent
  /// height is bounded (e.g. chart fullscreen), the map tile height must leave
  /// room for that vertical chrome to avoid [Column] overflow.
  double _resolvedMapTileHeight({
    required BuildContext context,
    required BoxConstraints constraints,
    required AppBrazilStoreSalesMapStyle style,
    required _BrazilStoreSalesMapSnapshot snapshot,
  }) {
    final requested = style.height;
    final maxParent = constraints.maxHeight;
    if (!maxParent.isFinite || maxParent >= double.infinity) {
      return requested;
    }

    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final headerReserve = _estimateAppRegionMapHeaderReserve(context, style);
    final footerReserve = _estimateFooterReserveBelowMap(
      context,
      style,
      snapshot,
      tokens,
    );
    final spare = maxParent - headerReserve - footerReserve;
    if (!spare.isFinite) {
      return requested;
    }
    return (spare - _boundedMapTileLayoutSafetyPx).clamp(200.0, 4000.0);
  }

  double _estimateAppRegionMapHeaderReserve(
    BuildContext context,
    AppBrazilStoreSalesMapStyle style,
  ) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final scaler = MediaQuery.textScalerOf(context);
    final textTheme = Theme.of(context).textTheme;
    final overlineBlock =
        scaler.scale((textTheme.labelSmall?.fontSize ?? 11) * 1.3) +
        tokens.gapXs +
        scaler.scale((textTheme.bodySmall?.fontSize ?? 12) * 1.35 + 8);
    var reserve = 0.0;
    if (style.showMetricSelector &&
        AppBrazilStoreSalesMapMetric.values.length > 1) {
      reserve += overlineBlock + tokens.gapMd;
    }
    if (style.showRegionFilter) {
      reserve += overlineBlock + tokens.gapMd;
    }
    return reserve.clamp(96.0, 260.0);
  }

  double _estimateFooterReserveBelowMap(
    BuildContext context,
    AppBrazilStoreSalesMapStyle style,
    _BrazilStoreSalesMapSnapshot snapshot,
    AppThemeTokens tokens,
  ) {
    final scaler = MediaQuery.textScalerOf(context);
    var reserve = 0.0;
    if (style.showDataQualityNotice &&
        snapshot.diagnostics.hasDiscardedPoints) {
      reserve += tokens.gapSm + scaler.scale(56);
    }
    if (style.showMarkerScaleLegend && snapshot.hasMarkers) {
      reserve += tokens.gapMd + scaler.scale(36);
    }
    final selectedMarkerGroup = snapshot.selectedMarkerGroup;
    final selectedPoint = snapshot.selectedPoint;
    if (_showBelowMapMarkerDetail &&
        selectedMarkerGroup != null &&
        (selectedMarkerGroup.isMunicipalityAggregate ||
            selectedMarkerGroup.isCluster)) {
      reserve += tokens.gapMd + scaler.scale(160);
    } else if (_showBelowMapMarkerDetail && selectedPoint != null) {
      reserve += tokens.gapMd + scaler.scale(160);
    }
    if (selectedPoint == null &&
        selectedMarkerGroup == null &&
        snapshot.selectedStateBucket != null) {
      reserve += tokens.gapMd + scaler.scale(96);
    }
    return reserve;
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

  bool get _showOverlayMarkerDetail =>
      widget.style.showStoreDetail &&
      widget.style.selectedMarkerDetailPlacement ==
          AppBrazilStoreSalesSelectedMarkerDetailPlacement.overlay;

  bool get _showBelowMapMarkerDetail =>
      widget.style.showStoreDetail &&
      widget.style.selectedMarkerDetailPlacement ==
          AppBrazilStoreSalesSelectedMarkerDetailPlacement.belowMap;

  List<AppMapMetric<AppBrazilStoreSalesStateBucket>> _buildMetrics(
    AppLocalizations l10n,
  ) => <AppMapMetric<AppBrazilStoreSalesStateBucket>>[
    AppMapMetric<AppBrazilStoreSalesStateBucket>(
      key: AppBrazilStoreSalesMapMetric.revenue.key,
      label: AppBrazilStoreSalesMapMetric.revenue.label,
      legendLabel: l10n.brazilStoreSalesMapLegendRevenuePerState,
      valueBuilder: (bucket) => bucket.salesAmount,
      tooltipBuilder: _stateTooltipSubtitle,
    ),
    AppMapMetric<AppBrazilStoreSalesStateBucket>(
      key: AppBrazilStoreSalesMapMetric.salesCount.key,
      label: AppBrazilStoreSalesMapMetric.salesCount.label,
      legendLabel: l10n.brazilStoreSalesMapLegendSalesPerState,
      valueBuilder: (bucket) => bucket.salesCount,
      tooltipBuilder: _stateTooltipSubtitle,
    ),
  ];

  AppMapViewport _preferredViewport(_BrazilStoreSalesMapSnapshot snapshot) {
    final selectedPoint = snapshot.selectedPoint;
    if (widget.style.autoFocusSelectedStore && selectedPoint != null) {
      return AppMapViewport(
        centerLatitude: selectedPoint.latitude,
        centerLongitude: selectedPoint.longitude,
        zoomLevel: widget.style.selectedStoreZoomLevel,
      );
    }

    final regionKey = _activeRegionKey;
    if (regionKey == null) {
      return AppBrazilMapStaticData.brazilViewport;
    }

    return AppBrazilMapStaticData.regionViewports[regionKey] ??
        AppBrazilMapStaticData.brazilViewport;
  }

  String _stateLabelFor(
    AppBrazilStoreSalesStateBucket bucket, {
    bool compact = false,
  }) {
    if (compact) {
      return bucket.uf;
    }

    final labelMode = switch (widget.style.stateLabelMode) {
      AppBrazilStoreSalesStateLabelMode.responsive =>
        AppBreakpoints.isDesktop(context)
            ? AppBrazilStoreSalesStateLabelMode.stateName
            : AppBrazilStoreSalesStateLabelMode.uf,
      final labelMode => labelMode,
    };

    return switch (labelMode) {
      AppBrazilStoreSalesStateLabelMode.uf => bucket.uf,
      AppBrazilStoreSalesStateLabelMode.stateName => bucket.stateName,
      AppBrazilStoreSalesStateLabelMode.responsive => bucket.uf,
    };
  }

  _BrazilStoreSalesMapSnapshot _resolveSnapshot(BuildContext context) {
    final selectedStoreId = _selectedStoreId;
    final snapshot = _snapshot;
    if (snapshot != null &&
        snapshot.metric == _selectedMetric &&
        snapshot.selectedStoreId == selectedStoreId &&
        snapshot.requestedStateKey == _internalSelectedStateKey &&
        snapshot.activeRegionKey == _activeRegionKey &&
        snapshot.zoomLevel == _currentZoomLevel) {
      return snapshot;
    }

    final nextSnapshot = _BrazilStoreSalesMapSnapshot.build(
      context: context,
      points: widget.points,
      metric: _selectedMetric,
      selectedStoreId: selectedStoreId,
      requestedStateKey: _internalSelectedStateKey,
      activeRegionKey: _activeRegionKey,
      zoomLevel: _currentZoomLevel,
      style: widget.style,
    );
    _snapshot = nextSnapshot;
    return nextSnapshot;
  }

  String? get _selectedStoreId {
    final controlledSelectedStoreId = widget.selectedStoreId;
    if (controlledSelectedStoreId != null &&
        controlledSelectedStoreId != _dismissedControlledSelectedStoreId) {
      return controlledSelectedStoreId;
    }
    return _internalSelectedStoreId;
  }

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
      _snapshot = null;
    });
    widget.onMetricChanged?.call(metric);
  }

  void _handleScopeChanged(AppMapScopeChangedEvent event) {
    setState(() {
      _activeRegionKey = event.currentScopeKey;
      _currentZoomLevel =
          (event.currentScopeKey == null
                  ? AppBrazilMapStaticData.brazilViewport
                  : AppBrazilMapStaticData.regionViewports[event
                        .currentScopeKey])
              ?.zoomLevel ??
          AppBrazilMapStaticData.brazilViewport.zoomLevel;
      final selectedStoreId = _selectedStoreId;
      final selectedPoint = _pointById(selectedStoreId);
      if (selectedPoint != null &&
          !AppBrazilStoreSalesMapData.pointMatchesRegion(
            selectedPoint,
            _activeRegionKey,
          )) {
        _internalSelectedStoreId = null;
        _internalSelectedStateKey = null;
      }
      _snapshot = null;
    });
  }

  void _handleStateTap(
    AppMapRegionTapEvent<AppBrazilStoreSalesStateBucket> event,
  ) {
    setState(() {
      _internalSelectedStoreId = null;
      _internalSelectedStateKey = event.regionKey;
      _snapshot = null;
    });
    widget.onStateTap?.call(event);
  }

  void _handlePointTap(AppMapPointTapEvent event) {
    final payload = event.point.payload;
    if (payload is AppBrazilStoreSalesStateBubble) {
      _handleStateBubbleTap(payload, event.index);
      return;
    }

    if (payload is! AppBrazilStoreSalesMarkerGroup) {
      return;
    }

    final point = payload.primaryPoint;
    setState(() {
      _internalSelectedStoreId = point.id;
      _dismissedControlledSelectedStoreId = null;
      _internalSelectedStateKey = AppBrazilStoreSalesMapData.normalizeUf(
        point.uf,
      );
      _currentZoomLevel = widget.style.selectedStoreZoomLevel;
      _snapshot = null;
    });

    if (payload.isMunicipalityAggregate) {
      widget.onMunicipalityTap?.call(
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
      widget.onStoreClusterTap?.call(
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

    widget.onStoreTap?.call(
      AppBrazilStoreSalesPointTapEvent(
        point: point,
        index: event.index,
        metric: _selectedMetric,
      ),
    );
  }

  void _clearSelectedMarkerDetail() {
    setState(() {
      if (widget.selectedStoreId != null) {
        _dismissedControlledSelectedStoreId = widget.selectedStoreId;
      }
      _internalSelectedStoreId = null;
      _snapshot = null;
    });
  }

  void _handleStateBubbleTap(
    AppBrazilStoreSalesStateBubble bubble,
    int index,
  ) {
    final bucket = bubble.bucket;
    setState(() {
      _internalSelectedStoreId = null;
      _internalSelectedStateKey = bucket.uf;
      _snapshot = null;
    });

    widget.onStateTap?.call(
      AppMapRegionTapEvent<AppBrazilStoreSalesStateBucket>(
        item: bucket,
        regionKey: bucket.uf,
        regionLabel: _stateLabelFor(bucket),
        metricKey: _selectedMetric.key,
        metricValue: _selectedMetric.valueForBucket(bucket),
        index: index,
      ),
    );
  }

  void _handleViewportChanged(AppMapViewportChangedEvent event) {
    if (!widget.style.enableProximityCluster) {
      return;
    }

    final nextZoomLevel = event.viewport.zoomLevel;
    if ((nextZoomLevel - _currentZoomLevel).abs() < 0.25) {
      return;
    }

    setState(() {
      _currentZoomLevel = nextZoomLevel;
      _snapshot = null;
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

  AppBrazilStoreSalesPoint? _pointById(String? selectedStoreId) {
    if (selectedStoreId == null) {
      return null;
    }

    for (final point in widget.points) {
      if (point.id == selectedStoreId) {
        return point;
      }
    }

    return null;
  }

  Widget _buildMarker(
    BuildContext context,
    AppMapPoint point,
    int index,
  ) {
    final payload = point.payload;
    if (payload is AppBrazilStoreSalesStateBubble) {
      return _StateBubbleMarker(
        bucket: payload.bucket,
        metric: _selectedMetric,
        style: point.style ?? const AppMapMarkerStyle(),
        semanticLabel: _stateBubbleSemanticLabel(payload.bucket),
      );
    }

    final group = payload is AppBrazilStoreSalesMarkerGroup ? payload : null;
    final style = point.style ?? const AppMapMarkerStyle();
    final marker = _StoreMapMarker(
      style: style,
      count: group?.points.length ?? 1,
      visual: widget.style.markerVisual,
      semanticLabel: _markerSemanticLabel(group),
    );
    final selectedStoreId = _selectedStoreId;
    final showDetailOverlay =
        _showOverlayMarkerDetail &&
        group != null &&
        selectedStoreId != null &&
        group.points.any((point) => point.id == selectedStoreId);

    if (!showDetailOverlay) {
      return marker;
    }

    return _SelectedMarkerDetailAnchor(
      group: group,
      selectedStoreId: selectedStoreId,
      metric: _selectedMetric,
      marker: marker,
      onClose: _clearSelectedMarkerDetail,
    );
  }

  Widget _buildMarkerTooltip(
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

  String _stateTooltipSubtitle(AppBrazilStoreSalesStateBucket bucket) {
    final revenue = AppBrFormatters.currency(bucket.salesAmount);
    final salesCount = _formatInteger(bucket.salesCount);
    final stores = _formatInteger(bucket.storeCount);
    return '$revenue | $salesCount vendas | $stores lojas';
  }

  Color _markerColor(BuildContext context) {
    return widget.style.markerColor ?? context.appColors.tertiary;
  }

  Color _markerStrokeColor(BuildContext context) {
    return widget.style.markerStrokeColor ??
        Theme.of(context).colorScheme.surface;
  }

  Color _lowColor(BuildContext context) {
    return Theme.of(context).colorScheme.surfaceContainerHighest;
  }

  Color _highColor(BuildContext context) {
    return context.appColors.secondary;
  }

  String _markerSemanticLabel(AppBrazilStoreSalesMarkerGroup? group) {
    if (group == null) {
      return 'Loja no mapa';
    }

    if (group.isCluster) {
      return '${group.points.length} lojas em ${group.cityLabel}, '
          '${AppBrFormatters.currency(group.salesAmount)}, '
          '${_formatInteger(group.salesCount)} vendas';
    }

    final point = group.primaryPoint;
    return '${point.name}, ${group.cityLabel}, '
        '${AppBrFormatters.currency(point.salesAmount)}, '
        '${_formatInteger(point.salesCount)} vendas';
  }

  String _stateBubbleSemanticLabel(AppBrazilStoreSalesStateBucket bucket) {
    return '${bucket.stateName}, '
        '${AppBrFormatters.currency(bucket.salesAmount)}, '
        '${_formatInteger(bucket.salesCount)} vendas, '
        '${_formatInteger(bucket.storeCount)} lojas';
  }
}

class _BrazilStoreSalesMapSnapshot {
  const _BrazilStoreSalesMapSnapshot({
    required this.metric,
    required this.selectedStoreId,
    required this.requestedStateKey,
    required this.activeRegionKey,
    required this.buckets,
    required this.mapPoints,
    required this.selectedPoint,
    required this.selectedMarkerGroup,
    required this.selectedStateKey,
    required this.selectedStateBucket,
    required this.minMarkerValue,
    required this.maxMarkerValue,
    required this.diagnostics,
    required this.zoomLevel,
  });

  factory _BrazilStoreSalesMapSnapshot.build({
    required BuildContext context,
    required List<AppBrazilStoreSalesPoint> points,
    required AppBrazilStoreSalesMapMetric metric,
    required String? selectedStoreId,
    required String? requestedStateKey,
    required String? activeRegionKey,
    required double zoomLevel,
    required AppBrazilStoreSalesMapStyle style,
  }) {
    final preparedData = AppBrazilStoreSalesMapData.prepareSnapshotData(
      points,
      includeEmptyStates: style.includeEmptyStates,
      regionKey: activeRegionKey,
    );
    final diagnostics = preparedData.diagnostics;
    final buckets = preparedData.buckets;
    final markerGroups = _showsStoreMarkers(style.markerAggregation)
        ? AppBrazilStoreSalesMapData.buildMarkerGroupsFromValidPoints(
            preparedData.validPoints,
            collapseSameCoordinateMarkers: style.collapseSameCoordinateMarkers,
            enableProximityCluster: style.enableProximityCluster,
            proximityClusterDistanceDegrees:
                AppBrazilStoreSalesMapData.proximityClusterDistanceForZoom(
                  baseDistanceDegrees: style.proximityClusterDistanceDegrees,
                  zoomLevel: zoomLevel,
                ),
            coordinatePrecision: style.clusterCoordinatePrecision,
            markerAggregation: style.markerAggregation,
          )
        : const <AppBrazilStoreSalesMarkerGroup>[];
    final stateBubbleBuckets = _stateBubbleBuckets(
      buckets,
      metric,
      style.markerAggregation,
    );
    final (minValue, maxValue) = _markerValueRange(
      markerGroups: markerGroups,
      stateBubbleBuckets: stateBubbleBuckets,
      metric: metric,
    );
    final colorScheme = Theme.of(context).colorScheme;
    final markerColor = style.markerColor ?? context.appColors.tertiary;
    final markerStrokeColor = style.markerStrokeColor ?? colorScheme.surface;
    final selectedMarkerColor =
        style.selectedMarkerColor ?? context.appColors.secondary;
    final selectedMarkerStrokeColor =
        style.selectedMarkerStrokeColor ?? colorScheme.surface;
    AppBrazilStoreSalesPoint? selectedPoint;
    AppBrazilStoreSalesMarkerGroup? selectedMarkerGroup;
    var selectedStateKey = requestedStateKey;
    if (selectedStoreId != null) {
      for (final point in preparedData.validPoints) {
        if (point.id == selectedStoreId) {
          selectedPoint = point;
          selectedStateKey = AppBrazilStoreSalesMapData.normalizeUf(point.uf);
          break;
        }
      }
    }

    AppBrazilStoreSalesStateBucket? selectedStateBucket;
    if (selectedStateKey != null) {
      for (final bucket in buckets) {
        if (bucket.uf == selectedStateKey) {
          selectedStateBucket = bucket;
          break;
        }
      }
    }

    final mapPoints = <AppMapPoint>[];
    for (final bucket in stateBubbleBuckets) {
      final centroid = AppBrazilMapStaticData.stateCentroidsByUf[bucket.uf];
      if (centroid == null) {
        continue;
      }

      final selected = bucket.uf == selectedStateKey;
      final value = metric.valueForBucket(bucket);
      final markerSize = _effectiveMarkerSize(
        size: AppBrazilStoreSalesMapData.markerSizeFor(
          value: value,
          minValue: minValue,
          maxValue: maxValue,
          minSize: style.markerMinSize,
          maxSize: style.markerMaxSize,
        ),
        isCluster: false,
        visual: AppBrazilStoreSalesMarkerVisual.bubble,
      );

      mapPoints.add(
        AppMapPoint(
          latitude: centroid.latitude,
          longitude: centroid.longitude,
          label: style.showTooltip ? bucket.uf : null,
          tooltip: style.showTooltip ? _stateBubbleTooltip(bucket) : null,
          payload: AppBrazilStoreSalesStateBubble(bucket: bucket),
          style: AppMapMarkerStyle(
            size: selected ? markerSize + 4 : markerSize,
            color: selected ? selectedMarkerColor : markerColor,
            strokeColor: selected
                ? selectedMarkerStrokeColor
                : markerStrokeColor,
            strokeWidth: selected ? 2.4 : 1.5,
          ),
        ),
      );
    }

    for (final group in markerGroups) {
      final selected = group.points.any((point) => point.id == selectedStoreId);
      if (selected) {
        selectedMarkerGroup = group;
        selectedPoint = group.points.firstWhere(
          (point) => point.id == selectedStoreId,
          orElse: () => group.primaryPoint,
        );
        selectedStateKey = AppBrazilStoreSalesMapData.normalizeUf(
          selectedPoint.uf,
        );
      }

      final size = AppBrazilStoreSalesMapData.markerSizeFor(
        value: group.valueForMetric(metric),
        minValue: minValue,
        maxValue: maxValue,
        minSize: style.markerMinSize,
        maxSize: style.markerMaxSize,
      );
      final markerSize = _effectiveMarkerSize(
        size: size,
        isCluster: group.isCluster,
        visual: style.markerVisual,
      );
      final showMarkerTooltip =
          style.showTooltip &&
          !(selected &&
              style.showStoreDetail &&
              style.selectedMarkerDetailPlacement ==
                  AppBrazilStoreSalesSelectedMarkerDetailPlacement.overlay);

      mapPoints.add(
        AppMapPoint(
          latitude: group.latitude,
          longitude: group.longitude,
          label: showMarkerTooltip
              ? group.isCluster
                    ? '${group.points.length} lojas'
                    : group.primaryPoint.name
              : null,
          tooltip: showMarkerTooltip
              ? _groupTooltip(group, metric, style.maxClusterTooltipStores)
              : null,
          payload: group,
          style: AppMapMarkerStyle(
            size: selected ? markerSize + 4 : markerSize,
            color: selected ? selectedMarkerColor : markerColor,
            strokeColor: selected
                ? selectedMarkerStrokeColor
                : markerStrokeColor,
            strokeWidth: selected ? 2.4 : 1.5,
          ),
        ),
      );
    }

    return _BrazilStoreSalesMapSnapshot(
      metric: metric,
      selectedStoreId: selectedStoreId,
      requestedStateKey: requestedStateKey,
      activeRegionKey: activeRegionKey,
      buckets: buckets,
      mapPoints: mapPoints,
      selectedPoint: selectedPoint,
      selectedMarkerGroup: selectedMarkerGroup,
      selectedStateKey: selectedStateKey,
      selectedStateBucket: selectedStateBucket,
      minMarkerValue: minValue,
      maxMarkerValue: maxValue,
      diagnostics: diagnostics,
      zoomLevel: zoomLevel,
    );
  }

  final AppBrazilStoreSalesMapMetric metric;
  final String? selectedStoreId;
  final String? requestedStateKey;
  final String? activeRegionKey;
  final double zoomLevel;
  final List<AppBrazilStoreSalesStateBucket> buckets;
  final List<AppMapPoint> mapPoints;
  final AppBrazilStoreSalesPoint? selectedPoint;
  final AppBrazilStoreSalesMarkerGroup? selectedMarkerGroup;
  final String? selectedStateKey;
  final AppBrazilStoreSalesStateBucket? selectedStateBucket;
  final num minMarkerValue;
  final num maxMarkerValue;
  final AppBrazilStoreSalesMapDiagnostics diagnostics;

  bool get hasMarkers => mapPoints.isNotEmpty;

  static (num, num) _markerValueRange({
    required List<AppBrazilStoreSalesMarkerGroup> markerGroups,
    required List<AppBrazilStoreSalesStateBucket> stateBubbleBuckets,
    required AppBrazilStoreSalesMapMetric metric,
  }) {
    final values = <num>[
      for (final group in markerGroups) group.valueForMetric(metric),
      for (final bucket in stateBubbleBuckets) metric.valueForBucket(bucket),
    ];

    if (values.isEmpty) {
      return (0, 0);
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

    return (minValue, maxValue);
  }

  static bool _showsStoreMarkers(
    AppBrazilStoreSalesMarkerAggregation aggregation,
  ) {
    return switch (aggregation) {
      AppBrazilStoreSalesMarkerAggregation.stores => true,
      AppBrazilStoreSalesMarkerAggregation.municipalities => true,
      AppBrazilStoreSalesMarkerAggregation.states => false,
      AppBrazilStoreSalesMarkerAggregation.storesAndStates => true,
    };
  }

  static List<AppBrazilStoreSalesStateBucket> _stateBubbleBuckets(
    List<AppBrazilStoreSalesStateBucket> buckets,
    AppBrazilStoreSalesMapMetric metric,
    AppBrazilStoreSalesMarkerAggregation aggregation,
  ) {
    final showStateBubbles = switch (aggregation) {
      AppBrazilStoreSalesMarkerAggregation.stores => false,
      AppBrazilStoreSalesMarkerAggregation.municipalities => false,
      AppBrazilStoreSalesMarkerAggregation.states => true,
      AppBrazilStoreSalesMarkerAggregation.storesAndStates => true,
    };
    if (!showStateBubbles) {
      return const <AppBrazilStoreSalesStateBucket>[];
    }

    return [
      for (final bucket in buckets)
        if (metric.valueForBucket(bucket) > 0) bucket,
    ];
  }

  static double _effectiveMarkerSize({
    required double size,
    required bool isCluster,
    required AppBrazilStoreSalesMarkerVisual visual,
  }) {
    final minimumSize = switch (visual) {
      AppBrazilStoreSalesMarkerVisual.dot => isCluster ? 22.0 : size,
      AppBrazilStoreSalesMarkerVisual.bubble => 30.0,
      AppBrazilStoreSalesMarkerVisual.storeIcon => 26.0,
    };

    return size.clamp(minimumSize, double.infinity);
  }

  static String _groupTooltip(
    AppBrazilStoreSalesMarkerGroup group,
    AppBrazilStoreSalesMapMetric metric,
    int maxStores,
  ) {
    final revenue = AppBrFormatters.currency(group.salesAmount);
    final salesCount = _formatInteger(group.salesCount);
    if (!group.isCluster) {
      final point = group.primaryPoint;
      return '${point.name}\n${group.cityLabel}\n$revenue | $salesCount vendas';
    }

    final buffer = StringBuffer()
      ..writeln('${group.points.length} lojas')
      ..writeln(group.cityLabel)
      ..write('$revenue | $salesCount vendas');
    final safeMaxStores = maxStores.clamp(1, 20);
    for (final point in group.points.take(safeMaxStores)) {
      buffer
        ..writeln()
        ..write('- ${point.name}');
    }
    final hiddenStores = group.points.length - safeMaxStores;
    if (hiddenStores > 0) {
      buffer
        ..writeln()
        ..write('+ $hiddenStores lojas');
    }

    return buffer.toString();
  }

  static String _stateBubbleTooltip(AppBrazilStoreSalesStateBucket bucket) {
    return '${bucket.stateName} / ${bucket.uf}\n'
        '${AppBrFormatters.currency(bucket.salesAmount)} | '
        '${_formatInteger(bucket.salesCount)} vendas | '
        '${_formatInteger(bucket.storeCount)} lojas';
  }
}

class _MarkerScaleLegend extends StatelessWidget {
  const _MarkerScaleLegend({
    required this.sizeLegendLabel,
    required this.metric,
    required this.minValue,
    required this.maxValue,
    required this.minSize,
    required this.maxSize,
    required this.color,
    required this.strokeColor,
    required this.visual,
  });

  final String sizeLegendLabel;
  final AppBrazilStoreSalesMapMetric metric;
  final num minValue;
  final num maxValue;
  final double minSize;
  final double maxSize;
  final Color color;
  final Color strokeColor;
  final AppBrazilStoreSalesMarkerVisual visual;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final textStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    final middleValue = maxValue <= minValue
        ? minValue
        : minValue + ((maxValue - minValue) / 2);

    return Padding(
      padding: EdgeInsets.only(top: tokens.gapMd),
      child: _MapAuxiliarySurface(
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: tokens.gapMd,
          runSpacing: tokens.gapSm,
          children: [
            Text(sizeLegendLabel, style: textStyle),
            _MarkerScaleLegendItem(
              label: _formatMetricValue(metric, minValue),
              size: minSize,
              color: color,
              strokeColor: strokeColor,
              visual: visual,
            ),
            _MarkerScaleLegendItem(
              label: _formatMetricValue(metric, middleValue),
              size: minSize + ((maxSize - minSize) / 2),
              color: color,
              strokeColor: strokeColor,
              visual: visual,
            ),
            _MarkerScaleLegendItem(
              label: _formatMetricValue(metric, maxValue),
              size: maxSize,
              color: color,
              strokeColor: strokeColor,
              visual: visual,
            ),
          ],
        ),
      ),
    );
  }
}

class _MapAuxiliarySurface extends StatelessWidget {
  const _MapAuxiliarySurface({required this.child});

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

class _MapDataQualityNotice extends StatelessWidget {
  const _MapDataQualityNotice({required this.diagnostics});

  final AppBrazilStoreSalesMapDiagnostics diagnostics;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final colorScheme = Theme.of(context).colorScheme;
    final details = <String>[
      if (diagnostics.invalidCoordinateCount > 0)
        '${diagnostics.invalidCoordinateCount} com coordenada invalida',
      if (diagnostics.unknownUfCount > 0)
        '${diagnostics.unknownUfCount} com UF desconhecida',
      if (diagnostics.filteredByRegionCount > 0)
        '${diagnostics.filteredByRegionCount} fora do recorte',
    ].join(' | ');

    return Padding(
      padding: EdgeInsets.only(top: tokens.gapSm),
      child: _MapAuxiliarySurface(
        child: Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 16,
              color: colorScheme.onSurfaceVariant,
            ),
            SizedBox(width: tokens.gapSm),
            Expanded(
              child: Text(
                '${diagnostics.discardedPointCount} lojas nao exibidas'
                '${details.isEmpty ? '' : ': $details'}.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MarkerScaleLegendItem extends StatelessWidget {
  const _MarkerScaleLegendItem({
    required this.label,
    required this.size,
    required this.color,
    required this.strokeColor,
    required this.visual,
  });

  final String label;
  final double size;
  final Color color;
  final Color strokeColor;
  final AppBrazilStoreSalesMarkerVisual visual;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StoreMapMarker(
          style: AppMapMarkerStyle(
            size: size,
            color: color,
            strokeColor: strokeColor,
          ),
          count: 1,
          visual: visual,
          semanticLabel: label,
        ),
        SizedBox(width: tokens.gapXs),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _SelectedMarkerDetailAnchor extends StatefulWidget {
  const _SelectedMarkerDetailAnchor({
    required this.group,
    required this.selectedStoreId,
    required this.metric,
    required this.marker,
    required this.onClose,
  });

  final AppBrazilStoreSalesMarkerGroup group;
  final String selectedStoreId;
  final AppBrazilStoreSalesMapMetric metric;
  final Widget marker;
  final VoidCallback onClose;

  @override
  State<_SelectedMarkerDetailAnchor> createState() =>
      _SelectedMarkerDetailAnchorState();
}

class _SelectedMarkerDetailAnchorState
    extends State<_SelectedMarkerDetailAnchor> {
  final OverlayPortalController _controller = OverlayPortalController();
  final LayerLink _link = LayerLink();

  @override
  void initState() {
    super.initState();
    _syncOverlayVisibility();
  }

  @override
  void didUpdateWidget(covariant _SelectedMarkerDetailAnchor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.group != widget.group ||
        oldWidget.selectedStoreId != widget.selectedStoreId ||
        oldWidget.metric != widget.metric) {
      _syncOverlayVisibility();
    }
  }

  void _syncOverlayVisibility() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _controller.show();
    });
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _link,
      child: OverlayPortal(
        controller: _controller,
        overlayChildBuilder: (context) {
          return _SelectedMarkerDetailFollower(
            link: _link,
            group: widget.group,
            selectedStoreId: widget.selectedStoreId,
            metric: widget.metric,
            onClose: widget.onClose,
          );
        },
        child: widget.marker,
      ),
    );
  }
}

class _SelectedMarkerDetailFollower extends StatelessWidget {
  const _SelectedMarkerDetailFollower({
    required this.link,
    required this.group,
    required this.selectedStoreId,
    required this.metric,
    required this.onClose,
  });

  final LayerLink link;
  final AppBrazilStoreSalesMarkerGroup group;
  final String selectedStoreId;
  final AppBrazilStoreSalesMapMetric metric;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final maxWidth = (screenWidth - 32).clamp(260.0, 340.0);
    final selectedPoint = group.points.firstWhere(
      (point) => point.id == selectedStoreId,
      orElse: () => group.primaryPoint,
    );

    final child = group.isCluster || group.isMunicipalityAggregate
        ? _SelectedMarkerGroupDetailCard(
            group: group,
            metric: metric,
            onClose: onClose,
          )
        : _SelectedMarkerStoreDetailCard(
            point: selectedPoint,
            metric: metric,
            onClose: onClose,
          );

    return Positioned.fill(
      child: IgnorePointer(
        ignoring: false,
        child: CompositedTransformFollower(
          link: link,
          showWhenUnlinked: false,
          targetAnchor: Alignment.topCenter,
          followerAnchor: Alignment.bottomCenter,
          offset: const Offset(0, -10),
          child: UnconstrainedBox(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _StateBubbleMarker extends StatelessWidget {
  const _StateBubbleMarker({
    required this.bucket,
    required this.metric,
    required this.style,
    required this.semanticLabel,
  });

  final AppBrazilStoreSalesStateBucket bucket;
  final AppBrazilStoreSalesMapMetric metric;
  final AppMapMarkerStyle style;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final markerColor = style.color ?? context.appColors.tertiary;
    final markerStrokeColor =
        style.strokeColor ?? Theme.of(context).colorScheme.surface;
    final dimension = style.size;
    final metricValue = metric.valueForBucket(bucket);
    final label = metric == AppBrazilStoreSalesMapMetric.salesCount
        ? _formatInteger(metricValue)
        : bucket.uf;

    return Semantics(
      button: true,
      label: semanticLabel,
      child: SizedBox.square(
        dimension: dimension,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: markerColor.withValues(alpha: 0.18),
            shape: BoxShape.circle,
            border: Border.all(
              color: markerStrokeColor.withValues(alpha: 0.92),
              width: style.strokeWidth,
            ),
          ),
          child: Center(
            child: Text(
              label,
              maxLines: 1,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: markerColor,
                fontWeight: FontWeight.w900,
                fontSize: dimension >= 54 ? 11 : 9,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StoreMapMarker extends StatelessWidget {
  const _StoreMapMarker({
    required this.style,
    required this.count,
    required this.visual,
    required this.semanticLabel,
  });

  final AppMapMarkerStyle style;
  final int count;
  final AppBrazilStoreSalesMarkerVisual visual;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final markerColor = style.color ?? context.appColors.tertiary;
    final markerStrokeColor =
        style.strokeColor ?? Theme.of(context).colorScheme.surface;
    final dimension = style.size;
    final showCount = count > 1 && dimension >= 22;
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: semanticLabel,
      child: SizedBox.square(
        dimension: dimension,
        child: switch (visual) {
          AppBrazilStoreSalesMarkerVisual.dot => DecoratedBox(
            decoration: BoxDecoration(
              color: markerColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: markerStrokeColor,
                width: style.strokeWidth,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.16),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: showCount
                ? Center(
                    child: Text(
                      count > 99 ? '99+' : count.toString(),
                      maxLines: 1,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colorScheme.onTertiary,
                        fontWeight: FontWeight.w800,
                        fontSize: dimension >= 28 ? 10 : 8,
                      ),
                    ),
                  )
                : null,
          ),
          AppBrazilStoreSalesMarkerVisual.bubble => DecoratedBox(
            decoration: BoxDecoration(
              color: markerColor.withValues(alpha: 0.16),
              shape: BoxShape.circle,
              border: Border.all(
                color: markerColor.withValues(alpha: 0.82),
                width: 2.2,
              ),
            ),
            child: showCount
                ? Center(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colorScheme.surface.withValues(alpha: 0.86),
                        shape: BoxShape.circle,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Text(
                          count > 99 ? '99+' : count.toString(),
                          maxLines: 1,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: markerColor,
                                fontWeight: FontWeight.w800,
                                fontSize: dimension >= 48 ? 11 : 9,
                              ),
                        ),
                      ),
                    ),
                  )
                : null,
          ),
          AppBrazilStoreSalesMarkerVisual.storeIcon => Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: markerColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: markerStrokeColor,
                      width: style.strokeWidth,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.storefront_rounded,
                    size: (dimension * 0.52).clamp(13, 22).toDouble(),
                    color: colorScheme.onTertiary,
                  ),
                ),
              ),
              if (showCount)
                Positioned(
                  right: -2,
                  top: -2,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: markerColor,
                        width: 1.4,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(3),
                      child: Text(
                        count > 99 ? '99+' : count.toString(),
                        maxLines: 1,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: markerColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 8,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        },
      ),
    );
  }
}

class _StateBubbleTooltipCard extends StatelessWidget {
  const _StateBubbleTooltipCard({
    required this.bucket,
    required this.metric,
  });

  final AppBrazilStoreSalesStateBucket bucket;
  final AppBrazilStoreSalesMapMetric metric;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;

    return _SelectedMarkerDetailSurface(
      title: bucket.stateName,
      subtitle: bucket.regionName,
      icon: Icons.map_outlined,
      metric: metric,
      child: Wrap(
        spacing: tokens.gapSm,
        runSpacing: tokens.gapSm,
        children: <Widget>[
          AppTagChip(
            label: AppBrFormatters.currency(bucket.salesAmount),
            icon: Icons.attach_money,
          ),
          AppTagChip(
            label: '${_formatInteger(bucket.salesCount)} vendas',
            icon: Icons.receipt_long_outlined,
          ),
          AppTagChip(
            label: '${_formatInteger(bucket.storeCount)} filiais',
            icon: Icons.storefront_outlined,
          ),
        ],
      ),
    );
  }
}

class _PlainMapTooltipCard extends StatelessWidget {
  const _PlainMapTooltipCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surface,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.22),
      borderRadius: BorderRadius.circular(tokens.formFieldRadius),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(tokens.formFieldRadius),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: EdgeInsets.all(tokens.gapMd),
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectedStateDetail extends StatelessWidget {
  const _SelectedStateDetail({
    required this.bucket,
    required this.metric,
  });

  final AppBrazilStoreSalesStateBucket bucket;
  final AppBrazilStoreSalesMapMetric metric;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;

    return Padding(
      padding: EdgeInsets.only(top: tokens.gapMd),
      child: _SelectedMarkerDetailSurface(
        title: bucket.stateName,
        subtitle: '${bucket.uf} selecionado',
        icon: Icons.map_outlined,
        metric: metric,
        child: Wrap(
          spacing: tokens.gapSm,
          runSpacing: tokens.gapSm,
          children: <Widget>[
            AppTagChip(
              label: AppBrFormatters.currency(bucket.salesAmount),
              icon: Icons.attach_money,
            ),
            AppTagChip(
              label: '${_formatInteger(bucket.salesCount)} vendas',
              icon: Icons.receipt_long_outlined,
            ),
            AppTagChip(
              label: '${_formatInteger(bucket.storeCount)} filiais',
              icon: Icons.storefront_outlined,
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedMunicipalityDetail extends StatelessWidget {
  const _SelectedMunicipalityDetail({
    required this.group,
    required this.metric,
  });

  final AppBrazilStoreSalesMarkerGroup group;
  final AppBrazilStoreSalesMapMetric metric;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;

    return Padding(
      padding: EdgeInsets.only(top: tokens.gapMd),
      child: _SelectedMarkerGroupDetailCard(group: group, metric: metric),
    );
  }
}

class _SelectedStoreDetail extends StatelessWidget {
  const _SelectedStoreDetail({
    required this.point,
    required this.metric,
  });

  final AppBrazilStoreSalesPoint point;
  final AppBrazilStoreSalesMapMetric metric;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;

    return Padding(
      padding: EdgeInsets.only(top: tokens.gapMd),
      child: _SelectedMarkerStoreDetailCard(point: point, metric: metric),
    );
  }
}

class _SelectedMarkerGroupDetailCard extends StatelessWidget {
  const _SelectedMarkerGroupDetailCard({
    required this.group,
    required this.metric,
    this.onClose,
  });

  final AppBrazilStoreSalesMarkerGroup group;
  final AppBrazilStoreSalesMapMetric metric;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final colorScheme = Theme.of(context).colorScheme;
    final visibleBranches = group.points.take(5).toList(growable: false);
    final hiddenBranchCount = group.points.length - visibleBranches.length;
    final branchLabel = group.points.length == 1
        ? '1 filial agrupada'
        : '${_formatInteger(group.points.length)} filiais agrupadas';

    return _SelectedMarkerDetailSurface(
      title: group.cityLabel,
      subtitle: branchLabel,
      icon: Icons.location_city_outlined,
      metric: metric,
      onClose: onClose,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: tokens.gapSm,
            runSpacing: tokens.gapSm,
            children: [
              AppTagChip(
                label: AppBrFormatters.currency(group.salesAmount),
                icon: Icons.attach_money,
              ),
              AppTagChip(
                label: '${_formatInteger(group.salesCount)} vendas',
                icon: Icons.receipt_long_outlined,
              ),
              AppTagChip(
                label: '${_formatInteger(group.points.length)} filiais',
                icon: Icons.storefront_outlined,
              ),
            ],
          ),
          if (visibleBranches.isNotEmpty) ...[
            SizedBox(height: tokens.gapMd),
            Divider(color: colorScheme.outlineVariant, height: 1),
            SizedBox(height: tokens.gapSm),
            for (final point in visibleBranches)
              _SelectedMarkerBranchRow(point: point),
            if (hiddenBranchCount > 0)
              Padding(
                padding: EdgeInsets.only(top: tokens.gapXs),
                child: Text(
                  '+ ${_formatInteger(hiddenBranchCount)} filiais',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _SelectedMarkerStoreDetailCard extends StatelessWidget {
  const _SelectedMarkerStoreDetailCard({
    required this.point,
    required this.metric,
    this.onClose,
    this.showTechnicalLocationDetails = true,
  });

  final AppBrazilStoreSalesPoint point;
  final AppBrazilStoreSalesMapMetric metric;
  final VoidCallback? onClose;
  final bool showTechnicalLocationDetails;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final cityLabel = _cityLabelFor(point);
    final municipalityCode = point.municipalityCode?.trim();

    return _SelectedMarkerDetailSurface(
      title: point.name,
      subtitle: point.subtitle ?? cityLabel,
      icon: Icons.storefront_outlined,
      metric: metric,
      onClose: onClose,
      child: Wrap(
        spacing: tokens.gapSm,
        runSpacing: tokens.gapSm,
        children: [
          AppTagChip(
            label: AppBrFormatters.currency(point.salesAmount),
            icon: Icons.attach_money,
          ),
          AppTagChip(
            label: '${_formatInteger(point.salesCount)} vendas',
            icon: Icons.receipt_long_outlined,
          ),
          AppTagChip(label: cityLabel, icon: Icons.place_outlined),
          if (showTechnicalLocationDetails &&
              municipalityCode != null &&
              municipalityCode.isNotEmpty)
            AppTagChip(
              label: 'IBGE $municipalityCode',
              icon: Icons.pin_drop_outlined,
            ),
          if (showTechnicalLocationDetails)
            AppTagChip(
              label: _locationResolutionLabel(point.locationResolution),
              icon: Icons.my_location_outlined,
            ),
          if (showTechnicalLocationDetails)
            AppTagChip(
              label:
                  '${point.latitude.toStringAsFixed(4)}, '
                  '${point.longitude.toStringAsFixed(4)}',
              icon: Icons.explore_outlined,
            ),
        ],
      ),
    );
  }
}

class _SelectedMarkerDetailSurface extends StatelessWidget {
  const _SelectedMarkerDetailSurface({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.metric,
    required this.child,
    this.onClose,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final AppBrazilStoreSalesMapMetric metric;
  final Widget child;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surface,
      elevation: onClose == null ? 0 : 8,
      shadowColor: Colors.black.withValues(alpha: 0.22),
      borderRadius: BorderRadius.circular(tokens.formFieldRadius),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(tokens.formFieldRadius),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: EdgeInsets.all(tokens.contentSpacing),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: context.appColors.secondary, size: 20),
                  SizedBox(width: tokens.gapSm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        SizedBox(height: tokens.gapXs),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: tokens.gapSm),
                  if (onClose == null)
                    AppTagChip(label: metric.label)
                  else
                    Tooltip(
                      message: 'Fechar detalhes',
                      child: IconButton(
                        onPressed: onClose,
                        icon: const Icon(Icons.close_rounded),
                        iconSize: 18,
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints.tightFor(
                          width: 32,
                          height: 32,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: tokens.gapMd),
              if (onClose != null) ...[
                AppTagChip(label: metric.label),
                SizedBox(height: tokens.gapSm),
              ],
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectedMarkerBranchRow extends StatelessWidget {
  const _SelectedMarkerBranchRow({required this.point});

  final AppBrazilStoreSalesPoint point;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: tokens.gapXs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              point.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(width: tokens.gapSm),
          Text(
            AppBrFormatters.compactCurrency(point.salesAmount),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(width: tokens.gapSm),
          Text(
            '${_formatInteger(point.salesCount)} vendas',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatInteger(num value) {
  return _integerFormat.format(value);
}

String _formatMetricValue(AppBrazilStoreSalesMapMetric metric, num value) {
  return switch (metric) {
    AppBrazilStoreSalesMapMetric.revenue => AppBrFormatters.compactCurrency(
      value,
    ),
    AppBrazilStoreSalesMapMetric.salesCount => _formatInteger(value),
  };
}

String _cityLabelFor(AppBrazilStoreSalesPoint point) {
  return switch (point.city) {
    final city? when city.trim().isNotEmpty =>
      '${city.trim()} / ${AppBrazilStoreSalesMapData.normalizeUf(point.uf)}',
    _ => AppBrazilStoreSalesMapData.normalizeUf(point.uf),
  };
}

String _locationResolutionLabel(
  AppBrazilStoreSalesLocationResolution? resolution,
) {
  return switch (resolution) {
    AppBrazilStoreSalesLocationResolution.providedGeoPoint =>
      'Coordenada da filial',
    AppBrazilStoreSalesLocationResolution.ibgeMunicipalityCode =>
      'Geolocalizacao IBGE',
    AppBrazilStoreSalesLocationResolution.cep => 'Geolocalizacao CEP',
    AppBrazilStoreSalesLocationResolution.cityUf => 'Geolocalizacao cidade/UF',
    AppBrazilStoreSalesLocationResolution.capitalUf => 'Capital da UF',
    AppBrazilStoreSalesLocationResolution.stateUf => 'Centro da UF',
    null => 'Origem da coordenada nao informada',
  };
}

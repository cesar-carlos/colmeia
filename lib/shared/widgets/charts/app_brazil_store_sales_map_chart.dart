import 'dart:async';

import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/core/layout/app_breakpoints.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_tag_chip.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_map_static_data.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_data.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_models.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_overlay_chrome.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_shell.dart';
import 'package:colmeia/shared/widgets/charts/app_region_map_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    this.filterBranchIds = const <String>{},
    this.fixedBranchIds = const <String>{},
    this.style = const AppBrazilStoreSalesMapStyle(),
    this.onStoreTap,
    this.onBranchFilter,
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
  /// Branch ids selected outside the map (e.g. sheet filter). Used with [fixedBranchIds]
  /// so "Fixar filial" / "Desfixar filial" are not confused with map-only pins.
  final Set<String> filterBranchIds;
  /// Union of external highlights (filter + map pin); drives reuse keys and cleanup.
  final Set<String> fixedBranchIds;
  final AppBrazilStoreSalesMapStyle style;
  final ValueChanged<AppBrazilStoreSalesPointTapEvent>? onStoreTap;
  final ValueChanged<AppBrazilStoreSalesPointTapEvent>? onBranchFilter;
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
  Timer? _viewportClusterDebounceTimer;
  double? _pendingViewportClusterZoomLevel;

  /// Small shrink of the map tile when height is bounded: real layout (labels,
  /// chips, legend padding) can exceed our header/footer estimates by a few
  /// logical pixels and cause a [Column] overflow.
  static const double _boundedMapTileLayoutSafetyPx = 6;
  static const Duration _touchViewportClusterDebounceDuration = Duration(
    milliseconds: 180,
  );
  static const Duration _desktopViewportClusterDebounceDuration = Duration(
    milliseconds: 120,
  );

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

    if (oldWidget.selectedStoreId != widget.selectedStoreId ||
        oldWidget.style != widget.style) {
      if (oldWidget.selectedStoreId != null &&
          widget.selectedStoreId == null) {
        _dismissedControlledSelectedStoreId = null;
      }
      if (oldWidget.selectedStoreId != widget.selectedStoreId &&
          widget.selectedStoreId != null) {
        _currentZoomLevel = widget.style.selectedStoreZoomLevel;
        _dismissedControlledSelectedStoreId = null;
      }
      _snapshot = null;
    }

    if (oldWidget.filterBranchIds != widget.filterBranchIds ||
        oldWidget.fixedBranchIds != widget.fixedBranchIds) {
      _snapshot = null;
    }

    if (widget.onBranchFilter != null) {
      if (widget.selectedStoreId != null &&
          _internalSelectedStoreId == widget.selectedStoreId) {
        _internalSelectedStoreId = null;
        _snapshot = null;
      } else if (oldWidget.selectedStoreId != null &&
          widget.selectedStoreId == null &&
          _internalSelectedStoreId == oldWidget.selectedStoreId) {
        _internalSelectedStoreId = null;
        _snapshot = null;
      }
    }
  }

  @override
  void dispose() {
    _viewportClusterDebounceTimer?.cancel();
    super.dispose();
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
        final stateDataLabelTextStyle = _stateDataLabelTextStyle(
          context,
          compact: usesCompactStateLabels,
          maxWidth: constraints.maxWidth,
        );
        final useCompactMarkerLegend = _shouldUseCompactMarkerLegend(
          usesCompactMapChrome: usesCompactMapChrome,
          maxWidth: constraints.maxWidth,
        );
        final mapTileHeight = _resolvedMapTileHeight(
          context: context,
          constraints: constraints,
          style: widget.style,
          snapshot: snapshot,
          usesCompactMapChrome: usesCompactMapChrome,
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
              markerTooltipBuilder: _useWindowsSafeMarkerDetails
                  ? null
                  : _buildMarkerTooltip,
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
                showShapeTooltip: false,
                showDataLabels: widget.style.showDataLabels,
                showMetricSelector: widget.style.showMetricSelector,
                enableZoomPan: widget.style.enableZoomPan,
                lowValueColor: widget.style.lowValueColor ?? _lowColor(context),
                highValueColor:
                    widget.style.highValueColor ?? _highColor(context),
                dataLabelTextStyle: stateDataLabelTextStyle,
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
            if (widget.style.showMarkerScaleLegend &&
                snapshot.hasMarkers &&
                useCompactMarkerLegend)
              _MarkerScaleLegendMenuButton(
                sizeLegendLabel: l10n.brazilStoreSalesMapMarkerSizeLegend,
                metric: _selectedMetric,
                minValue: snapshot.minMarkerValue,
                maxValue: snapshot.maxMarkerValue,
                minSize: widget.style.markerMinSize,
                maxSize: widget.style.markerMaxSize,
                color: _markerColor(context),
                strokeColor: _markerStrokeColor(context),
                visual: widget.style.markerVisual,
              )
            else if (widget.style.showMarkerScaleLegend && snapshot.hasMarkers)
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
                selectedStoreId: _selectedStoreId,
                onSelectBranch: (point) => _handleMarkerBranchAction(
                  point: point,
                  index: _mapPointIndexFor(point, snapshot),
                ),
                selectBranchLabelBuilder: _branchActionLabelFor,
              )
            else if (_showBelowMapMarkerDetail && selectedPoint != null)
              _SelectedStoreDetail(
                point: selectedPoint,
                metric: _selectedMetric,
                onSelectBranch: (point) => _handleMarkerBranchAction(
                  point: point,
                  index: _mapPointIndexFor(point, snapshot),
                ),
                selectBranchLabel: _branchActionLabelFor(selectedPoint),
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
    required bool usesCompactMapChrome,
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
      constraints.maxWidth,
      usesCompactMapChrome,
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
    double maxWidth,
    bool usesCompactMapChrome,
  ) {
    final scaler = MediaQuery.textScalerOf(context);
    var reserve = 0.0;
    if (style.showDataQualityNotice &&
        snapshot.diagnostics.hasDiscardedPoints) {
      reserve += tokens.gapSm + scaler.scale(56);
    }
    if (style.showMarkerScaleLegend && snapshot.hasMarkers) {
      final compactLegend = _shouldUseCompactMarkerLegend(
        usesCompactMapChrome: usesCompactMapChrome,
        maxWidth: maxWidth,
      );
      reserve += tokens.gapMd + scaler.scale(compactLegend ? 46 : 40);
    }
    final selectedMarkerGroup = snapshot.selectedMarkerGroup;
    final selectedPoint = snapshot.selectedPoint;
    if (_showBelowMapMarkerDetail &&
        selectedMarkerGroup != null &&
        (selectedMarkerGroup.isMunicipalityAggregate ||
            selectedMarkerGroup.isCluster)) {
      reserve += tokens.gapMd + scaler.scale(300);
    } else if (_showBelowMapMarkerDetail && selectedPoint != null) {
      reserve += tokens.gapMd + scaler.scale(220);
    }
    if (selectedPoint == null &&
        selectedMarkerGroup == null &&
        snapshot.selectedStateBucket != null) {
      reserve += tokens.gapMd + scaler.scale(96);
    }
    return reserve;
  }

  bool _shouldUseCompactMarkerLegend({
    required bool usesCompactMapChrome,
    required double maxWidth,
  }) {
    return usesCompactMapChrome || (maxWidth.isFinite && maxWidth < 420);
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
      !_shouldUseCompactBranchSheet &&
      widget.style.selectedMarkerDetailPlacement ==
          AppBrazilStoreSalesSelectedMarkerDetailPlacement.overlay;

  bool get _showBelowMapMarkerDetail =>
      widget.style.showStoreDetail &&
      widget.style.selectedMarkerDetailPlacement ==
          AppBrazilStoreSalesSelectedMarkerDetailPlacement.belowMap;

  bool get _useWindowsSafeMarkerDetails =>
      defaultTargetPlatform == TargetPlatform.windows;

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
    final requestedLabelMode = widget.style.stateLabelMode;
    if (compact &&
        requestedLabelMode != AppBrazilStoreSalesStateLabelMode.stateName) {
      return bucket.uf;
    }

    final labelMode = switch (requestedLabelMode) {
      AppBrazilStoreSalesStateLabelMode.responsive =>
        AppBreakpoints.isDesktop(context)
            ? AppBrazilStoreSalesStateLabelMode.stateName
            : AppBrazilStoreSalesStateLabelMode.uf,
      final labelMode => labelMode,
    };

    return switch (labelMode) {
      AppBrazilStoreSalesStateLabelMode.uf => bucket.uf,
      AppBrazilStoreSalesStateLabelMode.stateName =>
        compact ? _compactStateNameLabel(bucket) : bucket.stateName,
      AppBrazilStoreSalesStateLabelMode.responsive => bucket.uf,
    };
  }

  TextStyle? _stateDataLabelTextStyle(
    BuildContext context, {
    required bool compact,
    required double maxWidth,
  }) {
    final theme = Theme.of(context);
    final base = theme.textTheme.labelSmall;
    final requestedLabelMode = widget.style.stateLabelMode;
    final usesStateNames =
        requestedLabelMode == AppBrazilStoreSalesStateLabelMode.stateName ||
        (requestedLabelMode == AppBrazilStoreSalesStateLabelMode.responsive &&
            AppBreakpoints.isDesktop(context));
    final compactStateNames = compact && usesStateNames;
    final fontSize = compactStateNames
        ? _compactStateLabelFontSize(maxWidth)
        : (compact ? 10.0 : null);

    return base?.copyWith(
      color: theme.colorScheme.onSurface.withValues(
        alpha: compactStateNames ? 0.88 : 1,
      ),
      fontWeight: compactStateNames ? FontWeight.w800 : FontWeight.w700,
      fontSize: fontSize,
      height: compactStateNames ? 1.04 : null,
    );
  }

  double _compactStateLabelFontSize(double maxWidth) {
    if (!maxWidth.isFinite) {
      return 9;
    }
    if (maxWidth < 380) {
      return 7;
    }
    if (maxWidth < 600) {
      return 8;
    }
    return 9;
  }

  String _compactStateNameLabel(AppBrazilStoreSalesStateBucket bucket) {
    return switch (bucket.uf) {
      'DF' => 'Distrito\nFederal',
      'ES' => 'Espirito\nSanto',
      'MS' => 'Mato Grosso\ndo Sul',
      'MT' => 'Mato\nGrosso',
      'MG' => 'Minas\nGerais',
      'RJ' => 'Rio de\nJaneiro',
      'RN' => 'Rio Grande\ndo Norte',
      'RS' => 'Rio Grande\ndo Sul',
      'SC' => 'Santa\nCatarina',
      'SP' => 'Sao\nPaulo',
      final _ => bucket.stateName,
    };
  }

  String _computeSnapshotReuseKey({required String? selectedStoreId}) {
    final w = widget;
    final style = w.style;
    final parts = <String>[
      'fx=${_sortedSetJoin(w.fixedBranchIds)}',
      'fl=${_sortedSetJoin(w.filterBranchIds)}',
      style.markerAggregation.name,
      style.markerVisual.name,
      style.enableProximityCluster.toString(),
      style.collapseSameCoordinateMarkers.toString(),
      '${style.clusterCoordinatePrecision}',
      '${style.proximityClusterDistanceDegrees}',
      style.includeEmptyStates.toString(),
      style.showTooltip.toString(),
      '${style.markerMinSize}|${style.markerMaxSize}|${style.height}',
      'm=${_selectedMetric.name}',
      'ss=$selectedStoreId',
      'rs=$_internalSelectedStateKey',
      'ak=$_activeRegionKey',
      'z=$_currentZoomLevel',
      'pts=${_pointsContentDigest(w.points)}',
    ];
    return parts.join(';');
  }

  static String _sortedSetJoin(Set<String> values) {
    if (values.isEmpty) {
      return '';
    }
    final sorted = values.toList(growable: false)..sort();
    return sorted.join(',');
  }

  static int _pointsContentDigest(List<AppBrazilStoreSalesPoint> points) {
    var h = Object.hash(0xBEE5CAFE, points.length);
    for (final p in points) {
      h = Object.hash(
        h,
        p.id,
        p.salesAmount,
        p.salesCount,
        p.salesDataLoading,
        p.salesDataUnavailable,
        p.latitude,
        p.longitude,
        p.uf,
        p.city ?? '',
        p.municipalityCode ?? '',
      );
    }
    return h;
  }

  _BrazilStoreSalesMapSnapshot _resolveSnapshot(BuildContext context) {
    final selectedStoreId = _selectedStoreId;
    final reuseKey = _computeSnapshotReuseKey(selectedStoreId: selectedStoreId);
    final snapshot = _snapshot;
    if (snapshot != null && snapshot.cachedReuseKey == reuseKey) {
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
      cachedReuseKey: reuseKey,
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
    _selectPoint(point);
    if (_shouldUseCompactBranchSheet) {
      unawaited(
        _openCompactBranchDetailSheet(
          group: payload,
          initialStoreId: point.id,
          markerIndex: event.index,
        ),
      );
    }

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

    _emitStoreTap(point: point, index: event.index);
  }

  void _selectPoint(AppBrazilStoreSalesPoint point) {
    setState(() {
      _internalSelectedStoreId = point.id;
      _dismissedControlledSelectedStoreId = null;
      _internalSelectedStateKey = AppBrazilStoreSalesMapData.normalizeUf(
        point.uf,
      );
      _currentZoomLevel = widget.style.selectedStoreZoomLevel;
      _snapshot = null;
    });
  }

  void _emitStoreTap({
    required AppBrazilStoreSalesPoint point,
    required int index,
  }) {
    widget.onStoreTap?.call(
      AppBrazilStoreSalesPointTapEvent(
        point: point,
        index: index,
        metric: _selectedMetric,
      ),
    );
  }

  void _emitBranchFilter({
    required AppBrazilStoreSalesPoint point,
    required int index,
  }) {
    widget.onBranchFilter?.call(
      AppBrazilStoreSalesPointTapEvent(
        point: point,
        index: index,
        metric: _selectedMetric,
      ),
    );
  }

  int _mapPointIndexFor(
    AppBrazilStoreSalesPoint point,
    _BrazilStoreSalesMapSnapshot snapshot,
  ) {
    final index = snapshot.mapPoints.indexWhere((mapPoint) {
      final payload = mapPoint.payload;
      return payload is AppBrazilStoreSalesMarkerGroup &&
          payload.points.any((groupPoint) => groupPoint.id == point.id);
    });
    return index < 0 ? 0 : index;
  }

  void _handleMarkerBranchAction({
    required AppBrazilStoreSalesPoint point,
    required int index,
  }) {
    if (!mounted) {
      return;
    }
    if (widget.onBranchFilter == null) {
      _selectPoint(point);
      _emitStoreTap(point: point, index: index);
      return;
    }

    _emitBranchFilter(point: point, index: index);
  }

  String _branchActionLabelFor(AppBrazilStoreSalesPoint point) {
    final l10n = AppLocalizations.of(context);
    if (widget.onBranchFilter == null) {
      return l10n.salesLiveMapPinBranchAction;
    }
    final pinnedByMap = widget.selectedStoreId == point.id;
    if (pinnedByMap) {
      return l10n.salesLiveMapUnpinBranchFromMapAction;
    }
    return l10n.salesLiveMapPinBranchAction;
  }

  bool get _shouldUseCompactBranchSheet =>
      widget.style.showStoreDetail && AppBreakpoints.isMobile(context);

  Future<void> _openCompactBranchDetailSheet({
    required AppBrazilStoreSalesMarkerGroup group,
    required String initialStoreId,
    required int markerIndex,
  }) async {
    final l10nContext = context;
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
          child: _SelectedMarkerGroupDetailCard(
            group: group,
            metric: _selectedMetric,
            initialStoreId: initialStoreId,
            onDismiss: () => unawaited(Navigator.of(sheetContext).maybePop()),
            onClose: () => unawaited(Navigator.of(sheetContext).maybePop()),
            onSelectBranch: widget.onBranchFilter == null
                ? null
                : (point) {
                    unawaited(Navigator.of(sheetContext).maybePop());
                    _handleMarkerBranchAction(point: point, index: markerIndex);
                  },
            selectBranchLabelBuilder: _branchActionLabelFor,
          ),
        );
      },
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

  /// When the parent drives the map pin via `onBranchFilter` and
  /// `selectedStoreId`, closing the floating card calls the same toggle as the
  /// pin button so the card only stays open while pinned.
  void _handlePinnedMapOverlayClose() {
    final pinnedId = widget.selectedStoreId;
    if (widget.onBranchFilter != null && pinnedId != null) {
      final snapshot = _snapshot ?? _resolveSnapshot(context);
      final point = _pointById(pinnedId);
      if (point != null) {
        _emitBranchFilter(
          point: point,
          index: _mapPointIndexFor(point, snapshot),
        );
      }
      return;
    }
    _clearSelectedMarkerDetail();
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

    // While auto-focus keeps the camera on a selected branch, the engine
    // still reports the *current* zoom during transitions (e.g. Brazil ~1.0
    // right after we set clustering zoom to [selectedStoreZoomLevel]).
    // Applying those samples overwrites [_currentZoomLevel], invalidates the
    // snapshot on every tick, and can spin rebuilds + Windows AXTree updates
    // until the process dies (e.g. after "Fixar filial").
    if (widget.style.autoFocusSelectedStore && _selectedStoreId != null) {
      return;
    }

    final nextZoomLevel = event.viewport.zoomLevel;
    final debounceDuration = _shouldDebounceTouchViewportClustering
        ? _touchViewportClusterDebounceDuration
        : _desktopViewportClusterDebounceDuration;

    _pendingViewportClusterZoomLevel = nextZoomLevel;
    _viewportClusterDebounceTimer?.cancel();
    _viewportClusterDebounceTimer = Timer(
      debounceDuration,
      () {
        final pendingZoomLevel = _pendingViewportClusterZoomLevel;
        _pendingViewportClusterZoomLevel = null;
        if (pendingZoomLevel == null) {
          return;
        }
        _applyViewportClusterZoomLevel(pendingZoomLevel);
      },
    );
  }

  bool get _shouldDebounceTouchViewportClustering {
    if (!widget.style.enableZoomPan) {
      return false;
    }

    return switch (defaultTargetPlatform) {
      TargetPlatform.android ||
      TargetPlatform.fuchsia ||
      TargetPlatform.iOS => true,
      TargetPlatform.linux ||
      TargetPlatform.macOS ||
      TargetPlatform.windows => false,
    };
  }

  void _applyViewportClusterZoomLevel(double nextZoomLevel) {
    if (!mounted || (nextZoomLevel - _currentZoomLevel).abs() < 0.25) {
      return;
    }

    setState(() {
      _currentZoomLevel = nextZoomLevel;
      _snapshot = null;
    });
    if (kDebugMode) {
      AppLogger.info(
        'Brazil store sales map viewport changed',
        context: <String, Object?>{
          'operation': 'AppBrazilStoreSalesMapChart',
          'zoomLevel': nextZoomLevel,
          'pointCount': widget.points.length,
          'activeRegionKey': _activeRegionKey,
        },
      );
    }
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
      key: ValueKey<String>('brazil-store-sales-map-marker-$index'),
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
      if (group == null || !widget.style.showTooltip) {
        return marker;
      }

      return AppBrazilStoreSalesBranchHoverDetailAnchor(
        group: group,
        metric: _selectedMetric,
        marker: marker,
        onPinBranch: (point) =>
            _handleMarkerBranchAction(point: point, index: index),
        pinBranchLabelBuilder: _branchActionLabelFor,
      );
    }

    return AppBrazilStoreSalesSelectedMarkerDetailAnchor(
      group: group,
      selectedStoreId: selectedStoreId,
      metric: _selectedMetric,
      marker: marker,
      onClose: _handlePinnedMapOverlayClose,
      onSelectBranch: (point) =>
          _handleMarkerBranchAction(point: point, index: index),
      selectBranchLabelBuilder: _branchActionLabelFor,
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
    return '${bucket.stateName} (${bucket.uf}) | '
        '$revenue | $salesCount vendas | $stores lojas';
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

    final salesStatus = group.points.any((point) => point.salesDataLoading)
        ? ', vendas carregando'
        : group.points.any((point) => point.salesDataUnavailable)
        ? ', vendas indisponiveis'
        : '';

    if (group.isCluster) {
      return '${group.points.length} lojas em ${group.cityLabel}, '
          '${AppBrFormatters.currency(group.salesAmount)}, '
          '${_formatInteger(group.salesCount)} vendas$salesStatus';
    }

    final point = group.primaryPoint;
    return '${point.name}, ${group.cityLabel}, '
        '${AppBrFormatters.currency(point.salesAmount)}, '
        '${_formatInteger(point.salesCount)} vendas$salesStatus';
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
    required this.cachedReuseKey,
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
    required String cachedReuseKey,
  }) {
    final stopwatch = kDebugMode || kProfileMode
        ? (Stopwatch()..start())
        : null;
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
    final pendingMarkerColor = context.appColors.secondary;
    final unavailableMarkerColor = colorScheme.onSurfaceVariant;
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
      final hasLoadingSales = group.points.any(
        (point) => point.salesDataLoading,
      );
      final hasUnavailableSales =
          !hasLoadingSales &&
          group.points.any((point) => point.salesDataUnavailable);
      final effectiveMarkerColor = selected
          ? selectedMarkerColor
          : hasLoadingSales
          ? pendingMarkerColor
          : hasUnavailableSales
          ? unavailableMarkerColor
          : markerColor;
      final effectiveStrokeColor = selected
          ? selectedMarkerStrokeColor
          : hasLoadingSales
          ? colorScheme.surface
          : markerStrokeColor;
      mapPoints.add(
        AppMapPoint(
          latitude: group.latitude,
          longitude: group.longitude,
          payload: group,
          style: AppMapMarkerStyle(
            size: selected ? markerSize + 4 : markerSize,
            color: effectiveMarkerColor,
            strokeColor: effectiveStrokeColor,
            strokeWidth: selected || hasLoadingSales ? 2.4 : 1.5,
          ),
        ),
      );
    }

    final snapshot = _BrazilStoreSalesMapSnapshot(
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
      cachedReuseKey: cachedReuseKey,
    );
    if (stopwatch != null) {
      AppLogger.info(
        'Brazil store sales map snapshot built',
        context: <String, Object?>{
          'operation': 'AppBrazilStoreSalesMapChart',
          'elapsedMs': stopwatch.elapsedMilliseconds,
          'inputPointCount': points.length,
          'validPointCount': preparedData.validPoints.length,
          'bucketCount': buckets.length,
          'markerGroupCount': markerGroups.length,
          'mapPointCount': mapPoints.length,
          'aggregation': style.markerAggregation.name,
          'activeRegionKey': activeRegionKey,
        },
      );
    }
    return snapshot;
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
  final String cachedReuseKey;

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

    return Padding(
      padding: EdgeInsets.only(top: tokens.gapMd),
      child: _MapAuxiliarySurface(
        child: _MarkerScaleLegendContent(
          sizeLegendLabel: sizeLegendLabel,
          metric: metric,
          minValue: minValue,
          maxValue: maxValue,
          minSize: minSize,
          maxSize: maxSize,
          color: color,
          strokeColor: strokeColor,
          visual: visual,
        ),
      ),
    );
  }
}

class _MarkerScaleLegendMenuButton extends StatelessWidget {
  const _MarkerScaleLegendMenuButton({
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
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(top: tokens.gapMd),
      child: _MapAuxiliarySurface(
        child: Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => _showLegendSheet(context),
            icon: const Icon(Icons.info_outline_rounded, size: 18),
            label: const Text('Legenda'),
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              foregroundColor: colorScheme.onSurfaceVariant,
              padding: EdgeInsets.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ),
      ),
    );
  }

  void _showLegendSheet(BuildContext context) {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        useSafeArea: true,
        showDragHandle: true,
        builder: (context) {
          final tokens = Theme.of(context).extension<AppThemeTokens>()!;
          return Padding(
            padding: EdgeInsets.fromLTRB(
              tokens.contentSpacing,
              tokens.gapSm,
              tokens.contentSpacing,
              tokens.contentSpacing,
            ),
            child: _MarkerScaleLegendContent(
              sizeLegendLabel: sizeLegendLabel,
              metric: metric,
              minValue: minValue,
              maxValue: maxValue,
              minSize: minSize,
              maxSize: maxSize,
              color: color,
              strokeColor: strokeColor,
              visual: visual,
            ),
          );
        },
      ),
    );
  }
}

class _MarkerScaleLegendContent extends StatelessWidget {
  const _MarkerScaleLegendContent({
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

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(sizeLegendLabel, style: textStyle),
          SizedBox(width: tokens.gapMd),
          _MarkerScaleLegendItem(
            label: _formatMetricValue(metric, minValue),
            size: minSize,
            color: color,
            strokeColor: strokeColor,
            visual: visual,
          ),
          SizedBox(width: tokens.gapMd),
          _MarkerScaleLegendItem(
            label: _formatMetricValue(metric, middleValue),
            size: minSize + ((maxSize - minSize) / 2),
            color: color,
            strokeColor: strokeColor,
            visual: visual,
          ),
          SizedBox(width: tokens.gapMd),
          _MarkerScaleLegendItem(
            label: _formatMetricValue(metric, maxValue),
            size: maxSize,
            color: color,
            strokeColor: strokeColor,
            visual: visual,
          ),
        ],
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

@visibleForTesting
class AppBrazilStoreSalesSelectedMarkerDetailAnchor extends StatefulWidget {
  const AppBrazilStoreSalesSelectedMarkerDetailAnchor({
    required this.group,
    required this.selectedStoreId,
    required this.metric,
    required this.marker,
    required this.onClose,
    super.key,
    this.onSelectBranch,
    this.selectBranchLabel,
    this.selectBranchLabelBuilder,
  });

  final AppBrazilStoreSalesMarkerGroup group;
  final String selectedStoreId;
  final AppBrazilStoreSalesMapMetric metric;
  final Widget marker;
  final VoidCallback onClose;
  final ValueChanged<AppBrazilStoreSalesPoint>? onSelectBranch;
  final String? selectBranchLabel;
  final String Function(AppBrazilStoreSalesPoint)? selectBranchLabelBuilder;

  @override
  State<AppBrazilStoreSalesSelectedMarkerDetailAnchor> createState() =>
      _SelectedMarkerDetailAnchorState();
}

class _SelectedMarkerDetailAnchorState
    extends State<AppBrazilStoreSalesSelectedMarkerDetailAnchor> {
  final OverlayPortalController _controller = OverlayPortalController();
  final LayerLink _link = LayerLink();
  final GlobalKey _markerKey = GlobalKey();
  double? _markerGlobalDx;

  @override
  void initState() {
    super.initState();
    _syncOverlayVisibility();
  }

  @override
  void didUpdateWidget(
    covariant AppBrazilStoreSalesSelectedMarkerDetailAnchor oldWidget,
  ) {
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
      _updateMarkerGlobalDx();
      _controller.show();
    });
  }

  void _updateMarkerGlobalDx() {
    final markerContext = _markerKey.currentContext;
    final renderObject = markerContext?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) {
      return;
    }

    final nextDx = renderObject
        .localToGlobal(
          renderObject.size.center(Offset.zero),
        )
        .dx;
    if (_markerGlobalDx == nextDx) {
      return;
    }

    setState(() {
      _markerGlobalDx = nextDx;
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
            onSelectBranch: widget.onSelectBranch,
            selectBranchLabel: widget.selectBranchLabel,
            selectBranchLabelBuilder: widget.selectBranchLabelBuilder,
            markerGlobalDx: _markerGlobalDx,
          );
        },
        child: KeyedSubtree(key: _markerKey, child: widget.marker),
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
    required this.markerGlobalDx,
    this.onSelectBranch,
    this.selectBranchLabel,
    this.selectBranchLabelBuilder,
  });

  final LayerLink link;
  final AppBrazilStoreSalesMarkerGroup group;
  final String selectedStoreId;
  final AppBrazilStoreSalesMapMetric metric;
  final VoidCallback onClose;
  final double? markerGlobalDx;
  final ValueChanged<AppBrazilStoreSalesPoint>? onSelectBranch;
  final String? selectBranchLabel;
  final String Function(AppBrazilStoreSalesPoint)? selectBranchLabelBuilder;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final maxWidth = (screenWidth - 32).clamp(260.0, 340.0);
    final followerAnchor = _followerAnchorFor(
      screenWidth: screenWidth,
      maxWidth: maxWidth,
      markerGlobalDx: markerGlobalDx,
    );
    void handleSelectBranch(AppBrazilStoreSalesPoint point) {
      onSelectBranch?.call(point);
    }

    final selectBranch = onSelectBranch == null ? null : handleSelectBranch;
    return Positioned.fill(
      child: IgnorePointer(
        ignoring: false,
        child: CompositedTransformFollower(
          link: link,
          showWhenUnlinked: false,
          targetAnchor: Alignment.topCenter,
          followerAnchor: followerAnchor,
          offset: _followerOffsetFor(followerAnchor),
          child: UnconstrainedBox(
            alignment: followerAnchor,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: _MapMarkerDetailSemanticsBoundary(
                child: _SelectedMarkerGroupDetailCard(
                  group: group,
                  metric: metric,
                  initialStoreId: selectedStoreId,
                  onClose: onClose,
                  onSelectBranch: selectBranch,
                  selectBranchLabel: selectBranchLabel,
                  selectBranchLabelBuilder: selectBranchLabelBuilder,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

@visibleForTesting
class AppBrazilStoreSalesBranchHoverDetailAnchor extends StatefulWidget {
  const AppBrazilStoreSalesBranchHoverDetailAnchor({
    required this.group,
    required this.metric,
    required this.marker,
    super.key,
    this.onPinBranch,
    this.pinBranchLabel,
    this.pinBranchLabelBuilder,
  });

  final AppBrazilStoreSalesMarkerGroup group;
  final AppBrazilStoreSalesMapMetric metric;
  final Widget marker;
  final ValueChanged<AppBrazilStoreSalesPoint>? onPinBranch;
  final String? pinBranchLabel;
  final String Function(AppBrazilStoreSalesPoint)? pinBranchLabelBuilder;

  @override
  State<AppBrazilStoreSalesBranchHoverDetailAnchor> createState() =>
      _HoverMarkerDetailAnchorState();
}

class _HoverMarkerDetailAnchorState
    extends State<AppBrazilStoreSalesBranchHoverDetailAnchor> {
  static const Duration _hideDelay = Duration(milliseconds: 140);

  final OverlayPortalController _controller = OverlayPortalController();
  final LayerLink _link = LayerLink();
  final GlobalKey _markerKey = GlobalKey();
  Timer? _hideTimer;
  bool _hoveringMarker = false;
  bool _hoveringCard = false;
  double? _markerGlobalDx;

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  void _show() {
    _hideTimer?.cancel();
    _updateMarkerGlobalDx();
    _controller.show();
  }

  void _updateMarkerGlobalDx() {
    final markerContext = _markerKey.currentContext;
    final renderObject = markerContext?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) {
      return;
    }

    final nextDx = renderObject
        .localToGlobal(
          renderObject.size.center(Offset.zero),
        )
        .dx;
    if (_markerGlobalDx == nextDx) {
      return;
    }

    setState(() {
      _markerGlobalDx = nextDx;
    });
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(_hideDelay, () {
      if (!mounted || _hoveringMarker || _hoveringCard) {
        return;
      }
      _controller.hide();
    });
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _link,
      child: OverlayPortal(
        controller: _controller,
        overlayChildBuilder: (context) {
          return _HoverMarkerDetailFollower(
            link: _link,
            group: widget.group,
            metric: widget.metric,
            onPinBranch: widget.onPinBranch,
            pinBranchLabel: widget.pinBranchLabel,
            pinBranchLabelBuilder: widget.pinBranchLabelBuilder,
            onDismiss: _controller.hide,
            markerGlobalDx: _markerGlobalDx,
            onEnter: () {
              _hoveringCard = true;
              _show();
            },
            onExit: () {
              _hoveringCard = false;
              _scheduleHide();
            },
          );
        },
        child: MouseRegion(
          onEnter: (_) {
            _hoveringMarker = true;
            _show();
          },
          onExit: (_) {
            _hoveringMarker = false;
            _scheduleHide();
          },
          child: KeyedSubtree(key: _markerKey, child: widget.marker),
        ),
      ),
    );
  }
}

class _HoverMarkerDetailFollower extends StatelessWidget {
  const _HoverMarkerDetailFollower({
    required this.link,
    required this.group,
    required this.metric,
    required this.onEnter,
    required this.onExit,
    required this.markerGlobalDx,
    this.onPinBranch,
    this.pinBranchLabel,
    this.pinBranchLabelBuilder,
    this.onDismiss,
  });

  final LayerLink link;
  final AppBrazilStoreSalesMarkerGroup group;
  final AppBrazilStoreSalesMapMetric metric;
  final VoidCallback onEnter;
  final VoidCallback onExit;
  final double? markerGlobalDx;
  final ValueChanged<AppBrazilStoreSalesPoint>? onPinBranch;
  final String? pinBranchLabel;
  final String Function(AppBrazilStoreSalesPoint)? pinBranchLabelBuilder;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final maxWidth = (screenWidth - 32).clamp(280.0, 360.0);
    final followerAnchor = _followerAnchorFor(
      screenWidth: screenWidth,
      maxWidth: maxWidth,
      markerGlobalDx: markerGlobalDx,
    );
    void handleSelectBranch(AppBrazilStoreSalesPoint point) {
      onPinBranch?.call(point);
    }

    final selectBranch = onPinBranch == null ? null : handleSelectBranch;

    return Positioned.fill(
      child: CompositedTransformFollower(
        link: link,
        showWhenUnlinked: false,
        targetAnchor: Alignment.topCenter,
        followerAnchor: followerAnchor,
        offset: _followerOffsetFor(followerAnchor),
        child: UnconstrainedBox(
          alignment: followerAnchor,
          child: MouseRegion(
            onEnter: (_) => onEnter(),
            onExit: (_) => onExit(),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: _MapMarkerDetailSemanticsBoundary(
                child: _SelectedMarkerGroupDetailCard(
                  group: group,
                  metric: metric,
                  showTechnicalLocationDetails: false,
                  onSelectBranch: selectBranch,
                  selectBranchLabel: pinBranchLabel ?? 'Fixar filial',
                  selectBranchLabelBuilder: pinBranchLabelBuilder,
                  onDismiss: onDismiss,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MapMarkerDetailSemanticsBoundary extends StatelessWidget {
  const _MapMarkerDetailSemanticsBoundary({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform != TargetPlatform.windows) {
      return child;
    }

    // Windows' accessibility bridge can reject fast-changing overlay
    // semantics when marker hover cards mount/remount. Keep one stable
    // semantic boundary for the overlay and exclude the dynamic internals.
    return Semantics(
      container: true,
      label: 'Detalhes da filial no mapa',
      child: ExcludeSemantics(child: child),
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
    super.key,
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
    this.selectedStoreId,
    this.onSelectBranch,
    this.selectBranchLabelBuilder,
  });

  final AppBrazilStoreSalesMarkerGroup group;
  final AppBrazilStoreSalesMapMetric metric;
  final String? selectedStoreId;
  final ValueChanged<AppBrazilStoreSalesPoint>? onSelectBranch;
  final String Function(AppBrazilStoreSalesPoint)? selectBranchLabelBuilder;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;

    return Padding(
      padding: EdgeInsets.only(top: tokens.gapMd),
      child: _SelectedMarkerGroupDetailCard(
        group: group,
        metric: metric,
        initialStoreId: selectedStoreId,
        onSelectBranch: onSelectBranch,
        selectBranchLabelBuilder: selectBranchLabelBuilder,
      ),
    );
  }
}

class _SelectedStoreDetail extends StatelessWidget {
  const _SelectedStoreDetail({
    required this.point,
    required this.metric,
    this.onSelectBranch,
    this.selectBranchLabel,
  });

  final AppBrazilStoreSalesPoint point;
  final AppBrazilStoreSalesMapMetric metric;
  final ValueChanged<AppBrazilStoreSalesPoint>? onSelectBranch;
  final String? selectBranchLabel;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;

    return Padding(
      padding: EdgeInsets.only(top: tokens.gapMd),
      child: _SelectedMarkerStoreDetailCard(
        point: point,
        metric: metric,
        onSelectBranch: onSelectBranch,
        selectBranchLabel: selectBranchLabel,
      ),
    );
  }
}

class _SelectedMarkerGroupDetailCard extends StatelessWidget {
  const _SelectedMarkerGroupDetailCard({
    required this.group,
    required this.metric,
    this.initialStoreId,
    this.onClose,
    this.onDismiss,
    this.onSelectBranch,
    this.selectBranchLabel,
    this.selectBranchLabelBuilder,
    this.showTechnicalLocationDetails = true,
  });

  final AppBrazilStoreSalesMarkerGroup group;
  final AppBrazilStoreSalesMapMetric metric;
  final String? initialStoreId;
  final VoidCallback? onClose;
  final VoidCallback? onDismiss;
  final ValueChanged<AppBrazilStoreSalesPoint>? onSelectBranch;
  final String? selectBranchLabel;
  final String Function(AppBrazilStoreSalesPoint)? selectBranchLabelBuilder;
  final bool showTechnicalLocationDetails;

  @override
  Widget build(BuildContext context) {
    return _SelectedMarkerBranchCarouselCard(
      group: group,
      metric: metric,
      initialStoreId: initialStoreId,
      onClose: onClose,
      onDismiss: onDismiss,
      onSelectBranch: onSelectBranch,
      selectBranchLabel: selectBranchLabel,
      selectBranchLabelBuilder: selectBranchLabelBuilder,
      showTechnicalLocationDetails: showTechnicalLocationDetails,
    );
  }
}

class _SelectedMarkerStoreDetailCard extends StatelessWidget {
  const _SelectedMarkerStoreDetailCard({
    required this.point,
    required this.metric,
    this.onSelectBranch,
    this.selectBranchLabel,
    this.showTechnicalLocationDetails = true,
  });

  final AppBrazilStoreSalesPoint point;
  final AppBrazilStoreSalesMapMetric metric;
  final ValueChanged<AppBrazilStoreSalesPoint>? onSelectBranch;
  final String? selectBranchLabel;
  final bool showTechnicalLocationDetails;

  @override
  Widget build(BuildContext context) {
    return _SelectedMarkerBranchDetailSurface(
      point: point,
      metric: metric,
      showTechnicalLocationDetails: showTechnicalLocationDetails,
      onSelectBranch: onSelectBranch == null
          ? null
          : () => onSelectBranch!(point),
      selectBranchLabel: selectBranchLabel,
    );
  }
}

class _SelectedMarkerBranchCarouselCard extends StatefulWidget {
  const _SelectedMarkerBranchCarouselCard({
    required this.group,
    required this.metric,
    this.initialStoreId,
    this.onClose,
    this.onDismiss,
    this.onSelectBranch,
    this.selectBranchLabel,
    this.selectBranchLabelBuilder,
    this.showTechnicalLocationDetails = true,
  });

  final AppBrazilStoreSalesMarkerGroup group;
  final AppBrazilStoreSalesMapMetric metric;
  final String? initialStoreId;
  final VoidCallback? onClose;
  final VoidCallback? onDismiss;
  final ValueChanged<AppBrazilStoreSalesPoint>? onSelectBranch;
  final String? selectBranchLabel;
  final String Function(AppBrazilStoreSalesPoint)? selectBranchLabelBuilder;
  final bool showTechnicalLocationDetails;

  @override
  State<_SelectedMarkerBranchCarouselCard> createState() =>
      _SelectedMarkerBranchCarouselCardState();
}

class _SelectedMarkerBranchCarouselCardState
    extends State<_SelectedMarkerBranchCarouselCard> {
  late int _selectedIndex;
  late List<AppBrazilStoreSalesPoint> _orderedPoints;

  @override
  void initState() {
    super.initState();
    _orderedPoints = _orderedBranchPoints(
      widget.group,
      initialStoreId: widget.initialStoreId,
    );
    _selectedIndex = _initialIndex();
  }

  @override
  void didUpdateWidget(covariant _SelectedMarkerBranchCarouselCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.group != widget.group ||
        oldWidget.initialStoreId != widget.initialStoreId) {
      _orderedPoints = _orderedBranchPoints(
        widget.group,
        initialStoreId: widget.initialStoreId,
      );
      _selectedIndex = _initialIndex();
    } else if (_selectedIndex >= _orderedPoints.length) {
      _selectedIndex = 0;
    }
  }

  int _initialIndex() {
    final storeId = widget.initialStoreId;
    if (storeId == null) {
      return 0;
    }

    final index = _orderedPoints.indexWhere(
      (point) => point.id == storeId,
    );
    return index < 0 ? 0 : index;
  }

  void _move(int delta) {
    final count = _orderedPoints.length;
    if (count <= 1) {
      return;
    }

    setState(() {
      _selectedIndex = (_selectedIndex + delta) % count;
      if (_selectedIndex < 0) {
        _selectedIndex += count;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final point = _orderedPoints[_selectedIndex];
    final count = _orderedPoints.length;

    return Focus(
      autofocus: defaultTargetPlatform != TargetPlatform.windows,
      onKeyEvent: _handleKeyEvent,
      child: _SelectedMarkerBranchDetailSurface(
        point: point,
        metric: widget.metric,
        onClose: widget.onClose,
        showTechnicalLocationDetails: widget.showTechnicalLocationDetails,
        branchPositionLabel: count > 1
            ? '${_formatInteger(_selectedIndex + 1)} de ${_formatInteger(count)}'
            : null,
        aggregateSummary: count > 1
            ? _BranchAggregateSummary(
                group: widget.group,
                metric: widget.metric,
              )
            : null,
        onSelectBranch: widget.onSelectBranch == null
            ? null
            : () => widget.onSelectBranch!(point),
        selectBranchLabel:
            widget.selectBranchLabelBuilder?.call(point) ??
            widget.selectBranchLabel,
        navigation: count > 1
            ? _BranchCarouselNavigation(
                currentIndex: _selectedIndex,
                points: _orderedPoints,
                onPrevious: () => _move(-1),
                onNext: () => _move(1),
                onSelectIndex: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
              )
            : null,
      ),
    );
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _move(-1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _move(1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      final dismiss = widget.onDismiss ?? widget.onClose;
      dismiss?.call();
      return dismiss == null ? KeyEventResult.ignored : KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }
}

class _SelectedMarkerBranchDetailSurface extends StatelessWidget {
  const _SelectedMarkerBranchDetailSurface({
    required this.point,
    required this.metric,
    this.onClose,
    this.showTechnicalLocationDetails = true,
    this.branchPositionLabel,
    this.aggregateSummary,
    this.onSelectBranch,
    this.selectBranchLabel,
    this.navigation,
  });

  final AppBrazilStoreSalesPoint point;
  final AppBrazilStoreSalesMapMetric metric;
  final VoidCallback? onClose;
  final bool showTechnicalLocationDetails;
  final String? branchPositionLabel;
  final Widget? aggregateSummary;
  final VoidCallback? onSelectBranch;
  final String? selectBranchLabel;
  final Widget? navigation;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final colorScheme = Theme.of(context).colorScheme;
    final cityLabel = _cityLabelFor(point);
    final municipalityCode = point.municipalityCode?.trim();
    final branchName = _branchNameLabel(point);
    final agentName = _trimmedOrNull(point.agentName);
    final legacySubtitle = _trimmedOrNull(point.subtitle);
    final maxCardHeight = (MediaQuery.sizeOf(context).height - 48).clamp(
      260.0,
      460.0,
    );

    return Semantics(
      container: true,
      label: 'Detalhes da filial no mapa',
      child: AppBrazilStoreSalesMapOverlayTooltipScope(
        child: Material(
          key: const ValueKey<String>('brazil-store-sales-branch-card'),
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
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxCardHeight),
              child: SingleChildScrollView(
                key: const ValueKey<String>(
                  'brazil-store-sales-branch-card-scroll',
                ),
                padding: EdgeInsets.all(tokens.contentSpacing),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.storefront_outlined,
                          color: context.appColors.secondary,
                          size: 20,
                        ),
                        SizedBox(width: tokens.gapSm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _branchDisplayName(point),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              SizedBox(height: tokens.gapXs),
                              Text(
                                cityLabel,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: tokens.gapSm),
                        if (onClose == null)
                          AppTagChip(label: branchPositionLabel ?? metric.label)
                        else
                          AppBrazilStoreSalesMapWindowsSafeOverlayIconButton(
                            key: const ValueKey<String>(
                              'brazil-store-sales-branch-card-close',
                            ),
                            icon: Icons.close_rounded,
                            iconSize: 18,
                            dimension: 32,
                            onPressed: onClose!,
                            tooltipMessage: 'Fechar detalhes',
                          ),
                      ],
                    ),
                    SizedBox(height: tokens.gapMd),
                    if (onClose != null) ...[
                      Wrap(
                        spacing: tokens.gapSm,
                        runSpacing: tokens.gapSm,
                        children: [
                          const AppTagChip(label: 'Filial fixada'),
                          AppTagChip(label: metric.label),
                          if (branchPositionLabel != null)
                            AppTagChip(label: branchPositionLabel!),
                        ],
                      ),
                      SizedBox(height: tokens.gapSm),
                    ],
                    if (aggregateSummary != null) ...[
                      aggregateSummary!,
                      SizedBox(height: tokens.gapMd),
                    ],
                    Wrap(
                      spacing: tokens.gapSm,
                      runSpacing: tokens.gapSm,
                      children: [
                        if (point.salesDataLoading)
                          const AppTagChip(
                            label: 'Carregando vendas',
                            icon: Icons.sync_rounded,
                          )
                        else ...[
                          AppTagChip(
                            label: AppBrFormatters.currency(point.salesAmount),
                            icon: Icons.attach_money,
                          ),
                          AppTagChip(
                            label: '${_formatInteger(point.salesCount)} vendas',
                            icon: Icons.receipt_long_outlined,
                          ),
                        ],
                        if (!point.salesDataLoading &&
                            point.salesDataUnavailable)
                          AppTagChip(
                            label:
                                point.salesDataStatusLabel ??
                                'Vendas indisponiveis',
                            icon: Icons.sync_problem_outlined,
                          ),
                        if (agentName != null)
                          AppTagChip(
                            label: _agentChipLabel(agentName),
                            icon: Icons.hub_outlined,
                          )
                        else if (legacySubtitle != null)
                          AppTagChip(
                            label: legacySubtitle,
                            icon: Icons.hub_outlined,
                          ),
                        if (branchName != null)
                          AppTagChip(
                            label: branchName,
                            icon: Icons.store_mall_directory_outlined,
                          ),
                        if (showTechnicalLocationDetails &&
                            municipalityCode != null &&
                            municipalityCode.isNotEmpty)
                          AppTagChip(
                            label: 'IBGE $municipalityCode',
                            icon: Icons.pin_drop_outlined,
                          ),
                        if (showTechnicalLocationDetails)
                          AppTagChip(
                            label: _locationResolutionLabel(
                              point.locationResolution,
                            ),
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
                    if (onSelectBranch != null) ...[
                      SizedBox(height: tokens.gapMd),
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton.icon(
                          key: const ValueKey<String>(
                            'brazil-store-sales-branch-card-select',
                          ),
                          onPressed: onSelectBranch,
                          icon: const Icon(Icons.push_pin_outlined, size: 18),
                          label: Text(selectBranchLabel ?? 'Selecionar filial'),
                        ),
                      ),
                    ],
                    if (navigation != null) ...[
                      SizedBox(height: tokens.gapMd),
                      Divider(color: colorScheme.outlineVariant, height: 1),
                      SizedBox(height: tokens.gapXs),
                      navigation!,
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BranchCarouselNavigation extends StatelessWidget {
  const _BranchCarouselNavigation({
    required this.currentIndex,
    required this.points,
    required this.onPrevious,
    required this.onNext,
    required this.onSelectIndex,
  });

  final int currentIndex;
  final List<AppBrazilStoreSalesPoint> points;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ValueChanged<int> onSelectIndex;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final colorScheme = Theme.of(context).colorScheme;
    final branchCount = points.length;
    final showBranchPicker = branchCount >= 10;

    final pickerTooltip = defaultTargetPlatform == TargetPlatform.windows
        ? ''
        : 'Escolher filial';

    return Row(
      children: [
        if (showBranchPicker) ...[
          PopupMenuButton<int>(
            key: const ValueKey<String>(
              'brazil-store-sales-branch-card-picker',
            ),
            tooltip: pickerTooltip,
            onSelected: onSelectIndex,
            itemBuilder: (context) => [
              for (var index = 0; index < points.length; index++)
                PopupMenuItem<int>(
                  value: index,
                  child: Text(
                    '${_formatInteger(index + 1)}. '
                    '${_branchDisplayName(points[index])}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            icon: const Icon(Icons.list_alt_outlined),
          ),
          SizedBox(width: tokens.gapXs),
        ],
        AppBrazilStoreSalesMapWindowsSafeOverlayIconButton(
          key: const ValueKey<String>(
            'brazil-store-sales-branch-card-previous',
          ),
          icon: Icons.chevron_left_rounded,
          dimension: 34,
          onPressed: onPrevious,
          tooltipMessage: 'Filial anterior',
        ),
        Expanded(
          child: Text(
            '${_formatInteger(currentIndex + 1)} de '
            '${_formatInteger(branchCount)}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        SizedBox(width: tokens.gapXs),
        AppBrazilStoreSalesMapWindowsSafeOverlayIconButton(
          key: const ValueKey<String>('brazil-store-sales-branch-card-next'),
          icon: Icons.chevron_right_rounded,
          dimension: 34,
          onPressed: onNext,
          tooltipMessage: 'Proxima filial',
        ),
      ],
    );
  }
}

class _BranchAggregateSummary extends StatelessWidget {
  const _BranchAggregateSummary({
    required this.group,
    required this.metric,
  });

  final AppBrazilStoreSalesMarkerGroup group;
  final AppBrazilStoreSalesMapMetric metric;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final colorScheme = Theme.of(context).colorScheme;
    final hasLoadingSales = group.points.any(
      (point) => point.salesDataLoading,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(tokens.formFieldRadius),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: EdgeInsets.all(tokens.gapSm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total do ponto',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: tokens.gapXs),
            Wrap(
              spacing: tokens.gapSm,
              runSpacing: tokens.gapSm,
              children: [
                if (hasLoadingSales)
                  const AppTagChip(
                    label: 'Carregando vendas',
                    icon: Icons.sync_rounded,
                  )
                else ...[
                  AppTagChip(
                    label: AppBrFormatters.currency(group.salesAmount),
                    icon: Icons.attach_money,
                  ),
                  AppTagChip(
                    label: '${_formatInteger(group.salesCount)} vendas',
                    icon: Icons.receipt_long_outlined,
                  ),
                ],
                AppTagChip(
                  label: '${_formatInteger(group.points.length)} filiais',
                  icon: Icons.storefront_outlined,
                ),
                AppTagChip(label: metric.label),
              ],
            ),
          ],
        ),
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
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final AppBrazilStoreSalesMapMetric metric;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surface,
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
                  AppTagChip(label: metric.label),
                ],
              ),
              SizedBox(height: tokens.gapMd),
              child,
            ],
          ),
        ),
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

  return _branchDisplayName(left).compareTo(_branchDisplayName(right));
}

String _branchDisplayName(AppBrazilStoreSalesPoint point) {
  return _trimmedOrNull(point.fantasyName) ??
      _trimmedOrNull(point.name) ??
      'Filial sem nome';
}

String? _branchNameLabel(AppBrazilStoreSalesPoint point) {
  final branchName = _trimmedOrNull(point.branchName);
  if (branchName == null || branchName == _branchDisplayName(point)) {
    return null;
  }
  return branchName;
}

String _agentChipLabel(String agentName) {
  return agentName.toLowerCase().startsWith('agente ')
      ? agentName
      : 'Agente $agentName';
}

String? _trimmedOrNull(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }
  return trimmed;
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

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
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_localizations.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_models.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_overlay_chrome.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_snapshot.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_shell.dart';
import 'package:colmeia/shared/widgets/charts/app_region_map_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

part 'app_brazil_store_sales_map_chart_auxiliary.dart';
part 'app_brazil_store_sales_map_chart_details.dart';
part 'app_brazil_store_sales_map_chart_overlay.dart';

String _formatSalesCount(BuildContext context, num value) {
  final locale = Localizations.localeOf(context);
  return NumberFormat('#,##0', locale.toLanguageTag()).format(value.round());
}

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

  /// Optional externally controlled selection (e.g. deep-link); when set and
  /// not dismissed, overrides internal marker selection.
  final String? selectedStoreId;

  /// Branch ids selected outside the map (e.g. sheet filter).
  final Set<String> filterBranchIds;

  /// Union of external highlights (e.g. filter); drives reuse keys and cleanup.
  final Set<String> fixedBranchIds;
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
  Timer? _viewportClusterDebounceTimer;
  double? _pendingViewportClusterZoomLevel;

  void _cancelPendingViewportClusterSampling() {
    _viewportClusterDebounceTimer?.cancel();
    _viewportClusterDebounceTimer = null;
    _pendingViewportClusterZoomLevel = null;
  }

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
  static const Duration _windowsViewportClusterDebounceDuration = Duration(
    milliseconds: 500,
  );

  @override
  void initState() {
    super.initState();
    _selectedMetric = widget.initialMetric;
    _currentZoomLevel = widget.selectedStoreId != null
        ? widget.style.selectedStoreZoomLevel
        : AppBrazilMapStaticData.brazilViewport.zoomLevel;
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
      if (oldWidget.selectedStoreId != null && widget.selectedStoreId == null) {
        _dismissedControlledSelectedStoreId = null;
        _currentZoomLevel = AppBrazilMapStaticData.brazilViewport.zoomLevel;
        _cancelPendingViewportClusterSampling();
      }
      if (oldWidget.selectedStoreId != widget.selectedStoreId &&
          widget.selectedStoreId != null) {
        _currentZoomLevel = widget.style.selectedStoreZoomLevel;
        _dismissedControlledSelectedStoreId = null;
        _cancelPendingViewportClusterSampling();
      }
      _snapshot = null;
    }

    if (oldWidget.filterBranchIds != widget.filterBranchIds ||
        oldWidget.fixedBranchIds != widget.fixedBranchIds) {
      _snapshot = null;
    }
  }

  @override
  void dispose() {
    _cancelPendingViewportClusterSampling();
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
                  ? AppBrazilStoreSalesMapLocalizations.regionScopeOptions(l10n)
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
                scopeRootLabel: l10n.brazilStoreSalesMapCountryLabel,
                lowValueColor: widget.style.lowValueColor ?? _lowColor(context),
                highValueColor:
                    widget.style.highValueColor ?? _highColor(context),
                dataLabelTextStyle: stateDataLabelTextStyle,
                metricSelectorPadding: usesCompactMapChrome
                    ? EdgeInsets.zero
                    : null,
                legendNumberFormat: _legendFormat,
                emptyStateMessage: _resolvedEmptyStateMessage(l10n),
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
                selectBranchLabelBuilder: (_) => AppLocalizations.of(
                  context,
                ).brazilStoreSalesMapShowBranchOnMapAction,
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

  String _resolvedEmptyStateMessage(AppLocalizations l10n) {
    if (widget.style.emptyStateMessage ==
        AppBrazilStoreSalesMapStyle.defaultEmptyStateMessage) {
      return l10n.brazilStoreSalesMapEmptyState;
    }
    return widget.style.emptyStateMessage;
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
    final languageCode = Localizations.localeOf(context).languageCode;
    if (languageCode != 'pt') {
      return bucket.stateName;
    }
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
    return AppBrazilStoreSalesMapSnapshotBuilder.buildReuseKey(
      points: widget.points,
      fixedBranchIds: widget.fixedBranchIds,
      filterBranchIds: widget.filterBranchIds,
      style: widget.style,
      metric: _selectedMetric,
      selectedStoreId: selectedStoreId,
      requestedStateKey: _internalSelectedStateKey,
      activeRegionKey: _activeRegionKey,
      zoomLevel: _currentZoomLevel,
    );
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
    _selectPoint(point);
    _emitStoreTap(point: point, index: index);
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
            onSelectBranch: (point) {
              unawaited(Navigator.of(sheetContext).maybePop());
              _handleMarkerBranchAction(point: point, index: markerIndex);
            },
            selectBranchLabelBuilder: (_) => AppLocalizations.of(
              sheetContext,
            ).brazilStoreSalesMapShowBranchOnMapAction,
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

    // Syncfusion Maps + debounced viewport zoom + OverlayPortals overload the
    // Windows accessibility bridge (AXTree) in practice. In release builds we
    // still follow zoom with a heavy throttle; in debug/profile/tests we skip
    // viewport-driven clustering updates entirely on Windows.
    if (defaultTargetPlatform == TargetPlatform.windows && !kReleaseMode) {
      _cancelPendingViewportClusterSampling();
      return;
    }

    // While auto-focus keeps the camera on a selected branch, the engine
    // still reports the *current* zoom during transitions (e.g. Brazil ~1.0
    // right after we set clustering zoom to [selectedStoreZoomLevel]).
    // Applying those samples overwrites [_currentZoomLevel], invalidates the
    // snapshot on every tick, and can spin rebuilds + Windows AXTree updates.
    if (widget.style.autoFocusSelectedStore && _selectedStoreId != null) {
      _cancelPendingViewportClusterSampling();
      return;
    }

    final rawZoom = event.viewport.zoomLevel;
    final nextZoomLevel =
        defaultTargetPlatform == TargetPlatform.windows && kReleaseMode
        ? (rawZoom * 4).round() / 4.0
        : rawZoom;

    final debounceDuration =
        defaultTargetPlatform == TargetPlatform.windows && kReleaseMode
        ? _windowsViewportClusterDebounceDuration
        : (_shouldDebounceTouchViewportClustering
              ? _touchViewportClusterDebounceDuration
              : _desktopViewportClusterDebounceDuration);

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
    if (widget.style.autoFocusSelectedStore && _selectedStoreId != null) {
      return;
    }
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
      );
    }

    return AppBrazilStoreSalesSelectedMarkerDetailAnchor(
      group: group,
      selectedStoreId: selectedStoreId,
      metric: _selectedMetric,
      marker: marker,
      onClose: _clearSelectedMarkerDetail,
      onSelectBranch: (point) =>
          _handleMarkerBranchAction(point: point, index: index),
      selectBranchLabelBuilder: (_) =>
          AppLocalizations.of(context).brazilStoreSalesMapShowBranchOnMapAction,
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

  String _stateBubbleSemanticLabel(AppBrazilStoreSalesStateBucket bucket) {
    final l10n = AppLocalizations.of(context);
    return l10n.brazilStoreSalesMapSemanticsStateAggregate(
      bucket.stateName,
      AppBrFormatters.currency(bucket.salesAmount),
      _formatSalesCount(context, bucket.salesCount),
      _formatSalesCount(context, bucket.storeCount),
    );
  }
}

class _BrazilStoreSalesMapSnapshot {
  const _BrazilStoreSalesMapSnapshot({
    required this.data,
    required this.mapPoints,
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
    final data = AppBrazilStoreSalesMapSnapshotBuilder.build(
      AppBrazilStoreSalesMapSnapshotInput(
        points: points,
        metric: metric,
        selectedStoreId: selectedStoreId,
        requestedStateKey: requestedStateKey,
        activeRegionKey: activeRegionKey,
        zoomLevel: zoomLevel,
        style: style,
      ),
      cachedReuseKey: cachedReuseKey,
    );
    final mapPoints = _buildMapPoints(
      context: context,
      data: data,
      style: style,
    );

    final snapshot = _BrazilStoreSalesMapSnapshot(
      data: data,
      mapPoints: mapPoints,
    );
    if (stopwatch != null) {
      AppLogger.info(
        'Brazil store sales map snapshot built',
        context: <String, Object?>{
          'operation': 'AppBrazilStoreSalesMapChart',
          'elapsedMs': stopwatch.elapsedMilliseconds,
          'inputPointCount': points.length,
          'validPointCount': data.validPointCount,
          'bucketCount': data.buckets.length,
          'markerGroupCount': data.markerGroups.length,
          'mapPointCount': mapPoints.length,
          'aggregation': style.markerAggregation.name,
          'activeRegionKey': activeRegionKey,
        },
      );
    }
    return snapshot;
  }

  final AppBrazilStoreSalesMapSnapshotData data;
  final List<AppMapPoint> mapPoints;

  AppBrazilStoreSalesMapMetric get metric => data.metric;
  String? get selectedStoreId => data.selectedStoreId;
  String? get requestedStateKey => data.requestedStateKey;
  String? get activeRegionKey => data.activeRegionKey;
  double get zoomLevel => data.zoomLevel;
  List<AppBrazilStoreSalesStateBucket> get buckets => data.buckets;
  AppBrazilStoreSalesPoint? get selectedPoint => data.selectedPoint;
  AppBrazilStoreSalesMarkerGroup? get selectedMarkerGroup =>
      data.selectedMarkerGroup;
  String? get selectedStateKey => data.selectedStateKey;
  AppBrazilStoreSalesStateBucket? get selectedStateBucket =>
      data.selectedStateBucket;
  num get minMarkerValue => data.minMarkerValue;
  num get maxMarkerValue => data.maxMarkerValue;
  AppBrazilStoreSalesMapDiagnostics get diagnostics => data.diagnostics;
  String get cachedReuseKey => data.cachedReuseKey;

  bool get hasMarkers => mapPoints.isNotEmpty;

  static List<AppMapPoint> _buildMapPoints({
    required BuildContext context,
    required AppBrazilStoreSalesMapSnapshotData data,
    required AppBrazilStoreSalesMapStyle style,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final markerColor = style.markerColor ?? context.appColors.tertiary;
    final markerStrokeColor = style.markerStrokeColor ?? colorScheme.surface;
    final pendingMarkerColor = context.appColors.secondary;
    final unavailableMarkerColor = colorScheme.onSurfaceVariant;
    final selectedMarkerColor =
        style.selectedMarkerColor ?? context.appColors.secondary;
    final selectedMarkerStrokeColor =
        style.selectedMarkerStrokeColor ?? colorScheme.surface;
    final mapPoints = <AppMapPoint>[];

    for (final bucket in data.stateBubbleBuckets) {
      final centroid = AppBrazilMapStaticData.stateCentroidsByUf[bucket.uf];
      if (centroid == null) {
        continue;
      }

      final selected = bucket.uf == data.selectedStateKey;
      final value = data.metric.valueForBucket(bucket);
      final markerSize = _effectiveMarkerSize(
        size: AppBrazilStoreSalesMapData.markerSizeFor(
          value: value,
          minValue: data.minMarkerValue,
          maxValue: data.maxMarkerValue,
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
          tooltip: style.showTooltip
              ? _stateBubbleTooltip(context, bucket)
              : null,
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

    for (final group in data.markerGroups) {
      final selected = group.points.any(
        (point) => point.id == data.selectedStoreId,
      );
      final size = AppBrazilStoreSalesMapData.markerSizeFor(
        value: group.valueForMetric(data.metric),
        minValue: data.minMarkerValue,
        maxValue: data.maxMarkerValue,
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

    return mapPoints;
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

  static String _stateBubbleTooltip(
    BuildContext context,
    AppBrazilStoreSalesStateBucket bucket,
  ) {
    final l10n = AppLocalizations.of(context);
    return l10n.brazilStoreSalesMapStateBucketTooltip(
      bucket.stateName,
      bucket.uf,
      AppBrFormatters.currency(bucket.salesAmount),
      _formatSalesCount(context, bucket.salesCount),
      _formatSalesCount(context, bucket.storeCount),
    );
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
  return _trimmedOrNull(point.fantasyName) ??
      _trimmedOrNull(point.name) ??
      point.id;
}

String _branchDisplayNameUi(
  BuildContext context,
  AppBrazilStoreSalesPoint point,
) {
  return _trimmedOrNull(point.fantasyName) ??
      _trimmedOrNull(point.name) ??
      AppLocalizations.of(context).brazilStoreSalesMapDefaultBranchName;
}

String? _branchNameLabel(AppBrazilStoreSalesPoint point) {
  final branchName = _trimmedOrNull(point.branchName);
  if (branchName == null || branchName == _branchOrdinalName(point)) {
    return null;
  }
  return branchName;
}

String _agentChipLabel(AppLocalizations l10n, String agentName) {
  final lower = agentName.toLowerCase();
  if (lower.startsWith('agente ') || lower.startsWith('agent ')) {
    return agentName;
  }
  return l10n.brazilStoreSalesMapAgentChipWithName(agentName);
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

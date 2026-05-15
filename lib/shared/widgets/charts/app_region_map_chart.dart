import 'dart:typed_data';

import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_shell.dart';
import 'package:colmeia/shared/widgets/charts/app_map_models.dart';
import 'package:colmeia/shared/widgets/charts/engines/syncfusion_region_map_chart.dart';
import 'package:colmeia/shared/widgets/forms/app_choice_chip.dart';
import 'package:colmeia/shared/widgets/forms/app_segmented_control.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

export 'app_map_models.dart';

enum AppMapSourceType {
  asset,
  network,
  memory,
}

enum AppMapRegionLevel {
  region,
  state,
  city,
  custom,
}

class AppMapDefinition {
  const AppMapDefinition.asset({
    required String assetPath,
    required this.shapeDataField,
    this.regionLevel = AppMapRegionLevel.custom,
  }) : sourceType = AppMapSourceType.asset,
       pathOrUrl = assetPath,
       bytes = null;

  const AppMapDefinition.network({
    required String url,
    required this.shapeDataField,
    this.regionLevel = AppMapRegionLevel.custom,
  }) : sourceType = AppMapSourceType.network,
       pathOrUrl = url,
       bytes = null;

  const AppMapDefinition.memory({
    required Uint8List sourceBytes,
    required this.shapeDataField,
    this.regionLevel = AppMapRegionLevel.custom,
  }) : sourceType = AppMapSourceType.memory,
       pathOrUrl = null,
       bytes = sourceBytes;

  final AppMapSourceType sourceType;
  final String shapeDataField;
  final String? pathOrUrl;
  final Uint8List? bytes;
  final AppMapRegionLevel regionLevel;
}

class AppMapMetric<T> {
  const AppMapMetric({
    required this.key,
    required this.label,
    required this.valueBuilder,
    this.legendLabel,
    this.tooltipBuilder,
  });

  final String key;
  final String label;
  final num Function(T item) valueBuilder;
  final String? legendLabel;
  final String Function(T item)? tooltipBuilder;
}

class AppRegionMapChartStyle {
  const AppRegionMapChartStyle({
    this.height,
    this.chartPadding,
    this.showTooltip = true,
    this.showShapeTooltip = true,
    this.showLegend = true,
    this.showDataLabels = false,
    this.showMetricSelector = true,
    this.enableZoomPan = true,
    this.enableDoubleTapZooming = false,
    this.enableAutoDrillOnTap = false,
    this.autoDrillCeiling,
    this.minZoomLevel = 1,
    this.maxZoomLevel = 8,
    this.selectionColor,
    this.selectionStrokeColor,
    this.selectionStrokeWidth = 1.8,
    this.shapeStrokeColor,
    this.shapeStrokeWidth = 0.8,
    this.lowValueColor,
    this.highValueColor,
    this.legendLabelTextStyle,
    this.legendNumberFormat,
    this.dataLabelTextStyle,
    this.metricSelectorPadding,
    this.scopeRootLabel = 'Brasil',
    this.mapLoadingMessage = 'Carregando mapa...',
    this.emptyStateMessage = 'Nenhum dado territorial para exibir.',
    this.excludeNativeMapSemanticsOnWindows = true,
    this.mapSemanticsLabel,
    this.metricGroupLabel = 'Métrica',
    this.scopeGroupLabel = 'Escopo',
    this.showGroupLabels = true,
  });

  final double? height;
  final EdgeInsets? chartPadding;
  final bool showTooltip;
  final bool showShapeTooltip;
  final bool showLegend;
  final bool showDataLabels;
  final bool showMetricSelector;
  final bool enableZoomPan;
  final bool enableDoubleTapZooming;
  final bool enableAutoDrillOnTap;

  /// When set, auto drill-on-tap never advances beyond this granularity (e.g.
  /// cap at [AppMapDrillLevel.state] so UF taps select instead of drilling to city).
  final AppMapDrillLevel? autoDrillCeiling;

  final double minZoomLevel;
  final double maxZoomLevel;
  final Color? selectionColor;
  final Color? selectionStrokeColor;
  final double selectionStrokeWidth;
  final Color? shapeStrokeColor;
  final double shapeStrokeWidth;
  final Color? lowValueColor;
  final Color? highValueColor;
  final TextStyle? legendLabelTextStyle;
  final NumberFormat? legendNumberFormat;
  final TextStyle? dataLabelTextStyle;
  final EdgeInsets? metricSelectorPadding;

  /// Label for the root scope chip (national / full map view).
  final String scopeRootLabel;

  /// Shown under the progress indicator while the map layer loads.
  final String mapLoadingMessage;

  /// Shown when the chart has no rows and no custom empty placeholder.
  final String emptyStateMessage;

  /// Workaround for a Syncfusion Maps 33.x + Flutter Windows accessibility
  /// bridge crash while the native map semantics tree is mounted/remounted.
  final bool excludeNativeMapSemanticsOnWindows;

  /// Optional summary announced for the map surface when native map semantics
  /// are excluded. When null, the engine builds a summary from the metric,
  /// regions and markers.
  final String? mapSemanticsLabel;

  /// Overline shown above the metric chips. Set [showGroupLabels] to `false`
  /// to hide both labels.
  final String metricGroupLabel;

  /// Overline shown above the scope chips.
  final String scopeGroupLabel;

  /// Whether to render the overline labels above the chip groups.
  final bool showGroupLabels;
}

class AppRegionMapChart<T> extends StatefulWidget {
  const AppRegionMapChart({
    required this.items,
    required this.mapDefinition,
    required this.metrics,
    required this.regionKeyBuilder,
    required this.regionLabelBuilder,
    super.key,
    this.title,
    this.subtitle,
    this.titleTrailing,
    this.belowSubtitle,
    this.scopeOptions = const <AppMapScopeOption>[],
    this.activeScopeKey,
    this.preferredViewport,
    this.selectedMetricKey,
    this.selectedRegionKey,
    this.currentDrillLevel = AppMapDrillLevel.region,
    this.onRegionTap,
    this.onRegionTapEvent,
    this.onSelectionChanged,
    this.onMetricChanged,
    this.onScopeChanged,
    this.onDrillDownRequested,
    this.onDrillUpRequested,
    this.onViewportChanged,
    this.style = const AppRegionMapChartStyle(),
    this.preset = AppChartPreset.standard,
    this.isLoading = false,
    this.isRefreshing = false,
    this.emptyPlaceholder,
    this.points = const <AppMapPoint>[],
    this.markerStyle = const AppMapMarkerStyle(),
    this.markerBuilder,
    this.markerTooltipBuilder,
    this.onPointTap,
  });

  final List<T> items;
  final AppMapDefinition mapDefinition;
  final List<AppMapMetric<T>> metrics;
  final String Function(T item) regionKeyBuilder;
  final String Function(T item) regionLabelBuilder;

  final String? title;
  final String? subtitle;
  final Widget? titleTrailing;
  final Widget? belowSubtitle;
  final List<AppMapScopeOption> scopeOptions;
  final String? activeScopeKey;
  final AppMapViewport? preferredViewport;

  final String? selectedMetricKey;
  final String? selectedRegionKey;
  final AppMapDrillLevel currentDrillLevel;

  /// Prefer [onRegionTapEvent] for structured payloads and analytics.
  final void Function(T item, String regionKey)? onRegionTap;
  final ValueChanged<AppMapRegionTapEvent<T>>? onRegionTapEvent;
  final ValueChanged<AppMapSelectionChangedEvent<T>>? onSelectionChanged;
  final ValueChanged<AppMapMetricChangedEvent>? onMetricChanged;
  final ValueChanged<AppMapScopeChangedEvent>? onScopeChanged;
  final ValueChanged<AppMapDrillDownEvent<T>>? onDrillDownRequested;
  final ValueChanged<AppMapDrillUpEvent>? onDrillUpRequested;

  /// Fired when the user pans or zooms the map. Avoid removing this chart from
  /// the tree or navigating synchronously inside this callback; schedule work
  /// after the current frame instead.
  final ValueChanged<AppMapViewportChangedEvent>? onViewportChanged;

  final AppRegionMapChartStyle style;
  final AppChartPreset preset;
  final bool isLoading;
  final bool isRefreshing;
  final Widget? emptyPlaceholder;

  /// Optional list of geographic markers overlaid on top of the region
  /// shapes. Use to highlight stores, agencies, events, etc.
  final List<AppMapPoint> points;

  /// Default visual style for markers. Per-point [AppMapPoint.style]
  /// overrides this when provided.
  final AppMapMarkerStyle markerStyle;

  /// Builder for a custom marker widget. When provided, the resulting
  /// widget is used as the marker child instead of the icon shape from
  /// [AppMapMarkerStyle.iconType].
  final Widget Function(BuildContext context, AppMapPoint point, int index)?
  markerBuilder;

  /// Builder for rich marker tooltip content. When null, the engine uses
  /// [AppMapPoint.tooltip] or [AppMapPoint.label] as plain text.
  final Widget Function(BuildContext context, AppMapPoint point, int index)?
  markerTooltipBuilder;

  /// Called when the user taps a marker.
  final ValueChanged<AppMapPointTapEvent>? onPointTap;

  @override
  State<AppRegionMapChart<T>> createState() => _AppRegionMapChartState<T>();
}

class _AppRegionMapChartState<T> extends State<AppRegionMapChart<T>> {
  String? _internalSelectedMetricKey;

  bool get _isControlled => widget.selectedMetricKey != null;

  @override
  void initState() {
    super.initState();
    _internalSelectedMetricKey = widget.selectedMetricKey;
  }

  @override
  void didUpdateWidget(covariant AppRegionMapChart<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isControlled) {
      _internalSelectedMetricKey = widget.selectedMetricKey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final resolvedMetric = _resolveSelectedMetric();

    final showGroupLabels = widget.style.showGroupLabels;
    final metricSelector = _MetricSelector<T>(
      metrics: widget.metrics,
      selectedMetricKey: resolvedMetric.key,
      style: widget.style,
      onMetricChanged: _handleMetricChanged,
    );
    final labeledMetricSelector = showGroupLabels
        ? _MapControlGroup(
            label: widget.style.metricGroupLabel,
            child: metricSelector,
          )
        : metricSelector;

    final innerChart = SyncfusionRegionMapChart<T>(
      items: widget.items,
      mapDefinition: widget.mapDefinition,
      metric: resolvedMetric,
      regionKeyBuilder: widget.regionKeyBuilder,
      regionLabelBuilder: widget.regionLabelBuilder,
      selectedRegionKey: widget.selectedRegionKey,
      preferredViewport: widget.preferredViewport,
      currentDrillLevel: widget.currentDrillLevel,
      onRegionTap: widget.onRegionTap,
      onRegionTapEvent: widget.onRegionTapEvent,
      onSelectionChanged: widget.onSelectionChanged,
      onDrillDownRequested: widget.onDrillDownRequested,
      onViewportChanged: widget.onViewportChanged,
      style: widget.style,
      preset: widget.preset,
      isLoading: widget.isLoading,
      isRefreshing: widget.isRefreshing,
      emptyPlaceholder: widget.emptyPlaceholder,
      points: widget.points,
      markerStyle: widget.markerStyle,
      markerBuilder: widget.markerBuilder,
      markerTooltipBuilder: widget.markerTooltipBuilder,
      onPointTap: widget.onPointTap,
    );

    final drillUpButton = _buildDrillUpButton();
    final scopeNavigator = _buildScopeNavigator();

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (widget.style.showMetricSelector &&
            widget.metrics.length > 1) ...<Widget>[
          labeledMetricSelector,
          SizedBox(height: tokens.gapMd),
        ],
        if (scopeNavigator != null) ...<Widget>[
          scopeNavigator,
          SizedBox(height: tokens.gapMd),
        ],
        if (drillUpButton != null) ...<Widget>[
          drillUpButton,
          SizedBox(height: tokens.gapMd),
        ],
        innerChart,
      ],
    );

    if (widget.title == null) {
      return content;
    }

    return AppChartShell(
      title: widget.title!,
      subtitle: widget.subtitle,
      titleTrailing: widget.titleTrailing,
      belowSubtitle: widget.belowSubtitle,
      child: content,
    );
  }

  AppMapMetric<T> _resolveSelectedMetric() {
    if (widget.metrics.isEmpty) {
      throw ArgumentError.value(
        widget.metrics,
        'metrics',
        'AppRegionMapChart requires at least one metric definition.',
      );
    }

    final key = _isControlled
        ? widget.selectedMetricKey
        : _internalSelectedMetricKey;
    if (key == null) {
      return widget.metrics.first;
    }

    for (final metric in widget.metrics) {
      if (metric.key == key) {
        return metric;
      }
    }
    return widget.metrics.first;
  }

  void _handleMetricChanged(AppMapMetricChangedEvent event) {
    if (!_isControlled) {
      setState(() {
        _internalSelectedMetricKey = event.metricKey;
      });
    }
    widget.onMetricChanged?.call(event);
  }

  Widget? _buildDrillUpButton() {
    final callback = widget.onDrillUpRequested;
    if (callback == null ||
        widget.currentDrillLevel == AppMapDrillLevel.region) {
      return null;
    }

    final nextLevel = switch (widget.currentDrillLevel) {
      AppMapDrillLevel.custom => AppMapDrillLevel.city,
      AppMapDrillLevel.city => AppMapDrillLevel.state,
      AppMapDrillLevel.state => AppMapDrillLevel.region,
      AppMapDrillLevel.region => AppMapDrillLevel.region,
    };
    final label = switch (nextLevel) {
      AppMapDrillLevel.region => 'Voltar para regiões',
      AppMapDrillLevel.state => 'Voltar para estados',
      AppMapDrillLevel.city => 'Voltar para cidades',
      AppMapDrillLevel.custom => 'Voltar',
    };

    return Align(
      alignment: Alignment.centerLeft,
      child: Tooltip(
        message: 'Retornar ao nível anterior do mapa',
        child: ActionChip(
          avatar: const Icon(Icons.arrow_back_rounded, size: 16),
          label: Text(label),
          onPressed: () {
            callback(
              AppMapDrillUpEvent(
                fromLevel: widget.currentDrillLevel,
                toLevel: nextLevel,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget? _buildScopeNavigator() {
    final callback = widget.onScopeChanged;
    if (callback == null || widget.scopeOptions.isEmpty) {
      return null;
    }

    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final rootLabel = widget.style.scopeRootLabel;

    final navigator = Semantics(
      label: 'Escopo territorial',
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Wrap(
          spacing: tokens.gapSm,
          runSpacing: tokens.gapSm,
          children: <Widget>[
            AppChoiceChip(
              label: rootLabel,
              selected: widget.activeScopeKey == null,
              tooltip: 'Ver mapa completo ($rootLabel)',
              semanticLabel: 'Ver mapa completo $rootLabel',
              onSelected: () {
                if (widget.activeScopeKey == null) {
                  return;
                }
                callback(
                  AppMapScopeChangedEvent(
                    previousScopeKey: widget.activeScopeKey,
                    currentScopeKey: null,
                  ),
                );
              },
            ),
            for (final option in widget.scopeOptions)
              AppChoiceChip(
                label: option.label,
                selected: option.key == widget.activeScopeKey,
                tooltip: 'Focar em ${option.label}',
                semanticLabel: 'Focar em ${option.label}',
                onSelected: () {
                  if (option.key == widget.activeScopeKey) {
                    return;
                  }
                  callback(
                    AppMapScopeChangedEvent(
                      previousScopeKey: widget.activeScopeKey,
                      currentScopeKey: option.key,
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );

    if (!widget.style.showGroupLabels) {
      return navigator;
    }
    return _MapControlGroup(
      label: widget.style.scopeGroupLabel,
      child: navigator,
    );
  }
}

class _MapControlGroup extends StatelessWidget {
  const _MapControlGroup({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final typography = theme.appTypography;
    final colors = theme.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          label.toUpperCase(),
          style: typography.utilityOverline.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        SizedBox(height: tokens.gapXs),
        child,
      ],
    );
  }
}

class _MetricSelector<T> extends StatelessWidget {
  const _MetricSelector({
    required this.metrics,
    required this.selectedMetricKey,
    required this.style,
    required this.onMetricChanged,
  });

  final List<AppMapMetric<T>> metrics;
  final String selectedMetricKey;
  final AppRegionMapChartStyle style;
  final ValueChanged<AppMapMetricChangedEvent> onMetricChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: style.metricSelectorPadding ?? EdgeInsets.zero,
      child: Semantics(
        label: 'Métrica do mapa',
        child: AppSegmentedControl<String>(
          options: metrics
              .map(
                (metric) => AppSegmentedControlOption<String>(
                  value: metric.key,
                  label: metric.label,
                ),
              )
              .toList(growable: false),
          value: selectedMetricKey,
          onChanged: (nextMetricKey) {
            if (nextMetricKey == selectedMetricKey) {
              return;
            }
            onMetricChanged(
              AppMapMetricChangedEvent(
                metricKey: nextMetricKey,
                previousMetricKey: selectedMetricKey,
              ),
            );
          },
        ),
      ),
    );
  }
}

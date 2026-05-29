import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_formatters.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_models.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_theme.dart';
import 'package:colmeia/shared/widgets/charts/app_step_line_chart.dart';
import 'package:colmeia/shared/widgets/charts/engines/chart_engine_defaults.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class SyncfusionStepLineChart extends StatefulWidget {
  const SyncfusionStepLineChart({
    required this.entries,
    required this.isMultiSeries,
    required this.style,
    required this.preset,
    super.key,
    this.onPointTap,
    this.isLoading = false,
    this.emptyPlaceholder,
  });

  final List<AppStepLineEntry> entries;
  final bool isMultiSeries;
  final void Function(
    AppStepLineEntry entry,
    AppChartPoint point,
    int pointIndex,
    int seriesIndex,
  )?
  onPointTap;
  final AppStepLineChartStyle style;
  final AppChartPreset preset;
  final bool isLoading;
  final Widget? emptyPlaceholder;

  @override
  State<SyncfusionStepLineChart> createState() =>
      _SyncfusionStepLineChartState();
}

class _SyncfusionStepLineChartState extends State<SyncfusionStepLineChart> {
  List<AppStepLineEntry>? _entriesRef;
  List<AppStepLineEntry> _visibleEntries = const <AppStepLineEntry>[];

  void _recomputeVisibleEntriesIfNeeded() {
    if (identical(_entriesRef, widget.entries)) {
      return;
    }
    _entriesRef = widget.entries;
    _visibleEntries = widget.entries
        .map(
          (entry) => AppStepLineEntry(
            label: entry.label,
            color: entry.color,
            points: entry.points
                .where(_hasRenderableValue)
                .toList(growable: false),
          ),
        )
        .toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    _recomputeVisibleEntriesIfNeeded();
  }

  @override
  void didUpdateWidget(covariant SyncfusionStepLineChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    _recomputeVisibleEntriesIfNeeded();
  }

  @override
  Widget build(BuildContext context) {
    final chartTheme = AppChartTheme.fromContext(
      context,
      preset: widget.preset,
    );
    final theme = Theme.of(context);
    final colors = theme.appColors;
    final typography = theme.appTypography;
    final resolvedHeight = widget.style.height ?? chartTheme.height;
    final gridLineColor = colors.outlineVariant.withValues(alpha: 0.35);

    if (widget.isLoading) {
      final loadingLabel = AppLocalizations.of(context).chartLoadingGeneric;
      return SizedBox(
        height: resolvedHeight,
        child: Center(
          child: Semantics(
            container: true,
            liveRegion: true,
            label: loadingLabel,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                CircularProgressIndicator(color: chartTheme.primaryColor),
                const SizedBox(height: 12),
                Text(
                  loadingLabel,
                  style: typography.body.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    _recomputeVisibleEntriesIfNeeded();

    final allEmpty = _visibleEntries.every((entry) => entry.points.isEmpty);
    if (allEmpty) {
      return SizedBox(
        height: resolvedHeight,
        child: Center(
          child:
              widget.emptyPlaceholder ??
              Text(
                'Sem dados disponiveis para este periodo.',
                textAlign: TextAlign.center,
                style: typography.body.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
        ),
      );
    }

    final series = <CartesianSeries<AppChartPoint, String>>[];
    for (var i = 0; i < _visibleEntries.length; i++) {
      final entry = _visibleEntries[i];
      final seriesColor = entry.color ?? chartTheme.paletteColor(i);
      series.add(
        StepLineSeries<AppChartPoint, String>(
          dataSource: entry.points,
          xValueMapper: (point, _) => point.label,
          yValueMapper: (point, _) => point.value,
          name: entry.label,
          color: seriesColor,
          width: widget.style.lineWidth ?? 2.5,
          animationDuration: resolveChartAnimationDurationMs(
            context: context,
            styleDuration: widget.style.animationDuration,
            defaultMs: AppChartEngineAnimationDefaults.cartesianSeriesMs,
          ),
          markerSettings: MarkerSettings(
            isVisible: widget.style.showMarkers,
            height: widget.style.markerSize ?? 7,
            width: widget.style.markerSize ?? 7,
            color: seriesColor,
            borderColor: colors.surface,
          ),
          dataLabelSettings: DataLabelSettings(
            isVisible: widget.style.showDataLabels,
          ),
          onPointTap: widget.onPointTap == null
              ? null
              : (details) {
                  final pointIndex = details.pointIndex;
                  if (pointIndex != null &&
                      pointIndex >= 0 &&
                      pointIndex < entry.points.length) {
                    widget.onPointTap!(
                      entry,
                      entry.points[pointIndex],
                      pointIndex,
                      i,
                    );
                  }
                },
        ),
      );
    }

    return SizedBox(
      height: resolvedHeight,
      child: SfCartesianChart(
        margin: widget.style.chartPadding ?? EdgeInsets.zero,
        plotAreaBorderWidth: 0,
        onTooltipRender: buildSanitizingTooltipRenderer(),
        tooltipBehavior: buildChartTooltipBehavior(
          context,
          enable: widget.style.showTooltip,
          shared: widget.isMultiSeries,
        ),
        trackballBehavior: widget.style.showTrackball
            ? TrackballBehavior(
                enable: true,
                activationMode: ActivationMode.singleTap,
                tooltipSettings: const InteractiveTooltip(
                  format: 'point.x : point.y',
                ),
              )
            : null,
        legend: Legend(
          isVisible: widget.isMultiSeries && widget.style.showLegend,
          position: LegendPosition.bottom,
          overflowMode: LegendItemOverflowMode.wrap,
        ),
        zoomPanBehavior: ZoomPanBehavior(
          enablePinching: chartTheme.enableSelectionZooming,
          enablePanning: chartTheme.enableSelectionZooming,
          enableSelectionZooming: chartTheme.enableSelectionZooming,
        ),
        primaryXAxis: const CategoryAxis(
          majorGridLines: MajorGridLines(width: 0),
        ),
        primaryYAxis: NumericAxis(
          axisLine: const AxisLine(width: 0),
          majorGridLines: MajorGridLines(
            color: gridLineColor,
            width: widget.style.showYGridLines ? 1 : 0,
          ),
          numberFormat:
              widget.style.yAxisFormat ??
              AppChartFormatters.compactCurrencyFormat,
          axisLabelFormatter: widget.style.yAxisFormat == null
              ? null
              : (details) => ChartAxisLabel(
                  widget.style.yAxisFormat!.format(details.value),
                  details.textStyle,
                ),
        ),
        series: series,
      ),
    );
  }

  bool _hasRenderableValue(AppChartPoint point) {
    return point.value.toDouble().isFinite;
  }
}

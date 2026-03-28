import 'package:colmeia/shared/widgets/charts/app_chart_models.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_shell.dart';
import 'package:colmeia/shared/widgets/charts/engines/syncfusion_area_trend_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppAreaTrendChartStyle {
  const AppAreaTrendChartStyle({
    this.height,
    this.lineWidth,
    this.yAxisFormat,
    this.chartPadding,
    this.showTooltip = true,
    this.showYGridLines = true,
    this.showGradientFill = true,
    this.showMarkers = false,
    this.showTrackball = false,
    this.markerSize,
    this.animationDuration,
  });

  final double? height;
  final double? lineWidth;

  /// [NumberFormat] applied to Y-axis tick labels.
  final NumberFormat? yAxisFormat;

  final EdgeInsets? chartPadding;
  final bool showTooltip;
  final bool showYGridLines;

  /// When true, the area under the line is filled with a gradient.
  final bool showGradientFill;

  /// When true, each data point shows a marker dot.
  final bool showMarkers;

  /// When true, enables Syncfusion's trackball — a crosshair that snaps to the
  /// nearest data point on touch/hover, showing all series values at once.
  /// Particularly useful for multi-series charts.
  final bool showTrackball;

  final double? markerSize;
  final Duration? animationDuration;
}

/// An entry in a multi-series [AppAreaTrendChart].
///
/// Each entry provides its own label (for the legend), a list of data points,
/// and an optional color override.
class AppAreaTrendEntry {
  const AppAreaTrendEntry({
    required this.label,
    required this.points,
    this.color,
  });

  final String label;
  final List<AppChartPoint> points;

  /// Optional color override. Falls back to the chart theme palette entry.
  final Color? color;
}

/// Area trend chart for visualizing one or more series over time with a
/// gradient-filled area under the curve.
///
/// **Single series** — provide [points]:
/// ```dart
/// AppAreaTrendChart(
///   title: 'Faturamento semanal',
///   points: _weekPoints,
///   style: AppAreaTrendChartStyle(
///     yAxisFormat: AppBrFormatters.compactCurrencyFormat,
///     showMarkers: true,
///   ),
/// )
/// ```
///
/// **Multi-series** — provide [entries] instead of [points]:
/// ```dart
/// AppAreaTrendChart(
///   title: 'Lojas comparadas',
///   entries: [
///     AppAreaTrendEntry(label: 'Centro', points: _centroPoints),
///     AppAreaTrendEntry(label: 'Norte',  points: _nortePoints),
///   ],
///   style: AppAreaTrendChartStyle(showTrackball: true),
/// )
/// ```
class AppAreaTrendChart extends StatelessWidget {
  const AppAreaTrendChart({
    super.key,
    this.points = const <AppChartPoint>[],
    this.entries,
    this.title,
    this.subtitle,
    this.titleTrailing,
    this.belowSubtitle,
    this.style = const AppAreaTrendChartStyle(),
    this.preset = AppChartPreset.explorable,
    this.isLoading = false,
    this.emptyPlaceholder,
  });

  /// Data for a single-series chart. Ignored when [entries] is provided.
  final List<AppChartPoint> points;

  /// Data for a multi-series chart. When set, overrides [points].
  final List<AppAreaTrendEntry>? entries;

  final String? title;
  final String? subtitle;
  final Widget? titleTrailing;
  final Widget? belowSubtitle;

  final AppAreaTrendChartStyle style;
  final AppChartPreset preset;
  final bool isLoading;
  final Widget? emptyPlaceholder;

  @override
  Widget build(BuildContext context) {
    final resolvedEntries =
        entries ??
        <AppAreaTrendEntry>[
          AppAreaTrendEntry(label: '', points: points),
        ];

    final innerChart = SyncfusionAreaTrendChart(
      entries: resolvedEntries,
      isMultiSeries: entries != null,
      style: style,
      preset: preset,
      isLoading: isLoading,
      emptyPlaceholder: emptyPlaceholder,
    );

    if (title == null) {
      return innerChart;
    }

    return AppChartShell(
      title: title!,
      subtitle: subtitle,
      titleTrailing: titleTrailing,
      belowSubtitle: belowSubtitle,
      child: innerChart,
    );
  }
}

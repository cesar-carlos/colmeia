import 'package:colmeia/shared/widgets/charts/app_chart_models.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_shell.dart';
import 'package:colmeia/shared/widgets/charts/engines/syncfusion_time_series_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppTimeSeriesChartStyle {
  const AppTimeSeriesChartStyle({
    this.height,
    this.yAxisFormat,
    this.lineWidth,
    this.showTooltip = true,
    this.showYGridLines = true,
    this.chartPadding,
  });

  final double? height;
  final NumberFormat? yAxisFormat;
  final double? lineWidth;
  final bool showTooltip;
  final bool showYGridLines;
  final EdgeInsets? chartPadding;
}

class AppTimeSeriesChart extends StatelessWidget {
  const AppTimeSeriesChart({
    required this.points,
    super.key,
    this.title,
    this.subtitle,
    this.titleTrailing,
    this.belowSubtitle,
    this.preset = AppChartPreset.explorable,
    this.style = const AppTimeSeriesChartStyle(),
    this.isLoading = false,
    this.emptyPlaceholder,
    this.onPointTap,
    this.onPointTapEvent,
  });

  final List<AppChartPoint> points;
  final String? title;
  final String? subtitle;
  final Widget? titleTrailing;
  final Widget? belowSubtitle;
  final AppChartPreset preset;
  final AppTimeSeriesChartStyle style;
  final bool isLoading;
  final Widget? emptyPlaceholder;

  /// Called when a data point is tapped.
  final ValueChanged<AppChartPoint>? onPointTap;

  /// Structured alternative to [onPointTap] with item and index.
  final ValueChanged<AppChartItemTapEvent<AppChartPoint>>? onPointTapEvent;

  @override
  Widget build(BuildContext context) {
    void handlePointTap(AppChartPoint point, int index) {
      onPointTap?.call(point);
      onPointTapEvent?.call(
        AppChartItemTapEvent<AppChartPoint>(
          item: point,
          index: index,
        ),
      );
    }

    final innerChart = SyncfusionTimeSeriesChart(
      points: points,
      preset: preset,
      style: style,
      isLoading: isLoading,
      emptyPlaceholder: emptyPlaceholder,
      onPointTap: (onPointTap == null && onPointTapEvent == null)
          ? null
          : handlePointTap,
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

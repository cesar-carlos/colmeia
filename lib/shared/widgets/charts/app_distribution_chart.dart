import 'package:colmeia/shared/widgets/charts/app_chart_models.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_shell.dart';
import 'package:colmeia/shared/widgets/charts/engines/syncfusion_distribution_chart.dart';
import 'package:flutter/material.dart';

class AppDistributionChartStyle {
  const AppDistributionChartStyle({
    this.height,
    this.showTooltip = true,
    this.showLegend = true,
    this.chartPadding,
  });

  final double? height;
  final bool showTooltip;
  final bool showLegend;
  final EdgeInsets? chartPadding;
}

class AppDistributionChart extends StatelessWidget {
  const AppDistributionChart({
    required this.points,
    super.key,
    this.title,
    this.subtitle,
    this.titleTrailing,
    this.belowSubtitle,
    this.preset = AppChartPreset.standard,
    this.style = const AppDistributionChartStyle(),
    this.isLoading = false,
    this.emptyPlaceholder,
    this.onSegmentTap,
    this.onSegmentTapEvent,
  });

  final List<AppChartPoint> points;
  final String? title;
  final String? subtitle;
  final Widget? titleTrailing;
  final Widget? belowSubtitle;
  final AppChartPreset preset;
  final AppDistributionChartStyle style;
  final bool isLoading;
  final Widget? emptyPlaceholder;

  /// Called when a pie/doughnut segment is tapped.
  final ValueChanged<AppChartPoint>? onSegmentTap;

  /// Structured alternative to [onSegmentTap] with segment index.
  final ValueChanged<AppChartItemTapEvent<AppChartPoint>>? onSegmentTapEvent;

  @override
  Widget build(BuildContext context) {
    void handleSegmentTap(AppChartPoint point, int index) {
      onSegmentTap?.call(point);
      onSegmentTapEvent?.call(AppChartItemTapEvent(item: point, index: index));
    }

    final innerChart = SyncfusionDistributionChart(
      points: points,
      preset: preset,
      style: style,
      isLoading: isLoading,
      emptyPlaceholder: emptyPlaceholder,
      onSegmentTap: (onSegmentTap == null && onSegmentTapEvent == null)
          ? null
          : handleSegmentTap,
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

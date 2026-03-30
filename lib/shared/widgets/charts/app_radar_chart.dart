import 'package:colmeia/shared/widgets/charts/app_chart_models.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_shell.dart';
import 'package:colmeia/shared/widgets/charts/engines/custom_radar_chart.dart';
import 'package:flutter/material.dart';

class AppRadarChartStyle {
  const AppRadarChartStyle({
    this.height,
    this.chartPadding,
    this.showLegend = true,
    this.showAxisLabels = true,
    this.showMarkers = true,
    this.gridDivisions = 4,
    this.maxValue,
    this.fillOpacity = 0.16,
    this.strokeWidth = 2,
    this.markerRadius = 4,
    this.axisLabelTextStyle,
    this.legendTextStyle,
  });

  final double? height;
  final EdgeInsets? chartPadding;
  final bool showLegend;
  final bool showAxisLabels;
  final bool showMarkers;
  final int gridDivisions;
  final num? maxValue;
  final double fillOpacity;
  final double strokeWidth;
  final double markerRadius;
  final TextStyle? axisLabelTextStyle;
  final TextStyle? legendTextStyle;
}

class AppRadarChartEntry {
  const AppRadarChartEntry({
    required this.label,
    required this.points,
    this.color,
  });

  final String label;
  final List<AppChartPoint> points;
  final Color? color;
}

class AppRadarChart extends StatelessWidget {
  const AppRadarChart({
    super.key,
    this.points = const <AppChartPoint>[],
    this.entries,
    this.title,
    this.subtitle,
    this.titleTrailing,
    this.belowSubtitle,
    this.style = const AppRadarChartStyle(),
    this.preset = AppChartPreset.standard,
    this.isLoading = false,
    this.emptyPlaceholder,
    this.onPointTap,
    this.onPointTapEvent,
  });

  final List<AppChartPoint> points;
  final List<AppRadarChartEntry>? entries;
  final String? title;
  final String? subtitle;
  final Widget? titleTrailing;
  final Widget? belowSubtitle;
  final AppRadarChartStyle style;
  final AppChartPreset preset;
  final bool isLoading;
  final Widget? emptyPlaceholder;

  /// Called when a category axis vertex is tapped.
  /// category is the axis label; point is the matched data point from the
  /// first series that contains the category (null if not found).
  final void Function(String category, AppChartPoint? point)? onPointTap;
  final ValueChanged<AppChartCategoryPointTapEvent<AppRadarChartEntry>>?
  onPointTapEvent;

  @override
  Widget build(BuildContext context) {
    final resolvedEntries =
        entries ??
        <AppRadarChartEntry>[
          AppRadarChartEntry(label: '', points: points),
        ];
    final categories = _resolveCategories(resolvedEntries);

    void handlePointTap(String category, AppChartPoint? _) {
      final categoryIndex = categories.indexOf(category);
      AppRadarChartEntry? matchedEntry;
      AppChartPoint? matchedPoint;
      int? matchedEntryIndex;

      for (final entry in resolvedEntries.indexed) {
        for (final point in entry.$2.points) {
          if (point.label == category) {
            matchedEntry = entry.$2;
            matchedPoint = point;
            matchedEntryIndex = entry.$1;
            break;
          }
        }
        if (matchedPoint != null) {
          break;
        }
      }

      onPointTap?.call(category, matchedPoint);
      onPointTapEvent?.call(
        AppChartCategoryPointTapEvent<AppRadarChartEntry>(
          category: category,
          categoryIndex: categoryIndex,
          point: matchedPoint,
          entry: matchedEntry,
          entryIndex: matchedEntryIndex,
        ),
      );
    }

    final innerChart = CustomRadarChart(
      entries: resolvedEntries,
      isMultiSeries: entries != null,
      style: style,
      preset: preset,
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

  static List<String> _resolveCategories(List<AppRadarChartEntry> entries) {
    final labels = <String>[];
    for (final entry in entries) {
      for (final point in entry.points) {
        if (!labels.contains(point.label)) {
          labels.add(point.label);
        }
      }
    }
    return labels;
  }
}

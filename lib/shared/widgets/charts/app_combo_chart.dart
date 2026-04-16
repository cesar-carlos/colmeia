import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_shell.dart';
import 'package:colmeia/shared/widgets/charts/engines/syncfusion_combo_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppComboChartStyle {
  const AppComboChartStyle({
    this.height,
    this.barWidth,
    this.barSpacing,
    this.lineWidth,
    this.chartPadding,
    this.animationDuration,
    this.leftAxisFormat,
    this.rightAxisFormat,
    this.showTooltip = true,
    this.showYGridLines = true,
    this.showXAxis = true,
    this.showRightYAxis = true,
    this.showLegend = true,
    this.showMarkers = true,
    this.axisLabelTextStyle,
    this.legendTextStyle,
    this.barColor,
    this.lineColor,
    this.showDataLabels = false,
    this.dataLabelTextStyle,
    this.enableAutoScroll = true,
    // Default matches AppThemeTokens.chartComboDefaultCategoryMinSlotWidth.
    this.minCategorySlotWidth = 80,
    this.showScrollFade = true,
    this.horizontalScrollSemanticsHint,
    this.stickyPrimaryYAxisWhileScrolling = true,
    this.stickyPrimaryYAxisWidth = 72,
  });

  final double? height;
  final double? barWidth;
  final double? barSpacing;
  final double? lineWidth;
  final EdgeInsets? chartPadding;
  final Duration? animationDuration;

  /// [NumberFormat] for the left Y-axis (bar values).
  final NumberFormat? leftAxisFormat;

  /// [NumberFormat] for the right Y-axis (line values).
  final NumberFormat? rightAxisFormat;

  final bool showTooltip;
  final bool showYGridLines;
  final bool showXAxis;

  /// When false, hides the right Y-axis tick labels (line series scale). The
  /// line still uses that axis for scaling; tooltips keep full values.
  final bool showRightYAxis;

  final bool showLegend;

  /// Whether each line data point shows a marker dot.
  final bool showMarkers;

  final TextStyle? axisLabelTextStyle;
  final TextStyle? legendTextStyle;

  /// Optional bar color override. Falls back to the chart theme primary color.
  final Color? barColor;

  /// Optional line color override. Falls back to the chart theme secondary
  /// color.
  final Color? lineColor;

  final bool showDataLabels;
  final TextStyle? dataLabelTextStyle;

  /// When true, widens the plot (minimum [minCategorySlotWidth] per category)
  /// and wraps it in horizontal scroll if wider than the layout.
  final bool enableAutoScroll;

  /// Minimum logical width per category (bar slot) when [enableAutoScroll] is
  /// true. Higher values trigger horizontal scroll sooner on narrow layouts.
  final double minCategorySlotWidth;

  /// Trailing edge fade when horizontal scroll is active.
  final bool showScrollFade;

  /// Semantics hint when horizontal scroll is active (e.g. swipe to see more).
  final String? horizontalScrollSemanticsHint;

  /// When true and horizontal scroll is active, keeps the primary (left) Y-axis
  /// labels in a fixed column while the plot scrolls.
  final bool stickyPrimaryYAxisWhileScrolling;

  /// Width reserved for the sticky primary Y-axis column (tick labels).
  final double stickyPrimaryYAxisWidth;
}

enum AppComboChartSeriesType {
  bar,
  line,
}

class AppComboChartPointTapEvent<T> {
  const AppComboChartPointTapEvent({
    required this.item,
    required this.index,
    required this.seriesType,
    required this.value,
  });

  final T item;
  final int index;
  final AppComboChartSeriesType seriesType;
  final num value;
}

/// Mixed bar + line chart for scenarios where two metrics share the same
/// X-axis but have different scales or visual emphasis.
///
/// The bar series is plotted against the left Y-axis; the line series is
/// plotted against the right Y-axis. Both axes can be formatted independently.
///
/// Usage:
/// ```dart
/// AppComboChart<_DaySummary>(
///   title: 'Pedidos e ticket médio',
///   items: _daySummaries,
///   xLabelBuilder: (d) => d.label,
///   barValueBuilder: (d) => d.orders,
///   barSeriesLabel: 'Pedidos',
///   lineValueBuilder: (d) => d.avgTicket,
///   lineSeriesLabel: 'Ticket médio',
///   style: AppComboChartStyle(
///     rightAxisFormat: AppBrFormatters.compactCurrencyFormat,
///   ),
/// )
/// ```
class AppComboChart<T> extends StatelessWidget {
  const AppComboChart({
    required this.items,
    required this.xLabelBuilder,
    required this.barValueBuilder,
    required this.barSeriesLabel,
    required this.lineValueBuilder,
    required this.lineSeriesLabel,
    super.key,
    this.title,
    this.subtitle,
    this.titleTrailing,
    this.belowSubtitle,
    this.onBarTap,
    this.onLineTap,
    this.onBarTapEvent,
    this.onLineTapEvent,
    this.style = const AppComboChartStyle(),
    this.preset = AppChartPreset.standard,
    this.isLoading = false,
    this.emptyPlaceholder,
  });

  final List<T> items;
  final String Function(T item) xLabelBuilder;

  final num Function(T item) barValueBuilder;

  /// Legend label for the bar series.
  final String barSeriesLabel;

  final num Function(T item) lineValueBuilder;

  /// Legend label for the line series.
  final String lineSeriesLabel;

  final String? title;
  final String? subtitle;
  final Widget? titleTrailing;
  final Widget? belowSubtitle;

  /// Called when the user taps a bar data point.
  final void Function(T item, int index)? onBarTap;

  /// Called when the user taps a line data point.
  final void Function(T item, int index)? onLineTap;

  final ValueChanged<AppComboChartPointTapEvent<T>>? onBarTapEvent;

  final ValueChanged<AppComboChartPointTapEvent<T>>? onLineTapEvent;

  final AppComboChartStyle style;
  final AppChartPreset preset;
  final bool isLoading;
  final Widget? emptyPlaceholder;

  @override
  Widget build(BuildContext context) {
    void handleBarTap(T item, int index) {
      onBarTap?.call(item, index);
      onBarTapEvent?.call(
        AppComboChartPointTapEvent(
          item: item,
          index: index,
          seriesType: AppComboChartSeriesType.bar,
          value: barValueBuilder(item),
        ),
      );
    }

    void handleLineTap(T item, int index) {
      onLineTap?.call(item, index);
      onLineTapEvent?.call(
        AppComboChartPointTapEvent(
          item: item,
          index: index,
          seriesType: AppComboChartSeriesType.line,
          value: lineValueBuilder(item),
        ),
      );
    }

    final innerChart = SyncfusionComboChart<T>(
      items: items,
      xLabelBuilder: xLabelBuilder,
      barValueBuilder: barValueBuilder,
      barSeriesLabel: barSeriesLabel,
      lineValueBuilder: lineValueBuilder,
      lineSeriesLabel: lineSeriesLabel,
      style: style,
      preset: preset,
      onBarTap: (onBarTap == null && onBarTapEvent == null)
          ? null
          : handleBarTap,
      onLineTap: (onLineTap == null && onLineTapEvent == null)
          ? null
          : handleLineTap,
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

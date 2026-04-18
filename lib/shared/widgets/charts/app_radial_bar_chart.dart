import 'package:colmeia/shared/widgets/charts/app_chart_models.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_shell.dart';
import 'package:colmeia/shared/widgets/charts/engines/syncfusion_radial_bar_chart.dart';
import 'package:flutter/material.dart';

class AppRadialBarChartStyle {
  const AppRadialBarChartStyle({
    this.height,
    this.chartPadding,
    this.showTooltip = true,
    this.showLegend = false,
    this.showDataLabels = false,
    this.maximumValue,
    this.trackColor,
    this.trackOpacity = 0.14,
    this.dataLabelTextStyle,
    this.enableTapHighlight = false,
    this.tapHighlightDimmedOpacity = 0.35,
  });

  final double? height;
  final EdgeInsets? chartPadding;
  final bool showTooltip;
  final bool showLegend;
  final bool showDataLabels;
  final double? maximumValue;
  final Color? trackColor;
  final double trackOpacity;
  final TextStyle? dataLabelTextStyle;

  /// When true, tapping a ring highlights it (Syncfusion `SelectionBehavior`):
  /// the tapped segment keeps full opacity while the others fade to
  /// [tapHighlightDimmedOpacity]. Independent from `onSegmentTap` callbacks.
  final bool enableTapHighlight;

  /// Opacity applied to non-selected rings while [enableTapHighlight] is
  /// active. Defaults to `0.35`; set to `1.0` to disable the dim.
  final double tapHighlightDimmedOpacity;
}

class AppRadialBarChart<T> extends StatelessWidget {
  const AppRadialBarChart({
    required this.items,
    required this.labelBuilder,
    required this.valueBuilder,
    super.key,
    this.title,
    this.subtitle,
    this.titleTrailing,
    this.belowSubtitle,
    this.colorBuilder,
    this.dataLabelBuilder,
    this.tooltipLabelBuilder,
    this.onSegmentTap,
    this.onSegmentTapEvent,
    this.style = const AppRadialBarChartStyle(),
    this.preset = AppChartPreset.standard,
    this.isLoading = false,
    this.emptyPlaceholder,
  });

  final List<T> items;
  final String Function(T item) labelBuilder;
  final num Function(T item) valueBuilder;
  final Color? Function(T item)? colorBuilder;
  final String? Function(T item, num value)? dataLabelBuilder;
  final String? Function(T item, num value)? tooltipLabelBuilder;
  final void Function(T item, int index)? onSegmentTap;

  /// Structured alternative to [onSegmentTap] — carries item and index
  /// in a single typed payload.
  final ValueChanged<AppChartItemTapEvent<T>>? onSegmentTapEvent;

  final String? title;
  final String? subtitle;
  final Widget? titleTrailing;
  final Widget? belowSubtitle;
  final AppRadialBarChartStyle style;
  final AppChartPreset preset;
  final bool isLoading;
  final Widget? emptyPlaceholder;

  @override
  Widget build(BuildContext context) {
    void handleSegmentTap(T item, int index) {
      onSegmentTap?.call(item, index);
      onSegmentTapEvent?.call(AppChartItemTapEvent(item: item, index: index));
    }

    final innerChart = SyncfusionRadialBarChart<T>(
      items: items,
      labelBuilder: labelBuilder,
      valueBuilder: valueBuilder,
      colorBuilder: colorBuilder,
      dataLabelBuilder: dataLabelBuilder,
      tooltipLabelBuilder: tooltipLabelBuilder,
      onSegmentTap: (onSegmentTap == null && onSegmentTapEvent == null)
          ? null
          : handleSegmentTap,
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

import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_shell.dart';
import 'package:colmeia/shared/widgets/charts/engines/syncfusion_treemap_chart.dart';
import 'package:flutter/material.dart';

enum AppTreemapLayoutAlgorithm {
  squarified,
  slice,
  dice,
}

class AppTreemapColorRange {
  const AppTreemapColorRange({
    required this.from,
    required this.to,
    required this.color,
    this.name,
  });

  final num from;
  final num to;
  final Color color;
  final String? name;
}

class AppTreemapNode {
  const AppTreemapNode({
    required this.group,
    required this.weight,
    required this.indices,
  });

  final String group;
  final double weight;
  final List<int> indices;
}

class AppTreemapChartStyle {
  const AppTreemapChartStyle({
    this.height,
    this.chartPadding,
    this.layout = AppTreemapLayoutAlgorithm.squarified,
    this.sortAscending = false,
    this.showLegend = false,
    this.useBarLegend = false,
    this.showTooltip = true,
    this.showLabels = true,
    this.tileColor,
    this.labelTextStyle,
    this.legendTextStyle,
    this.tooltipTextStyle,
    this.borderColor,
    this.borderWidth = 1,
    this.borderRadius = 12,
    this.levelPadding = 2,
    this.selectionColor,
    this.selectionBorderColor,
    this.selectionBorderWidth = 2,
  });

  final double? height;
  final EdgeInsets? chartPadding;
  final AppTreemapLayoutAlgorithm layout;
  final bool sortAscending;
  final bool showLegend;
  final bool useBarLegend;
  final bool showTooltip;
  final bool showLabels;
  final Color? tileColor;
  final TextStyle? labelTextStyle;
  final TextStyle? legendTextStyle;
  final TextStyle? tooltipTextStyle;
  final Color? borderColor;
  final double borderWidth;
  final double borderRadius;
  final double levelPadding;
  final Color? selectionColor;
  final Color? selectionBorderColor;
  final double selectionBorderWidth;
}

class AppTreemapChart<T> extends StatelessWidget {
  const AppTreemapChart({
    required this.items,
    required this.groupBuilder,
    required this.weightValueBuilder,
    super.key,
    this.title,
    this.subtitle,
    this.titleTrailing,
    this.belowSubtitle,
    this.subgroupBuilder,
    this.colorValueBuilder,
    this.colorRanges,
    this.labelBuilder,
    this.tooltipLabelBuilder,
    this.onTileSelected,
    this.style = const AppTreemapChartStyle(),
    this.preset = AppChartPreset.standard,
    this.isLoading = false,
    this.emptyPlaceholder,
  });

  final List<T> items;
  final String Function(T item) groupBuilder;
  final double Function(T item) weightValueBuilder;
  final String Function(T item)? subgroupBuilder;
  final num Function(T item)? colorValueBuilder;
  final List<AppTreemapColorRange>? colorRanges;
  final String? Function(AppTreemapNode node)? labelBuilder;
  final String? Function(AppTreemapNode node)? tooltipLabelBuilder;
  final void Function(AppTreemapNode node)? onTileSelected;

  final String? title;
  final String? subtitle;
  final Widget? titleTrailing;
  final Widget? belowSubtitle;
  final AppTreemapChartStyle style;
  final AppChartPreset preset;
  final bool isLoading;
  final Widget? emptyPlaceholder;

  @override
  Widget build(BuildContext context) {
    final innerChart = SyncfusionTreemapChart<T>(
      items: items,
      groupBuilder: groupBuilder,
      weightValueBuilder: weightValueBuilder,
      subgroupBuilder: subgroupBuilder,
      colorValueBuilder: colorValueBuilder,
      colorRanges: colorRanges,
      labelBuilder: labelBuilder,
      tooltipLabelBuilder: tooltipLabelBuilder,
      onTileSelected: onTileSelected,
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

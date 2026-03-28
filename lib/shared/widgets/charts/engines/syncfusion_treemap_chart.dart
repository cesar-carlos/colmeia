import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_theme.dart';
import 'package:colmeia/shared/widgets/charts/app_treemap_chart.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_treemap/treemap.dart';

class SyncfusionTreemapChart<T> extends StatelessWidget {
  const SyncfusionTreemapChart({
    required this.items,
    required this.groupBuilder,
    required this.weightValueBuilder,
    required this.style,
    required this.preset,
    super.key,
    this.subgroupBuilder,
    this.colorValueBuilder,
    this.colorRanges,
    this.labelBuilder,
    this.tooltipLabelBuilder,
    this.onTileSelected,
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
  final AppTreemapChartStyle style;
  final AppChartPreset preset;
  final bool isLoading;
  final Widget? emptyPlaceholder;

  @override
  Widget build(BuildContext context) {
    final chartTheme = AppChartTheme.fromContext(context, preset: preset);
    final theme = Theme.of(context);
    final colors = theme.appColors;
    final resolvedHeight = style.height ?? chartTheme.height;

    if (isLoading) {
      return SizedBox(
        height: resolvedHeight,
        child: Center(
          child: CircularProgressIndicator(color: chartTheme.primaryColor),
        ),
      );
    }

    if (items.isEmpty && emptyPlaceholder != null) {
      return SizedBox(
        height: resolvedHeight,
        child: Center(child: emptyPlaceholder),
      );
    }

    final levels = <TreemapLevel>[
      TreemapLevel(
        color:
            style.tileColor ?? chartTheme.primaryColor.withValues(alpha: 0.9),
        padding: EdgeInsets.all(style.levelPadding),
        border: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(style.borderRadius),
          side: BorderSide(
            color: style.borderColor ?? colors.surface,
            width: style.borderWidth,
          ),
        ),
        groupMapper: (index) => groupBuilder(items[index]),
        colorValueMapper: colorValueBuilder == null
            ? null
            : (tile) => _aggregateColorValue(tile.indices),
        labelBuilder: !style.showLabels
            ? null
            : (context, tile) {
                final node = _nodeFromTile(tile);
                final label =
                    labelBuilder?.call(node) ??
                    '${node.group}\n${node.weight.toStringAsFixed(0)}';
                return Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    label,
                    style:
                        style.labelTextStyle ??
                        theme.textTheme.labelMedium?.copyWith(
                          color: colors.onPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                );
              },
        tooltipBuilder: !style.showTooltip
            ? null
            : (context, tile) {
                final node = _nodeFromTile(tile);
                final label =
                    tooltipLabelBuilder?.call(node) ??
                    '${node.group}: ${node.weight.toStringAsFixed(0)}';
                return DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.inverseSurface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(
                      label,
                      style:
                          style.tooltipTextStyle ??
                          theme.textTheme.bodySmall?.copyWith(
                            color: colors.inverseOnSurface,
                          ),
                    ),
                  ),
                );
              },
      ),
      if (subgroupBuilder != null)
        TreemapLevel(
          padding: EdgeInsets.all(style.levelPadding),
          border: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(style.borderRadius * 0.75),
            side: BorderSide(
              color: (style.borderColor ?? colors.surface).withValues(
                alpha: 0.8,
              ),
              width: style.borderWidth,
            ),
          ),
          groupMapper: (index) => subgroupBuilder!(items[index]),
          colorValueMapper: colorValueBuilder == null
              ? null
              : (tile) => _aggregateColorValue(tile.indices),
          labelBuilder: !style.showLabels
              ? null
              : (context, tile) {
                  final node = _nodeFromTile(tile);
                  final label =
                      labelBuilder?.call(node) ??
                      '${node.group}\n${node.weight.toStringAsFixed(0)}';
                  return Padding(
                    padding: const EdgeInsets.all(6),
                    child: Text(
                      label,
                      style:
                          style.labelTextStyle ??
                          theme.textTheme.labelSmall?.copyWith(
                            color: colors.onPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  );
                },
          tooltipBuilder: !style.showTooltip
              ? null
              : (context, tile) {
                  final node = _nodeFromTile(tile);
                  final label =
                      tooltipLabelBuilder?.call(node) ??
                      '${node.group}: ${node.weight.toStringAsFixed(0)}';
                  return DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.inverseSurface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Text(
                        label,
                        style:
                            style.tooltipTextStyle ??
                            theme.textTheme.bodySmall?.copyWith(
                              color: colors.inverseOnSurface,
                            ),
                      ),
                    ),
                  );
                },
        ),
    ];

    final selectionSettings = TreemapSelectionSettings(
      color:
          style.selectionColor ??
          chartTheme.primaryColor.withValues(alpha: 0.35),
      border: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(style.borderRadius),
        side: BorderSide(
          color: style.selectionBorderColor ?? chartTheme.primaryColor,
          width: style.selectionBorderWidth,
        ),
      ),
    );

    final treemap = switch (style.layout) {
      AppTreemapLayoutAlgorithm.squarified => SfTreemap(
        dataCount: items.length,
        levels: levels,
        weightValueMapper: (index) => weightValueBuilder(items[index]),
        colorMappers: _buildColorMappers(),
        legend: _buildLegend(),
        onSelectionChanged: onTileSelected == null
            ? null
            : (tile) => onTileSelected!(_nodeFromTile(tile)),
        selectionSettings: selectionSettings,
      ),
      AppTreemapLayoutAlgorithm.slice => SfTreemap.slice(
        dataCount: items.length,
        levels: levels,
        sortAscending: style.sortAscending,
        weightValueMapper: (index) => weightValueBuilder(items[index]),
        colorMappers: _buildColorMappers(),
        legend: _buildLegend(),
        onSelectionChanged: onTileSelected == null
            ? null
            : (tile) => onTileSelected!(_nodeFromTile(tile)),
        selectionSettings: selectionSettings,
      ),
      AppTreemapLayoutAlgorithm.dice => SfTreemap.dice(
        dataCount: items.length,
        levels: levels,
        sortAscending: style.sortAscending,
        weightValueMapper: (index) => weightValueBuilder(items[index]),
        colorMappers: _buildColorMappers(),
        legend: _buildLegend(),
        onSelectionChanged: onTileSelected == null
            ? null
            : (tile) => onTileSelected!(_nodeFromTile(tile)),
        selectionSettings: selectionSettings,
      ),
    };

    return SizedBox(
      height: resolvedHeight,
      child: Padding(
        padding: style.chartPadding ?? EdgeInsets.zero,
        child: treemap,
      ),
    );
  }

  double _aggregateColorValue(List<int> indices) {
    if (indices.isEmpty || colorValueBuilder == null) {
      return 0;
    }

    var total = 0.0;
    for (final index in indices) {
      total += colorValueBuilder!(items[index]).toDouble();
    }
    return total / indices.length;
  }

  List<TreemapColorMapper>? _buildColorMappers() {
    final ranges = colorRanges;
    if (ranges == null || ranges.isEmpty) {
      return null;
    }

    return ranges
        .map(
          (range) => TreemapColorMapper.range(
            from: range.from.toDouble(),
            to: range.to.toDouble(),
            color: range.color,
            name: range.name,
          ),
        )
        .toList();
  }

  TreemapLegend? _buildLegend() {
    if (!style.showLegend) {
      return null;
    }

    return style.useBarLegend
        ? TreemapLegend.bar(
            position: TreemapLegendPosition.bottom,
            textStyle: style.legendTextStyle,
          )
        : TreemapLegend(
            position: TreemapLegendPosition.bottom,
            textStyle: style.legendTextStyle,
          );
  }

  AppTreemapNode _nodeFromTile(TreemapTile tile) {
    return AppTreemapNode(
      group: tile.group,
      weight: tile.weight,
      indices: List<int>.from(tile.indices),
    );
  }
}

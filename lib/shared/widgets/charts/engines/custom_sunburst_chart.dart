import 'dart:math' as math;

import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_theme.dart';
import 'package:colmeia/shared/widgets/charts/app_sunburst_chart.dart';
import 'package:flutter/material.dart';

class CustomSunburstChart<T> extends StatelessWidget {
  const CustomSunburstChart({
    required this.items,
    required this.idBuilder,
    required this.labelBuilder,
    required this.valueBuilder,
    required this.parentIdBuilder,
    required this.style,
    required this.preset,
    super.key,
    this.colorBuilder,
    this.centerLabel,
    this.onSegmentTap,
    this.isLoading = false,
    this.emptyPlaceholder,
  });

  final List<T> items;
  final String Function(T item) idBuilder;
  final String Function(T item) labelBuilder;
  final num Function(T item) valueBuilder;
  final String? Function(T item) parentIdBuilder;
  final Color? Function(T item)? colorBuilder;
  final String? centerLabel;
  final void Function(AppSunburstNode<T> node)? onSegmentTap;
  final AppSunburstChartStyle style;
  final AppChartPreset preset;
  final bool isLoading;
  final Widget? emptyPlaceholder;

  @override
  Widget build(BuildContext context) {
    final chartTheme = AppChartTheme.fromContext(context, preset: preset);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final resolvedHeight = style.height ?? chartTheme.height;

    if (isLoading) {
      return SizedBox(
        height: resolvedHeight,
        child: Center(
          child: CircularProgressIndicator(color: chartTheme.primaryColor),
        ),
      );
    }

    final tree = _SunburstTree<T>.fromItems(
      items: items,
      idBuilder: idBuilder,
      labelBuilder: labelBuilder,
      valueBuilder: valueBuilder,
      parentIdBuilder: parentIdBuilder,
      colorBuilder: colorBuilder,
      chartTheme: chartTheme,
    );

    if (tree.roots.isEmpty && emptyPlaceholder != null) {
      return SizedBox(
        height: resolvedHeight,
        child: Center(child: emptyPlaceholder),
      );
    }

    return SizedBox(
      height: resolvedHeight,
      child: Padding(
        padding: style.chartPadding ?? EdgeInsets.zero,
        child: Column(
          children: <Widget>[
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final layout = _SunburstLayout<T>.fromTree(
                    tree: tree,
                    size: constraints.biggest,
                    style: style,
                  );

                  return Stack(
                    children: <Widget>[
                      Positioned.fill(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTapUp: onSegmentTap == null
                              ? null
                              : (details) {
                                  final hit = layout.hitTest(
                                    details.localPosition,
                                  );
                                  if (hit != null) {
                                    onSegmentTap!(hit.node);
                                  }
                                },
                          child: CustomPaint(
                            painter: _SunburstPainter<T>(
                              layout: layout,
                              style: style,
                              labelTextStyle:
                                  style.labelTextStyle ??
                                  theme.textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                              borderColor:
                                  style.borderColor ??
                                  colorScheme.surfaceContainerHighest,
                            ),
                          ),
                        ),
                      ),
                      if (style.showCenterSummary)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: Center(
                              child: _SunburstCenterLabel(
                                diameter: layout.innerRadius * 2,
                                valueLabel: _formatCompactNumber(
                                  tree.totalValue,
                                ),
                                label:
                                    centerLabel ??
                                    '${tree.roots.length} grupos',
                                valueTextStyle:
                                    style.centerValueTextStyle ??
                                    theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                                labelTextStyle:
                                    style.centerLabelTextStyle ??
                                    theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            if (style.showLegend && tree.roots.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: tree.roots
                      .map(
                        (root) => _SunburstLegendItem(
                          color: root.publicNode.color,
                          label: root.publicNode.label,
                          textStyle:
                              style.legendTextStyle ??
                              theme.textTheme.labelMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                        ),
                      )
                      .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SunburstCenterLabel extends StatelessWidget {
  const _SunburstCenterLabel({
    required this.diameter,
    required this.valueLabel,
    required this.label,
    this.valueTextStyle,
    this.labelTextStyle,
  });

  final double diameter;
  final String valueLabel;
  final String label;
  final TextStyle? valueTextStyle;
  final TextStyle? labelTextStyle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: diameter,
      height: diameter,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              valueLabel,
              style: valueTextStyle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: labelTextStyle,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SunburstLegendItem extends StatelessWidget {
  const _SunburstLegendItem({
    required this.color,
    required this.label,
    this.textStyle,
  });

  final Color color;
  final String label;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: textStyle),
      ],
    );
  }
}

class _SunburstTree<T> {
  const _SunburstTree({
    required this.roots,
    required this.maxDepth,
    required this.totalValue,
  });

  factory _SunburstTree.fromItems({
    required List<T> items,
    required String Function(T item) idBuilder,
    required String Function(T item) labelBuilder,
    required num Function(T item) valueBuilder,
    required String? Function(T item) parentIdBuilder,
    required Color? Function(T item)? colorBuilder,
    required AppChartTheme chartTheme,
  }) {
    final nodesById = <String, _TreeNode<T>>{};
    final roots = <_TreeNode<T>>[];

    for (final item in items) {
      final id = idBuilder(item).trim();
      if (id.isEmpty || nodesById.containsKey(id)) {
        continue;
      }

      nodesById[id] = _TreeNode<T>(
        id: id,
        item: item,
        label: labelBuilder(item),
        parentId: parentIdBuilder(item)?.trim(),
        ownValue: math.max(valueBuilder(item).toDouble(), 0),
        explicitColor: colorBuilder?.call(item),
      );
    }

    for (final node in nodesById.values) {
      final parentId = node.parentId;
      final parent = parentId == null || parentId.isEmpty
          ? null
          : nodesById[parentId];
      if (parent == null || identical(parent, node)) {
        roots.add(node);
      } else {
        parent.children.add(node);
      }
    }

    for (final root in roots) {
      root.sortChildren();
    }

    roots.sort(
      (a, b) => b.previewValue.compareTo(a.previewValue),
    );

    for (final (index, root) in roots.indexed) {
      _assignColors(
        root,
        baseColor: root.explicitColor ?? chartTheme.paletteColor(index),
      );
      _computeTotals(root, depth: 0);
    }

    final maxDepth = roots.fold<int>(
      0,
      (current, root) => math.max(current, root.maxDepth),
    );
    final totalValue = roots.fold<double>(
      0,
      (current, root) => current + root.totalValue,
    );

    return _SunburstTree<T>(
      roots: roots.where((root) => root.totalValue > 0).toList(),
      maxDepth: maxDepth,
      totalValue: math.max(totalValue, 0),
    );
  }

  final List<_TreeNode<T>> roots;
  final int maxDepth;
  final double totalValue;

  static void _assignColors<T>(
    _TreeNode<T> node, {
    required Color baseColor,
  }) {
    node.resolvedColor = node.explicitColor ?? baseColor;
    for (final child in node.children) {
      final alpha = math.max(0.35, 0.88 - (child.depthPreview * 0.12));
      _assignColors<T>(
        child,
        baseColor: child.explicitColor ?? baseColor.withValues(alpha: alpha),
      );
    }
  }

  static double _computeTotals<T>(_TreeNode<T> node, {required int depth}) {
    var childrenTotal = 0.0;
    node.maxDepth = depth;
    for (final child in node.children) {
      child.depthPreview = depth + 1;
      childrenTotal += _computeTotals(child, depth: depth + 1);
      node.maxDepth = math.max(node.maxDepth, child.maxDepth);
    }

    node
      ..totalValue = childrenTotal > 0 ? childrenTotal : node.ownValue
      ..publicNode = AppSunburstNode<T>(
        id: node.id,
        item: node.item,
        label: node.label,
        value: node.ownValue,
        totalValue: node.totalValue,
        depth: depth,
        childrenCount: node.children.length,
        color: node.resolvedColor!,
        parentId: node.parentId,
      );
    return node.totalValue;
  }
}

class _TreeNode<T> {
  _TreeNode({
    required this.id,
    required this.item,
    required this.label,
    required this.parentId,
    required this.ownValue,
    this.explicitColor,
  });

  final String id;
  final T item;
  final String label;
  final String? parentId;
  final double ownValue;
  final Color? explicitColor;
  final List<_TreeNode<T>> children = <_TreeNode<T>>[];

  late AppSunburstNode<T> publicNode;
  Color? resolvedColor;
  double totalValue = 0;
  int maxDepth = 0;
  int depthPreview = 0;

  double get previewValue {
    if (children.isEmpty) {
      return ownValue;
    }

    return children.fold<double>(
      0,
      (total, child) => total + child.previewValue,
    );
  }

  void sortChildren() {
    children.sort((a, b) => b.previewValue.compareTo(a.previewValue));
    for (final child in children) {
      child
        ..depthPreview = depthPreview + 1
        ..sortChildren();
    }
  }
}

class _SunburstLayout<T> {
  const _SunburstLayout({
    required this.segments,
    required this.center,
    required this.innerRadius,
  });

  factory _SunburstLayout.fromTree({
    required _SunburstTree<T> tree,
    required Size size,
    required AppSunburstChartStyle style,
  }) {
    final safeWidth = math.max(size.width, 1);
    final safeHeight = math.max(size.height, 1);
    final radius = (math.min(safeWidth, safeHeight) / 2) - 8;
    final center = Offset(safeWidth / 2, safeHeight / 2);
    final innerRadius = radius * style.innerRadiusFactor;
    final ringCount = math.max(tree.maxDepth + 1, 1);
    final gapBudget = style.ringGap * math.max(ringCount - 1, 0);
    final availableRadius = math.max(radius - innerRadius - gapBudget, 1);
    final ringWidth = availableRadius / ringCount;
    final segments = <_SunburstSegment<T>>[];

    if (tree.totalValue > 0) {
      _appendSegments(
        nodes: tree.roots,
        totalValue: tree.totalValue,
        startAngle: -math.pi / 2,
        sweepAngle: math.pi * 2,
        innerRadius: innerRadius,
        ringWidth: ringWidth,
        ringGap: style.ringGap,
        segmentSpacing: style.segmentSpacing,
        segments: segments,
      );
    }

    return _SunburstLayout<T>(
      segments: segments,
      center: center,
      innerRadius: innerRadius,
    );
  }

  final List<_SunburstSegment<T>> segments;
  final Offset center;
  final double innerRadius;

  _SunburstSegment<T>? hitTest(Offset position) {
    for (final segment in segments.reversed) {
      if (segment.contains(position, center)) {
        return segment;
      }
    }

    return null;
  }

  static void _appendSegments<T>({
    required List<_TreeNode<T>> nodes,
    required double totalValue,
    required double startAngle,
    required double sweepAngle,
    required double innerRadius,
    required double ringWidth,
    required double ringGap,
    required double segmentSpacing,
    required List<_SunburstSegment<T>> segments,
  }) {
    if (nodes.isEmpty || totalValue <= 0) {
      return;
    }

    var cursor = startAngle;
    for (final node in nodes) {
      if (node.totalValue <= 0) {
        continue;
      }

      final share = node.totalValue / totalValue;
      final rawSweep = sweepAngle * share;
      final outerRadius = innerRadius + ringWidth;
      final gapAngle = outerRadius <= 0 ? 0.0 : segmentSpacing / outerRadius;
      final adjustedSweep = math.max(rawSweep - gapAngle, 0).toDouble();
      final adjustedStart = cursor + (gapAngle / 2);

      final segment = _SunburstSegment<T>(
        node: node.publicNode,
        startAngle: adjustedStart,
        sweepAngle: adjustedSweep,
        innerRadius: innerRadius,
        outerRadius: outerRadius,
      );
      segments.add(segment);

      if (node.children.isNotEmpty) {
        _appendSegments(
          nodes: node.children,
          totalValue: node.totalValue,
          startAngle: adjustedStart,
          sweepAngle: adjustedSweep,
          innerRadius: outerRadius + ringGap,
          ringWidth: ringWidth,
          ringGap: ringGap,
          segmentSpacing: segmentSpacing,
          segments: segments,
        );
      }

      cursor += rawSweep;
    }
  }
}

class _SunburstSegment<T> {
  const _SunburstSegment({
    required this.node,
    required this.startAngle,
    required this.sweepAngle,
    required this.innerRadius,
    required this.outerRadius,
  });

  final AppSunburstNode<T> node;
  final double startAngle;
  final double sweepAngle;
  final double innerRadius;
  final double outerRadius;

  double get midAngle => startAngle + (sweepAngle / 2);

  bool contains(Offset position, Offset center) {
    final dx = position.dx - center.dx;
    final dy = position.dy - center.dy;
    final distance = math.sqrt((dx * dx) + (dy * dy));
    if (distance < innerRadius || distance > outerRadius) {
      return false;
    }

    final angle = _normalizeAngle(math.atan2(dy, dx));
    final normalizedStart = _normalizeAngle(startAngle);
    final normalizedEnd = _normalizeAngle(startAngle + sweepAngle);

    if (normalizedStart <= normalizedEnd) {
      return angle >= normalizedStart && angle <= normalizedEnd;
    }

    return angle >= normalizedStart || angle <= normalizedEnd;
  }

  static double _normalizeAngle(double angle) {
    const fullTurn = math.pi * 2;
    var normalized = angle % fullTurn;
    if (normalized < 0) {
      normalized += fullTurn;
    }
    return normalized;
  }
}

class _SunburstPainter<T> extends CustomPainter {
  const _SunburstPainter({
    required this.layout,
    required this.style,
    required this.labelTextStyle,
    required this.borderColor,
  });

  final _SunburstLayout<T> layout;
  final AppSunburstChartStyle style;
  final TextStyle? labelTextStyle;
  final Color borderColor;

  @override
  void paint(Canvas canvas, Size size) {
    for (final segment in layout.segments) {
      final path = _segmentPath(segment, layout.center);
      final fillPaint = Paint()
        ..color = segment.node.color
        ..style = PaintingStyle.fill;
      final strokePaint = Paint()
        ..color = borderColor
        ..strokeWidth = style.borderWidth
        ..style = PaintingStyle.stroke;

      canvas
        ..drawPath(path, fillPaint)
        ..drawPath(path, strokePaint);

      if (style.showLabels && segment.sweepAngle >= style.minLabelSweepAngle) {
        _paintLabel(canvas, segment);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SunburstPainter<T> oldDelegate) {
    return oldDelegate.layout != layout || oldDelegate.style != style;
  }

  Path _segmentPath(_SunburstSegment<T> segment, Offset center) {
    final rectOuter = Rect.fromCircle(
      center: center,
      radius: segment.outerRadius,
    );
    final rectInner = Rect.fromCircle(
      center: center,
      radius: segment.innerRadius,
    );

    return Path()
      ..arcTo(rectOuter, segment.startAngle, segment.sweepAngle, false)
      ..lineTo(
        center.dx +
            (math.cos(segment.startAngle + segment.sweepAngle) *
                segment.innerRadius),
        center.dy +
            (math.sin(segment.startAngle + segment.sweepAngle) *
                segment.innerRadius),
      )
      ..arcTo(
        rectInner,
        segment.startAngle + segment.sweepAngle,
        -segment.sweepAngle,
        false,
      )
      ..close();
  }

  void _paintLabel(Canvas canvas, _SunburstSegment<T> segment) {
    final textPainter =
        TextPainter(
          text: TextSpan(text: segment.node.label, style: labelTextStyle),
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
          maxLines: 2,
          ellipsis: '...',
        )..layout(
          maxWidth: math.max(segment.outerRadius - segment.innerRadius, 40),
        );

    final labelRadius = (segment.innerRadius + segment.outerRadius) / 2;
    final labelCenter = Offset(
      layout.center.dx + (math.cos(segment.midAngle) * labelRadius),
      layout.center.dy + (math.sin(segment.midAngle) * labelRadius),
    );
    final offset = Offset(
      labelCenter.dx - (textPainter.width / 2),
      labelCenter.dy - (textPainter.height / 2),
    );

    textPainter.paint(canvas, offset);
  }
}

String _formatCompactNumber(double value) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1)}M';
  }
  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(1)}k';
  }
  if (value == value.roundToDouble()) {
    return value.toStringAsFixed(0);
  }
  return value.toStringAsFixed(1);
}

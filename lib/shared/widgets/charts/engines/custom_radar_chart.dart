import 'dart:math' as math;

import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_models.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_theme.dart';
import 'package:colmeia/shared/widgets/charts/app_radar_chart.dart';
import 'package:flutter/material.dart';

class CustomRadarChart extends StatelessWidget {
  const CustomRadarChart({
    required this.entries,
    required this.isMultiSeries,
    required this.style,
    required this.preset,
    super.key,
    this.isLoading = false,
    this.emptyPlaceholder,
  });

  final List<AppRadarChartEntry> entries;
  final bool isMultiSeries;
  final AppRadarChartStyle style;
  final AppChartPreset preset;
  final bool isLoading;
  final Widget? emptyPlaceholder;

  @override
  Widget build(BuildContext context) {
    final chartTheme = AppChartTheme.fromContext(context, preset: preset);
    final resolvedHeight = style.height ?? chartTheme.height;
    final allEmpty = entries.every((entry) => entry.points.isEmpty);

    if (isLoading) {
      return SizedBox(
        height: resolvedHeight,
        child: Center(
          child: CircularProgressIndicator(color: chartTheme.primaryColor),
        ),
      );
    }

    if (allEmpty && emptyPlaceholder != null) {
      return SizedBox(
        height: resolvedHeight,
        child: Center(child: emptyPlaceholder),
      );
    }

    final categories = _resolveCategories(entries);
    if (categories.isEmpty) {
      return SizedBox(
        height: resolvedHeight,
        child: Center(child: emptyPlaceholder ?? const SizedBox.shrink()),
      );
    }

    final showLegend = isMultiSeries && style.showLegend;

    return SizedBox(
      height: resolvedHeight,
      child: Column(
        children: <Widget>[
          Expanded(
            child: Padding(
              padding: style.chartPadding ?? const EdgeInsets.all(12),
              child: CustomPaint(
                painter: _RadarChartPainter(
                  entries: entries,
                  categories: categories,
                  style: style,
                  textDirection: Directionality.of(context),
                  colors: Theme.of(context).appColors,
                  palette: chartTheme.palette,
                ),
                child: const SizedBox.expand(),
              ),
            ),
          ),
          if (showLegend)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 16,
                runSpacing: 8,
                children: <Widget>[
                  for (var i = 0; i < entries.length; i++)
                    _LegendItem(
                      color: entries[i].color ?? chartTheme.paletteColor(i),
                      label: entries[i].label,
                      textStyle: style.legendTextStyle,
                    ),
                ],
              ),
            ),
        ],
      ),
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

class _LegendItem extends StatelessWidget {
  const _LegendItem({
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
        const SizedBox(width: 8),
        Text(label, style: textStyle ?? Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _RadarChartPainter extends CustomPainter {
  const _RadarChartPainter({
    required this.entries,
    required this.categories,
    required this.style,
    required this.textDirection,
    required this.colors,
    required this.palette,
  });

  final List<AppRadarChartEntry> entries;
  final List<String> categories;
  final AppRadarChartStyle style;
  final TextDirection textDirection;
  final AppColors colors;
  final List<Color> palette;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final labelInset = style.showAxisLabels ? 26 : 10;
    final radius = math
        .max(0, math.min(size.width, size.height) / 2 - labelInset.toDouble())
        .toDouble();

    if (radius <= 0 || categories.length < 3) {
      return;
    }

    final gridPaint = Paint()
      ..color = colors.outlineVariant.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final spokePaint = Paint()
      ..color = colors.outlineVariant.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final maxValue = _resolveMaxValue(entries, style.maxValue);

    for (var level = 1; level <= style.gridDivisions; level++) {
      final levelRadius = radius * (level / style.gridDivisions);
      canvas.drawPath(
        _polygonPath(center, levelRadius, categories.length),
        gridPaint,
      );
    }

    for (var i = 0; i < categories.length; i++) {
      final point = _vertexOffset(center, radius, i, categories.length);
      canvas.drawLine(center, point, spokePaint);
    }

    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final color = entry.color ?? palette[i % palette.length];
      final path = Path();
      final markerPaint = Paint()..color = color;
      final fillPaint = Paint()
        ..color = color.withValues(alpha: style.fillOpacity)
        ..style = PaintingStyle.fill;
      final strokePaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = style.strokeWidth;

      for (var pointIndex = 0; pointIndex < categories.length; pointIndex++) {
        final category = categories[pointIndex];
        final pointValue = _valueForCategory(entry.points, category);
        final normalized = (pointValue / maxValue).clamp(0, 1).toDouble();
        final point = _vertexOffset(
          center,
          radius * normalized,
          pointIndex,
          categories.length,
        );

        if (pointIndex == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }

        if (style.showMarkers) {
          canvas.drawCircle(point, style.markerRadius, markerPaint);
        }
      }

      path.close();
      canvas
        ..drawPath(path, fillPaint)
        ..drawPath(path, strokePaint);
    }

    if (style.showAxisLabels) {
      final baseStyle =
          style.axisLabelTextStyle ??
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w500);

      for (var i = 0; i < categories.length; i++) {
        final point = _vertexOffset(
          center,
          radius + 14,
          i,
          categories.length,
        );
        final textPainter = TextPainter(
          text: TextSpan(
            text: categories[i],
            style: baseStyle.copyWith(color: colors.onSurfaceVariant),
          ),
          textDirection: textDirection,
          textAlign: TextAlign.center,
          maxLines: 2,
        )..layout(maxWidth: 76);

        final offset = Offset(
          point.dx - (textPainter.width / 2),
          point.dy - (textPainter.height / 2),
        );
        textPainter.paint(canvas, offset);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RadarChartPainter oldDelegate) {
    return oldDelegate.entries != entries ||
        oldDelegate.categories != categories ||
        oldDelegate.style != style ||
        oldDelegate.colors != colors ||
        oldDelegate.palette != palette;
  }

  static Path _polygonPath(Offset center, double radius, int sides) {
    final path = Path();
    for (var i = 0; i < sides; i++) {
      final point = _vertexOffset(center, radius, i, sides);
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    return path;
  }

  static Offset _vertexOffset(
    Offset center,
    double radius,
    int index,
    int sides,
  ) {
    final angle = (-math.pi / 2) + ((2 * math.pi * index) / sides);
    return Offset(
      center.dx + radius * math.cos(angle),
      center.dy + radius * math.sin(angle),
    );
  }

  static double _resolveMaxValue(
    List<AppRadarChartEntry> entries,
    num? configuredMaxValue,
  ) {
    if (configuredMaxValue != null && configuredMaxValue > 0) {
      return configuredMaxValue.toDouble();
    }

    var maxValue = 0.0;
    for (final entry in entries) {
      for (final point in entry.points) {
        maxValue = math.max(maxValue, point.value.toDouble());
      }
    }

    return math.max(maxValue, 1);
  }

  static double _valueForCategory(List<AppChartPoint> points, String category) {
    for (final point in points) {
      if (point.label == category) {
        return point.value.toDouble();
      }
    }
    return 0;
  }
}

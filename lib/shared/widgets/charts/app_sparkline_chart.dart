import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Trend direction hint for [AppSparklineChart].
///
/// When [auto], the direction is inferred from the first and last value.
enum AppSparklineTrend { auto, up, down, flat }

/// A micro inline chart that renders a compact line (with optional fill) for
/// showing a trend at a glance — typically embedded inside a KPI card or table
/// row.
///
/// Usage:
/// ```dart
/// AppSparklineChart(
///   values: [12, 18, 14, 22, 19, 25],
///   height: 36,
///   showFill: true,
/// )
/// ```
///
/// Color defaults to the theme primary but can be driven by [trend] or
/// overridden with [color].
class AppSparklineChart extends StatelessWidget {
  const AppSparklineChart({
    required this.values,
    super.key,
    this.height = 40,
    this.color,
    this.lineWidth = 1.5,
    this.showFill = true,
    this.showEndDot = true,
    this.trend = AppSparklineTrend.auto,
  });

  final List<num> values;

  /// Height of the sparkline widget. Width fills the available space.
  final double height;

  /// Optional explicit color. Overrides both theme defaults and [trend] color.
  final Color? color;

  final double lineWidth;

  /// When true, fills the area under the line with a semi-transparent gradient.
  final bool showFill;

  /// When true, draws a filled circle at the last data point.
  final bool showEndDot;

  /// Drives the default color when [color] is not provided.
  /// [AppSparklineTrend.auto] infers the direction from the first/last value.
  final AppSparklineTrend trend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolved = _resolveColor(theme);

    if (values.length < 2) {
      return SizedBox(height: height);
    }

    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: _SparklinePainter(
          values: values,
          color: resolved,
          lineWidth: lineWidth,
          showFill: showFill,
          showEndDot: showEndDot,
        ),
      ),
    );
  }

  Color _resolveColor(ThemeData theme) {
    if (color != null) return color!;

    final effectiveTrend = trend == AppSparklineTrend.auto
        ? _inferTrend()
        : trend;

    return switch (effectiveTrend) {
      AppSparklineTrend.up => const Color(0xFF2E9E5B),
      AppSparklineTrend.down => theme.colorScheme.error,
      _ => theme.colorScheme.primary,
    };
  }

  AppSparklineTrend _inferTrend() {
    if (values.length < 2) return AppSparklineTrend.flat;
    final delta = values.last - values.first;
    if (delta > 0) return AppSparklineTrend.up;
    if (delta < 0) return AppSparklineTrend.down;
    return AppSparklineTrend.flat;
  }
}

class _SparklinePainter extends CustomPainter {
  const _SparklinePainter({
    required this.values,
    required this.color,
    required this.lineWidth,
    required this.showFill,
    required this.showEndDot,
  });

  final List<num> values;
  final Color color;
  final double lineWidth;
  final bool showFill;
  final bool showEndDot;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final minVal = values.reduce(math.min).toDouble();
    final maxVal = values.reduce(math.max).toDouble();
    final range = maxVal - minVal;
    final safeRange = range == 0 ? 1.0 : range;

    final xStep = size.width / (values.length - 1);
    final verticalPadding = lineWidth + (showEndDot ? 3.0 : 0.0);

    Offset pointAt(int i) {
      final x = i * xStep;
      final normalized = (values[i].toDouble() - minVal) / safeRange;
      final y = size.height -
          verticalPadding -
          normalized * (size.height - verticalPadding * 2);
      return Offset(x, y);
    }

    final points = List.generate(values.length, pointAt);

    if (showFill) {
      final fillPath = Path()..moveTo(points.first.dx, size.height);
      for (final p in points) {
        fillPath.lineTo(p.dx, p.dy);
      }
      fillPath
        ..lineTo(points.last.dx, size.height)
        ..close();

      final fillPaint = Paint()
        ..shader = LinearGradient(
          colors: <Color>[
            color.withValues(alpha: 0.30),
            color.withValues(alpha: 0.02),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
        ..style = PaintingStyle.fill;

      canvas.drawPath(fillPath, fillPaint);
    }

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = lineWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    canvas.drawPath(linePath, linePaint);

    if (showEndDot) {
      final dotPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(points.last, lineWidth + 1.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      old.values != values ||
      old.color != color ||
      old.lineWidth != lineWidth ||
      old.showFill != showFill ||
      old.showEndDot != showEndDot;
}

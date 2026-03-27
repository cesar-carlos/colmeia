import 'dart:math' as math;

import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:flutter/material.dart';

/// Honeycomb stroke grid behind [child]. Theme-driven by default; override
/// [lineColor] / [patternOpacity] per screen when needed.
class HoneycombHexBackground extends StatelessWidget {
  const HoneycombHexBackground({
    required this.child,
    super.key,
    this.lineColor,
    this.patternOpacity,
    this.edgeFade = true,
  });

  final Widget child;

  /// Grid stroke; defaults to [ColorScheme.outlineVariant].
  final Color? lineColor;

  /// Base opacity before internal gain; uses [AppThemeTokens] when null.
  final double? patternOpacity;

  /// When false, the grid keeps uniform strength to the screen edges.
  final bool edgeFade;

  static const double _fallbackPatternOpacity = 0.055;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<AppThemeTokens>();
    final opacity =
        patternOpacity ??
        tokens?.hexGridPatternOpacity ??
        _fallbackPatternOpacity;

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        CustomPaint(
          painter: _HoneycombPainter(
            color: lineColor ?? cs.outlineVariant,
            patternOpacity: opacity,
            edgeFade: edgeFade,
          ),
        ),
        child,
      ],
    );
  }
}

final class _HoneycombPainter extends CustomPainter {
  _HoneycombPainter({
    required this.color,
    required this.patternOpacity,
    required this.edgeFade,
  });

  final Color color;
  final double patternOpacity;
  final bool edgeFade;

  static const double _radius = 52;
  static const double _strokeWidth = 1.05;
  static const double _horiz = 90.07;
  static const double _vert = 1.5 * _radius;
  static const double _edgeFadeDistance = 220;

  static const double _opacityGain = 3.2;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    final rows = (size.height / _vert).ceil() + 2;
    final cols = (size.width / _horiz).ceil() + 2;
    for (var row = 0; row < rows; row++) {
      final xOffset = row.isOdd ? _horiz * 0.5 : 0.0;
      final y = row * _vert - _vert;
      for (var col = 0; col < cols; col++) {
        final x = col * _horiz + xOffset - _horiz;
        final fade = edgeFade ? _edgeFade(x: x, y: y, size: size) : 1.0;
        if (fade <= 0) {
          continue;
        }
        paint.color = color.withValues(
          alpha: patternOpacity * _opacityGain * fade,
        );
        canvas.drawPath(_hexPath(Offset(x, y), _radius), paint);
      }
    }
  }

  static double _edgeFade({
    required double x,
    required double y,
    required Size size,
  }) {
    final horizontalDistance = (math.min(x, size.width - x) / _edgeFadeDistance)
        .clamp(0, 1)
        .toDouble();
    final verticalDistance = (math.min(y, size.height - y) / _edgeFadeDistance)
        .clamp(0, 1)
        .toDouble();
    final horizontal = _smoothstep(horizontalDistance);
    final vertical = _smoothstep(verticalDistance);
    return math.min(horizontal, vertical);
  }

  static double _smoothstep(double value) {
    return value * value * (3 - 2 * value);
  }

  static Path _hexPath(Offset center, double r) {
    final path = Path();
    for (var i = 0; i < 6; i++) {
      final angle = (math.pi / 3) * i - math.pi / 6;
      final px = center.dx + r * math.cos(angle);
      final py = center.dy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(px, py);
      } else {
        path.lineTo(px, py);
      }
    }
    return path..close();
  }

  @override
  bool shouldRepaint(covariant _HoneycombPainter old) =>
      old.color != color ||
      old.patternOpacity != patternOpacity ||
      old.edgeFade != edgeFade;
}

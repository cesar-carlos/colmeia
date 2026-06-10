import 'dart:math' as math;

import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:colmeia/shared/widgets/app_skeleton.dart';
import 'package:flutter/material.dart';

enum ChartLoadingPlaceholderVariant {
  radial,
  timeSeries,
}

Widget buildChartLoadingState({
  required BuildContext context,
  required double height,
  required Color indicatorColor,
  String? label,
  ChartLoadingPlaceholderVariant variant =
      ChartLoadingPlaceholderVariant.radial,
}) {
  return AppSkeleton(
    enabled: true,
    showDelay: Duration.zero,
    loadingSemanticsLabel:
        label ?? AppLocalizations.of(context).chartLoadingGeneric,
    child: SizedBox(
      height: height,
      child: ExcludeSemantics(
        child: _ChartLoadingPlaceholder(
          indicatorColor: indicatorColor,
          variant: variant,
        ),
      ),
    ),
  );
}

Widget buildChartEmptyState({
  required BuildContext context,
  required double height,
  required String message,
  Widget? placeholder,
  String? semanticsLabel,
}) {
  final theme = Theme.of(context);
  final colors = theme.appColors;
  final typography = theme.appTypography;
  final trimmedSemanticsLabel = semanticsLabel?.trim();
  final content =
      placeholder ??
      Text(
        message,
        textAlign: TextAlign.center,
        style: typography.body.copyWith(
          color: colors.onSurfaceVariant,
        ),
      );

  final semanticsWrapped =
      trimmedSemanticsLabel != null && trimmedSemanticsLabel.isNotEmpty
      ? Semantics(
          container: true,
          label: trimmedSemanticsLabel,
          excludeSemantics: true,
          child: content,
        )
      : content;

  return SizedBox(
    height: height,
    child: Center(
      child: semanticsWrapped,
    ),
  );
}

class _ChartLoadingPlaceholder extends StatelessWidget {
  const _ChartLoadingPlaceholder({
    required this.indicatorColor,
    required this.variant,
  });

  final Color indicatorColor;
  final ChartLoadingPlaceholderVariant variant;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.appColors;
    final tokens = theme.extension<AppThemeTokens>()!;
    final typography = theme.appTypography;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 240.0;
        final maxHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : 240.0;
        final ringSize = math
            .min(maxWidth * 0.72, maxHeight * 0.72)
            .clamp(112.0, 220.0);
        final innerRingSize = ringSize * 0.68;
        final centerSize = ringSize * 0.34;
        final legendLineWidth = math
            .min(maxWidth * 0.22, 96)
            .clamp(52.0, 96.0)
            .toDouble();

        Widget buildLegendItem(int index) {
          final swatchColor = switch (index) {
            0 => indicatorColor.withValues(alpha: 0.22),
            1 => indicatorColor.withValues(alpha: 0.16),
            _ => indicatorColor.withValues(alpha: 0.1),
          };
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: swatchColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              SizedBox(width: tokens.gapXs),
              SizedBox(
                width: legendLineWidth,
                child: Text(
                  'Categoria ${index + 1}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: typography.body.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          );
        }

        return KeyedSubtree(
          key: ValueKey<String>('chart-loading-placeholder-${variant.name}'),
          child: switch (variant) {
            ChartLoadingPlaceholderVariant.radial => Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                SizedBox(
                  width: ringSize,
                  height: ringSize,
                  child: Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      Container(
                        width: ringSize,
                        height: ringSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors.surfaceContainerHighest,
                        ),
                      ),
                      Container(
                        width: innerRingSize,
                        height: innerRingSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: indicatorColor.withValues(alpha: 0.12),
                        ),
                      ),
                      Container(
                        width: centerSize,
                        height: centerSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.colorScheme.surface,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: tokens.gapMd),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: tokens.gapMd,
                  runSpacing: tokens.gapSm,
                  children: List<Widget>.generate(3, buildLegendItem),
                ),
              ],
            ),
            ChartLoadingPlaceholderVariant.timeSeries => Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                SizedBox(
                  width: maxWidth,
                  height: maxHeight * 0.7,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(
                        tokens.cardRadius,
                      ),
                      border: Border.all(
                        color: colors.outlineVariant.withValues(alpha: 0.18),
                      ),
                    ),
                    child: CustomPaint(
                      painter: _TimeSeriesLoadingPlaceholderPainter(
                        baseColor: colors.surfaceContainerHighest,
                        accentColor: indicatorColor,
                        gridColor: colors.outlineVariant.withValues(
                          alpha: 0.18,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: tokens.gapMd),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: tokens.gapMd,
                  runSpacing: tokens.gapSm,
                  children: List<Widget>.generate(3, buildLegendItem),
                ),
              ],
            ),
          },
        );
      },
    );
  }
}

class _TimeSeriesLoadingPlaceholderPainter extends CustomPainter {
  const _TimeSeriesLoadingPlaceholderPainter({
    required this.baseColor,
    required this.accentColor,
    required this.gridColor,
  });

  final Color baseColor;
  final Color accentColor;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    const leftInset = 20.0;
    const rightInset = 12.0;
    const topInset = 18.0;
    const bottomInset = 22.0;

    final plotRect = Rect.fromLTWH(
      leftInset,
      topInset,
      math.max(0, size.width - leftInset - rightInset),
      math.max(0, size.height - topInset - bottomInset),
    );
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    final axisPaint = Paint()
      ..color = baseColor.withValues(alpha: 0.9)
      ..strokeWidth = 1.5;

    for (var step = 1; step <= 3; step++) {
      final dy = plotRect.top + (plotRect.height / 4) * step;
      canvas.drawLine(
        Offset(plotRect.left, dy),
        Offset(plotRect.right, dy),
        gridPaint,
      );
    }

    canvas
      ..drawLine(
        Offset(plotRect.left, plotRect.top),
        Offset(plotRect.left, plotRect.bottom),
        axisPaint,
      )
      ..drawLine(
        Offset(plotRect.left, plotRect.bottom),
        Offset(plotRect.right, plotRect.bottom),
        axisPaint,
      );

    void drawSeries(List<double> normalizedY, Color color) {
      if (normalizedY.length < 2) {
        return;
      }
      final path = Path();
      final stepX = plotRect.width / (normalizedY.length - 1);
      for (var i = 0; i < normalizedY.length; i++) {
        final x = plotRect.left + (stepX * i);
        final y = plotRect.top + (plotRect.height * normalizedY[i]);
        final point = Offset(x, y);
        if (i == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = 3;
      canvas.drawPath(path, paint);
    }

    drawSeries(
      const <double>[0.62, 0.4, 0.5, 0.28, 0.18, 0.36],
      accentColor.withValues(alpha: 0.28),
    );
    drawSeries(
      const <double>[0.72, 0.58, 0.46, 0.38, 0.3, 0.24],
      accentColor.withValues(alpha: 0.18),
    );
    drawSeries(
      const <double>[0.8, 0.7, 0.56, 0.52, 0.42, 0.34],
      accentColor.withValues(alpha: 0.12),
    );

    final tickPaint = Paint()..color = baseColor.withValues(alpha: 0.72);
    for (var i = 0; i < 6; i++) {
      final x = plotRect.left + (plotRect.width / 5) * i;
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(x, size.height - 8),
          width: 20,
          height: 4,
        ),
        const Radius.circular(999),
      );
      canvas.drawRRect(rect, tickPaint);
    }
  }

  @override
  bool shouldRepaint(
    covariant _TimeSeriesLoadingPlaceholderPainter oldDelegate,
  ) {
    return oldDelegate.baseColor != baseColor ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.gridColor != gridColor;
  }
}

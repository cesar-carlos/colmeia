import 'dart:math' as math;

import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/charts/app_map_models.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SyncfusionRegionMapValueLegend extends StatelessWidget {
  const SyncfusionRegionMapValueLegend({
    required this.values,
    required this.lowColor,
    required this.highColor,
    required this.gapSm,
    required this.gapXs,
    super.key,
    this.title,
    this.numberFormat,
    this.textStyle,
  });

  final List<double> values;
  final Color lowColor;
  final Color highColor;
  final double gapSm;
  final double gapXs;
  final String? title;
  final NumberFormat? numberFormat;
  final TextStyle? textStyle;

  static String _formatEndpoint(double value, NumberFormat? format) {
    if (format != null) {
      return format.format(value);
    }
    return value.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final minValue = values.isEmpty ? 0.0 : values.reduce(math.min);
    final maxValue = values.isEmpty ? 0.0 : values.reduce(math.max);

    final row = Row(
      children: <Widget>[
        Text(
          _formatEndpoint(minValue, numberFormat),
          style: textStyle,
        ),
        SizedBox(width: gapSm),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: <Color>[lowColor, highColor]),
              borderRadius: const BorderRadius.all(Radius.circular(999)),
            ),
            child: const SizedBox(height: 10),
          ),
        ),
        SizedBox(width: gapSm),
        Text(
          _formatEndpoint(maxValue, numberFormat),
          style: textStyle,
        ),
      ],
    );

    final l10n = AppLocalizations.of(context);
    final minLabel = _formatEndpoint(minValue, numberFormat);
    final maxLabel = _formatEndpoint(maxValue, numberFormat);

    if (title == null || title!.isEmpty) {
      return Semantics(
        label: l10n.regionMapLegendSemanticsLabel(minLabel, maxLabel),
        child: SyncfusionRegionMapLegendSurface(child: row),
      );
    }

    return Semantics(
      label: l10n.regionMapLegendWithTitleSemanticsLabel(
        title!,
        minLabel,
        maxLabel,
      ),
      child: SyncfusionRegionMapLegendSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(title!, style: textStyle),
            SizedBox(height: gapXs),
            row,
          ],
        ),
      ),
    );
  }
}

class SyncfusionRegionMapLegendSurface extends StatelessWidget {
  const SyncfusionRegionMapLegendSurface({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(tokens.formFieldRadius),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: tokens.gapMd,
          vertical: tokens.gapSm,
        ),
        child: child,
      ),
    );
  }
}

class SyncfusionRegionMapResetViewportButton extends StatelessWidget {
  const SyncfusionRegionMapResetViewportButton({
    required this.onPressed,
    super.key,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final colors = theme.appColors;
    final l10n = AppLocalizations.of(context);
    final tooltipLabel = l10n.mapCenterViewportTooltip;

    return Tooltip(
      message: tooltipLabel,
      child: Semantics(
        button: true,
        label: tooltipLabel,
        child: Material(
          color: colors.surface.withValues(alpha: 0.92),
          elevation: 2,
          borderRadius: BorderRadius.circular(tokens.formFieldRadius),
          child: InkWell(
            borderRadius: BorderRadius.circular(tokens.formFieldRadius),
            onTap: onPressed,
            child: SizedBox(
              width: 48,
              height: 48,
              child: Center(
                child: Icon(
                  Icons.my_location_rounded,
                  size: 18,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Default marker visual: a colored shape with a thin contrasting stroke.
class SyncfusionRegionMapMarkerShape extends StatelessWidget {
  const SyncfusionRegionMapMarkerShape({
    required this.style,
    required this.defaultColor,
    required this.defaultStrokeColor,
    super.key,
  });

  final AppMapMarkerStyle style;
  final Color defaultColor;
  final Color defaultStrokeColor;

  @override
  Widget build(BuildContext context) {
    final fill = style.color ?? defaultColor;
    final stroke = style.strokeColor ?? defaultStrokeColor;
    final size = style.size;

    switch (style.iconType) {
      case AppMapMarkerIcon.circle:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: fill,
            shape: BoxShape.circle,
            border: Border.all(color: stroke, width: style.strokeWidth),
          ),
        );
      case AppMapMarkerIcon.rectangle:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: fill,
            border: Border.all(color: stroke, width: style.strokeWidth),
          ),
        );
      case AppMapMarkerIcon.diamond:
      case AppMapMarkerIcon.triangle:
        return SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _SyncfusionRegionMapMarkerPolygonPainter(
              iconType: style.iconType,
              fill: fill,
              stroke: stroke,
              strokeWidth: style.strokeWidth,
            ),
          ),
        );
    }
  }
}

class _SyncfusionRegionMapMarkerPolygonPainter extends CustomPainter {
  _SyncfusionRegionMapMarkerPolygonPainter({
    required this.iconType,
    required this.fill,
    required this.stroke,
    required this.strokeWidth,
  });

  final AppMapMarkerIcon iconType;
  final Color fill;
  final Color stroke;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;
    switch (iconType) {
      case AppMapMarkerIcon.diamond:
        path
          ..moveTo(w / 2, 0)
          ..lineTo(w, h / 2)
          ..lineTo(w / 2, h)
          ..lineTo(0, h / 2)
          ..close();
      case AppMapMarkerIcon.triangle:
        path
          ..moveTo(w / 2, 0)
          ..lineTo(w, h)
          ..lineTo(0, h)
          ..close();
      case AppMapMarkerIcon.circle:
      case AppMapMarkerIcon.rectangle:
        return;
    }
    final fillPaint = Paint()
      ..color = fill
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeJoin = StrokeJoin.round;
    canvas
      ..drawPath(path, fillPaint)
      ..drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _SyncfusionRegionMapMarkerPolygonPainter old) {
    return old.iconType != iconType ||
        old.fill != fill ||
        old.stroke != stroke ||
        old.strokeWidth != strokeWidth;
  }
}

class SyncfusionMapsSemanticsBoundary extends StatelessWidget {
  const SyncfusionMapsSemanticsBoundary({
    required this.child,
    required this.excludeOnWindows,
    required this.label,
    super.key,
  });

  final Widget child;
  final bool excludeOnWindows;
  final String label;

  @override
  Widget build(BuildContext context) {
    if (!excludeOnWindows || defaultTargetPlatform != TargetPlatform.windows) {
      return child;
    }

    // Syncfusion Maps 33.x can emit transient semantics nodes that Windows'
    // accessibility bridge rejects while the layer mounts or remounts.
    return Semantics(
      container: true,
      label: label,
      child: ExcludeSemantics(child: child),
    );
  }
}

/// Fixed visual slot for the map: subtle background and rounded corners even
/// while the engine downloads/parses GeoJSON.
class SyncfusionRegionMapSurface extends StatelessWidget {
  const SyncfusionRegionMapSurface({
    required this.height,
    required this.background,
    required this.borderRadius,
    required this.child,
    super.key,
    this.padding,
  });

  final double height;
  final Color background;
  final BorderRadius borderRadius;
  final EdgeInsets? padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: borderRadius,
        ),
        child: padding == null
            ? child
            : Padding(padding: padding!, child: child),
      ),
    );
  }
}

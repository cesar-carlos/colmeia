import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

/// Centralized animation defaults so every Syncfusion chart engine animates
/// for the same length out of the box (and reacts to OS reduce-motion).
///
/// Historical defaults across engines were inconsistent (1500 / 1200 / 900 /
/// 0 ms). The values below match what we already adopted in the production
/// charts on the overview home (350 ms for cartesian series, 500 ms for
/// circular series).
class AppChartEngineAnimationDefaults {
  const AppChartEngineAnimationDefaults._();

  /// Default sweep for cartesian series (bar / line / area / scatter / step).
  static const double cartesianSeriesMs = 350;

  /// Default sweep for circular / radial series (donut / pie / funnel /
  /// pyramid / radial bar).
  static const double circularSeriesMs = 500;

  /// Default for gauges (slightly slower because the needle motion reads
  /// better with a longer arc).
  static const double gaugeMs = 600;
}

/// Default Syncfusion column geometry when chart styles omit explicit bar width,
/// spacing / gap, or minimum category slot width.
///
/// Keeps `columnWidthRatio + columnSpacingRatio` ≤ 1; tuned for overview home
/// charts (readable labels + horizontal scroll on narrow layouts).
class AppChartEngineCartesianBarGeometryDefaults {
  const AppChartEngineCartesianBarGeometryDefaults._();

  /// Fraction of category slot filled by the column (Syncfusion column width).
  static const double columnWidthRatio = 0.66;

  /// Gap fraction between columns when comparison/combo styles omit pixel gap
  /// or relative spacing fields.
  static const double columnSpacingRatio = 0.32;

  /// Minimum logical px per category slot when horizontal scroll widens the plot.
  static const double minCategorySlotWidth = 128;
}

/// Resolves the actual animation duration the engine should pass to a
/// Syncfusion series.
///
/// - When the user style supplies an explicit duration, it wins.
/// - When the platform requests reduced motion (`MediaQueryData.disableAnimations`)
///   the duration collapses to `0` regardless of the configured value.
/// - When neither is set, [defaultMs] is used.
double resolveChartAnimationDurationMs({
  required BuildContext context,
  required Duration? styleDuration,
  required double defaultMs,
}) {
  final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
  if (reduceMotion) {
    return 0;
  }
  if (styleDuration != null) {
    return styleDuration.inMilliseconds.toDouble();
  }
  return defaultMs;
}

/// Returns a [TooltipBehavior] aligned with the colmeia design system:
/// dark inverse-surface background, high-contrast white-ish text, no border.
///
/// Used by every Syncfusion chart engine so tooltips look identical across
/// charts (matches the comparison/combo/donut implementations that shipped
/// first).
TooltipBehavior buildChartTooltipBehavior(
  BuildContext context, {
  required bool enable,
  bool shared = false,
  ActivationMode activationMode = ActivationMode.singleTap,
  int durationMs = 2400,
  bool canShowMarker = true,
  ChartWidgetBuilder<dynamic, dynamic>? builder,
  TooltipPosition tooltipPosition = TooltipPosition.auto,
}) {
  final colorScheme = Theme.of(context).colorScheme;
  return TooltipBehavior(
    enable: enable,
    shared: shared,
    activationMode: activationMode,
    duration: durationMs.toDouble(),
    tooltipPosition: tooltipPosition,
    color: colorScheme.inverseSurface,
    textStyle: TextStyle(
      color: colorScheme.onInverseSurface,
      fontSize: 12,
      fontWeight: FontWeight.w600,
    ),
    borderWidth: 0,
    canShowMarker: canShowMarker,
    builder: builder,
  );
}

/// Helper for `onTooltipRender` callbacks that strips Syncfusion's default
/// `"Series 0"` header — every engine in this repo prefers carrying the
/// category / series label inside the body text, so the header is noise.
///
/// Pass an optional [bodyResolver] to also customize the body text. Keep it
/// `null` to only sanitize the header.
void Function(TooltipArgs args) buildSanitizingTooltipRenderer({
  String? Function(TooltipArgs args)? bodyResolver,
}) {
  return (TooltipArgs args) {
    args.header = '';
    if (bodyResolver != null) {
      final next = bodyResolver(args);
      if (next != null && next.isNotEmpty) {
        args.text = next;
      }
    }
  };
}

/// Shared category-axis viewport pan behavior for cartesian engines that use
/// [CategoryAxis.autoScrollingDelta] (comparison bar + combo charts).
ZoomPanBehavior? buildCategoryViewportZoomPanBehavior({required bool enabled}) {
  if (!enabled) {
    return null;
  }
  return ZoomPanBehavior(
    enablePanning: true,
    zoomMode: ZoomMode.x,
  );
}

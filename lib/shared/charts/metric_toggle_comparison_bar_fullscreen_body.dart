import 'dart:math' as math;

import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:flutter/material.dart';

/// Minimum chart height when the viewport has enough room (portrait / tall).
const double kFullscreenChartMinHeight = 220;

/// Lower minimum for short viewports (landscape phones, tight fullscreen body).
const double kFullscreenChartMinHeightCompact = 80;

/// Resolves a sensible minimum chart height for the available vertical space.
double resolveFullscreenChartMinHeight(double maxHeight) {
  if (maxHeight <= 0) {
    return 0;
  }
  if (maxHeight < 300) {
    return math.max(
      kFullscreenChartMinHeightCompact,
      maxHeight * 0.5,
    ).clamp(0, maxHeight);
  }
  return math.min(kFullscreenChartMinHeight, maxHeight);
}

/// Resolves chart height for fullscreen layouts without invalid [num.clamp] bounds.
double resolveFullscreenChartHeight({
  required double maxHeight,
  required double reservedHeight,
  double? minChartHeight,
}) {
  final maxH = maxHeight;
  final raw = (maxH - reservedHeight).clamp(0.0, maxH);
  final resolvedMin =
      minChartHeight ?? resolveFullscreenChartMinHeight(maxH);
  final minH = math.min(resolvedMin, raw);
  return raw.clamp(minH, maxH);
}

bool isLandscapeChartViewport(BuildContext context) {
  return MediaQuery.orientationOf(context) == Orientation.landscape;
}

double _controlChartGap(AppThemeTokens tokens, BuildContext context) {
  return isLandscapeChartViewport(context)
      ? tokens.gapXs
      : tokens.contentSpacing;
}

/// Chart height for fullscreen body layouts: landscape uses the full slot.
double resolveFullscreenBodyChartHeight({
  required BuildContext context,
  required double maxHeight,
}) {
  if (maxHeight <= 0) {
    return 0;
  }
  if (isLandscapeChartViewport(context)) {
    return maxHeight;
  }
  return resolveFullscreenChartHeight(
    maxHeight: maxHeight,
    reservedHeight: 0,
    minChartHeight: resolveFullscreenChartMinHeight(maxHeight),
  );
}

/// Shared fullscreen body layout: control on top, chart fills remaining height.
///
/// Used by comparison bar and combo charts to avoid duplicating the
/// [LayoutBuilder] height math in every fullscreen route.
Widget buildSegmentedControlFullscreenBody({
  required AppThemeTokens tokens,
  required Widget control,
  required Widget Function(double availableChartHeight) chartBuilder,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      control,
      Builder(
        builder: (context) => SizedBox(height: _controlChartGap(tokens, context)),
      ),
      Expanded(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxH = constraints.maxHeight;
            if (!maxH.isFinite || maxH <= 0) {
              return const SizedBox.shrink();
            }
            final availableChartHeight = resolveFullscreenBodyChartHeight(
              context: context,
              maxHeight: maxH,
            );
            return SizedBox(
              height: availableChartHeight,
              width: constraints.maxWidth,
              child: chartBuilder(availableChartHeight),
            );
          },
        ),
      ),
    ],
  );
}

/// Shared fullscreen body layout: metric toggle on top, chart fills below.
Widget buildMetricToggleComparisonBarFullscreenBody({
  required AppThemeTokens tokens,
  required Widget metricToggle,
  required Widget Function(double availableChartHeight) chartBuilder,
}) {
  return buildSegmentedControlFullscreenBody(
    tokens: tokens,
    control: metricToggle,
    chartBuilder: chartBuilder,
  );
}

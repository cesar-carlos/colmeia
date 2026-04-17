import 'dart:math' as math;

import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

/// Minimum scaled line height used when reserving top margin for outer data
/// labels on comparison column charts.
const double kComparisonBarOuterLabelLineHeightMin = 18;

/// Maximum scaled line height used when reserving top margin for outer data
/// labels on comparison column charts (one compact label line, not a block).
///
/// Kept above typical single-line body text so compact currency labels (e.g.
/// `R$ 16,7 mil`) and modest [TextScaler] values are not clipped at the chart top.
const double kComparisonBarOuterLabelLineHeightMax = 42;

/// Whether data labels sit outside the column and need extra top margin.
bool comparisonBarChartNeedsOuterDataLabelHeadroom({
  required bool showDataLabels,
  required ChartDataLabelAlignment dataLabelAlignment,
}) {
  if (!showDataLabels) {
    return false;
  }
  return switch (dataLabelAlignment) {
    ChartDataLabelAlignment.middle ||
    ChartDataLabelAlignment.top ||
    ChartDataLabelAlignment.bottom => false,
    ChartDataLabelAlignment.auto || ChartDataLabelAlignment.outer => true,
  };
}

/// Top (and base) margin for [SfCartesianChart] so outer data labels are not
/// clipped; uses [MediaQuery.textScalerOf] for accessibility font scaling.
EdgeInsets resolveComparisonBarChartMargin(
  BuildContext context, {
  required bool showDataLabels,
  required ChartDataLabelAlignment dataLabelAlignment,
  required Offset? dataLabelOffset,
  required EdgeInsets? chartPadding,
  double outerDataLabelTopReserve = 0,
}) {
  final base = chartPadding ?? EdgeInsets.zero;
  if (!comparisonBarChartNeedsOuterDataLabelHeadroom(
    showDataLabels: showDataLabels,
    dataLabelAlignment: dataLabelAlignment,
  )) {
    return base;
  }
  final theme = Theme.of(context);
  final tokens = theme.extension<AppThemeTokens>();
  final bodyStyle =
      theme.textTheme.bodySmall ??
      theme.textTheme.bodyMedium ??
      theme.textTheme.bodyLarge;
  final fontSize = bodyStyle?.fontSize ?? 12.0;
  final heightFactor = bodyStyle?.height ?? 1.25;
  final textScaler = MediaQuery.textScalerOf(context);
  final rawLineHeight = fontSize * heightFactor;
  final estimatedLineHeight = textScaler
      .scale(rawLineHeight)
      .clamp(
        kComparisonBarOuterLabelLineHeightMin,
        kComparisonBarOuterLabelLineHeightMax,
      );
  final lift = dataLabelOffset?.dy ?? 0;
  // Space after the label line: use the larger of gap tokens (not both), so we
  // do not double-count; still grows under [TextScaler] when gapSm scales up.
  final clearance = math.max(
    textScaler.scale(tokens?.gapSm ?? 8.0),
    tokens?.gapMd ?? 12.0,
  );
  final minTop = estimatedLineHeight + lift.abs() + clearance;
  final top = math.max(base.top, minTop) + outerDataLabelTopReserve;
  return EdgeInsets.fromLTRB(base.left, top, base.right, base.bottom);
}

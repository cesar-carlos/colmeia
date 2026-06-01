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
const double kComparisonBarOuterLabelLineHeightMax = 50;

/// Vertical padding around bar value text when labels are drawn as
/// [CartesianChartAnnotation]s (`syncfusion_combo_chart.dart` uses
/// `EdgeInsets.all(5)`). Top margin must include this so tall columns do not
/// clip the label at the chart edge.
const double kComparisonBarAnnotationLabelVerticalInset = 10;

/// Extra top headroom when annotation value labels use the pill layout from
/// `syncfusion_comparison_bar_chart.dart` (outer vertical padding 8 plus
/// inner vertical padding 8 above the text). The generic annotation inset alone
/// assumed ~5px outer padding, not 16px above the line.
const double kComparisonBarAnnotationPillExtraTopAllowance = 22;

/// Logical line count in a bar data label (`\n`-separated). Returns `0` when
/// [label] is null or empty.
int comparisonBarDataLabelLineCount(String? label) {
  if (label == null || label.isEmpty) {
    return 0;
  }
  return label.split(RegExp(r'\r?\n')).length;
}

/// Maximum [comparisonBarDataLabelLineCount] across [labels]; at least `1`.
int comparisonBarMaxDataLabelLines(Iterable<String?>? labels) {
  if (labels == null) {
    return 1;
  }
  var maxLines = 1;
  for (final label in labels) {
    final count = comparisonBarDataLabelLineCount(label);
    if (count > maxLines) {
      maxLines = count;
    }
  }
  return maxLines;
}

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
///
/// When [valueLabelsRenderedAsChartAnnotations] is true, built-in column
/// [DataLabelSettings] are typically off and value text is drawn with
/// [CartesianChartAnnotation] instead. By default, the top margin still
/// reserves one line of label height (same as built-in outer labels) plus
/// annotation padding; when [dataLabelAnnotationUsesPillBackground] is true,
/// extra headroom is added for the pill-shaped label chrome used by the
/// comparison bar chart Syncfusion engine. Callers that already reserve plot
/// headroom through the axis can disable that top margin to avoid a large empty
/// band above the bars.
EdgeInsets resolveComparisonBarChartMargin(
  BuildContext context, {
  required bool showDataLabels,
  required ChartDataLabelAlignment dataLabelAlignment,
  required Offset? dataLabelOffset,
  required EdgeInsets? chartPadding,
  bool reserveOuterDataLabelTopMargin = true,
  double outerDataLabelTopReserve = 0,
  bool valueLabelsRenderedAsChartAnnotations = false,
  bool dataLabelAnnotationUsesPillBackground = false,
  int maxDataLabelLines = 1,
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
  final hPad = textScaler.scale(tokens?.gapMd ?? 12.0);
  final left = math.max(base.left, hPad);
  final right = math.max(base.right, hPad);
  if (!reserveOuterDataLabelTopMargin) {
    return EdgeInsets.fromLTRB(left, base.top, right, base.bottom);
  }
  final lineCount = math.max(1, maxDataLabelLines);
  final interLineGap = lineCount > 1
      ? textScaler.scale(tokens?.gapXs ?? 4.0)
      : 0.0;
  final labelBlockHeight =
      estimatedLineHeight * lineCount + interLineGap * (lineCount - 1);
  var minTop = labelBlockHeight + lift.abs() + clearance;
  if (valueLabelsRenderedAsChartAnnotations) {
    minTop += kComparisonBarAnnotationLabelVerticalInset;
    if (dataLabelAnnotationUsesPillBackground) {
      minTop += kComparisonBarAnnotationPillExtraTopAllowance;
    }
  }
  final top = math.max(base.top, minTop) + outerDataLabelTopReserve;
  return EdgeInsets.fromLTRB(left, top, right, base.bottom);
}

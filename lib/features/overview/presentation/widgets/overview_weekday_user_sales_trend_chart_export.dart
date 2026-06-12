import 'dart:math' as math;

import 'package:colmeia/features/overview/presentation/widgets/overview_weekday_user_grouped_bar_chart.dart';
import 'package:colmeia/features/overview/presentation/widgets/weekday_user_grouped_chart_data.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/charts/chart_export_capture.dart';
import 'package:flutter/material.dart';

/// Mirrors [OverviewWeekdayUserGroupedBarChart] slot geometry for PDF export.
const double kOverviewWeekdayUserGroupedPerBarSlot = 18;
const double kOverviewWeekdayUserGroupedMinCategoryWidthFloor = 88;

double overviewWeekdayUserGroupedChartMinCategoryWidth(int seriesCount) {
  return math.max(
    kOverviewWeekdayUserGroupedMinCategoryWidthFloor,
    math.max(1, seriesCount) * kOverviewWeekdayUserGroupedPerBarSlot,
  );
}

/// Builds the offscreen chart widget used by weekday user sales trend PDF export.
WidgetBuilder? buildOverviewWeekdayUserGroupedChartExportBuilder({
  required WeekdayUserGroupedChartModel? model,
  required AppLocalizations l10n,
  required AppThemeTokens tokens,
  required bool isSalesCount,
  required String title,
  required String subtitle,
}) {
  if (model == null) {
    return null;
  }

  final exportPlotHeight =
      tokens.chartStandardHeight + tokens.contentSpacing * 2 + tokens.gapMd;

  return (exportContext) {
    final exportTokens =
        Theme.of(exportContext).extension<AppThemeTokens>() ?? tokens;
    final categoryCount = math.max(
      1,
      model.weekdayCategoryLabels.length,
    );
    final minSlotWidth = overviewWeekdayUserGroupedChartMinCategoryWidth(
      model.userNames.length,
    );
    return wrapCartesianChartForPdfExport(
      context: exportContext,
      itemCount: categoryCount,
      minSlotWidth: minSlotWidth,
      height: exportPlotHeight + tokens.gapSm * 2 + 48,
      chart: OverviewWeekdayUserGroupedBarChart(
        l10n: l10n,
        model: model,
        isSalesCount: isSalesCount,
        title: title,
        subtitle: subtitle,
        belowSubtitle: const SizedBox.shrink(),
        plotFloorAccessibilityNotice: l10n.chartComparisonPlotFloorNotice,
        extremeSpreadAccessibilityNotice:
            l10n.chartComparisonExtremeValueSpreadNotice,
        tokens: exportTokens,
        useChartShell: false,
        chartHeightOverride: exportPlotHeight,
        animationDurationMs: 0,
      ),
    );
  };
}

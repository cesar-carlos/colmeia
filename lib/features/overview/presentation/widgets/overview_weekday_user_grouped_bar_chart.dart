import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/features/overview/presentation/widgets/weekday_user_grouped_chart_data.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_shell.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_theme.dart';
import 'package:colmeia/shared/widgets/charts/comparison_bar_plot_floor.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

/// Grouped column chart: weekdays on the category axis; one [ColumnSeries] per
/// user (side‑by‑side clusters). Legend identifies users by colour.
class OverviewWeekdayUserGroupedBarChart extends StatelessWidget {
  const OverviewWeekdayUserGroupedBarChart({
    required this.l10n,
    required this.model,
    required this.isSalesCount,
    required this.title,
    required this.subtitle,
    required this.belowSubtitle,
    required this.plotFloorAccessibilityNotice,
    required this.extremeSpreadAccessibilityNotice,
    required this.tokens,
    super.key,
  });

  final AppLocalizations l10n;
  final WeekdayUserGroupedChartModel model;
  final bool isSalesCount;
  final String title;
  final String subtitle;
  final Widget belowSubtitle;
  final String plotFloorAccessibilityNotice;
  final String extremeSpreadAccessibilityNotice;
  final AppThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    final localeName = l10n.localeName;
    final salesCountFormat = NumberFormat.decimalPattern(localeName);
    final chartTheme = AppChartTheme.fromContext(
      context,
      preset: AppChartPreset.standard,
    );
    final colorScheme = Theme.of(context).colorScheme;
    final axisLabelStyle = Theme.of(context).textTheme.bodySmall;

    final flat = weekdayUserGroupedFlatValues(model);
    if (kDebugMode) {
      debugLogSuspiciousComparisonBarSpread(flat);
    }
    final hasPlotFloor = model.seriesData.any(
      (series) => series.any(
        (d) =>
            d.value.toDouble() > 0 &&
            (d.plottedY.toDouble() - d.value.toDouble()).abs() > 1e-9,
      ),
    );
    final hasExtremeSpread = comparisonBarValuesHaveExtremeSpread(flat);

    final semanticsParts = <String>[];
    if (hasPlotFloor) {
      final t = plotFloorAccessibilityNotice.trim();
      if (t.isNotEmpty) {
        semanticsParts.add(t);
      }
    }
    if (hasExtremeSpread) {
      final t = extremeSpreadAccessibilityNotice.trim();
      if (t.isNotEmpty) {
        semanticsParts.add(t);
      }
    }
    final semanticsCoordinatorLabel =
        semanticsParts.isEmpty ? null : semanticsParts.join(' ');

    Widget? floorTrailing;
    if (hasPlotFloor) {
      final t = plotFloorAccessibilityNotice.trim();
      if (t.isNotEmpty) {
        floorTrailing = Tooltip(
          message: t,
          child: Icon(
            Icons.info_outline,
            size: 20,
            color: colorScheme.onSurfaceVariant,
          ),
        );
      }
    }

    final legendBand =
        model.userNames.isNotEmpty ? tokens.gapMd + 56.0 : tokens.gapSm;
    final plotHeight = tokens.chartStandardHeight +
        tokens.contentSpacing * 2 +
        tokens.gapMd +
        legendBand;

    final yFormat = isSalesCount
        ? NumberFormat.decimalPattern(localeName)
        : AppBrFormatters.compactCurrencyFormatForLocale(localeName);

    final seriesList = <CartesianSeries<WeekdayUserGroupedBarDatum, String>>[];
    for (var s = 0; s < model.userNames.length; s++) {
      final userName = model.userNames[s];
      final data = model.seriesData[s];
      final displayName = truncateLegendUserName(userName);
      seriesList.add(
        ColumnSeries<WeekdayUserGroupedBarDatum, String>(
          name: displayName,
          legendItemText: displayName,
          dataSource: data,
          xValueMapper: (d, _) => d.weekdayCategoryLabel,
          yValueMapper: (d, _) => d.plottedY,
          width: 0.72,
          spacing: 0.12,
          borderRadius: BorderRadius.circular(6),
          color: chartTheme.paletteColor(s),
          animationDuration: 0,
        ),
      );
    }

    final chart = SizedBox(
      height: plotHeight,
      child: SfCartesianChart(
        margin: const EdgeInsets.fromLTRB(4, 8, 4, 4),
        plotAreaBorderWidth: 0,
        legend: Legend(
          isVisible: model.userNames.isNotEmpty,
          position: LegendPosition.bottom,
          overflowMode: LegendItemOverflowMode.wrap,
          padding: tokens.gapSm,
          itemPadding: tokens.gapSm,
          textStyle: Theme.of(context).textTheme.bodySmall,
        ),
        tooltipBehavior: TooltipBehavior(
          enable: true,
          duration: 4000,
        ),
        primaryXAxis: CategoryAxis(
          majorGridLines: const MajorGridLines(width: 0),
          labelStyle: axisLabelStyle,
        ),
        primaryYAxis: NumericAxis(
          minimum: 0,
          axisLine: const AxisLine(width: 0),
          majorGridLines: MajorGridLines(
            width: 1,
            color: colorScheme.outlineVariant.withValues(alpha: 0.35),
          ),
          labelStyle: axisLabelStyle,
          numberFormat: yFormat,
        ),
        onTooltipRender: (args) {
          final si = args.seriesIndex;
          final pi = args.pointIndex;
          if (si is! int || pi is! int) {
            return;
          }
          if (si < 0 ||
              si >= model.userNames.length ||
              pi < 0 ||
              pi >= model.seriesData[si].length) {
            return;
          }
          final d = model.seriesData[si][pi];
          final day = d.weekdayCategoryLabel;
          final user = model.userNames[si].trim().isEmpty
              ? '—'
              : model.userNames[si].trim();
          args
            ..header = day
            ..text = l10n.overviewWeekdayUserSalesTooltip(
              day,
              user,
              salesCountFormat.format(d.salesCount),
              AppBrFormatters.currency(d.salesAmount),
            );
        },
        series: seriesList,
      ),
    );

    final footnote = model.combinedRemainingUsers
        ? Padding(
            padding: EdgeInsets.only(top: tokens.gapSm),
            child: Text(
              l10n.overviewWeekdayUserGroupedTruncationFootnote(
                kWeekdayUserGroupedMaxSeries - 1,
                l10n.overviewWeekdayUserGroupedOthersLabel,
              ),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          )
        : null;

    Widget shellChild = footnote == null
        ? chart
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              chart,
              footnote,
            ],
          );

    if (semanticsCoordinatorLabel != null &&
        semanticsCoordinatorLabel.isNotEmpty) {
      shellChild = Semantics(
        label: semanticsCoordinatorLabel,
        excludeSemantics: true,
        child: shellChild,
      );
    }

    return AppChartShell(
      title: title,
      subtitle: subtitle,
      belowSubtitle: belowSubtitle,
      titleTrailing: floorTrailing,
      child: shellChild,
    );
  }
}

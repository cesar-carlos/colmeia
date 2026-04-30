import 'dart:math' as math;

import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/features/overview/presentation/widgets/weekday_user_grouped_chart_data.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_shell.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_theme.dart';
import 'package:colmeia/shared/widgets/charts/chart_horizontal_scroll_shell.dart';
import 'package:colmeia/shared/widgets/charts/comparison_bar_plot_floor.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

/// Grouped column chart: weekdays on the category axis; one [ColumnSeries] per
/// user (side‑by‑side clusters).
///
/// Rendering layout:
/// - The Syncfusion `Legend` is **disabled**; legend chips are rendered above
///   the chart in a [Wrap] so they stay visible (and don't scroll horizontally
///   with the plot when the chart overflows).
/// - The chart is wrapped in a [ChartHorizontalScrollShell] only when the
///   minimum cluster width × weekday count exceeds the available width.
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

  static const double _kGroupedChartAnimationMs = 350;

  /// Logical-pixel floor per **bar**, so a cluster with N series gets at least
  /// `N × _kPerBarSlot` of horizontal space (clamped to keep the chart usable
  /// even with a single user).
  static const double _kPerBarSlot = 18;

  static const double _kMinCategoryWidthFloor = 88;

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
    final semanticsCoordinatorLabel = semanticsParts.isEmpty
        ? null
        : semanticsParts.join(' ');

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

    final seriesCount = math.max(1, model.userNames.length);
    final categoryCount = math.max(1, model.weekdayCategoryLabels.length);

    final plotHeight =
        tokens.chartStandardHeight + tokens.contentSpacing * 2 + tokens.gapMd;

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
          animationDuration: _kGroupedChartAnimationMs,
        ),
      );
    }

    Widget buildCartesian(double width, double height) {
      return SizedBox(
        width: width,
        height: height,
        child: SfCartesianChart(
          margin: const EdgeInsets.fromLTRB(4, 8, 4, 4),
          plotAreaBorderWidth: 0,
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
    }

    final minCategoryWidth = math.max(
      _kMinCategoryWidthFloor,
      seriesCount * _kPerBarSlot,
    );

    final chart = LayoutBuilder(
      builder: (context, constraints) {
        var layoutW =
            constraints.hasBoundedWidth &&
                constraints.maxWidth.isFinite &&
                constraints.maxWidth > 0
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        if (!layoutW.isFinite || layoutW <= 0) {
          layoutW = minCategoryWidth * categoryCount;
        }
        final requiredW = math.max(layoutW, minCategoryWidth * categoryCount);
        final needsScroll = requiredW > layoutW + 0.5;
        final scrollSlot = chartHorizontalScrollBottomTrackSlotHeight(context);
        final chartBodyH = needsScroll ? plotHeight - scrollSlot : plotHeight;

        var body = buildCartesian(
          needsScroll ? requiredW : layoutW,
          chartBodyH,
        );
        if (needsScroll) {
          body = ChartHorizontalScrollShell(
            body,
            bottomTrackSlot: scrollSlot,
            semanticsHint: l10n.overviewComparisonBarHorizontalScrollHint,
          );
        }

        return SizedBox(height: plotHeight, child: body);
      },
    );

    final showsLegend = model.userNames.isNotEmpty;
    final externalLegend = showsLegend
        ? Padding(
            padding: EdgeInsets.only(top: tokens.gapSm, bottom: tokens.gapSm),
            child: _GroupedChartLegend(
              userNames: model.userNames,
              chartTheme: chartTheme,
            ),
          )
        : SizedBox(height: tokens.gapSm);

    final mediaPlatform = Theme.of(context).platform;
    final isMobilePlatform =
        mediaPlatform == TargetPlatform.android ||
        mediaPlatform == TargetPlatform.iOS ||
        mediaPlatform == TargetPlatform.fuchsia;

    final children = <Widget>[
      externalLegend,
      LayoutBuilder(
        builder: (context, constraints) {
          final layoutW = constraints.hasBoundedWidth
              ? constraints.maxWidth
              : MediaQuery.sizeOf(context).width;
          final wouldScroll =
              (minCategoryWidth * categoryCount) > layoutW + 0.5;
          if (!wouldScroll || !isMobilePlatform) {
            return chart;
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              chart,
              Padding(
                padding: EdgeInsets.only(top: tokens.gapSm),
                child: Text(
                  l10n.chartComparisonPanGestureHint,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ];

    if (model.combinedRemainingUsers) {
      children.add(
        Padding(
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
        ),
      );
    }

    Widget shellChild = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
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

/// Wrap-based legend rendered outside the Syncfusion chart so it stays inside
/// the visible width even when the plot scrolls horizontally.
class _GroupedChartLegend extends StatelessWidget {
  const _GroupedChartLegend({
    required this.userNames,
    required this.chartTheme,
  });

  final List<String> userNames;
  final AppChartTheme chartTheme;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodySmall;
    return Wrap(
      spacing: 12,
      runSpacing: 6,
      children: <Widget>[
        for (var i = 0; i < userNames.length; i++)
          _LegendChip(
            color: chartTheme.paletteColor(i),
            label: truncateLegendUserName(userNames[i]),
            textStyle: textStyle,
          ),
      ],
    );
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({
    required this.color,
    required this.label,
    required this.textStyle,
  });

  final Color color;
  final String label;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.all(Radius.circular(3)),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: textStyle),
      ],
    );
  }
}

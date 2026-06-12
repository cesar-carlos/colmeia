import 'dart:math' as math;

import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/features/overview/presentation/widgets/weekday_user_grouped_chart_data.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_shell.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_theme.dart';
import 'package:colmeia/shared/widgets/charts/app_grouped_column_chart.dart';
import 'package:colmeia/shared/widgets/charts/app_grouped_column_chart_series.dart';
import 'package:colmeia/shared/widgets/charts/comparison_bar_plot_floor.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Grouped column chart: weekdays on the category axis; one series per user.
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
    this.onShare,
    this.openShareTooltip,
    this.openShareSemanticLabel,
    this.onOpenFullscreen,
    this.useChartShell = true,
    this.chartHeightOverride,
    this.expandPlotVertically = false,
    this.animationDurationMs,
    this.isLoading = false,
    this.emptyPlaceholder,
    this.semanticsLabel,
    this.semanticsHint,
    this.semanticsValue,
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
  final VoidCallback? onShare;
  final String? openShareTooltip;
  final String? openShareSemanticLabel;
  final VoidCallback? onOpenFullscreen;
  final bool useChartShell;
  final double? chartHeightOverride;
  final bool expandPlotVertically;
  final int? animationDurationMs;
  final bool isLoading;
  final Widget? emptyPlaceholder;
  final String? semanticsLabel;
  final String? semanticsHint;
  final String? semanticsValue;

  @override
  Widget build(BuildContext context) {
    final localeName = l10n.localeName;
    final salesCountFormat = NumberFormat.decimalPattern(localeName);
    final chartTheme = AppChartTheme.fromContext(
      context,
      preset: AppChartPreset.standard,
    );
    final colorScheme = Theme.of(context).colorScheme;

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
      if (t.isNotEmpty) semanticsParts.add(t);
    }
    if (hasExtremeSpread) {
      final t = extremeSpreadAccessibilityNotice.trim();
      if (t.isNotEmpty) semanticsParts.add(t);
    }
    final coordinatorLabel = semanticsParts.isEmpty
        ? semanticsLabel
        : [
            if (semanticsLabel != null && semanticsLabel!.trim().isNotEmpty)
              semanticsLabel!.trim(),
            ...semanticsParts,
          ].join(' ');

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

    assert(
      !expandPlotVertically || !useChartShell,
      'expandPlotVertically is only supported when useChartShell is false.',
    );

    final seriesCount = math.max(1, model.userNames.length);
    final categorySlotWidth =
        AppGroupedColumnChartLayout.clusteredCategorySlotWidth(
          seriesCount,
        );
    final categories = weekdayUserGroupedCategories(model);
    final groupedSeries =
        <AppGroupedColumnChartSeries<WeekdayUserGroupedCategory>>[
          for (var s = 0; s < model.userNames.length; s++)
            AppGroupedColumnChartSeries<WeekdayUserGroupedCategory>(
              name: truncateLegendUserName(model.userNames[s]),
              color: chartTheme.paletteColor(s),
              valueMapper: (category) => category.cells[s].plottedY.toDouble(),
            ),
        ];

    final yFormat = isSalesCount
        ? NumberFormat.decimalPattern(localeName)
        : AppBrFormatters.compactCurrencyFormatForLocale(localeName);

    final animMs =
        animationDurationMs ??
        AppGroupedColumnChartLayout.defaultCartesianAnimationMs;

    Widget buildGroupedPlot(double plotH) {
      return AppGroupedColumnChart<WeekdayUserGroupedCategory>(
        items: categories,
        xLabelBuilder: (category) => category.label,
        series: groupedSeries,
        primaryAxisFormat: yFormat,
        secondaryAxisFormat: yFormat,
        height: plotH,
        showLegend: false,
        isLoading: isLoading,
        emptyPlaceholder: emptyPlaceholder,
        semanticsLabel: coordinatorLabel,
        semanticsHint: semanticsHint,
        semanticsValue: semanticsValue,
        loadingLabel: l10n.overviewComparisonChartLoading,
        categorySlotWidth: categorySlotWidth,
        horizontalScrollSemanticsHint:
            l10n.overviewComparisonBarHorizontalScrollHint,
        animationDuration: Duration(milliseconds: animMs),
        tooltipBuilder: (data, point, series, pointIndex, seriesIndex) {
          final category = data as WeekdayUserGroupedCategory;
          final d = category.cells[seriesIndex];
          final day = d.weekdayCategoryLabel;
          final user = model.userNames[seriesIndex].trim().isEmpty
              ? '—'
              : model.userNames[seriesIndex].trim();
          return Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              l10n.overviewWeekdayUserSalesTooltip(
                day,
                user,
                salesCountFormat.format(d.salesCount),
                AppBrFormatters.currency(d.salesAmount),
              ),
              style: TextStyle(color: colorScheme.onInverseSurface),
            ),
          );
        },
      );
    }

    final plotHeight = expandPlotVertically
        ? 0.0
        : (chartHeightOverride ??
              (tokens.chartStandardHeight +
                  tokens.contentSpacing * 2 +
                  tokens.gapMd));

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

    Widget wrapWithPanHintIfNeeded({
      required double layoutW,
      required Widget plotSlot,
    }) {
      final wouldScroll =
          (categorySlotWidth * math.max(1, categories.length)) > layoutW + 0.5;
      if (!wouldScroll || !isMobilePlatform) {
        return plotSlot;
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          plotSlot,
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
    }

    final truncationFootnote = model.combinedRemainingUsers
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

    Widget shellChild;
    if (expandPlotVertically) {
      final flexChildren = <Widget>[
        externalLegend,
        Expanded(
          child: LayoutBuilder(
            builder: (context, expandedConstraints) {
              final layoutW =
                  expandedConstraints.hasBoundedWidth &&
                      expandedConstraints.maxWidth.isFinite &&
                      expandedConstraints.maxWidth > 0
                  ? expandedConstraints.maxWidth
                  : MediaQuery.sizeOf(context).width;
              final wouldScroll =
                  (categorySlotWidth * math.max(1, categories.length)) >
                  layoutW + 0.5;
              final wantsPanHint = wouldScroll && isMobilePlatform;
              final panHintBlock =
                  wantsPanHint && expandedConstraints.maxHeight >= 140
                  ? tokens.gapSm + 40.0
                  : 0.0;
              final plotH = expandedConstraints.maxHeight - panHintBlock < 1
                  ? 1.0
                  : expandedConstraints.maxHeight - panHintBlock;
              final core = buildGroupedPlot(plotH);
              if (panHintBlock <= 0) {
                return core;
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  core,
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
        ),
      ];
      if (truncationFootnote != null) {
        flexChildren.add(truncationFootnote);
      }
      shellChild = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: flexChildren,
      );
    } else {
      final chart = SizedBox(
        height: plotHeight,
        child: buildGroupedPlot(plotHeight),
      );

      final children = <Widget>[
        externalLegend,
        LayoutBuilder(
          builder: (context, constraints) {
            final layoutW = constraints.hasBoundedWidth
                ? constraints.maxWidth
                : MediaQuery.sizeOf(context).width;
            return wrapWithPanHintIfNeeded(
              layoutW: layoutW,
              plotSlot: chart,
            );
          },
        ),
      ];
      if (truncationFootnote != null) {
        children.add(truncationFootnote);
      }
      shellChild = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      );
    }

    if (!useChartShell) {
      return shellChild;
    }

    return AppChartShell(
      title: title,
      subtitle: subtitle,
      belowSubtitle: belowSubtitle,
      titleTrailing: floorTrailing,
      onShare: onShare,
      openShareTooltip: openShareTooltip,
      openShareSemanticLabel: openShareSemanticLabel,
      onOpenFullscreen: onOpenFullscreen,
      shareEnabled: !isLoading,
      child: shellChild,
    );
  }
}

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

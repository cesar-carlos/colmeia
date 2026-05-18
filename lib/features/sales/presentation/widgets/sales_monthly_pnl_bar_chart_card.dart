import 'dart:async';

import 'package:colmeia/app/router/app_chart_fullscreen_routes.dart';
import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/features/overview/presentation/widgets/overview_bar_chart_style.dart';
import 'package:colmeia/features/overview/presentation/widgets/overview_lucratividade_percent_metrics.dart';
import 'package:colmeia/features/sales/domain/entities/sales_monthly_pnl_point.dart';
import 'package:colmeia/features/sales/domain/sales_monthly_pnl_bar_chart_preferences.dart';
import 'package:colmeia/features/sales/domain/sales_monthly_pnl_point_percent_metric.dart';
import 'package:colmeia/features/sales/presentation/sales_monthly_pnl_chart_keys.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_shell.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_theme.dart';
import 'package:colmeia/shared/widgets/charts/app_comparison_bar_chart.dart';
import 'package:colmeia/shared/widgets/charts/app_grouped_column_chart.dart';
import 'package:colmeia/shared/widgets/charts/engines/chart_engine_defaults.dart';
import 'package:colmeia/shared/widgets/charts/engines/chart_engine_states.dart';
import 'package:colmeia/shared/widgets/forms/app_segmented_control.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';

class SalesMonthlyPnlBarChartCard extends StatefulWidget {
  const SalesMonthlyPnlBarChartCard({
    required this.l10n,
    required this.points,
    required this.loadFailed,
    required this.isLoading,
    required this.initialSession,
    required this.persistSession,
    super.key,
    this.loadFailureMessage,
    this.onOpenFullscreen,
  });

  final AppLocalizations l10n;
  final List<SalesMonthlyPnlPoint> points;
  final bool loadFailed;
  final bool isLoading;
  final SalesMonthlyPnlBarChartPreferences initialSession;
  final Future<void> Function(SalesMonthlyPnlBarChartPreferences session)
  persistSession;
  final String? loadFailureMessage;
  final VoidCallback? onOpenFullscreen;

  @override
  State<SalesMonthlyPnlBarChartCard> createState() =>
      _SalesMonthlyPnlBarChartCardState();
}

class _SalesMonthlyPnlBarChartCardState
    extends State<SalesMonthlyPnlBarChartCard> {
  late SalesMonthlyPnlBarChartPreferences _session;

  @override
  void initState() {
    super.initState();
    _session = widget.initialSession;
  }

  Future<void> _persistSession(SalesMonthlyPnlBarChartPreferences next) async {
    await widget.persistSession(next);
  }

  void _setSession(SalesMonthlyPnlBarChartPreferences next) {
    setState(() => _session = next);
    unawaited(_persistSession(next));
  }

  String _formatMonthLong(SalesMonthlyPnlPoint p, String locale) {
    return DateFormat.yMMM(locale).format(DateTime(p.year, p.month));
  }

  String _semanticsSummary(
    AppLocalizations l10n,
    List<SalesMonthlyPnlPoint> pts,
  ) {
    if (pts.isEmpty) {
      return '';
    }
    final locale = l10n.localeName;
    var totalVenda = 0.0;
    var totalLucro = 0.0;
    var totalCusto = 0.0;
    var top = pts.first;
    for (final p in pts) {
      totalVenda += p.venda;
      totalLucro += p.lucro;
      totalCusto += p.custoMercadoria;
      if (p.venda > top.venda) {
        top = p;
      }
    }
    return l10n.salesMonthlyPnlBarSummarySemantics(
      AppBrFormatters.smartCompactCurrencyForLocale(totalVenda, locale),
      AppBrFormatters.smartCompactCurrencyForLocale(totalLucro, locale),
      AppBrFormatters.smartCompactCurrencyForLocale(totalCusto, locale),
      _formatMonthLong(top, locale),
      AppBrFormatters.smartCompactCurrencyForLocale(top.venda, locale),
    );
  }

  bool _valuesAllZero(List<SalesMonthlyPnlPoint> pts) {
    for (final p in pts) {
      if (p.venda != 0 || p.lucro != 0 || p.custoMercadoria != 0) {
        return false;
      }
    }
    return true;
  }

  bool _percentAllZero(
    List<SalesMonthlyPnlPoint> pts,
    LucratividadePercentMetric metric,
  ) {
    for (final p in pts) {
      if (p.metricBarValue(metric) != 0) {
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final theme = Theme.of(context);
    final localeTag = l10n.localeName;
    final emptyMessage = widget.loadFailed
        ? (widget.loadFailureMessage ?? l10n.salesMonthlyPnlLoadFailed)
        : l10n.salesMonthlyPnlEmpty;
    final chartTheme = AppChartTheme.fromContext(
      context,
      preset: AppChartPreset.standard,
    );
    final resolvedHeight = chartTheme.height;
    final primaryMoney = AppBrFormatters.compactCurrencyFormatForLocale(
      localeTag,
    );
    final gridLineColor = theme.colorScheme.outlineVariant.withValues(
      alpha: 0.35,
    );

    final percentMetric = _session.percentMetric;

    final percentRatioFormat = NumberFormat.decimalPercentPattern(
      locale: localeTag,
      decimalDigits: 1,
    );

    void openBarFullscreen() {
      unawaited(
        pushSalesMonthlyPnlBarChartFullscreen(
          context: context,
          points: List<SalesMonthlyPnlPoint>.of(
            widget.points,
            growable: false,
          ),
          initialSession: _session,
          isLoading: widget.isLoading,
          loadFailed: widget.loadFailed,
          loadFailureMessage: widget.loadFailureMessage,
        ),
      );
    }

    final summary = _semanticsSummary(l10n, widget.points);

    return Semantics(
      container: true,
      label: l10n.salesMonthlyPnlBarChartSemantics,
      value: summary.isEmpty ? null : summary,
      child: _SalesMonthlyPnlBarChartBody(
        l10n: l10n,
        points: widget.points,
        loadFailed: widget.loadFailed,
        loadFailureMessage: widget.loadFailureMessage,
        isLoading: widget.isLoading,
        session: _session,
        onSessionChanged: _setSession,
        chartHeightOverride: resolvedHeight,
        emptyMessage: emptyMessage,
        summarySemantics: summary,
        tokens: tokens,
        theme: theme,
        chartTheme: chartTheme,
        localeTag: localeTag,
        primaryMoney: primaryMoney,
        gridLineColor: gridLineColor,
        percentRatioFormat: percentRatioFormat,
        openFullscreen: widget.onOpenFullscreen ?? openBarFullscreen,
        valuesAllZero: () => _valuesAllZero(widget.points),
        percentAllZero: () => _percentAllZero(widget.points, percentMetric),
        useChartShell: true,
      ),
    );
  }
}

extension SalesMonthlyPnlBarChartPreferencesCopy
    on SalesMonthlyPnlBarChartPreferences {
  SalesMonthlyPnlBarChartPreferences copyWith({
    SalesMonthlyPnlBarDisplayMode? displayMode,
    LucratividadePercentMetric? percentMetric,
  }) {
    return SalesMonthlyPnlBarChartPreferences(
      displayMode: displayMode ?? this.displayMode,
      percentMetric: percentMetric ?? this.percentMetric,
    );
  }
}

class _SalesMonthlyPnlBarChartBody extends StatelessWidget {
  const _SalesMonthlyPnlBarChartBody({
    required this.l10n,
    required this.points,
    required this.loadFailed,
    required this.isLoading,
    required this.session,
    required this.chartHeightOverride,
    required this.useChartShell,
    this.loadFailureMessage,
    this.onSessionChanged,
    this.emptyMessage,
    this.summarySemantics,
    this.tokens,
    this.theme,
    this.chartTheme,
    this.localeTag,
    this.primaryMoney,
    this.gridLineColor,
    this.percentRatioFormat,
    this.openFullscreen,
    this.valuesAllZero,
    this.percentAllZero,
  });

  final AppLocalizations l10n;
  final List<SalesMonthlyPnlPoint> points;
  final bool loadFailed;
  final bool isLoading;
  final SalesMonthlyPnlBarChartPreferences session;
  final double chartHeightOverride;
  final bool useChartShell;
  final String? loadFailureMessage;
  final ValueChanged<SalesMonthlyPnlBarChartPreferences>? onSessionChanged;
  final String? emptyMessage;
  final String? summarySemantics;
  final AppThemeTokens? tokens;
  final ThemeData? theme;
  final AppChartTheme? chartTheme;
  final String? localeTag;
  final NumberFormat? primaryMoney;
  final Color? gridLineColor;
  final NumberFormat? percentRatioFormat;
  final VoidCallback? openFullscreen;
  final bool Function()? valuesAllZero;
  final bool Function()? percentAllZero;

  String _monthShort(SalesMonthlyPnlPoint p, String locale) {
    return DateFormat('MMM/yy', locale).format(DateTime(p.year, p.month));
  }

  String _monthLong(SalesMonthlyPnlPoint p, String locale) {
    return DateFormat.yMMM(locale).format(DateTime(p.year, p.month));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = this.l10n;
    final theme = this.theme ?? Theme.of(context);
    final tokens = this.tokens ?? theme.extension<AppThemeTokens>()!;
    final chartTheme =
        this.chartTheme ??
        AppChartTheme.fromContext(context, preset: AppChartPreset.standard);
    final localeTag = this.localeTag ?? l10n.localeName;
    final primaryMoney =
        this.primaryMoney ??
        AppBrFormatters.compactCurrencyFormatForLocale(localeTag);
    final gridLineColor =
        this.gridLineColor ??
        theme.colorScheme.outlineVariant.withValues(alpha: 0.35);
    final percentRatioFormat =
        this.percentRatioFormat ??
        NumberFormat.decimalPercentPattern(
          locale: localeTag,
          decimalDigits: 1,
        );

    final emptyMsg = loadFailed
        ? (loadFailureMessage ?? l10n.salesMonthlyPnlLoadFailed)
        : (emptyMessage ?? l10n.salesMonthlyPnlEmpty);

    final isPercent =
        session.displayMode == SalesMonthlyPnlBarDisplayMode.percent;
    final metric = session.percentMetric;

    final showZerosOnly =
        points.isNotEmpty &&
        !loadFailed &&
        (isPercent
            ? percentAllZero?.call() ?? false
            : valuesAllZero?.call() ?? false);

    Widget chartBody;
    if (isLoading) {
      chartBody = buildChartLoadingState(
        context: context,
        height: chartHeightOverride,
        indicatorColor: chartTheme.primaryColor,
        label: l10n.overviewComparisonChartLoading,
        variant: ChartLoadingPlaceholderVariant.timeSeries,
      );
    } else if (points.isEmpty) {
      chartBody = buildChartEmptyState(
        context: context,
        height: chartHeightOverride,
        message: emptyMsg,
        placeholder: Padding(
          padding: EdgeInsets.symmetric(vertical: tokens.contentSpacing),
          child: Center(
            child: Text(
              emptyMsg,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ),
      );
    } else if (showZerosOnly) {
      chartBody = buildChartEmptyState(
        context: context,
        height: chartHeightOverride,
        message: l10n.salesMonthlyPnlBarZerosOnlyMessage,
        placeholder: Padding(
          padding: EdgeInsets.symmetric(horizontal: tokens.contentSpacing),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: theme.colorScheme.outline,
                ),
                SizedBox(width: tokens.gapSm),
                Expanded(
                  child: Text(
                    l10n.salesMonthlyPnlBarZerosOnlyMessage,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else if (isPercent) {
      final animMs = resolveChartAnimationDurationMs(
        context: context,
        styleDuration: const Duration(milliseconds: 150),
        defaultMs: AppChartEngineAnimationDefaults.cartesianSeriesMs,
      );
      chartBody = AppComparisonBarChart<SalesMonthlyPnlPoint>(
        items: points,
        plotFloorAccessibilityNotice: l10n.chartComparisonPlotFloorNotice,
        extremeSpreadAccessibilityNotice:
            l10n.chartComparisonExtremeValueSpreadNotice,
        labelBuilder: (p) => _monthShort(p, localeTag),
        valueBuilder: (p) => p.metricBarValue(metric) / 100.0,
        tooltipLabelBuilder: (p, ratio) {
          final line =
              metric == LucratividadePercentMetric.markupOverCost &&
                  p.custoMercadoria <= 0
              ? '${l10n.overviewLucratividadePercentSeriesMarkupLabel}: ${l10n.overviewLucratividadeMarkupUndefinedTooltip}'
              : '${lucratividadePercentBarSeriesLabel(l10n, metric)}: ${percentRatioFormat.format(ratio)}';
          return '${_monthLong(p, localeTag)}\n$line';
        },
        dataLabelBuilder: (_, ratio) => percentRatioFormat.format(ratio),
        style: _comparisonStyleWithPercent(
          tokens: tokens,
          l10n: l10n,
          chartHeightOverride: chartHeightOverride,
          animationMs: animMs,
          percentRatioFormat: percentRatioFormat,
        ),
      );
    } else {
      chartBody = AppGroupedColumnChart<SalesMonthlyPnlPoint>(
        items: points,
        xLabelBuilder: (p) => _monthShort(p, localeTag),
        salesValue: (p) => p.venda,
        profitValue: (p) => p.lucro,
        costValue: (p) => p.custoMercadoria,
        salesLabel: l10n.salesMonthlyPnlSeriesSalesLabel,
        profitLabel: l10n.salesMonthlyPnlSeriesProfitLabel,
        costLabel: l10n.salesMonthlyPnlSeriesCostLabel,
        salesColor: chartTheme.primaryColor,
        profitColor: chartTheme.paletteColor(1),
        costColor: chartTheme.paletteColor(2),
        primaryAxisFormat: primaryMoney,
        secondaryAxisFormat: primaryMoney,
        height: chartHeightOverride,
        gridLineColor: gridLineColor,
        horizontalScrollShellKey:
            SalesMonthlyPnlChartKeys.barHorizontalScrollShell,
        horizontalScrollSemanticsHint:
            l10n.overviewComparisonBarHorizontalScrollHint,
        tooltipBuilder: (data, point, series, pointIndex, seriesIndex) {
          final p = data as SalesMonthlyPnlPoint;
          final label = switch (seriesIndex) {
            1 => l10n.salesMonthlyPnlSeriesProfitLabel,
            2 => l10n.salesMonthlyPnlSeriesCostLabel,
            _ => l10n.salesMonthlyPnlSeriesSalesLabel,
          };
          final value = switch (seriesIndex) {
            1 => p.lucro,
            2 => p.custoMercadoria,
            _ => p.venda,
          };
          return Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _monthLong(p, localeTag),
                  style: TextStyle(
                    color: theme.colorScheme.onInverseSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$label: ${AppBrFormatters.smartCompactCurrencyForLocale(value, localeTag)}',
                  style: TextStyle(
                    color: theme.colorScheme.onInverseSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    final mainModeControl = salesMonthlyPnlBarDisplayModeSegmented(
      l10n: l10n,
      value: session.displayMode,
      onChanged: onSessionChanged == null
          ? null
          : (v) => onSessionChanged!(session.copyWith(displayMode: v)),
    );

    final percentSection =
        session.displayMode == SalesMonthlyPnlBarDisplayMode.percent
        ? Semantics(
            sortKey: const OrdinalSortKey(2),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final narrow = constraints.maxWidth < 380;
                return OverviewLucratividadePercentMetricSection(
                  l10n: l10n,
                  tokens: tokens,
                  metric: session.percentMetric,
                  useDropdownLayout: narrow,
                  hasChartData: points.isNotEmpty,
                  showChronologicalHint: true,
                  onMetricChanged: onSessionChanged == null
                      ? (_) {}
                      : (v) => onSessionChanged!(
                          session.copyWith(percentMetric: v),
                        ),
                );
              },
            ),
          )
        : const SizedBox.shrink();

    final belowSubtitle = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        mainModeControl,
        if (session.displayMode ==
            SalesMonthlyPnlBarDisplayMode.percent) ...<Widget>[
          SizedBox(height: tokens.gapSm),
          percentSection,
        ],
      ],
    );

    final surface = useChartShell
        ? AppChartShell(
            titleWidget: Text(
              l10n.salesMonthlyPnlBarChartTitle,
              style: theme.appTypography.sectionHeaderH2,
            ),
            subtitle: l10n.salesMonthlyPnlBarChartSubtitle,
            onOpenFullscreen: openFullscreen,
            belowSubtitle: onSessionChanged == null ? null : belowSubtitle,
            child: chartBody,
          )
        : chartBody;

    if (useChartShell) {
      return surface;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (onSessionChanged != null) belowSubtitle,
        Expanded(child: chartBody),
      ],
    );
  }
}

AppComparisonBarChartStyle _comparisonStyleWithPercent({
  required AppThemeTokens tokens,
  required AppLocalizations l10n,
  required double chartHeightOverride,
  required double animationMs,
  required NumberFormat percentRatioFormat,
}) {
  final base = overviewHomeComparisonBarChartStyle(
    tokens: tokens,
    kind: OverviewHomeBarChartKind.weekday,
    l10n: l10n,
    heightOverride: chartHeightOverride,
  );
  return AppComparisonBarChartStyle(
    barColor: base.barColor,
    barBorderRadius: base.barBorderRadius,
    height: base.height,
    barWidth: base.barWidth,
    spacing: base.spacing,
    barGap: base.barGap,
    borderColor: base.borderColor,
    borderWidth: base.borderWidth,
    plotAreaBackgroundColor: base.plotAreaBackgroundColor,
    chartPadding: base.chartPadding,
    animationDuration: Duration(milliseconds: animationMs.round()),
    yAxisFormat: percentRatioFormat,
    showXAxis: base.showXAxis,
    showYAxis: base.showYAxis,
    xLabelRotation: base.xLabelRotation,
    axisLabelTextStyle: base.axisLabelTextStyle,
    minY: base.minY,
    maxY: base.maxY,
    interval: base.interval,
    yAxisRangePadding: base.yAxisRangePadding,
    yAxisTitle: base.yAxisTitle,
    xAxisTitle: base.xAxisTitle,
    showTooltip: base.showTooltip,
    showYGridLines: base.showYGridLines,
    showDataLabels: base.showDataLabels,
    dataLabelTextStyle: base.dataLabelTextStyle,
    dataLabelAlignment: base.dataLabelAlignment,
    dataLabelOffset: base.dataLabelOffset,
    autoRotateXLabels: base.autoRotateXLabels,
    xLabelMaxChars: base.xLabelMaxChars,
    wrapXAxisLabelsInTwoLines: base.wrapXAxisLabelsInTwoLines,
    wrapXAxisCharsPerLine: base.wrapXAxisCharsPerLine,
    wrapXAxisMaxLines: base.wrapXAxisMaxLines,
    loadingLabel: base.loadingLabel,
    emptyMessage: base.emptyMessage,
    enableAutoScroll: base.enableAutoScroll,
    minBarWidth: base.minBarWidth,
    showScrollFade: base.showScrollFade,
    horizontalScrollSemanticsHint: base.horizontalScrollSemanticsHint,
    tooltipLabelMaxChars: base.tooltipLabelMaxChars,
    stickyPrimaryYAxisWhileScrolling: base.stickyPrimaryYAxisWhileScrolling,
    stickyPrimaryYAxisWidth: base.stickyPrimaryYAxisWidth,
    minPlottedValueShareOfMax: base.minPlottedValueShareOfMax,
    strictLinearBarHeights: base.strictLinearBarHeights,
    categoryAutoScrollingDelta: base.categoryAutoScrollingDelta,
    categoryAutoScrollingMode: base.categoryAutoScrollingMode,
    categoryViewportFootnote: base.categoryViewportFootnote,
    categoryViewportPanSemanticsLabel: base.categoryViewportPanSemanticsLabel,
    reserveOuterDataLabelTopMargin: base.reserveOuterDataLabelTopMargin,
    outerDataLabelTopReserve: base.outerDataLabelTopReserve,
    dataLabelBackgroundColor: base.dataLabelBackgroundColor,
    enableTapHighlight: base.enableTapHighlight,
    tapHighlightDimmedOpacity: base.tapHighlightDimmedOpacity,
  );
}

Widget salesMonthlyPnlBarDisplayModeSegmented({
  required AppLocalizations l10n,
  required SalesMonthlyPnlBarDisplayMode value,
  required ValueChanged<SalesMonthlyPnlBarDisplayMode>? onChanged,
}) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final narrow = constraints.maxWidth < 340;
      return Semantics(
        sortKey: const OrdinalSortKey(1),
        child: AppSegmentedControl<SalesMonthlyPnlBarDisplayMode>(
          expandToFill: true,
          options: <AppSegmentedControlOption<SalesMonthlyPnlBarDisplayMode>>[
            AppSegmentedControlOption<SalesMonthlyPnlBarDisplayMode>(
              value: SalesMonthlyPnlBarDisplayMode.amounts,
              label: narrow
                  ? l10n.salesMonthlyPnlBarDisplayValuesCompactLabel
                  : l10n.salesMonthlyPnlBarDisplayValuesLabel,
              tooltip: narrow
                  ? l10n.salesMonthlyPnlBarDisplayValuesLabel
                  : null,
            ),
            AppSegmentedControlOption<SalesMonthlyPnlBarDisplayMode>(
              value: SalesMonthlyPnlBarDisplayMode.percent,
              label: narrow
                  ? l10n.salesMonthlyPnlBarDisplayPercentCompactLabel
                  : l10n.salesMonthlyPnlBarDisplayPercentLabel,
              tooltip: narrow
                  ? l10n.salesMonthlyPnlBarDisplayPercentLabel
                  : null,
            ),
          ],
          value: value,
          onChanged: onChanged,
        ),
      );
    },
  );
}

Future<void> pushSalesMonthlyPnlBarChartFullscreen({
  required BuildContext context,
  required List<SalesMonthlyPnlPoint> points,
  required SalesMonthlyPnlBarChartPreferences initialSession,
  required bool isLoading,
  required bool loadFailed,
  String? loadFailureMessage,
  String? filterSummary,
}) {
  final pageL10n = AppLocalizations.of(context);
  return context.pushChartFullscreen<void>(
    extra: AppChartFullscreenRouteExtra(
      title: pageL10n.salesMonthlyPnlBarChartTitle,
      subtitle: pageL10n.salesMonthlyPnlBarChartSubtitle,
      filterSummary: filterSummary,
      chartSemanticsLabel: pageL10n.salesMonthlyPnlBarChartSemantics,
      chartBuilder: (fullscreenContext) {
        final l10nFs = AppLocalizations.of(fullscreenContext);
        final tokensFs = Theme.of(
          fullscreenContext,
        ).extension<AppThemeTokens>()!;
        final sessionHolder = <SalesMonthlyPnlBarChartPreferences>[
          initialSession,
        ];
        return StatefulBuilder(
          builder: (context, setFs) {
            final fsSession = sessionHolder[0];
            final isPct =
                fsSession.displayMode == SalesMonthlyPnlBarDisplayMode.percent;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                salesMonthlyPnlBarDisplayModeSegmented(
                  l10n: l10nFs,
                  value: fsSession.displayMode,
                  onChanged: (v) => setFs(() {
                    sessionHolder[0] = sessionHolder[0].copyWith(
                      displayMode: v,
                    );
                  }),
                ),
                if (isPct) ...<Widget>[
                  SizedBox(height: tokensFs.gapSm),
                  Semantics(
                    sortKey: const OrdinalSortKey(2),
                    child: LayoutBuilder(
                      builder: (context, c2) {
                        final narrow = c2.maxWidth < 380;
                        return OverviewLucratividadePercentMetricSection(
                          l10n: l10nFs,
                          tokens: tokensFs,
                          metric: fsSession.percentMetric,
                          useDropdownLayout: narrow,
                          hasChartData: points.isNotEmpty,
                          showChronologicalHint: true,
                          onMetricChanged: (v) => setFs(() {
                            sessionHolder[0] = sessionHolder[0].copyWith(
                              percentMetric: v,
                            );
                          }),
                        );
                      },
                    ),
                  ),
                ],
                SizedBox(height: tokensFs.contentSpacing),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, innerConstraints) {
                      final chartH = innerConstraints.maxHeight.isFinite
                          ? innerConstraints.maxHeight
                          : 220.0;
                      return _SalesMonthlyPnlBarChartBody(
                        l10n: l10nFs,
                        points: points,
                        loadFailed: loadFailed,
                        loadFailureMessage: loadFailureMessage,
                        isLoading: isLoading,
                        session: sessionHolder[0],
                        chartHeightOverride: chartH,
                        useChartShell: false,
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    ),
  );
}

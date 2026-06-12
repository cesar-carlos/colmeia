import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/features/agent_queries/domain/entities/lucratividade_percent_metric.dart';
import 'package:colmeia/features/agent_queries/presentation/lucratividade_percent_metric_labels.dart';
import 'package:colmeia/features/agent_queries/presentation/widgets/agent_query_chart_failure_placeholder_content.dart';
import 'package:colmeia/features/agent_queries/presentation/widgets/dashboard_lucratividade_percent_metrics.dart';
import 'package:colmeia/features/sales/domain/entities/sales_monthly_pnl_point.dart';
import 'package:colmeia/features/sales/domain/sales_monthly_pnl_bar_chart_preferences.dart';
import 'package:colmeia/features/sales/domain/sales_monthly_pnl_point_percent_metric.dart';
import 'package:colmeia/features/sales/presentation/sales_monthly_pnl_chart_keys.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_monthly_pnl_bar_chart_controls.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_monthly_pnl_grouped_column_series.dart';
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
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:intl/intl.dart';

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

class SalesMonthlyPnlBarChartBody extends StatelessWidget {
  const SalesMonthlyPnlBarChartBody({
    required this.l10n,
    required this.points,
    required this.loadFailed,
    required this.isLoading,
    required this.session,
    required this.chartHeightOverride,
    required this.useChartShell,
    super.key,
    this.loadFailure,
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
    this.onShare,
    this.valuesAllZero,
    this.percentAllZero,
  });

  final AppLocalizations l10n;
  final List<SalesMonthlyPnlPoint> points;
  final bool loadFailed;
  final AppFailure? loadFailure;
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
  final VoidCallback? onShare;
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
    final tokens = this.tokens ?? theme.appTokens;
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
        placeholder: AgentQueryChartFailurePlaceholderContent(
          emptyMessage: emptyMsg,
          textStyle: theme.textTheme.bodyMedium,
          verticalPadding: tokens.contentSpacing,
          loadFailure: loadFailed ? loadFailure : null,
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
        style: salesMonthlyPnlBarComparisonStyleWithPercent(
          tokens: tokens,
          l10n: l10n,
          chartHeightOverride: chartHeightOverride,
          animationMs: animMs,
          percentRatioFormat: percentRatioFormat,
        ),
      );
    } else {
      final groupedSeries = salesMonthlyPnlGroupedColumnSeries(
        l10n: l10n,
        salesColor: chartTheme.primaryColor,
        profitColor: chartTheme.paletteColor(1),
        costColor: chartTheme.paletteColor(2),
      );
      chartBody = AppGroupedColumnChart<SalesMonthlyPnlPoint>(
        items: points,
        xLabelBuilder: (p) => _monthShort(p, localeTag),
        series: groupedSeries,
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
          final label = groupedSeries[seriesIndex].name;
          final value = groupedSeries[seriesIndex].valueMapper(p);
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
                return DashboardLucratividadePercentMetricSection(
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
            onShare: onShare,
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

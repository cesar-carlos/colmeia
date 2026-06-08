import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/features/agent_queries/presentation/localization/agent_query_failure_l10n.dart';
import 'package:colmeia/features/agent_queries/presentation/widgets/agent_query_chart_failure_placeholder_content.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/charts/daily_sales_trend_chart_labels.dart';
import 'package:colmeia/shared/charts/daily_sales_trend_point.dart';
import 'package:colmeia/shared/charts/daily_sales_weekday_labels.dart';
import 'package:colmeia/shared/charts/metric_toggle_comparison_bar_fullscreen_body.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_fullscreen_request.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_share_request.dart';
import 'package:colmeia/shared/widgets/charts/app_comparison_bar_chart.dart';
import 'package:colmeia/shared/widgets/charts/app_dashboard_comparison_bar_chart_preset.dart';
import 'package:colmeia/shared/widgets/charts/chart_export_capture.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_metadata.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_table_data.dart';
import 'package:colmeia/shared/widgets/forms/app_segmented_control.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum _OverviewDailyMetric {
  salesCount,
  salesAmount,
}

/// Daily sales totals (bar chart) for the overview period or Sales branch/month scope.
class DailySalesTrendChart extends StatefulWidget {
  const DailySalesTrendChart({
    required this.l10n,
    required this.points,
    required this.loadFailed,
    this.isLoading = false,
    this.loadFailure,
    this.loadFailureMessage,
    this.useSalesDailyTotalsLabels = false,
    this.salesSubtitleOverride,
    this.salesScopeHintOverride,
    this.onRequestFullscreen,
    this.onRequestShare,
    super.key,
  });

  final AppLocalizations l10n;
  final List<DailySalesTrendPoint> points;
  final bool loadFailed;
  final bool isLoading;
  final AppFailure? loadFailure;
  final String? loadFailureMessage;

  /// When non-null, enables the fullscreen affordance: the chart emits an
  /// app-agnostic [AppChartFullscreenRequest] that the app layer maps to its
  /// fullscreen route, keeping this shared widget free of `app/` imports.
  final AppChartFullscreenRequestCallback? onRequestFullscreen;

  /// When non-null, enables the share affordance: the chart emits an
  /// app-agnostic [AppChartShareRequest] that the app layer maps to the
  /// platform share sheet, keeping this shared widget free of `app/` imports.
  final AppChartShareRequestCallback? onRequestShare;

  /// When true, chart titles and messages use [DailySalesTrendChartLabels] sales
  /// branch/month strings instead of overview home copy.
  final bool useSalesDailyTotalsLabels;

  /// When [useSalesDailyTotalsLabels] is true, replaces resolved subtitle (e.g. custom date range).
  final String? salesSubtitleOverride;

  /// When [useSalesDailyTotalsLabels] is true, replaces resolved Semantics scope hint.
  final String? salesScopeHintOverride;

  @override
  State<DailySalesTrendChart> createState() =>
      _OverviewDailySalesTrendChartState();
}

class _OverviewDailySalesTrendChartState
    extends State<DailySalesTrendChart> {
  final GlobalKey _shareKey = GlobalKey();

  _OverviewDailyMetric _metric = _OverviewDailyMetric.salesCount;

  List<DailySalesTrendPoint> _chartPointsNonZero() {
    if (_metric == _OverviewDailyMetric.salesCount) {
      return [
        for (final p in widget.points)
          if (p.salesCount > 0) p,
      ];
    }
    return [
      for (final p in widget.points)
        if (p.salesAmount > 0) p,
    ];
  }

  String _dayAxisLabel(DailySalesTrendPoint p) {
    final l10n = widget.l10n;
    final dateLine = AppBrFormatters.shortDate(p.saleDate);
    final dowLine = dailySalesShortWeekdayFromDateTime(l10n, p.saleDate);
    return '$dateLine\n$dowLine';
  }

  String _tooltipDateLine(DailySalesTrendPoint p) {
    final l10n = widget.l10n;
    return '${AppBrFormatters.shortDate(p.saleDate)} · ${dailySalesShortWeekdayFromDateTime(l10n, p.saleDate)}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final labels = DailySalesTrendChartLabels.resolve(
      l10n,
      salesBranchMonth: widget.useSalesDailyTotalsLabels,
    );
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final localeName = Localizations.localeOf(context).toString();
    final salesCountFormat = NumberFormat.decimalPattern(localeName);
    final compactSalesCountFormat = NumberFormat.compact(locale: localeName);
    final isSalesCount = _metric == _OverviewDailyMetric.salesCount;
    final emptyMessage = widget.loadFailed
        ? chartAgentQueryLoadFailureMessage(
            l10n: l10n,
            loadFailure: widget.loadFailure,
            legacyMessage: widget.loadFailureMessage,
            genericFallback: labels.resolveEmptyMessage(
              loadFailed: true,
            ),
          )
        : labels.resolveEmptyMessage(
            loadFailed: false,
          );
    final chartPoints = _chartPointsNonZero();
    final showEmptyPlaceholder = widget.points.isEmpty || chartPoints.isEmpty;

    final resolvedSubtitle = widget.salesSubtitleOverride ?? labels.subtitle;
    final resolvedScopeHint = widget.salesScopeHintOverride ?? labels.scopeHint;

    final onRequestFullscreen = widget.onRequestFullscreen;
    final onRequestShare = widget.onRequestShare;

    ChartShareMetadata shareMetadata({
      required bool isSalesCountMetric,
    }) {
      final shareTitle = labels.titleForMetric(isSalesCount: isSalesCountMetric);
      final inlineStyle = appDashboardComparisonBarChartStyle(
        tokens: tokens,
        kind: AppDashboardComparisonBarChartKind.daily,
        l10n: l10n,
        weekdayUsesCurrencyAxis: !isSalesCountMetric,
        weekdayRevenueDataLabelBackground: isSalesCountMetric
            ? null
            : Theme.of(context).colorScheme.surface,
      );
      return ChartShareMetadata(
        title: shareTitle,
        subtitle: resolvedSubtitle,
        tableData: ChartShareTableData(
          headers: <String>[
            l10n.chartSharePdfColumnDate,
            l10n.chartSharePdfColumnWeekday,
            labels.metricCountLabel,
            labels.metricAmountLabel,
          ],
          rows: <List<String>>[
            for (final point in widget.points)
              <String>[
                AppBrFormatters.shortDate(point.saleDate),
                dailySalesShortWeekdayFromDateTime(l10n, point.saleDate),
                salesCountFormat.format(point.salesCount),
                AppBrFormatters.currency(point.salesAmount),
              ],
          ],
        ),
        subject: shareTitle,
        chartExportBuilder: chartPoints.isEmpty
            ? null
            : (exportContext) {
                final exportStyle = inlineStyle.forPdfExport();
                return wrapCartesianChartForPdfExport(
                  context: exportContext,
                  itemCount: chartPoints.length,
                  minSlotWidth: comparisonBarMinSlotWidth(
                    minBarWidth: exportStyle.minBarWidth,
                  ),
                  height: exportStyle.height,
                  chart: AppComparisonBarChart<DailySalesTrendPoint>(
                    items: chartPoints,
                    plotFloorAccessibilityNotice:
                        l10n.chartComparisonPlotFloorNotice,
                    extremeSpreadAccessibilityNotice:
                        l10n.chartComparisonExtremeValueSpreadNotice,
                    labelBuilder: _dayAxisLabel,
                    valueBuilder: (point) => isSalesCountMetric
                        ? point.salesCount
                        : point.salesAmount,
                    tooltipLabelBuilder: (point, value) => labels.tooltip(
                      _tooltipDateLine(point),
                      salesCountFormat.format(point.salesCount),
                      AppBrFormatters.currency(point.salesAmount),
                    ),
                    dataLabelBuilder: (_, value) => isSalesCountMetric
                        ? compactSalesCountFormat.format(value)
                        : AppBrFormatters.compactCurrency(value),
                    style: exportStyle,
                  ),
                );
              },
      );
    }

    void openFullscreen() {
      final emit = onRequestFullscreen;
      if (emit == null) {
        return;
      }
      final chartPointsSnapshot = List<DailySalesTrendPoint>.of(
        chartPoints,
        growable: false,
      );
      final isSalesCountSnapshot = isSalesCount;
      final isLoadingSnapshot = widget.isLoading;
      final fullscreenShareKey = GlobalKey();
      final metadata = shareMetadata(isSalesCountMetric: isSalesCountSnapshot);
      emit(
        context,
        metadata.toFullscreenRequest(
          semanticsLabel: labels.semanticsForMetric(
            isSalesCount: isSalesCountSnapshot,
          ),
          shareCaptureKey: fullscreenShareKey,
          chartBuilder: (fullscreenContext) {
            final fullscreenTokens = Theme.of(
              fullscreenContext,
            ).extension<AppThemeTokens>()!;
            var fullscreenMetric = _metric;
            return RepaintBoundary(
              key: fullscreenShareKey,
              child: StatefulBuilder(
                builder: (context, setFullscreenState) {
                  final fullscreenIsSalesCount =
                      fullscreenMetric == _OverviewDailyMetric.salesCount;
                  return buildMetricToggleComparisonBarFullscreenBody(
                    tokens: fullscreenTokens,
                    metricToggle: AppSegmentedControl<_OverviewDailyMetric>(
                      options: <AppSegmentedControlOption<_OverviewDailyMetric>>[
                        AppSegmentedControlOption<_OverviewDailyMetric>(
                          value: _OverviewDailyMetric.salesCount,
                          label: labels.metricCountLabel,
                        ),
                        AppSegmentedControlOption<_OverviewDailyMetric>(
                          value: _OverviewDailyMetric.salesAmount,
                          label: labels.metricAmountLabel,
                        ),
                      ],
                      value: fullscreenMetric,
                      onChanged: (value) => setFullscreenState(
                        () => fullscreenMetric = value,
                      ),
                    ),
                    chartBuilder: (availableChartHeight) =>
                        AppComparisonBarChart<DailySalesTrendPoint>(
                      items: chartPointsSnapshot,
                      isLoading: isLoadingSnapshot,
                      plotFloorAccessibilityNotice:
                          l10n.chartComparisonPlotFloorNotice,
                      extremeSpreadAccessibilityNotice:
                          l10n.chartComparisonExtremeValueSpreadNotice,
                      labelBuilder: _dayAxisLabel,
                      valueBuilder: (point) => fullscreenIsSalesCount
                          ? point.salesCount
                          : point.salesAmount,
                      tooltipLabelBuilder: (point, value) {
                        final dateStr = _tooltipDateLine(point);
                        return labels.tooltip(
                          dateStr,
                          salesCountFormat.format(point.salesCount),
                          AppBrFormatters.currency(point.salesAmount),
                        );
                      },
                      dataLabelBuilder: (_, value) => fullscreenIsSalesCount
                          ? compactSalesCountFormat.format(value)
                          : AppBrFormatters.compactCurrency(value),
                      style: appDashboardComparisonBarChartStyle(
                        tokens: fullscreenTokens,
                        kind: AppDashboardComparisonBarChartKind.daily,
                        l10n: l10n,
                        weekdayUsesCurrencyAxis: !fullscreenIsSalesCount,
                        weekdayRevenueDataLabelBackground: fullscreenIsSalesCount
                            ? null
                            : Theme.of(context).colorScheme.surface,
                        heightOverride: availableChartHeight,
                      ),
                      emptyPlaceholder: showEmptyPlaceholder
                          ? AgentQueryChartFailurePlaceholderContent(
                              emptyMessage: emptyMessage,
                              textStyle: Theme.of(context).textTheme.bodyMedium,
                              verticalPadding: fullscreenTokens.contentSpacing,
                              loadFailure:
                                  widget.loadFailed ? widget.loadFailure : null,
                            )
                          : null,
                    ),
                  );
                },
              ),
            );
          },
        ),
      );
    }

    void openShare() {
      final emit = onRequestShare;
      if (emit == null || widget.isLoading) {
        return;
      }
      emit(
        context,
        shareMetadata(isSalesCountMetric: isSalesCount).toShareRequest(_shareKey),
      );
    }

    return Semantics(
      label: labels.semanticsForMetric(isSalesCount: isSalesCount),
      hint: resolvedScopeHint,
      child: RepaintBoundary(
        key: _shareKey,
        child: AppComparisonBarChart<DailySalesTrendPoint>(
          title: labels.titleForMetric(isSalesCount: isSalesCount),
          subtitle: resolvedSubtitle,
          onShare: onRequestShare == null || widget.isLoading ? null : openShare,
          shareProgressKey: _shareKey,
          shareEnabled: !widget.isLoading,
          onOpenFullscreen: onRequestFullscreen == null ? null : openFullscreen,
        belowSubtitle: AppSegmentedControl<_OverviewDailyMetric>(
          options: <AppSegmentedControlOption<_OverviewDailyMetric>>[
            AppSegmentedControlOption<_OverviewDailyMetric>(
              value: _OverviewDailyMetric.salesCount,
              label: labels.metricCountLabel,
            ),
            AppSegmentedControlOption<_OverviewDailyMetric>(
              value: _OverviewDailyMetric.salesAmount,
              label: labels.metricAmountLabel,
            ),
          ],
          value: _metric,
          onChanged: (value) => setState(() => _metric = value),
        ),
        items: chartPoints,
        isLoading: widget.isLoading,
        plotFloorAccessibilityNotice: l10n.chartComparisonPlotFloorNotice,
        extremeSpreadAccessibilityNotice:
            l10n.chartComparisonExtremeValueSpreadNotice,
        labelBuilder: _dayAxisLabel,
        valueBuilder: (point) =>
            isSalesCount ? point.salesCount : point.salesAmount,
        tooltipLabelBuilder: (point, value) => labels.tooltip(
          _tooltipDateLine(point),
          salesCountFormat.format(point.salesCount),
          AppBrFormatters.currency(point.salesAmount),
        ),
        dataLabelBuilder: (_, value) => isSalesCount
            ? compactSalesCountFormat.format(value)
            : AppBrFormatters.compactCurrency(value),
        style: appDashboardComparisonBarChartStyle(
          tokens: tokens,
          kind: AppDashboardComparisonBarChartKind.daily,
          l10n: l10n,
          weekdayUsesCurrencyAxis: !isSalesCount,
          weekdayRevenueDataLabelBackground: isSalesCount
              ? null
              : Theme.of(context).colorScheme.surface,
        ),
        emptyPlaceholder: showEmptyPlaceholder
            ? AgentQueryChartFailurePlaceholderContent(
                emptyMessage: emptyMessage,
                textStyle: Theme.of(context).textTheme.bodyMedium,
                verticalPadding: tokens.contentSpacing,
                loadFailure:
                    widget.loadFailed ? widget.loadFailure : null,
              )
            : null,
        ),
      ),
    );
  }
}

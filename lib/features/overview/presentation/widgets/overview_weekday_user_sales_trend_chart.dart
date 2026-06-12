import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/features/overview/domain/entities/overview_weekday_user_sales_trend_point.dart';
import 'package:colmeia/features/overview/presentation/share/overview_chart_share_export_filter.dart';
import 'package:colmeia/features/overview/presentation/share/overview_weekday_user_sales_trend_share.dart';
import 'package:colmeia/features/overview/presentation/widgets/overview_chart_load_failure_helpers.dart';
import 'package:colmeia/features/overview/presentation/widgets/overview_weekday_user_grouped_bar_chart.dart';
import 'package:colmeia/features/overview/presentation/widgets/overview_weekday_user_sales_trend_chart_export.dart';
import 'package:colmeia/features/overview/presentation/widgets/weekday_user_grouped_chart_data.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/charts/daily_sales_weekday_labels.dart';
import 'package:colmeia/shared/charts/metric_toggle_comparison_bar_fullscreen_body.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_fullscreen_request.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_share_request.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_shell.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_actions.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_export_header_context.dart';
import 'package:colmeia/shared/widgets/charts/metric_toggle_comparison_bar_card.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OverviewWeekdayUserSalesTrendChart extends StatefulWidget {
  const OverviewWeekdayUserSalesTrendChart({
    required this.l10n,
    required this.points,
    required this.loadFailed,
    this.loadFailure,
    this.loadFailureMessage,
    this.onViewAgentFailureDetails,
    this.onRequestFullscreen,
    this.onRequestShare,
    this.exportHeaderContext,
    super.key,
  });

  final AppLocalizations l10n;
  final ChartShareExportHeaderContext? exportHeaderContext;
  final List<OverviewWeekdayUserSalesTrendPoint> points;
  final bool loadFailed;
  final AppFailure? loadFailure;
  final String? loadFailureMessage;
  final VoidCallback? onViewAgentFailureDetails;
  final AppChartFullscreenRequestCallback? onRequestFullscreen;
  final AppChartShareRequestCallback? onRequestShare;

  @override
  State<OverviewWeekdayUserSalesTrendChart> createState() =>
      _OverviewWeekdayUserSalesTrendChartState();
}

class _OverviewWeekdayUserSalesTrendChartState
    extends State<OverviewWeekdayUserSalesTrendChart> {
  final GlobalKey _shareKey = GlobalKey();

  MetricToggleComparisonBarMetric _metric =
      MetricToggleComparisonBarMetric.count;

  List<OverviewWeekdayUserSalesTrendPoint>? _cachedChartPoints;
  List<OverviewWeekdayUserSalesTrendPoint>? _cachePointsIdentity;
  MetricToggleComparisonBarMetric? _cacheMetricForChartPoints;

  List<OverviewWeekdayUserSalesTrendPoint> _chartPointsForBuild() {
    if (_cachedChartPoints != null &&
        identical(widget.points, _cachePointsIdentity) &&
        _metric == _cacheMetricForChartPoints) {
      return _cachedChartPoints!;
    }
    _cachePointsIdentity = widget.points;
    _cacheMetricForChartPoints = _metric;
    if (_metric == MetricToggleComparisonBarMetric.count) {
      _cachedChartPoints = [
        for (final p in widget.points)
          if (p.salesCount > 0) p,
      ];
    } else {
      _cachedChartPoints = [
        for (final p in widget.points)
          if (p.salesAmount > 0) p,
      ];
    }
    return _cachedChartPoints!;
  }

  List<OverviewWeekdayUserSalesTrendPoint>? _semanticsPointsRef;
  MetricToggleComparisonBarMetric? _semanticsMetric;
  bool? _semanticsLoadFailed;
  String? _semanticsSummaryCache;

  @override
  void didUpdateWidget(covariant OverviewWeekdayUserSalesTrendChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.points, oldWidget.points) ||
        widget.loadFailed != oldWidget.loadFailed ||
        widget.l10n.localeName != oldWidget.l10n.localeName) {
      _semanticsSummaryCache = null;
      _semanticsPointsRef = null;
      _semanticsMetric = null;
      _semanticsLoadFailed = null;
      _cachedChartPoints = null;
      _cachePointsIdentity = null;
      _cacheMetricForChartPoints = null;
    }
  }

  String _semanticsSummaryForBuild({
    required AppLocalizations l10n,
    required NumberFormat salesCountFormat,
  }) {
    if (_semanticsSummaryCache != null &&
        identical(widget.points, _semanticsPointsRef) &&
        _metric == _semanticsMetric &&
        widget.loadFailed == _semanticsLoadFailed) {
      return _semanticsSummaryCache!;
    }
    _semanticsPointsRef = widget.points;
    _semanticsMetric = _metric;
    _semanticsLoadFailed = widget.loadFailed;
    _semanticsSummaryCache = _buildSemanticsSummary(
      l10n: l10n,
      salesCountFormat: salesCountFormat,
    );
    return _semanticsSummaryCache!;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final localeName = Localizations.localeOf(context).toString();
    final salesCountFormat = NumberFormat.decimalPattern(localeName);
    final isSalesCount = _metric == MetricToggleComparisonBarMetric.count;
    final emptyMessage = overviewChartLoadFailureMessage(
      l10n: l10n,
      loadFailed: widget.loadFailed,
      loadFailure: widget.loadFailure,
      legacyMessage: widget.loadFailureMessage,
      genericFallback: widget.loadFailed
          ? l10n.overviewWeekdayUserSalesLoadFailed
          : l10n.overviewWeekdayUserSalesEmpty,
    );
    final summary = _semanticsSummaryForBuild(
      l10n: l10n,
      salesCountFormat: salesCountFormat,
    );
    final chartPoints = _chartPointsForBuild();
    final showEmptyPlaceholder = widget.points.isEmpty || chartPoints.isEmpty;
    final chartTitle = isSalesCount
        ? l10n.overviewWeekdayUserSalesTitle
        : l10n.overviewWeekdayUserRevenueTitle;
    final chartSemantics = isSalesCount
        ? l10n.overviewWeekdayUserSalesChartSemantics
        : l10n.overviewWeekdayUserRevenueChartSemantics;

    final segmented = buildMetricToggleComparisonBarSegmentedControl(
      value: _metric,
      onChanged: (value) => setState(() {
        _metric = value;
        _cachedChartPoints = null;
        _cachePointsIdentity = null;
        _cacheMetricForChartPoints = null;
      }),
      countMetricLabel: l10n.overviewWeekdayMetricSalesCountLabel,
      amountMetricLabel: l10n.overviewWeekdayMetricSalesAmountLabel,
    );

    final groupedModel = showEmptyPlaceholder
        ? null
        : buildWeekdayUserGroupedChartModel(
            points: chartPoints,
            l10n: l10n,
            useSalesCount: isSalesCount,
          );
    final seriesTruncationNotice =
        groupedModel != null && groupedModel.combinedRemainingUsers
        ? l10n.overviewWeekdayUserGroupedTruncationFootnote(
            kWeekdayUserGroupedMaxSeries - 1,
            l10n.overviewWeekdayUserGroupedOthersLabel,
          )
        : null;

    final metadata = buildOverviewWeekdayUserSalesTrendShareMetadata(
      l10n: l10n,
      points: widget.points,
      isSalesCount: isSalesCount,
      title: chartTitle,
      salesCountFormat: salesCountFormat,
      exportHeaderContext: overviewWeekdayChartShareExportHeaderContext(
        base: widget.exportHeaderContext,
        l10n: l10n,
        isSalesCountMetric: isSalesCount,
      ),
      seriesTruncationNotice: seriesTruncationNotice,
      chartExportBuilder: buildOverviewWeekdayUserGroupedChartExportBuilder(
        model: groupedModel,
        l10n: l10n,
        tokens: tokens,
        isSalesCount: isSalesCount,
        title: chartTitle,
        subtitle: l10n.overviewWeekdayUserSalesSubtitle,
      ),
    );
    final shareActions = ChartShareActions(
      context: context,
      captureKey: _shareKey,
      metadata: metadata,
      onRequestShare: widget.onRequestShare,
      onRequestFullscreen: widget.onRequestFullscreen,
    );

    void openFullscreen() {
      final chartPointsSnapshot = List<OverviewWeekdayUserSalesTrendPoint>.of(
        chartPoints,
        growable: false,
      );
      final fullscreenShareKey = GlobalKey();
      shareActions.openFullscreen(
        metadata.toFullscreenRequest(
          semanticsLabel: chartSemantics,
          shareCaptureKey: fullscreenShareKey,
          chartBuilder: (fullscreenContext) {
            final fullscreenTokens = Theme.of(
              fullscreenContext,
            ).extension<AppThemeTokens>()!;
            final fullscreenL10n = AppLocalizations.of(fullscreenContext);
            var fullscreenMetric = _metric;
            return RepaintBoundary(
              key: fullscreenShareKey,
              child: StatefulBuilder(
                builder: (context, setFullscreenState) {
                  final fullscreenIsSalesCount =
                      fullscreenMetric == MetricToggleComparisonBarMetric.count;
                  if (showEmptyPlaceholder) {
                    return Center(
                      child: Text(
                        emptyMessage,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    );
                  }
                  return buildSegmentedControlFullscreenBody(
                    tokens: fullscreenTokens,
                    control: buildMetricToggleComparisonBarSegmentedControl(
                      value: fullscreenMetric,
                      onChanged: (value) => setFullscreenState(
                        () => fullscreenMetric = value,
                      ),
                      countMetricLabel:
                          fullscreenL10n.overviewWeekdayMetricSalesCountLabel,
                      amountMetricLabel:
                          fullscreenL10n.overviewWeekdayMetricSalesAmountLabel,
                    ),
                    chartBuilder: (_) => OverviewWeekdayUserGroupedBarChart(
                      l10n: fullscreenL10n,
                      model: buildWeekdayUserGroupedChartModel(
                        points: chartPointsSnapshot,
                        l10n: fullscreenL10n,
                        useSalesCount: fullscreenIsSalesCount,
                      ),
                      isSalesCount: fullscreenIsSalesCount,
                      title: fullscreenIsSalesCount
                          ? fullscreenL10n.overviewWeekdayUserSalesTitle
                          : fullscreenL10n.overviewWeekdayUserRevenueTitle,
                      subtitle: fullscreenL10n.overviewWeekdayUserSalesSubtitle,
                      belowSubtitle: const SizedBox.shrink(),
                      plotFloorAccessibilityNotice:
                          fullscreenL10n.chartComparisonPlotFloorNotice,
                      extremeSpreadAccessibilityNotice: fullscreenL10n
                          .chartComparisonExtremeValueSpreadNotice,
                      tokens: fullscreenTokens,
                      useChartShell: false,
                      expandPlotVertically: true,
                    ),
                  );
                },
              ),
            );
          },
        ),
      );
    }

    final chartBody = showEmptyPlaceholder
        ? AppChartShell(
            title: chartTitle,
            subtitle: l10n.overviewWeekdayUserSalesSubtitle,
            onShare: shareActions.shareCallback(),
            shareProgressKey: _shareKey,
            onOpenFullscreen: shareActions.fullscreenCallback(openFullscreen),
            belowSubtitle: segmented,
            child: overviewChartEmptyPlaceholder(
              emptyMessage: emptyMessage,
              textStyle: Theme.of(context).textTheme.bodyMedium,
              verticalPadding: tokens.contentSpacing,
              onViewAgentFailureDetails: widget.onViewAgentFailureDetails,
              loadFailure: widget.loadFailed ? widget.loadFailure : null,
            ),
          )
        : OverviewWeekdayUserGroupedBarChart(
            l10n: l10n,
            model: buildWeekdayUserGroupedChartModel(
              points: chartPoints,
              l10n: l10n,
              useSalesCount: isSalesCount,
            ),
            isSalesCount: isSalesCount,
            title: chartTitle,
            subtitle: l10n.overviewWeekdayUserSalesSubtitle,
            belowSubtitle: segmented,
            plotFloorAccessibilityNotice: l10n.chartComparisonPlotFloorNotice,
            extremeSpreadAccessibilityNotice:
                l10n.chartComparisonExtremeValueSpreadNotice,
            tokens: tokens,
            onShare: shareActions.shareCallback(),
            onOpenFullscreen: shareActions.fullscreenCallback(openFullscreen),
          );

    return Semantics(
      label: chartSemantics,
      hint: l10n.overviewWeekdayUserChartScopeHint,
      value: summary,
      child: RepaintBoundary(
        key: _shareKey,
        child: chartBody,
      ),
    );
  }

  String _buildSemanticsSummary({
    required AppLocalizations l10n,
    required NumberFormat salesCountFormat,
  }) {
    final points = widget.points;
    if (points.isEmpty) {
      return overviewChartLoadFailureMessage(
        l10n: l10n,
        loadFailed: widget.loadFailed,
        loadFailure: widget.loadFailure,
        legacyMessage: widget.loadFailureMessage,
        genericFallback: widget.loadFailed
            ? l10n.overviewWeekdayUserSalesLoadFailed
            : l10n.overviewWeekdayUserSalesEmpty,
      );
    }

    final totalSalesCount = points.fold<int>(
      0,
      (total, point) => total + point.salesCount,
    );
    final totalSalesAmount = points.fold<double>(
      0,
      (total, point) => total + point.salesAmount,
    );
    final topPoint = points.reduce((left, right) {
      final leftValue = _metric == MetricToggleComparisonBarMetric.count
          ? left.salesCount.toDouble()
          : left.salesAmount;
      final rightValue = _metric == MetricToggleComparisonBarMetric.count
          ? right.salesCount.toDouble()
          : right.salesAmount;
      return rightValue > leftValue ? right : left;
    });

    final topWeekdayLabel = dailySalesWeekdayLabel(
      topPoint.weekdayNumber,
      l10n,
    );
    final topUserName = topPoint.userName.trim().isEmpty
        ? '—'
        : topPoint.userName.trim();
    return _metric == MetricToggleComparisonBarMetric.count
        ? l10n.overviewWeekdayUserSalesSummarySemantics(
            salesCountFormat.format(totalSalesCount),
            AppBrFormatters.currency(totalSalesAmount),
            topWeekdayLabel,
            topUserName,
            salesCountFormat.format(topPoint.salesCount),
          )
        : l10n.overviewWeekdayUserRevenueSummarySemantics(
            AppBrFormatters.currency(totalSalesAmount),
            salesCountFormat.format(totalSalesCount),
            topWeekdayLabel,
            topUserName,
            AppBrFormatters.currency(topPoint.salesAmount),
          );
  }
}

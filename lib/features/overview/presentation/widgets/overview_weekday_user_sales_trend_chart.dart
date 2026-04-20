import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/features/overview/domain/entities/overview_weekday_user_sales_trend_point.dart';
import 'package:colmeia/features/overview/presentation/localization/overview_weekday_sales_trend_l10n.dart';
import 'package:colmeia/features/overview/presentation/widgets/overview_weekday_user_grouped_bar_chart.dart';
import 'package:colmeia/features/overview/presentation/widgets/weekday_user_grouped_chart_data.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_shell.dart';
import 'package:colmeia/shared/widgets/forms/app_segmented_control.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OverviewWeekdayUserSalesTrendChart extends StatefulWidget {
  const OverviewWeekdayUserSalesTrendChart({
    required this.l10n,
    required this.points,
    required this.loadFailed,
    this.loadFailureMessage,
    super.key,
  });

  final AppLocalizations l10n;
  final List<OverviewWeekdayUserSalesTrendPoint> points;
  final bool loadFailed;

  /// Specific message extracted from the underlying `AppFailure`. When set
  /// AND [loadFailed] is true, the chart shows this instead of the generic
  /// l10n "load failed" label (BUG #4 — actionable error context).
  final String? loadFailureMessage;

  @override
  State<OverviewWeekdayUserSalesTrendChart> createState() =>
      _OverviewWeekdayUserSalesTrendChartState();
}

enum _OverviewWeekdayUserMetric {
  salesCount,
  salesAmount,
}

class _OverviewWeekdayUserSalesTrendChartState
    extends State<OverviewWeekdayUserSalesTrendChart> {
  _OverviewWeekdayUserMetric _metric = _OverviewWeekdayUserMetric.salesCount;

  List<OverviewWeekdayUserSalesTrendPoint>? _cachedChartPoints;
  List<OverviewWeekdayUserSalesTrendPoint>? _cachePointsIdentity;
  _OverviewWeekdayUserMetric? _cacheMetricForChartPoints;

  List<OverviewWeekdayUserSalesTrendPoint> _chartPointsForBuild() {
    if (_cachedChartPoints != null &&
        identical(widget.points, _cachePointsIdentity) &&
        _metric == _cacheMetricForChartPoints) {
      return _cachedChartPoints!;
    }
    _cachePointsIdentity = widget.points;
    _cacheMetricForChartPoints = _metric;
    if (_metric == _OverviewWeekdayUserMetric.salesCount) {
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
  _OverviewWeekdayUserMetric? _semanticsMetric;
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
    final isSalesCount = _metric == _OverviewWeekdayUserMetric.salesCount;
    final emptyMessage = widget.loadFailed
        ? (widget.loadFailureMessage ??
              l10n.overviewWeekdayUserSalesLoadFailed)
        : l10n.overviewWeekdayUserSalesEmpty;
    final summary = _semanticsSummaryForBuild(
      l10n: l10n,
      salesCountFormat: salesCountFormat,
    );
    final chartPoints = _chartPointsForBuild();
    final showEmptyPlaceholder =
        widget.points.isEmpty || chartPoints.isEmpty;

    final segmented = AppSegmentedControl<_OverviewWeekdayUserMetric>(
      options: <AppSegmentedControlOption<_OverviewWeekdayUserMetric>>[
        AppSegmentedControlOption<_OverviewWeekdayUserMetric>(
          value: _OverviewWeekdayUserMetric.salesCount,
          label: l10n.overviewWeekdayMetricSalesCountLabel,
        ),
        AppSegmentedControlOption<_OverviewWeekdayUserMetric>(
          value: _OverviewWeekdayUserMetric.salesAmount,
          label: l10n.overviewWeekdayMetricSalesAmountLabel,
        ),
      ],
      value: _metric,
      onChanged: (value) => setState(() {
        _metric = value;
        _cachedChartPoints = null;
        _cachePointsIdentity = null;
        _cacheMetricForChartPoints = null;
      }),
    );

    final chartBody = showEmptyPlaceholder
        ? AppChartShell(
            title: isSalesCount
                ? l10n.overviewWeekdayUserSalesTitle
                : l10n.overviewWeekdayUserRevenueTitle,
            subtitle: l10n.overviewWeekdayUserSalesSubtitle,
            belowSubtitle: segmented,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: tokens.contentSpacing),
              child: Center(
                child: Text(
                  emptyMessage,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
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
            title: isSalesCount
                ? l10n.overviewWeekdayUserSalesTitle
                : l10n.overviewWeekdayUserRevenueTitle,
            subtitle: l10n.overviewWeekdayUserSalesSubtitle,
            belowSubtitle: segmented,
            plotFloorAccessibilityNotice: l10n.chartComparisonPlotFloorNotice,
            extremeSpreadAccessibilityNotice:
                l10n.chartComparisonExtremeValueSpreadNotice,
            tokens: tokens,
          );

    return Semantics(
      label: isSalesCount
          ? l10n.overviewWeekdayUserSalesChartSemantics
          : l10n.overviewWeekdayUserRevenueChartSemantics,
      hint: l10n.overviewWeekdayUserChartScopeHint,
      value: summary,
      child: chartBody,
    );
  }

  String _buildSemanticsSummary({
    required AppLocalizations l10n,
    required NumberFormat salesCountFormat,
  }) {
    final points = widget.points;
    if (points.isEmpty) {
      return widget.loadFailed
          ? (widget.loadFailureMessage ??
                l10n.overviewWeekdayUserSalesLoadFailed)
          : l10n.overviewWeekdayUserSalesEmpty;
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
      final leftValue = _metric == _OverviewWeekdayUserMetric.salesCount
          ? left.salesCount.toDouble()
          : left.salesAmount;
      final rightValue = _metric == _OverviewWeekdayUserMetric.salesCount
          ? right.salesCount.toDouble()
          : right.salesAmount;
      return rightValue > leftValue ? right : left;
    });

    final topWeekdayLabel =
        overviewWeekdaySalesLabel(topPoint.weekdayNumber, l10n);
    final topUserName = topPoint.userName.trim().isEmpty
        ? '—'
        : topPoint.userName.trim();
    return _metric == _OverviewWeekdayUserMetric.salesCount
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

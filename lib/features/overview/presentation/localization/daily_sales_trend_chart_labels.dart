import 'package:colmeia/l10n/app_localizations.dart';

/// Resolved copy and metric labels for the daily sales trend bar chart.
sealed class DailySalesTrendChartLabels {
  const DailySalesTrendChartLabels();

  static DailySalesTrendChartLabels resolve(
    AppLocalizations l10n, {
    required bool salesBranchMonth,
  }) {
    return salesBranchMonth
        ? SalesDailyTotalsTrendChartLabels(l10n)
        : OverviewDailySalesTrendChartLabels(l10n);
  }

  String titleForMetric({required bool isSalesCount});

  String get subtitle;

  String resolveEmptyMessage({
    required bool loadFailed,
    String? loadFailureMessage,
  });

  String semanticsForMetric({required bool isSalesCount});

  String get scopeHint;

  String tooltip(String date, String salesCount, String salesAmount);

  String get metricCountLabel;

  String get metricAmountLabel;
}

final class OverviewDailySalesTrendChartLabels extends DailySalesTrendChartLabels {
  OverviewDailySalesTrendChartLabels(this._l10n);

  final AppLocalizations _l10n;

  @override
  String titleForMetric({required bool isSalesCount}) => isSalesCount
      ? _l10n.overviewDailySalesTitle
      : _l10n.overviewWeekdayRevenueTitle;

  @override
  String get subtitle => _l10n.overviewDailySalesSubtitle;

  @override
  String resolveEmptyMessage({
    required bool loadFailed,
    String? loadFailureMessage,
  }) {
    if (loadFailed) {
      return loadFailureMessage ?? _l10n.overviewDailySalesLoadFailed;
    }
    return _l10n.overviewDailySalesEmpty;
  }

  @override
  String semanticsForMetric({required bool isSalesCount}) => isSalesCount
      ? _l10n.overviewDailySalesChartSemantics
      : _l10n.overviewDailySalesRevenueChartSemantics;

  @override
  String get scopeHint => _l10n.overviewWeekdayChartScopeHint;

  @override
  String tooltip(String date, String salesCount, String salesAmount) =>
      _l10n.overviewDailySalesTooltip(date, salesCount, salesAmount);

  @override
  String get metricCountLabel => _l10n.overviewWeekdayMetricSalesCountLabel;

  @override
  String get metricAmountLabel => _l10n.overviewWeekdayMetricSalesAmountLabel;
}

final class SalesDailyTotalsTrendChartLabels extends DailySalesTrendChartLabels {
  SalesDailyTotalsTrendChartLabels(this._l10n);

  final AppLocalizations _l10n;

  @override
  String titleForMetric({required bool isSalesCount}) => isSalesCount
      ? _l10n.salesDailyTotalsChartTitle
      : _l10n.salesDailyTotalsChartTitleAmount;

  @override
  String get subtitle => _l10n.salesDailyTotalsChartSubtitle;

  @override
  String resolveEmptyMessage({
    required bool loadFailed,
    String? loadFailureMessage,
  }) {
    if (loadFailed) {
      return loadFailureMessage ?? _l10n.salesDailyTotalsChartLoadFailed;
    }
    return _l10n.salesDailyTotalsChartEmpty;
  }

  @override
  String semanticsForMetric({required bool isSalesCount}) => isSalesCount
      ? _l10n.salesDailyTotalsChartSemanticsCount
      : _l10n.salesDailyTotalsChartSemanticsAmount;

  @override
  String get scopeHint => _l10n.salesDailyTotalsChartScopeHint;

  @override
  String tooltip(String date, String salesCount, String salesAmount) =>
      _l10n.salesDailyTotalsChartTooltip(date, salesCount, salesAmount);

  @override
  String get metricCountLabel => _l10n.salesDailyTotalsMetricSalesCountLabel;

  @override
  String get metricAmountLabel => _l10n.salesDailyTotalsMetricSalesAmountLabel;
}

import 'package:colmeia/features/overview/domain/entities/overview_daily_sales_trend_point.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_shell.dart';
import 'package:colmeia/shared/widgets/charts/engines/chart_engine_defaults.dart';
import 'package:colmeia/shared/widgets/forms/app_segmented_control.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

enum _OverviewDailyMetric {
  salesCount,
  salesAmount,
}

/// Daily sales totals (line chart) for the overview period.
class OverviewDailySalesTrendChart extends StatefulWidget {
  const OverviewDailySalesTrendChart({
    required this.l10n,
    required this.points,
    required this.loadFailed,
    this.loadFailureMessage,
    super.key,
  });

  final AppLocalizations l10n;
  final List<OverviewDailySalesTrendPoint> points;
  final bool loadFailed;
  final String? loadFailureMessage;

  @override
  State<OverviewDailySalesTrendChart> createState() =>
      _OverviewDailySalesTrendChartState();
}

class _OverviewDailySalesTrendChartState
    extends State<OverviewDailySalesTrendChart> {
  _OverviewDailyMetric _metric = _OverviewDailyMetric.salesCount;

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final theme = Theme.of(context);
    final localeName = Localizations.localeOf(context).toString();
    final salesCountFormat = NumberFormat.decimalPattern(localeName);
    final currencyFormat = NumberFormat.simpleCurrency(locale: localeName);
    final emptyMessage = widget.loadFailed
        ? (widget.loadFailureMessage ?? l10n.overviewDailySalesLoadFailed)
        : l10n.overviewDailySalesEmpty;

    final isSalesCount = _metric == _OverviewDailyMetric.salesCount;
    final title = isSalesCount
        ? l10n.overviewDailySalesTitle
        : l10n.overviewWeekdayRevenueTitle;

    if (widget.points.isEmpty) {
      return AppChartShell(
        title: title,
        subtitle: l10n.overviewDailySalesSubtitle,
        child: SizedBox(
          height: tokens.chartStandardHeight,
          child: Center(child: Text(emptyMessage)),
        ),
      );
    }

    final chartHeight = tokens.chartStandardHeight;
    final gridColor = theme.colorScheme.outlineVariant.withValues(alpha: 0.45);

    return AppChartShell(
      title: title,
      subtitle: l10n.overviewDailySalesSubtitle,
      belowSubtitle: AppSegmentedControl<_OverviewDailyMetric>(
        options: <AppSegmentedControlOption<_OverviewDailyMetric>>[
          AppSegmentedControlOption<_OverviewDailyMetric>(
            value: _OverviewDailyMetric.salesCount,
            label: l10n.overviewWeekdayMetricSalesCountLabel,
          ),
          AppSegmentedControlOption<_OverviewDailyMetric>(
            value: _OverviewDailyMetric.salesAmount,
            label: l10n.overviewWeekdayMetricSalesAmountLabel,
          ),
        ],
        value: _metric,
        onChanged: (value) => setState(() => _metric = value),
      ),
      child: Semantics(
        label: isSalesCount
            ? l10n.overviewDailySalesChartSemantics
            : l10n.overviewDailySalesRevenueChartSemantics,
        child: SizedBox(
          height: chartHeight,
          child: SfCartesianChart(
            plotAreaBorderWidth: 0,
            tooltipBehavior: buildChartTooltipBehavior(context, enable: true),
            primaryXAxis: CategoryAxis(
              majorGridLines: const MajorGridLines(width: 0),
              labelStyle: theme.textTheme.bodySmall,
              labelIntersectAction: AxisLabelIntersectAction.rotate45,
            ),
            primaryYAxis: NumericAxis(
              minimum: 0,
              axisLine: const AxisLine(width: 0),
              majorGridLines: MajorGridLines(color: gridColor),
              labelStyle: theme.textTheme.bodySmall,
              numberFormat: isSalesCount ? salesCountFormat : currencyFormat,
            ),
            series: <CartesianSeries<OverviewDailySalesTrendPoint, String>>[
              LineSeries<OverviewDailySalesTrendPoint, String>(
                dataSource: widget.points,
                xValueMapper: (p, _) =>
                    DateFormat.Md(localeName).format(p.saleDate),
                yValueMapper: (p, _) =>
                    isSalesCount ? p.salesCount.toDouble() : p.salesAmount,
                markerSettings: const MarkerSettings(isVisible: true),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

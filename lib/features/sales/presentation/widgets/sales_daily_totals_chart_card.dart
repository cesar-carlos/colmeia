import 'package:colmeia/features/overview/domain/entities/overview_daily_sales_trend_point.dart';
import 'package:colmeia/features/overview/presentation/widgets/overview_daily_sales_trend_chart.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class SalesDailyTotalsChartCard extends StatelessWidget {
  const SalesDailyTotalsChartCard({
    required this.l10n,
    required this.points,
    required this.loadFailed,
    required this.isLoading,
    this.loadFailureMessage,
    super.key,
  });

  final AppLocalizations l10n;
  final List<OverviewDailySalesTrendPoint> points;
  final bool loadFailed;
  final bool isLoading;
  final String? loadFailureMessage;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: OverviewDailySalesTrendChart(
        l10n: l10n,
        points: points,
        loadFailed: loadFailed,
        loadFailureMessage: loadFailureMessage,
        isLoading: isLoading,
        useSalesDailyTotalsLabels: true,
      ),
    );
  }
}

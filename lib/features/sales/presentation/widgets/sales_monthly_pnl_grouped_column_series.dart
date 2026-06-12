import 'package:colmeia/features/sales/domain/entities/sales_monthly_pnl_point.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/widgets/charts/app_grouped_column_chart_series.dart';
import 'package:flutter/material.dart';

List<AppGroupedColumnChartSeries<SalesMonthlyPnlPoint>>
salesMonthlyPnlGroupedColumnSeries({
  required AppLocalizations l10n,
  required Color salesColor,
  required Color profitColor,
  required Color costColor,
}) {
  return <AppGroupedColumnChartSeries<SalesMonthlyPnlPoint>>[
    AppGroupedColumnChartSeries<SalesMonthlyPnlPoint>(
      name: l10n.salesMonthlyPnlSeriesSalesLabel,
      color: salesColor,
      valueMapper: (point) => point.venda,
    ),
    AppGroupedColumnChartSeries<SalesMonthlyPnlPoint>(
      name: l10n.salesMonthlyPnlSeriesProfitLabel,
      color: profitColor,
      valueMapper: (point) => point.lucro,
      yAxis: AppGroupedColumnYAxis.secondary,
    ),
    AppGroupedColumnChartSeries<SalesMonthlyPnlPoint>(
      name: l10n.salesMonthlyPnlSeriesCostLabel,
      color: costColor,
      valueMapper: (point) => point.custoMercadoria,
      yAxis: AppGroupedColumnYAxis.secondary,
    ),
  ];
}

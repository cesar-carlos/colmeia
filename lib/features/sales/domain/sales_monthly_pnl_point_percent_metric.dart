import 'package:colmeia/features/agent_queries/domain/entities/lucratividade_percent_metric.dart';
import 'package:colmeia/features/sales/domain/entities/sales_monthly_pnl_point.dart';

extension LucratividadePercentMetricOnSalesMonthlyPnlPoint
    on SalesMonthlyPnlPoint {
  num metricBarValue(LucratividadePercentMetric metric) {
    switch (metric) {
      case LucratividadePercentMetric.costOverRevenue:
        return percentualCustoSobreVenda;
      case LucratividadePercentMetric.grossMargin:
        return margemLucroBrutoPercent;
      case LucratividadePercentMetric.markupOverCost:
        return markupSobreCustoPercent;
    }
  }
}

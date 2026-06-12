import 'package:colmeia/features/agent_queries/domain/entities/lucratividade_percent_metric.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_lucratividade_row.dart';

extension LucratividadePercentMetricOnLucratividadeRow
    on ResumoProdutoVendaLucratividadeRow {
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

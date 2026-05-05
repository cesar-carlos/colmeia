import 'package:colmeia/features/agent_queries/domain/entities/lucratividade_percent_metric.dart';
import 'package:colmeia/features/sales/domain/entities/sales_monthly_pnl_point.dart';
import 'package:colmeia/features/sales/domain/sales_monthly_pnl_point_percent_metric.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SalesMonthlyPnlPoint', () {
    test('percent getters match mensal aggregate formulas', () {
      const point = SalesMonthlyPnlPoint(
        year: 2026,
        month: 5,
        anoMes: '2026/05',
        venda: 1000,
        lucro: 400,
        custoMercadoria: 600,
      );

      expect(point.percentualCustoSobreVenda, closeTo(60.0, 0.001));
      expect(point.margemLucroBrutoPercent, closeTo(40.0, 0.001));
      expect(point.markupSobreCustoPercent, closeTo(400 / 6, 0.001));
    });

    test('percent getters return 0 when denominators missing', () {
      const zeroVenda = SalesMonthlyPnlPoint(
        year: 2026,
        month: 1,
        anoMes: '2026/01',
        venda: 0,
        lucro: 0,
        custoMercadoria: 0,
      );
      expect(zeroVenda.percentualCustoSobreVenda, 0);
      expect(zeroVenda.margemLucroBrutoPercent, 0);
      expect(zeroVenda.markupSobreCustoPercent, 0);

      const zeroCusto = SalesMonthlyPnlPoint(
        year: 2026,
        month: 2,
        anoMes: '2026/02',
        venda: 500,
        lucro: 500,
        custoMercadoria: 0,
      );
      expect(zeroCusto.percentualCustoSobreVenda, 0);
      expect(zeroCusto.markupSobreCustoPercent, 0);
      expect(zeroCusto.margemLucroBrutoPercent, closeTo(100.0, 0.001));
    });

    test('metricBarValue delegates to getters', () {
      const point = SalesMonthlyPnlPoint(
        year: 2026,
        month: 3,
        anoMes: '2026/03',
        venda: 200,
        lucro: 50,
        custoMercadoria: 150,
      );
      expect(
        point.metricBarValue(LucratividadePercentMetric.costOverRevenue),
        point.percentualCustoSobreVenda,
      );
      expect(
        point.metricBarValue(LucratividadePercentMetric.grossMargin),
        point.margemLucroBrutoPercent,
      );
      expect(
        point.metricBarValue(LucratividadePercentMetric.markupOverCost),
        point.markupSobreCustoPercent,
      );
    });
  });
}

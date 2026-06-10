import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_lucratividade_row.dart';
import 'package:colmeia/features/overview/domain/entities/overview.dart';
import 'package:colmeia/features/overview/domain/entities/overview_agent_query_failure_detail.dart';
import 'package:colmeia/features/overview/domain/entities/overview_agent_ranking.dart';
import 'package:colmeia/features/overview/domain/entities/overview_monthly_parcel_point.dart';
import 'package:colmeia/features/overview/domain/entities/overview_payment_kpis.dart';
import 'package:colmeia/features/overview/domain/entities/overview_payment_method_breakdown.dart';
import 'package:colmeia/features/overview/domain/entities/overview_progressive_snapshot.dart';
import 'package:colmeia/features/overview/domain/entities/overview_user_ranking.dart';
import 'package:colmeia/features/overview/domain/entities/overview_weekday_sales_trend_point.dart';
import 'package:colmeia/features/overview/domain/entities/overview_weekday_user_sales_trend_point.dart';
import 'package:colmeia/shared/charts/daily_sales_trend_point.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Overview.mergeSection', () {
    test('dailySales transfers trend and preserves base KPIs', () {
      final merged = _baseOverview().mergeSection(
        _detailOverview(),
        OverviewProgressiveSection.dailySales,
      );

      expect(merged.dailySalesTrend.single.salesAmount, 50);
      expect(merged.dailySalesTrend.single.salesCount, 5);
      expect(merged.kpis.totalAmount, _baseOverview().kpis.totalAmount);
    });

    test('weekdaySales transfers trend and partial failures', () {
      final detail = _detailOverview().copyWith(
        partialQueryFailureDetails: const <OverviewAgentQueryFailureDetail>[
          OverviewAgentQueryFailureDetail(
            agentId: 'a2',
            displayName: 'Agent 2',
            source: OverviewAgentQueryFailureSource.weekdayTrend,
            failure: NetworkFailure(message: 'weekday failed'),
          ),
        ],
      );

      final merged = _baseOverview().mergeSection(
        detail,
        OverviewProgressiveSection.weekdaySales,
      );

      expect(merged.weekdaySalesTrend, detail.weekdaySalesTrend);
      expect(
        merged.partialQueryFailureDetails,
        detail.partialQueryFailureDetails,
      );
    });

    test('weekdayUserSales transfers trend', () {
      final merged = _baseOverview().mergeSection(
        _detailOverview(),
        OverviewProgressiveSection.weekdayUserSales,
      );

      expect(
        merged.weekdayUserSalesTrend,
        _detailOverview().weekdayUserSalesTrend,
      );
    });

    test('lucratividadePeriod transfers trend and partial agent names', () {
      final merged = _baseOverview().mergeSection(
        _detailOverview(),
        OverviewProgressiveSection.lucratividadePeriod,
      );

      expect(merged.lucratividadeTrend, _detailOverview().lucratividadeTrend);
      expect(
        merged.lucratividadePartialFailureAgentNames,
        _detailOverview().lucratividadePartialFailureAgentNames,
      );
    });

    test('monthlyParcels transfers trend', () {
      final merged = _baseOverview().mergeSection(
        _detailOverview(),
        OverviewProgressiveSection.monthlyParcels,
      );

      expect(merged.monthlyParcelTrend, _detailOverview().monthlyParcelTrend);
    });

    test('paymentMix transfers payment data and preserves agent rankings', () {
      final merged = _baseOverview().mergeSection(
        _detailOverview(),
        OverviewProgressiveSection.paymentMix,
      );

      expect(merged.paymentMethods, _detailOverview().paymentMethods);
      expect(merged.kpis.totalAmount, _detailOverview().kpis.totalAmount);
      expect(merged.agentRankings, _baseOverview().agentRankings);
    });

    test('userRanking transfers user rankings only', () {
      final merged = _baseOverview().mergeSection(
        _detailOverview(),
        OverviewProgressiveSection.userRanking,
      );

      expect(merged.userRankings, _detailOverview().userRankings);
      expect(merged.agentRankings, _baseOverview().agentRankings);
    });
  });
}

Overview _baseOverview() {
  return Overview(
    periodStart: DateTime(2026, 3, 9),
    periodEnd: DateTime(2026, 4, 7),
    kpis: const OverviewPaymentKpis(
      totalSalesCount: 100,
      totalAmount: 9000,
      averageTicket: 90,
      paymentMethodCount: 1,
    ),
    paymentMethods: const <OverviewPaymentMethodBreakdown>[
      OverviewPaymentMethodBreakdown(
        code: 'Pix',
        label: 'Pix',
        totalSalesCount: 100,
        totalAmount: 9000,
        averageTicket: 90,
        sharePercent: 100,
      ),
    ],
    agentRankings: const <OverviewAgentRanking>[
      OverviewAgentRanking(
        agentId: 'a1',
        displayName: 'Agent 1',
        totalSalesCount: 100,
        totalAmount: 9000,
      ),
    ],
    userRankings: const <OverviewUserRanking>[
      OverviewUserRanking(
        userName: 'Base User',
        totalSalesCount: 100,
        totalAmount: 9000,
        averageTicket: 90,
      ),
    ],
    dailySalesTrend: <DailySalesTrendPoint>[
      DailySalesTrendPoint(
        saleDate: DateTime(2026, 3, 10),
        salesCount: 1,
        salesAmount: 10,
      ),
    ],
    weekdaySalesTrend: const <OverviewWeekdaySalesTrendPoint>[
      OverviewWeekdaySalesTrendPoint(
        weekdayNumber: 1,
        salesCount: 1,
        salesAmount: 10,
      ),
    ],
    weekdayUserSalesTrend: const <OverviewWeekdayUserSalesTrendPoint>[
      OverviewWeekdayUserSalesTrendPoint(
        weekdayNumber: 1,
        userName: 'Base User',
        salesCount: 1,
        salesAmount: 10,
      ),
    ],
    monthlyParcelTrend: const <OverviewMonthlyParcelPoint>[
      OverviewMonthlyParcelPoint(
        anoMes: '2026/03',
        qtdVendas: 1,
        valorParcela: 10,
      ),
    ],
    lucratividadeTrend: const <ResumoProdutoVendaLucratividadeRow>[
      ResumoProdutoVendaLucratividadeRow(
        codEmpresa: 1,
        codFilial: 1,
        qtdVendas: 1,
        qtdItensVendido: 1,
        valorTotalCustoMedio: 5,
        custoReposicao: 5,
        pontoEquilibrio: 0,
        valorTotalItem: 10,
      ),
    ],
    lucratividadePartialFailureAgentNames: const <String>['Base Agent'],
  );
}

Overview _detailOverview() {
  return Overview(
    periodStart: DateTime(2026, 3, 9),
    periodEnd: DateTime(2026, 4, 7),
    kpis: const OverviewPaymentKpis(
      totalSalesCount: 200,
      totalAmount: 18000,
      averageTicket: 90,
      paymentMethodCount: 2,
    ),
    paymentMethods: const <OverviewPaymentMethodBreakdown>[
      OverviewPaymentMethodBreakdown(
        code: 'Credito',
        label: 'Credito',
        totalSalesCount: 200,
        totalAmount: 18000,
        averageTicket: 90,
        sharePercent: 100,
      ),
    ],
    agentRankings: const <OverviewAgentRanking>[
      OverviewAgentRanking(
        agentId: 'a2',
        displayName: 'Agent 2',
        totalSalesCount: 200,
        totalAmount: 18000,
      ),
    ],
    userRankings: const <OverviewUserRanking>[
      OverviewUserRanking(
        userName: 'Detail User',
        totalSalesCount: 200,
        totalAmount: 18000,
        averageTicket: 90,
      ),
    ],
    dailySalesTrend: <DailySalesTrendPoint>[
      DailySalesTrendPoint(
        saleDate: DateTime(2026, 3, 11),
        salesCount: 5,
        salesAmount: 50,
      ),
    ],
    weekdaySalesTrend: const <OverviewWeekdaySalesTrendPoint>[
      OverviewWeekdaySalesTrendPoint(
        weekdayNumber: 2,
        salesCount: 5,
        salesAmount: 50,
      ),
    ],
    weekdayUserSalesTrend: const <OverviewWeekdayUserSalesTrendPoint>[
      OverviewWeekdayUserSalesTrendPoint(
        weekdayNumber: 2,
        userName: 'Detail User',
        salesCount: 5,
        salesAmount: 50,
      ),
    ],
    monthlyParcelTrend: const <OverviewMonthlyParcelPoint>[
      OverviewMonthlyParcelPoint(
        anoMes: '2026/04',
        qtdVendas: 5,
        valorParcela: 50,
      ),
    ],
    lucratividadeTrend: const <ResumoProdutoVendaLucratividadeRow>[
      ResumoProdutoVendaLucratividadeRow(
        codEmpresa: 1,
        codFilial: 2,
        qtdVendas: 5,
        qtdItensVendido: 5,
        valorTotalCustoMedio: 20,
        custoReposicao: 20,
        pontoEquilibrio: 0,
        valorTotalItem: 50,
      ),
    ],
    lucratividadePartialFailureAgentNames: const <String>['Detail Agent'],
  );
}

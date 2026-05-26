import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_lucratividade_mensal_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_lucratividade_row.dart';
import 'package:colmeia/features/overview/data/models/overview_model.dart';
import 'package:colmeia/features/overview/domain/entities/overview.dart';
import 'package:colmeia/features/overview/domain/entities/overview_agent_ranking.dart';
import 'package:colmeia/features/overview/domain/entities/overview_monthly_parcel_point.dart';
import 'package:colmeia/features/overview/domain/entities/overview_payment_kpis.dart';
import 'package:colmeia/features/overview/domain/entities/overview_payment_method_breakdown.dart';
import 'package:colmeia/features/overview/domain/entities/overview_user_ranking.dart';
import 'package:colmeia/features/overview/domain/entities/overview_weekday_sales_trend_point.dart';
import 'package:colmeia/features/overview/domain/entities/overview_weekday_user_sales_trend_point.dart';
import 'package:colmeia/shared/charts/daily_sales_trend_point.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OverviewModel', () {
    group('fromJson / toJson round-trip', () {
      test('preserves core fields through encode/decode cycle', () {
        final original = _fullModel();
        final decoded = OverviewModel.decode(original.encode());

        check(decoded.periodStart).equals(original.periodStart);
        check(decoded.periodEnd).equals(original.periodEnd);

        final kpis = decoded.kpis;
        check(kpis.totalSalesCount).equals(original.kpis.totalSalesCount);
        check(kpis.totalAmount).equals(original.kpis.totalAmount);
        check(kpis.averageTicket).equals(original.kpis.averageTicket);
        check(kpis.paymentMethodCount).equals(original.kpis.paymentMethodCount);

        check(decoded.paymentMethods).length.equals(2);
        check(decoded.paymentMethods.first.code).equals('PIX');
        check(decoded.paymentMethods.first.sharePercent).equals(60);

        check(decoded.agentRankings).length.equals(1);
        check(decoded.agentRankings.first.agentId).equals('a1');

        check(decoded.userRankings).length.equals(1);
        check(decoded.userRankings.first.userName).equals('Caixa 01');

        check(decoded.monthlyParcelTrend).length.equals(1);
        check(decoded.monthlyParcelTrend.single.anoMes).equals('2026/03');
        check(decoded.monthlyParcelTrend.single.qtdVendas).equals(5);
        check(decoded.monthlyParcelTrendLoadFailed).isFalse();
        check(decoded.weekdaySalesTrend).length.equals(1);
        check(decoded.weekdaySalesTrend.single.weekdayNumber).equals(2);
        check(decoded.weekdaySalesTrend.single.salesCount).equals(12);
        check(decoded.weekdaySalesTrend.single.salesAmount).equals(180.5);
        check(decoded.weekdaySalesTrendLoadFailed).isFalse();
        check(decoded.weekdayUserSalesTrend).isEmpty();
        check(decoded.weekdayUserSalesTrendLoadFailed).isFalse();
        check(decoded.dailySalesTrend).length.equals(1);
        check(decoded.dailySalesTrend.single.saleDate).equals(
          DateTime(2026, 4, 7),
        );
        check(decoded.dailySalesTrend.single.salesCount).equals(8);
        check(decoded.dailySalesTrendLoadFailed).isFalse();
        check(decoded.lucratividadeMensalTrend).length.equals(1);
        check(decoded.lucratividadeMensalTrend.single.anoMes).equals(
          '2026/04',
        );
        check(decoded.lucratividadeMensalTrendLoadFailed).isFalse();
        check(decoded.lucratividadeTrend).length.equals(1);
        check(decoded.lucratividadeTrend.single.chartAxisLabel).equals(
          'Agente 1',
        );
        check(decoded.lucratividadeTrendLoadFailed).isFalse();
      });

      test('fromJson still reads legacy persisted weekday-by-user keys', () {
        final decoded = OverviewModel.fromJson(<String, dynamic>{
          'periodStart': '2026-03-09T00:00:00.000',
          'periodEnd': '2026-04-07T00:00:00.000',
          'kpis': <String, Object?>{
            'totalSalesCount': 100,
            'totalAmount': 9000,
            'averageTicket': 90,
            'paymentMethodCount': 2,
          },
          'paymentMethods': const <Map<String, Object?>>[],
          'agentRankings': const <Map<String, Object?>>[],
          'userRankings': const <Map<String, Object?>>[],
          'weekdayUserSalesTrend': <Map<String, Object?>>[
            <String, Object?>{
              'weekdayNumber': 3,
              'userName': 'Bob',
              'salesCount': 2,
              'salesAmount': 22.0,
            },
          ],
          'weekdayUserSalesTrendLoadFailed': false,
        });

        check(decoded.weekdayUserSalesTrend).length.equals(1);
        check(decoded.weekdayUserSalesTrend.single.userName).equals('Bob');
        check(decoded.weekdayUserSalesTrendLoadFailed).isFalse();
      });

      test('preserves cache metadata through encode/decode', () {
        final base = _fullModel();
        final original = OverviewModel(
          periodStart: base.periodStart,
          periodEnd: base.periodEnd,
          kpis: base.kpis,
          paymentMethods: base.paymentMethods,
          agentRankings: base.agentRankings,
          userRankings: base.userRankings,
          cachedAt: DateTime.utc(2026, 4, 8, 12),
          sourceAgentIds: const <String>['z', 'a'],
        );
        final decoded = OverviewModel.decode(original.encode());

        check(decoded.cachedAt).equals(original.cachedAt);
        check(decoded.sourceAgentIds!).deepEquals(<String>['z', 'a']);
      });

      test('handles empty lists gracefully', () {
        final model = OverviewModel(
          periodStart: DateTime(2026, 3, 9),
          periodEnd: DateTime(2026, 4, 7),
          kpis: const OverviewPaymentKpis(
            totalSalesCount: 0,
            totalAmount: 0,
            averageTicket: 0,
            paymentMethodCount: 0,
          ),
          paymentMethods: const <OverviewPaymentMethodBreakdown>[],
          agentRankings: const <OverviewAgentRanking>[],
          userRankings: const <OverviewUserRanking>[],
        );

        final decoded = OverviewModel.decode(model.encode());

        check(decoded.paymentMethods).isEmpty();
        check(decoded.agentRankings).isEmpty();
        check(decoded.userRankings).isEmpty();
        check(decoded.kpis.totalSalesCount).equals(0);
        check(decoded.monthlyParcelTrend).isEmpty();
        check(decoded.monthlyParcelTrendLoadFailed).isFalse();
        check(decoded.weekdaySalesTrend).isEmpty();
        check(decoded.weekdaySalesTrendLoadFailed).isFalse();
        check(decoded.weekdayUserSalesTrend).isEmpty();
        check(decoded.weekdayUserSalesTrendLoadFailed).isFalse();
        check(decoded.dailySalesTrend).isEmpty();
        check(decoded.dailySalesTrendLoadFailed).isFalse();
        check(decoded.lucratividadeMensalTrend).isEmpty();
        check(decoded.lucratividadeMensalTrendLoadFailed).isFalse();
        check(decoded.lucratividadeTrend).isEmpty();
        check(decoded.lucratividadeTrendLoadFailed).isFalse();
      });

      test('defaults missing weekday cache fields safely', () {
        final decoded = OverviewModel.fromJson(<String, dynamic>{
          'periodStart': '2026-03-09T00:00:00.000',
          'periodEnd': '2026-04-07T00:00:00.000',
          'kpis': <String, Object?>{
            'totalSalesCount': 100,
            'totalAmount': 9000,
            'averageTicket': 90,
            'paymentMethodCount': 2,
          },
          'paymentMethods': const <Map<String, Object?>>[],
          'agentRankings': const <Map<String, Object?>>[],
          'userRankings': const <Map<String, Object?>>[],
        });

        check(decoded.weekdaySalesTrend).isEmpty();
        check(decoded.weekdaySalesTrendLoadFailed).isFalse();
        check(decoded.weekdayUserSalesTrend).isEmpty();
        check(decoded.weekdayUserSalesTrendLoadFailed).isFalse();
        check(decoded.dailySalesTrend).isEmpty();
        check(decoded.dailySalesTrendLoadFailed).isFalse();
        check(decoded.lucratividadeMensalTrend).isEmpty();
        check(decoded.lucratividadeMensalTrendLoadFailed).isFalse();
        check(decoded.lucratividadeTrend).isEmpty();
        check(decoded.lucratividadeTrendLoadFailed).isFalse();
      });
    });

    group('toEntity / fromEntity', () {
      test('toEntity maps to domain entity correctly', () {
        final model = _fullModel();
        final entity = model.toEntity();

        check(entity.periodStart).equals(model.periodStart);
        check(entity.kpis.totalSalesCount).equals(100);
        check(entity.paymentMethods).length.equals(2);
        check(entity.paymentMethods.first.code).equals('PIX');
        check(entity.agentRankings.single.agentId).equals('a1');
        check(entity.userRankings.single.averageTicket).equals(90);
        check(entity.monthlyParcelTrend.single.anoMes).equals('2026/03');
        check(entity.monthlyParcelTrendLoadFailed).isFalse();
        check(entity.weekdaySalesTrend.single.weekdayNumber).equals(2);
        check(entity.weekdaySalesTrend.single.salesCount).equals(12);
        check(entity.weekdaySalesTrendLoadFailed).isFalse();
        check(entity.weekdayUserSalesTrend.single.userName).equals('Alice');
        check(entity.weekdayUserSalesTrendLoadFailed).isFalse();
        check(entity.dailySalesTrend.single.salesCount).equals(8);
        check(entity.dailySalesTrendLoadFailed).isFalse();
        check(entity.lucratividadeMensalTrend.single.anoMes).equals('2026/04');
        check(entity.lucratividadeMensalTrendLoadFailed).isFalse();
        check(entity.lucratividadeTrend.single.chartAxisLabel).equals(
          'Agente 1',
        );
        check(entity.lucratividadeTrendLoadFailed).isFalse();
      });

      test('fromEntity preserves overview data', () {
        final entity = Overview(
          periodStart: DateTime(2026, 3, 9),
          periodEnd: DateTime(2026, 4, 7),
          kpis: const OverviewPaymentKpis(
            totalSalesCount: 50,
            totalAmount: 4500,
            averageTicket: 90,
            paymentMethodCount: 1,
          ),
          paymentMethods: const <OverviewPaymentMethodBreakdown>[
            OverviewPaymentMethodBreakdown(
              code: 'DIN',
              label: 'Dinheiro',
              totalSalesCount: 50,
              totalAmount: 4500,
              averageTicket: 90,
              sharePercent: 100,
            ),
          ],
          agentRankings: const <OverviewAgentRanking>[],
          userRankings: const <OverviewUserRanking>[],
          monthlyParcelTrend: const <OverviewMonthlyParcelPoint>[
            OverviewMonthlyParcelPoint(
              anoMes: '2026/04',
              qtdVendas: 3,
              valorParcela: 99,
            ),
          ],
          monthlyParcelTrendLoadFailed: true,
          weekdaySalesTrend: const <OverviewWeekdaySalesTrendPoint>[
            OverviewWeekdaySalesTrendPoint(
              weekdayNumber: 5,
              salesCount: 7,
              salesAmount: 333,
            ),
          ],
          weekdaySalesTrendLoadFailed: true,
          dailySalesTrend: <DailySalesTrendPoint>[
            DailySalesTrendPoint(
              saleDate: DateTime(2026, 4, 7),
              salesCount: 11,
              salesAmount: 990,
            ),
          ],
          dailySalesTrendLoadFailed: true,
          lucratividadeMensalTrend:
              const <ResumoProdutoVendaLucratividadeMensalRow>[
                ResumoProdutoVendaLucratividadeMensalRow(
                  codEmpresa: 1,
                  codFilial: 1,
                  ano: 2026,
                  mes: 4,
                  anoMes: '2026/04',
                  qtdVendas: 5,
                  qtdItensVendido: 6,
                  valorTotalCustoMedio: 50,
                  custoReposicao: 60,
                  pontoEquilibrio: 70,
                  valorTotalItem: 150,
                ),
              ],
          lucratividadeMensalTrendLoadFailed: true,
          lucratividadeTrend: const <ResumoProdutoVendaLucratividadeRow>[
            ResumoProdutoVendaLucratividadeRow(
              codEmpresa: 1,
              codFilial: 2,
              qtdVendas: 8,
              qtdItensVendido: 10,
              valorTotalCustoMedio: 100,
              custoReposicao: 120,
              pontoEquilibrio: 130,
              valorTotalItem: 300,
              chartAxisLabel: 'Loja 2',
            ),
          ],
          lucratividadeTrendLoadFailed: true,
        );

        final model = OverviewModel.fromEntity(entity);

        check(model.kpis.totalSalesCount).equals(50);
        check(model.paymentMethods.single.code).equals('DIN');
        check(model.agentRankings).isEmpty();
        check(model.monthlyParcelTrend.single.anoMes).equals('2026/04');
        check(model.monthlyParcelTrendLoadFailed).isTrue();
        check(model.weekdaySalesTrend.single.weekdayNumber).equals(5);
        check(model.weekdaySalesTrendLoadFailed).isTrue();
        check(model.dailySalesTrend.single.saleDate).equals(
          DateTime(2026, 4, 7),
        );
        check(model.dailySalesTrendLoadFailed).isTrue();
        check(model.lucratividadeMensalTrend.single.anoMes).equals('2026/04');
        check(model.lucratividadeMensalTrendLoadFailed).isTrue();
        check(model.lucratividadeTrend.single.chartAxisLabel).equals('Loja 2');
        check(model.lucratividadeTrendLoadFailed).isTrue();
      });
    });

    group('Overview helpers', () {
      test('hasRows is false when paymentMethods is empty', () {
        final overview = Overview(
          periodStart: DateTime(2026, 3, 9),
          periodEnd: DateTime(2026, 4, 7),
          kpis: const OverviewPaymentKpis(
            totalSalesCount: 0,
            totalAmount: 0,
            averageTicket: 0,
            paymentMethodCount: 0,
          ),
          paymentMethods: const <OverviewPaymentMethodBreakdown>[],
          agentRankings: const <OverviewAgentRanking>[],
          userRankings: const <OverviewUserRanking>[],
        );

        check(overview.hasRows).isFalse();
        check(overview.leadingPaymentMethod).isNull();
      });

      test('leadingPaymentMethod returns first payment method', () {
        final overview = Overview(
          periodStart: DateTime(2026, 3, 9),
          periodEnd: DateTime(2026, 4, 7),
          kpis: const OverviewPaymentKpis(
            totalSalesCount: 10,
            totalAmount: 900,
            averageTicket: 90,
            paymentMethodCount: 2,
          ),
          paymentMethods: const <OverviewPaymentMethodBreakdown>[
            OverviewPaymentMethodBreakdown(
              code: 'PIX',
              label: 'Pix',
              totalSalesCount: 7,
              totalAmount: 630,
              averageTicket: 90,
              sharePercent: 70,
            ),
            OverviewPaymentMethodBreakdown(
              code: 'CRED',
              label: 'Credito',
              totalSalesCount: 3,
              totalAmount: 270,
              averageTicket: 90,
              sharePercent: 30,
            ),
          ],
          agentRankings: const <OverviewAgentRanking>[],
          userRankings: const <OverviewUserRanking>[],
        );

        check(overview.hasRows).isTrue();
        check(overview.leadingPaymentMethod).isNotNull();
        check(overview.leadingPaymentMethod!.code).equals('PIX');
      });
    });
  });
}

OverviewModel _fullModel() {
  return OverviewModel(
    periodStart: DateTime(2026, 3, 9),
    periodEnd: DateTime(2026, 4, 7),
    kpis: const OverviewPaymentKpis(
      totalSalesCount: 100,
      totalAmount: 9000,
      averageTicket: 90,
      paymentMethodCount: 2,
    ),
    paymentMethods: const <OverviewPaymentMethodBreakdown>[
      OverviewPaymentMethodBreakdown(
        code: 'PIX',
        label: 'Pix',
        totalSalesCount: 60,
        totalAmount: 5400,
        averageTicket: 90,
        sharePercent: 60,
      ),
      OverviewPaymentMethodBreakdown(
        code: 'CRED',
        label: 'Credito',
        totalSalesCount: 40,
        totalAmount: 3600,
        averageTicket: 90,
        sharePercent: 40,
      ),
    ],
    agentRankings: const <OverviewAgentRanking>[
      OverviewAgentRanking(
        agentId: 'a1',
        displayName: 'Agente 1',
        totalSalesCount: 100,
        totalAmount: 9000,
      ),
    ],
    userRankings: const <OverviewUserRanking>[
      OverviewUserRanking(
        userName: 'Caixa 01',
        totalSalesCount: 100,
        totalAmount: 9000,
        averageTicket: 90,
      ),
    ],
    monthlyParcelTrend: const <OverviewMonthlyParcelPoint>[
      OverviewMonthlyParcelPoint(
        anoMes: '2026/03',
        qtdVendas: 5,
        valorParcela: 150.25,
      ),
    ],
    weekdaySalesTrend: const <OverviewWeekdaySalesTrendPoint>[
      OverviewWeekdaySalesTrendPoint(
        weekdayNumber: 2,
        salesCount: 12,
        salesAmount: 180.5,
      ),
    ],
    weekdayUserSalesTrend: const <OverviewWeekdayUserSalesTrendPoint>[
      OverviewWeekdayUserSalesTrendPoint(
        weekdayNumber: 2,
        userName: 'Alice',
        salesCount: 3,
        salesAmount: 40,
      ),
    ],
    dailySalesTrend: <DailySalesTrendPoint>[
      DailySalesTrendPoint(
        saleDate: DateTime(2026, 4, 7),
        salesCount: 8,
        salesAmount: 720,
      ),
    ],
    lucratividadeMensalTrend: const <ResumoProdutoVendaLucratividadeMensalRow>[
      ResumoProdutoVendaLucratividadeMensalRow(
        codEmpresa: 1,
        codFilial: 1,
        ano: 2026,
        mes: 4,
        anoMes: '2026/04',
        qtdVendas: 10,
        qtdItensVendido: 12,
        valorTotalCustoMedio: 100,
        custoReposicao: 120,
        pontoEquilibrio: 130,
        valorTotalItem: 300,
      ),
    ],
    lucratividadeTrend: const <ResumoProdutoVendaLucratividadeRow>[
      ResumoProdutoVendaLucratividadeRow(
        codEmpresa: 1,
        codFilial: 1,
        qtdVendas: 10,
        qtdItensVendido: 12,
        valorTotalCustoMedio: 100,
        custoReposicao: 120,
        pontoEquilibrio: 130,
        valorTotalItem: 300,
        chartAxisLabel: 'Agente 1',
      ),
    ],
  );
}

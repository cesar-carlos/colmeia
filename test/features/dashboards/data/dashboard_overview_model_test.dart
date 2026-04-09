import 'package:checks/checks.dart';
import 'package:colmeia/features/dashboards/data/models/dashboard_overview_model.dart';
import 'package:colmeia/features/dashboards/domain/entities/dashboard_agent_ranking.dart';
import 'package:colmeia/features/dashboards/domain/entities/dashboard_overview.dart';
import 'package:colmeia/features/dashboards/domain/entities/dashboard_payment_kpis.dart';
import 'package:colmeia/features/dashboards/domain/entities/dashboard_payment_method_breakdown.dart';
import 'package:colmeia/features/dashboards/domain/entities/dashboard_user_ranking.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DashboardOverviewModel', () {
    group('fromJson / toJson round-trip', () {
      test('preserves all fields through encode/decode cycle', () {
        final original = _fullModel();
        final decoded = DashboardOverviewModel.decode(original.encode());

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
      });

      test('preserves cache metadata through encode/decode', () {
        final base = _fullModel();
        final original = DashboardOverviewModel(
          periodStart: base.periodStart,
          periodEnd: base.periodEnd,
          kpis: base.kpis,
          paymentMethods: base.paymentMethods,
          agentRankings: base.agentRankings,
          userRankings: base.userRankings,
          cachedAt: DateTime.utc(2026, 4, 8, 12),
          sourceAgentIds: const <String>['z', 'a'],
        );
        final decoded = DashboardOverviewModel.decode(original.encode());

        check(decoded.cachedAt).equals(original.cachedAt);
        check(decoded.sourceAgentIds!).deepEquals(<String>['z', 'a']);
      });

      test('handles empty lists gracefully', () {
        final model = DashboardOverviewModel(
          periodStart: DateTime(2026, 3, 9),
          periodEnd: DateTime(2026, 4, 7),
          kpis: const DashboardPaymentKpis(
            totalSalesCount: 0,
            totalAmount: 0,
            averageTicket: 0,
            paymentMethodCount: 0,
          ),
          paymentMethods: const <DashboardPaymentMethodBreakdown>[],
          agentRankings: const <DashboardAgentRanking>[],
          userRankings: const <DashboardUserRanking>[],
        );

        final decoded = DashboardOverviewModel.decode(model.encode());

        check(decoded.paymentMethods).isEmpty();
        check(decoded.agentRankings).isEmpty();
        check(decoded.userRankings).isEmpty();
        check(decoded.kpis.totalSalesCount).equals(0);
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
      });

      test('fromEntity preserves overview data', () {
        final entity = DashboardOverview(
          periodStart: DateTime(2026, 3, 9),
          periodEnd: DateTime(2026, 4, 7),
          kpis: const DashboardPaymentKpis(
            totalSalesCount: 50,
            totalAmount: 4500,
            averageTicket: 90,
            paymentMethodCount: 1,
          ),
          paymentMethods: const <DashboardPaymentMethodBreakdown>[
            DashboardPaymentMethodBreakdown(
              code: 'DIN',
              label: 'Dinheiro',
              totalSalesCount: 50,
              totalAmount: 4500,
              averageTicket: 90,
              sharePercent: 100,
            ),
          ],
          agentRankings: const <DashboardAgentRanking>[],
          userRankings: const <DashboardUserRanking>[],
        );

        final model = DashboardOverviewModel.fromEntity(entity);

        check(model.kpis.totalSalesCount).equals(50);
        check(model.paymentMethods.single.code).equals('DIN');
        check(model.agentRankings).isEmpty();
      });
    });

    group('DashboardOverview helpers', () {
      test('hasRows is false when paymentMethods is empty', () {
        final overview = DashboardOverview(
          periodStart: DateTime(2026, 3, 9),
          periodEnd: DateTime(2026, 4, 7),
          kpis: const DashboardPaymentKpis(
            totalSalesCount: 0,
            totalAmount: 0,
            averageTicket: 0,
            paymentMethodCount: 0,
          ),
          paymentMethods: const <DashboardPaymentMethodBreakdown>[],
          agentRankings: const <DashboardAgentRanking>[],
          userRankings: const <DashboardUserRanking>[],
        );

        check(overview.hasRows).isFalse();
        check(overview.leadingPaymentMethod).isNull();
      });

      test('leadingPaymentMethod returns first payment method', () {
        final overview = DashboardOverview(
          periodStart: DateTime(2026, 3, 9),
          periodEnd: DateTime(2026, 4, 7),
          kpis: const DashboardPaymentKpis(
            totalSalesCount: 10,
            totalAmount: 900,
            averageTicket: 90,
            paymentMethodCount: 2,
          ),
          paymentMethods: const <DashboardPaymentMethodBreakdown>[
            DashboardPaymentMethodBreakdown(
              code: 'PIX',
              label: 'Pix',
              totalSalesCount: 7,
              totalAmount: 630,
              averageTicket: 90,
              sharePercent: 70,
            ),
            DashboardPaymentMethodBreakdown(
              code: 'CRED',
              label: 'Credito',
              totalSalesCount: 3,
              totalAmount: 270,
              averageTicket: 90,
              sharePercent: 30,
            ),
          ],
          agentRankings: const <DashboardAgentRanking>[],
          userRankings: const <DashboardUserRanking>[],
        );

        check(overview.hasRows).isTrue();
        check(overview.leadingPaymentMethod).isNotNull();
        check(overview.leadingPaymentMethod!.code).equals('PIX');
      });
    });
  });
}

DashboardOverviewModel _fullModel() {
  return DashboardOverviewModel(
    periodStart: DateTime(2026, 3, 9),
    periodEnd: DateTime(2026, 4, 7),
    kpis: const DashboardPaymentKpis(
      totalSalesCount: 100,
      totalAmount: 9000,
      averageTicket: 90,
      paymentMethodCount: 2,
    ),
    paymentMethods: const <DashboardPaymentMethodBreakdown>[
      DashboardPaymentMethodBreakdown(
        code: 'PIX',
        label: 'Pix',
        totalSalesCount: 60,
        totalAmount: 5400,
        averageTicket: 90,
        sharePercent: 60,
      ),
      DashboardPaymentMethodBreakdown(
        code: 'CRED',
        label: 'Credito',
        totalSalesCount: 40,
        totalAmount: 3600,
        averageTicket: 90,
        sharePercent: 40,
      ),
    ],
    agentRankings: const <DashboardAgentRanking>[
      DashboardAgentRanking(
        agentId: 'a1',
        displayName: 'Agente 1',
        totalSalesCount: 100,
        totalAmount: 9000,
      ),
    ],
    userRankings: const <DashboardUserRanking>[
      DashboardUserRanking(
        userName: 'Caixa 01',
        totalSalesCount: 100,
        totalAmount: 9000,
        averageTicket: 90,
      ),
    ],
  );
}

import 'package:colmeia/features/dashboards/data/models/dashboard_overview_model.dart';
import 'package:colmeia/features/dashboards/domain/entities/dashboard_filial_ranking.dart';
import 'package:colmeia/features/dashboards/domain/entities/dashboard_payment_kpis.dart';
import 'package:colmeia/features/dashboards/domain/entities/dashboard_payment_method_breakdown.dart';
import 'package:colmeia/features/dashboards/domain/entities/dashboard_user_ranking.dart';

/// Stub — dashboard data is now sourced from agent_queries.
/// Retained for feature-flag controlled rollouts. Will be removed once the
/// agent path is stable in production.
class ApiDashboardRemoteDataSource {
  const ApiDashboardRemoteDataSource();

  Future<DashboardOverviewModel> fetchOverview({
    required String userId,
  }) async {
    throw UnimplementedError(
      'Dashboard overview is now sourced from agent_queries.',
    );
  }
}

class FakeDashboardRemoteDataSource {
  const FakeDashboardRemoteDataSource();

  Future<DashboardOverviewModel> fetchOverview({
    required String userId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final end = DateTime.now();
    final start = end.subtract(const Duration(days: 29));

    return DashboardOverviewModel(
      periodStart: start,
      periodEnd: end,
      kpis: const DashboardPaymentKpis(
        totalSalesCount: 310,
        totalAmount: 27850.75,
        averageTicket: 89.84,
        paymentMethodCount: 4,
      ),
      paymentMethods: const <DashboardPaymentMethodBreakdown>[
        DashboardPaymentMethodBreakdown(
          code: 'PIX',
          label: 'Pix',
          totalSalesCount: 144,
          totalAmount: 12450.20,
          averageTicket: 86.46,
          sharePercent: 44.7,
        ),
        DashboardPaymentMethodBreakdown(
          code: 'CRED',
          label: 'Cartao de credito',
          totalSalesCount: 92,
          totalAmount: 9650.30,
          averageTicket: 104.89,
          sharePercent: 34.6,
        ),
        DashboardPaymentMethodBreakdown(
          code: 'DEB',
          label: 'Cartao de debito',
          totalSalesCount: 51,
          totalAmount: 3710,
          averageTicket: 72.75,
          sharePercent: 13.3,
        ),
        DashboardPaymentMethodBreakdown(
          code: 'DIN',
          label: 'Dinheiro',
          totalSalesCount: 23,
          totalAmount: 2040.25,
          averageTicket: 88.70,
          sharePercent: 7.4,
        ),
      ],
      filialRankings: const <DashboardFilialRanking>[
        DashboardFilialRanking(
          codEmpresa: 1,
          codFilial: 3,
          totalSalesCount: 130,
          totalAmount: 11800.40,
        ),
        DashboardFilialRanking(
          codEmpresa: 1,
          codFilial: 8,
          totalSalesCount: 102,
          totalAmount: 9570.10,
        ),
        DashboardFilialRanking(
          codEmpresa: 1,
          codFilial: 14,
          totalSalesCount: 78,
          totalAmount: 6480.25,
        ),
      ],
      userRankings: const <DashboardUserRanking>[
        DashboardUserRanking(
          userName: 'Caixa 01',
          totalSalesCount: 84,
          totalAmount: 7750.10,
          averageTicket: 92.26,
        ),
        DashboardUserRanking(
          userName: 'Caixa 02',
          totalSalesCount: 73,
          totalAmount: 6540.60,
          averageTicket: 89.60,
        ),
        DashboardUserRanking(
          userName: 'Caixa 03',
          totalSalesCount: 58,
          totalAmount: 5210.25,
          averageTicket: 89.83,
        ),
      ],
    );
  }
}

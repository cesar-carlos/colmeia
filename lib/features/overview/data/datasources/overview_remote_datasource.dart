import 'package:colmeia/features/overview/data/models/overview_model.dart';
import 'package:colmeia/features/overview/domain/entities/overview_agent_ranking.dart';
import 'package:colmeia/features/overview/domain/entities/overview_payment_kpis.dart';
import 'package:colmeia/features/overview/domain/entities/overview_payment_method_breakdown.dart';
import 'package:colmeia/features/overview/domain/entities/overview_user_ranking.dart';

/// Stub — overview data is now sourced from agent_queries.
/// Retained for feature-flag controlled rollouts. Will be removed once the
/// agent path is stable in production.
class ApiOverviewRemoteDataSource {
  const ApiOverviewRemoteDataSource();

  Future<OverviewModel> fetchOverview({
    required String userId,
  }) async {
    throw UnimplementedError(
      'Overview is now sourced from agent_queries.',
    );
  }
}

class FakeOverviewRemoteDataSource {
  const FakeOverviewRemoteDataSource();

  Future<OverviewModel> fetchOverview({
    required String userId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final end = DateTime.now();
    final start = end.subtract(const Duration(days: 29));

    return OverviewModel(
      periodStart: start,
      periodEnd: end,
      kpis: const OverviewPaymentKpis(
        totalSalesCount: 310,
        totalAmount: 27850.75,
        averageTicket: 89.84,
        paymentMethodCount: 4,
      ),
      paymentMethods: const <OverviewPaymentMethodBreakdown>[
        OverviewPaymentMethodBreakdown(
          code: 'PIX',
          label: 'Pix',
          totalSalesCount: 144,
          totalAmount: 12450.20,
          averageTicket: 86.46,
          sharePercent: 44.7,
        ),
        OverviewPaymentMethodBreakdown(
          code: 'CRED',
          label: 'Cartao de credito',
          totalSalesCount: 92,
          totalAmount: 9650.30,
          averageTicket: 104.89,
          sharePercent: 34.6,
        ),
        OverviewPaymentMethodBreakdown(
          code: 'DEB',
          label: 'Cartao de debito',
          totalSalesCount: 51,
          totalAmount: 3710,
          averageTicket: 72.75,
          sharePercent: 13.3,
        ),
        OverviewPaymentMethodBreakdown(
          code: 'DIN',
          label: 'Dinheiro',
          totalSalesCount: 23,
          totalAmount: 2040.25,
          averageTicket: 88.70,
          sharePercent: 7.4,
        ),
      ],
      agentRankings: const <OverviewAgentRanking>[
        OverviewAgentRanking(
          agentId: 'agent-a',
          displayName: 'Agente Alpha',
          totalSalesCount: 130,
          totalAmount: 11800.40,
        ),
        OverviewAgentRanking(
          agentId: 'agent-b',
          displayName: 'Agente Beta',
          totalSalesCount: 102,
          totalAmount: 9570.10,
        ),
        OverviewAgentRanking(
          agentId: 'agent-c',
          displayName: 'Agente Gamma',
          totalSalesCount: 78,
          totalAmount: 6480.25,
        ),
      ],
      userRankings: const <OverviewUserRanking>[
        OverviewUserRanking(
          userName: 'Caixa 01',
          totalSalesCount: 84,
          totalAmount: 7750.10,
          averageTicket: 92.26,
        ),
        OverviewUserRanking(
          userName: 'Caixa 02',
          totalSalesCount: 73,
          totalAmount: 6540.60,
          averageTicket: 89.60,
        ),
        OverviewUserRanking(
          userName: 'Caixa 03',
          totalSalesCount: 58,
          totalAmount: 5210.25,
          averageTicket: 89.83,
        ),
      ],
    );
  }
}

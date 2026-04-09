import 'package:colmeia/features/dashboards/domain/entities/dashboard_filial_ranking.dart';
import 'package:colmeia/features/dashboards/domain/entities/dashboard_payment_kpis.dart';
import 'package:colmeia/features/dashboards/domain/entities/dashboard_payment_method_breakdown.dart';
import 'package:colmeia/features/dashboards/domain/entities/dashboard_user_ranking.dart';

class DashboardOverview {
  const DashboardOverview({
    required this.periodStart,
    required this.periodEnd,
    required this.kpis,
    required this.paymentMethods,
    required this.filialRankings,
    required this.userRankings,
  });

  final DateTime periodStart;
  final DateTime periodEnd;
  final DashboardPaymentKpis kpis;
  final List<DashboardPaymentMethodBreakdown> paymentMethods;
  final List<DashboardFilialRanking> filialRankings;
  final List<DashboardUserRanking> userRankings;

  bool get hasRows => paymentMethods.isNotEmpty;

  DashboardPaymentMethodBreakdown? get leadingPaymentMethod {
    if (paymentMethods.isEmpty) {
      return null;
    }
    return paymentMethods.first;
  }
}

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
    this.isStaleCache = false,
    this.approvedAgentCount = 0,
    this.agentIdsExcludedFromQueryFailure = const <String>[],
    this.agentIdsMissingClientToken = const <String>[],
  });

  final DateTime periodStart;
  final DateTime periodEnd;
  final DashboardPaymentKpis kpis;
  final List<DashboardPaymentMethodBreakdown> paymentMethods;
  final List<DashboardFilialRanking> filialRankings;
  final List<DashboardUserRanking> userRankings;

  /// True when recovered from local cache after a remote error.
  final bool isStaleCache;

  /// Number of approved agents considered for this load (pagination total).
  final int approvedAgentCount;

  /// Approved agents whose resumo SQL failed; KPIs omit their data.
  final List<String> agentIdsExcludedFromQueryFailure;

  /// Approved agents skipped because no local `client_token` was stored.
  final List<String> agentIdsMissingClientToken;

  bool get hasRows => paymentMethods.isNotEmpty;

  bool get hasPartialAgentQueryFailure =>
      agentIdsExcludedFromQueryFailure.isNotEmpty;

  bool get hasMissingClientToken => agentIdsMissingClientToken.isNotEmpty;

  /// Multiple approved agents are consolidated; overlapping data may inflate
  /// totals if agents are not partitioned server-side.
  bool get shouldShowMultiAgentAggregationNote =>
      approvedAgentCount > 1 && hasRows;

  DashboardPaymentMethodBreakdown? get leadingPaymentMethod {
    if (paymentMethods.isEmpty) {
      return null;
    }
    return paymentMethods.first;
  }
}

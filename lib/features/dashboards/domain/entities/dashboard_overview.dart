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
    this.agentNamesExcludedFromQueryFailure = const <String>[],
    this.agentIdsMissingClientToken = const <String>[],
    this.agentNamesMissingClientToken = const <String>[],
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

  /// Display names for approved agents whose resumo SQL failed.
  final List<String> agentNamesExcludedFromQueryFailure;

  /// Approved agents skipped because no local `client_token` was stored.
  final List<String> agentIdsMissingClientToken;

  /// Display names for approved agents skipped because no local
  /// `client_token` was stored.
  final List<String> agentNamesMissingClientToken;

  bool get hasRows => paymentMethods.isNotEmpty;

  bool get hasPartialAgentQueryFailure =>
      agentIdsExcludedFromQueryFailure.isNotEmpty;

  bool get hasMissingClientToken => agentIdsMissingClientToken.isNotEmpty;

  bool get requiresClientTokenSetup => hasMissingClientToken && !hasRows;

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

  DashboardOverview copyWith({
    DateTime? periodStart,
    DateTime? periodEnd,
    DashboardPaymentKpis? kpis,
    List<DashboardPaymentMethodBreakdown>? paymentMethods,
    List<DashboardFilialRanking>? filialRankings,
    List<DashboardUserRanking>? userRankings,
    bool? isStaleCache,
    int? approvedAgentCount,
    List<String>? agentIdsExcludedFromQueryFailure,
    List<String>? agentNamesExcludedFromQueryFailure,
    List<String>? agentIdsMissingClientToken,
    List<String>? agentNamesMissingClientToken,
  }) {
    return DashboardOverview(
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd ?? this.periodEnd,
      kpis: kpis ?? this.kpis,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      filialRankings: filialRankings ?? this.filialRankings,
      userRankings: userRankings ?? this.userRankings,
      isStaleCache: isStaleCache ?? this.isStaleCache,
      approvedAgentCount: approvedAgentCount ?? this.approvedAgentCount,
      agentIdsExcludedFromQueryFailure:
          agentIdsExcludedFromQueryFailure ??
          this.agentIdsExcludedFromQueryFailure,
      agentNamesExcludedFromQueryFailure:
          agentNamesExcludedFromQueryFailure ??
          this.agentNamesExcludedFromQueryFailure,
      agentIdsMissingClientToken:
          agentIdsMissingClientToken ?? this.agentIdsMissingClientToken,
      agentNamesMissingClientToken:
          agentNamesMissingClientToken ?? this.agentNamesMissingClientToken,
    );
  }
}

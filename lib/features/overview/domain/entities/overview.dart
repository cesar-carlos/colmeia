import 'package:colmeia/features/overview/domain/entities/overview_agent_ranking.dart';
import 'package:colmeia/features/overview/domain/entities/overview_monthly_parcel_point.dart';
import 'package:colmeia/features/overview/domain/entities/overview_payment_kpis.dart';
import 'package:colmeia/features/overview/domain/entities/overview_payment_method_breakdown.dart';
import 'package:colmeia/features/overview/domain/entities/overview_user_ranking.dart';
import 'package:colmeia/features/overview/domain/entities/overview_weekday_sales_trend_point.dart';
import 'package:colmeia/features/overview/domain/entities/overview_weekday_user_sales_trend_point.dart';

class Overview {
  const Overview({
    required this.periodStart,
    required this.periodEnd,
    required this.kpis,
    required this.paymentMethods,
    required this.agentRankings,
    required this.userRankings,
    this.monthlyParcelTrend = const <OverviewMonthlyParcelPoint>[],
    this.monthlyParcelTrendLoadFailed = false,
    this.monthlyParcelTrendLoadFailureMessage,
    this.weekdaySalesTrend = const <OverviewWeekdaySalesTrendPoint>[],
    this.weekdaySalesTrendLoadFailed = false,
    this.weekdaySalesTrendLoadFailureMessage,
    this.weekdayUserSalesTrend = const <OverviewWeekdayUserSalesTrendPoint>[],
    this.weekdayUserSalesTrendLoadFailed = false,
    this.weekdayUserSalesTrendLoadFailureMessage,
    this.isStaleCache = false,
    this.approvedAgentCount = 0,
    this.agentIdsExcludedFromQueryFailure = const <String>[],
    this.agentNamesExcludedFromQueryFailure = const <String>[],
    this.agentIdsMissingClientToken = const <String>[],
    this.agentNamesMissingClientToken = const <String>[],
    this.mainResumoHadPlannedTargets = false,
  });

  final DateTime periodStart;
  final DateTime periodEnd;
  final OverviewPaymentKpis kpis;
  final List<OverviewPaymentMethodBreakdown> paymentMethods;
  final List<OverviewAgentRanking> agentRankings;
  final List<OverviewUserRanking> userRankings;

  /// Last 12 calendar months of parcel totals (sales count and amount) for
  /// the home chart. Empty when unavailable or not loaded (e.g. stale cache).
  final List<OverviewMonthlyParcelPoint> monthlyParcelTrend;

  /// True when the monthly resumo query failed; [monthlyParcelTrend] may be
  /// empty for this reason instead of genuinely having no rows.
  final bool monthlyParcelTrendLoadFailed;

  /// Specific user-facing message extracted from the underlying `AppFailure`
  /// (e.g. "Voce nao tem acesso a este agente.", "SQL invalido na query …").
  /// Charts use this when [monthlyParcelTrendLoadFailed] is true to give the
  /// user actionable context instead of a generic "could not load chart".
  /// Null when the failure was not user-facing or the load succeeded.
  final String? monthlyParcelTrendLoadFailureMessage;

  /// Weekday distribution (Sunday..Saturday) for the selected period.
  final List<OverviewWeekdaySalesTrendPoint> weekdaySalesTrend;

  /// True when the weekday resumo query failed; [weekdaySalesTrend] may be
  /// empty for this reason instead of genuinely having no rows.
  final bool weekdaySalesTrendLoadFailed;

  /// See [monthlyParcelTrendLoadFailureMessage] — same semantics for the
  /// weekday-sales chart.
  final String? weekdaySalesTrendLoadFailureMessage;

  /// Weekday distribution per user (merged across branches/agents) for the
  /// selected period.
  final List<OverviewWeekdayUserSalesTrendPoint> weekdayUserSalesTrend;

  /// True when the weekday-by-user resumo query failed; [weekdayUserSalesTrend]
  /// may be empty for this reason instead of genuinely having no rows.
  final bool weekdayUserSalesTrendLoadFailed;

  /// See [monthlyParcelTrendLoadFailureMessage] — same semantics for the
  /// weekday-by-user chart.
  final String? weekdayUserSalesTrendLoadFailureMessage;

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

  /// True when the main forma-pagamento resumo had at least one planned agent
  /// target (so SQL could run), even if merged rows were empty. Drives
  /// [requiresClientTokenSetup] together with [hasMissingClientToken] and
  /// [hasRows] so empty periods are not confused with “no token on device”.
  final bool mainResumoHadPlannedTargets;

  bool get hasRows => paymentMethods.isNotEmpty;

  bool get hasPartialAgentQueryFailure =>
      agentIdsExcludedFromQueryFailure.isNotEmpty;

  bool get hasMissingClientToken => agentIdsMissingClientToken.isNotEmpty;

  bool get requiresClientTokenSetup =>
      hasMissingClientToken && !hasRows && !mainResumoHadPlannedTargets;

  /// Multiple approved agents are consolidated; overlapping data may inflate
  /// totals if agents are not partitioned server-side.
  bool get shouldShowMultiAgentAggregationNote =>
      approvedAgentCount > 1 && hasRows;

  OverviewPaymentMethodBreakdown? get leadingPaymentMethod {
    if (paymentMethods.isEmpty) {
      return null;
    }
    return paymentMethods.first;
  }

  Overview copyWith({
    DateTime? periodStart,
    DateTime? periodEnd,
    OverviewPaymentKpis? kpis,
    List<OverviewPaymentMethodBreakdown>? paymentMethods,
    List<OverviewAgentRanking>? agentRankings,
    List<OverviewUserRanking>? userRankings,
    bool? isStaleCache,
    int? approvedAgentCount,
    List<String>? agentIdsExcludedFromQueryFailure,
    List<String>? agentNamesExcludedFromQueryFailure,
    List<String>? agentIdsMissingClientToken,
    List<String>? agentNamesMissingClientToken,
    List<OverviewMonthlyParcelPoint>? monthlyParcelTrend,
    bool? monthlyParcelTrendLoadFailed,
    String? monthlyParcelTrendLoadFailureMessage,
    List<OverviewWeekdaySalesTrendPoint>? weekdaySalesTrend,
    bool? weekdaySalesTrendLoadFailed,
    String? weekdaySalesTrendLoadFailureMessage,
    List<OverviewWeekdayUserSalesTrendPoint>? weekdayUserSalesTrend,
    bool? weekdayUserSalesTrendLoadFailed,
    String? weekdayUserSalesTrendLoadFailureMessage,
    bool? mainResumoHadPlannedTargets,
  }) {
    return Overview(
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd ?? this.periodEnd,
      kpis: kpis ?? this.kpis,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      agentRankings: agentRankings ?? this.agentRankings,
      userRankings: userRankings ?? this.userRankings,
      monthlyParcelTrend: monthlyParcelTrend ?? this.monthlyParcelTrend,
      monthlyParcelTrendLoadFailed:
          monthlyParcelTrendLoadFailed ?? this.monthlyParcelTrendLoadFailed,
      monthlyParcelTrendLoadFailureMessage:
          monthlyParcelTrendLoadFailureMessage ??
              this.monthlyParcelTrendLoadFailureMessage,
      weekdaySalesTrend: weekdaySalesTrend ?? this.weekdaySalesTrend,
      weekdaySalesTrendLoadFailed:
          weekdaySalesTrendLoadFailed ?? this.weekdaySalesTrendLoadFailed,
      weekdaySalesTrendLoadFailureMessage:
          weekdaySalesTrendLoadFailureMessage ??
              this.weekdaySalesTrendLoadFailureMessage,
      weekdayUserSalesTrend:
          weekdayUserSalesTrend ?? this.weekdayUserSalesTrend,
      weekdayUserSalesTrendLoadFailed: weekdayUserSalesTrendLoadFailed ??
          this.weekdayUserSalesTrendLoadFailed,
      weekdayUserSalesTrendLoadFailureMessage:
          weekdayUserSalesTrendLoadFailureMessage ??
              this.weekdayUserSalesTrendLoadFailureMessage,
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
      mainResumoHadPlannedTargets:
          mainResumoHadPlannedTargets ?? this.mainResumoHadPlannedTargets,
    );
  }
}

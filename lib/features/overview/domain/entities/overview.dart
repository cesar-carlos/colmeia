import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_lucratividade_mensal_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_lucratividade_row.dart';
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
    this.monthlyParcelTrendLoadFailure,
    this.monthlyParcelTrendLoadFailureMessage,
    this.weekdaySalesTrend = const <OverviewWeekdaySalesTrendPoint>[],
    this.weekdaySalesTrendLoadFailed = false,
    this.weekdaySalesTrendLoadFailure,
    this.weekdaySalesTrendLoadFailureMessage,
    this.weekdayUserSalesTrend = const <OverviewWeekdayUserSalesTrendPoint>[],
    this.weekdayUserSalesTrendLoadFailed = false,
    this.weekdayUserSalesTrendLoadFailure,
    this.weekdayUserSalesTrendLoadFailureMessage,
    this.dailySalesTrend = const <DailySalesTrendPoint>[],
    this.dailySalesTrendLoadFailed = false,
    this.dailySalesTrendLoadFailure,
    this.dailySalesTrendLoadFailureMessage,
    this.lucratividadeMensalTrend =
        const <ResumoProdutoVendaLucratividadeMensalRow>[],
    this.lucratividadeMensalTrendLoadFailed = false,
    this.lucratividadeMensalTrendLoadFailure,
    this.lucratividadeMensalTrendLoadFailureMessage,
    this.lucratividadeTrend = const <ResumoProdutoVendaLucratividadeRow>[],
    this.lucratividadeTrendLoadFailed = false,
    this.lucratividadeTrendLoadFailure,
    this.lucratividadeTrendLoadFailureMessage,
    this.lucratividadePartialFailureAgentNames = const <String>[],
    this.approvedAgentCount = 0,
    this.agentIdsExcludedFromQueryFailure = const <String>[],
    this.agentNamesExcludedFromQueryFailure = const <String>[],
    this.agentIdsMissingClientToken = const <String>[],
    this.agentNamesMissingClientToken = const <String>[],
    this.agentIdsSkippedDueToHubPresence = const <String>[],
    this.agentNamesSkippedDueToHubPresence = const <String>[],
    this.mainResumoHadPlannedTargets = false,
    this.partialQueryFailureDetails = const <OverviewAgentQueryFailureDetail>[],
    this.hubPresenceOnlineAgentIdsSnapshot,
  });

  /// Neutral, zeroed snapshot used as a structural placeholder while the
  /// real overview is still loading. Date fields are pinned to the epoch
  /// to make it obvious in logs that this is not a real period.
  factory Overview.empty() {
    return Overview(
      periodStart: DateTime(1970),
      periodEnd: DateTime(1970),
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
  }

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

  /// First section-wide `AppFailure` when every agent in the batch failed.
  /// Localize at presentation via `agentQueryFailureUserMessage`. Transient:
  /// not persisted in overview cache JSON.
  final AppFailure? monthlyParcelTrendLoadFailure;

  /// Legacy cached string from older loads; prefer [monthlyParcelTrendLoadFailure].
  final String? monthlyParcelTrendLoadFailureMessage;

  /// Weekday distribution (Sunday..Saturday) for the selected period.
  final List<OverviewWeekdaySalesTrendPoint> weekdaySalesTrend;

  /// True when the weekday resumo query failed; [weekdaySalesTrend] may be
  /// empty for this reason instead of genuinely having no rows.
  final bool weekdaySalesTrendLoadFailed;

  final AppFailure? weekdaySalesTrendLoadFailure;

  /// See [monthlyParcelTrendLoadFailureMessage] — legacy fallback string.
  final String? weekdaySalesTrendLoadFailureMessage;

  /// Weekday distribution per user (merged across branches/agents) for the
  /// selected period.
  final List<OverviewWeekdayUserSalesTrendPoint> weekdayUserSalesTrend;

  /// True when the weekday-by-user resumo query failed; [weekdayUserSalesTrend]
  /// may be empty for this reason instead of genuinely having no rows.
  final bool weekdayUserSalesTrendLoadFailed;

  final AppFailure? weekdayUserSalesTrendLoadFailure;

  final String? weekdayUserSalesTrendLoadFailureMessage;

  /// Daily sales totals for the selected period (merged across agents/branches).
  final List<DailySalesTrendPoint> dailySalesTrend;

  final bool dailySalesTrendLoadFailed;

  final AppFailure? dailySalesTrendLoadFailure;

  final String? dailySalesTrendLoadFailureMessage;

  /// Monthly product profitability trend (lucratividade mensal): 12 months
  /// ending at the filter month. Each row carries `anoMes`, costs, revenue,
  /// and derived percent metrics (`percentualCustoSobreVenda`,
  /// `margemLucroBrutoPercent`, `markupSobreCustoPercent`). Empty when not
  /// loaded or when the query fails.
  final List<ResumoProdutoVendaLucratividadeMensalRow> lucratividadeMensalTrend;

  /// True when the lucratividade mensal query failed.
  final bool lucratividadeMensalTrendLoadFailed;

  final AppFailure? lucratividadeMensalTrendLoadFailure;

  final String? lucratividadeMensalTrendLoadFailureMessage;

  /// Period product profitability (lucratividade): **one row per agent** for
  /// the overview filter date range (all branches summed per agent). Empty
  /// when not loaded or when the query fails.
  final List<ResumoProdutoVendaLucratividadeRow> lucratividadeTrend;

  /// True when the lucratividade (period, by agent) query failed.
  final bool lucratividadeTrendLoadFailed;

  final AppFailure? lucratividadeTrendLoadFailure;

  final String? lucratividadeTrendLoadFailureMessage;

  /// Agents whose period lucratividade SQL failed while other agents still
  /// contributed rows (partial chart). Empty when all succeeded or all failed.
  final List<String> lucratividadePartialFailureAgentNames;

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

  /// Approved agents that DO have a stored client_token but were
  /// excluded because the hub-presence policy (`is_hub_connected`
  /// from `/client/me/agents`) marked them as offline at dispatch
  /// time. Distinct from [agentIdsMissingClientToken] — fixing the
  /// missing-token agents would NOT bring these agents back. The
  /// agent operator needs to reconnect them to the hub. Surfaced
  /// via a dedicated banner so the user can act on the right axis.
  final List<String> agentIdsSkippedDueToHubPresence;

  /// Display names for [agentIdsSkippedDueToHubPresence].
  final List<String> agentNamesSkippedDueToHubPresence;

  /// True when the main forma-pagamento resumo had at least one planned agent
  /// target (so SQL could run), even if merged rows were empty. Drives
  /// [requiresClientTokenSetup] together with [hasMissingClientToken] and
  /// [hasRows] so empty periods are not confused with “no token on device”.
  final bool mainResumoHadPlannedTargets;

  /// Per-agent failure messages from the main payment resumo merge and/or
  /// lucratividade-by-agent wave. Not persisted in local overview cache.
  final List<OverviewAgentQueryFailureDetail> partialQueryFailureDetails;

  /// Presence snapshot captured while resolving query targets. Transient: used
  /// by presentation to avoid immediately reading the same presence cache again.
  final Set<String>? hubPresenceOnlineAgentIdsSnapshot;

  bool get hasRows => paymentMethods.isNotEmpty;

  bool get hasPartialAgentQueryFailure =>
      agentIdsExcludedFromQueryFailure.isNotEmpty;

  bool get hasLucratividadePartialFailure =>
      lucratividadePartialFailureAgentNames.isNotEmpty;

  bool get hasMissingClientToken => agentIdsMissingClientToken.isNotEmpty;

  /// True when at least one approved agent was skipped because the
  /// hub considered it offline at dispatch time. May co-exist with
  /// [hasMissingClientToken] — the user needs to act on both axes
  /// independently. Drives the dedicated "agentes offline" banner.
  bool get hasAgentsSkippedDueToHubPresence =>
      agentIdsSkippedDueToHubPresence.isNotEmpty;

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
    int? approvedAgentCount,
    List<String>? agentIdsExcludedFromQueryFailure,
    List<String>? agentNamesExcludedFromQueryFailure,
    List<String>? agentIdsMissingClientToken,
    List<String>? agentNamesMissingClientToken,
    List<String>? agentIdsSkippedDueToHubPresence,
    List<String>? agentNamesSkippedDueToHubPresence,
    List<OverviewMonthlyParcelPoint>? monthlyParcelTrend,
    bool? monthlyParcelTrendLoadFailed,
    AppFailure? monthlyParcelTrendLoadFailure,
    String? monthlyParcelTrendLoadFailureMessage,
    List<OverviewWeekdaySalesTrendPoint>? weekdaySalesTrend,
    bool? weekdaySalesTrendLoadFailed,
    AppFailure? weekdaySalesTrendLoadFailure,
    String? weekdaySalesTrendLoadFailureMessage,
    List<OverviewWeekdayUserSalesTrendPoint>? weekdayUserSalesTrend,
    bool? weekdayUserSalesTrendLoadFailed,
    AppFailure? weekdayUserSalesTrendLoadFailure,
    String? weekdayUserSalesTrendLoadFailureMessage,
    List<DailySalesTrendPoint>? dailySalesTrend,
    bool? dailySalesTrendLoadFailed,
    AppFailure? dailySalesTrendLoadFailure,
    String? dailySalesTrendLoadFailureMessage,
    List<ResumoProdutoVendaLucratividadeMensalRow>? lucratividadeMensalTrend,
    bool? lucratividadeMensalTrendLoadFailed,
    AppFailure? lucratividadeMensalTrendLoadFailure,
    String? lucratividadeMensalTrendLoadFailureMessage,
    List<ResumoProdutoVendaLucratividadeRow>? lucratividadeTrend,
    bool? lucratividadeTrendLoadFailed,
    AppFailure? lucratividadeTrendLoadFailure,
    String? lucratividadeTrendLoadFailureMessage,
    List<String>? lucratividadePartialFailureAgentNames,
    bool? mainResumoHadPlannedTargets,
    List<OverviewAgentQueryFailureDetail>? partialQueryFailureDetails,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
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
      monthlyParcelTrendLoadFailure:
          monthlyParcelTrendLoadFailure ?? this.monthlyParcelTrendLoadFailure,
      monthlyParcelTrendLoadFailureMessage:
          monthlyParcelTrendLoadFailureMessage ??
          this.monthlyParcelTrendLoadFailureMessage,
      weekdaySalesTrend: weekdaySalesTrend ?? this.weekdaySalesTrend,
      weekdaySalesTrendLoadFailed:
          weekdaySalesTrendLoadFailed ?? this.weekdaySalesTrendLoadFailed,
      weekdaySalesTrendLoadFailure:
          weekdaySalesTrendLoadFailure ?? this.weekdaySalesTrendLoadFailure,
      weekdaySalesTrendLoadFailureMessage:
          weekdaySalesTrendLoadFailureMessage ??
          this.weekdaySalesTrendLoadFailureMessage,
      weekdayUserSalesTrend:
          weekdayUserSalesTrend ?? this.weekdayUserSalesTrend,
      weekdayUserSalesTrendLoadFailed:
          weekdayUserSalesTrendLoadFailed ??
          this.weekdayUserSalesTrendLoadFailed,
      weekdayUserSalesTrendLoadFailure:
          weekdayUserSalesTrendLoadFailure ??
          this.weekdayUserSalesTrendLoadFailure,
      weekdayUserSalesTrendLoadFailureMessage:
          weekdayUserSalesTrendLoadFailureMessage ??
          this.weekdayUserSalesTrendLoadFailureMessage,
      dailySalesTrend: dailySalesTrend ?? this.dailySalesTrend,
      dailySalesTrendLoadFailed:
          dailySalesTrendLoadFailed ?? this.dailySalesTrendLoadFailed,
      dailySalesTrendLoadFailure:
          dailySalesTrendLoadFailure ?? this.dailySalesTrendLoadFailure,
      dailySalesTrendLoadFailureMessage:
          dailySalesTrendLoadFailureMessage ??
          this.dailySalesTrendLoadFailureMessage,
      lucratividadeMensalTrend:
          lucratividadeMensalTrend ?? this.lucratividadeMensalTrend,
      lucratividadeMensalTrendLoadFailed:
          lucratividadeMensalTrendLoadFailed ??
          this.lucratividadeMensalTrendLoadFailed,
      lucratividadeMensalTrendLoadFailure:
          lucratividadeMensalTrendLoadFailure ??
          this.lucratividadeMensalTrendLoadFailure,
      lucratividadeMensalTrendLoadFailureMessage:
          lucratividadeMensalTrendLoadFailureMessage ??
          this.lucratividadeMensalTrendLoadFailureMessage,
      lucratividadeTrend: lucratividadeTrend ?? this.lucratividadeTrend,
      lucratividadeTrendLoadFailed:
          lucratividadeTrendLoadFailed ?? this.lucratividadeTrendLoadFailed,
      lucratividadeTrendLoadFailure:
          lucratividadeTrendLoadFailure ?? this.lucratividadeTrendLoadFailure,
      lucratividadeTrendLoadFailureMessage:
          lucratividadeTrendLoadFailureMessage ??
          this.lucratividadeTrendLoadFailureMessage,
      lucratividadePartialFailureAgentNames:
          lucratividadePartialFailureAgentNames ??
          this.lucratividadePartialFailureAgentNames,
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
      agentIdsSkippedDueToHubPresence:
          agentIdsSkippedDueToHubPresence ??
          this.agentIdsSkippedDueToHubPresence,
      agentNamesSkippedDueToHubPresence:
          agentNamesSkippedDueToHubPresence ??
          this.agentNamesSkippedDueToHubPresence,
      mainResumoHadPlannedTargets:
          mainResumoHadPlannedTargets ?? this.mainResumoHadPlannedTargets,
      partialQueryFailureDetails:
          partialQueryFailureDetails ?? this.partialQueryFailureDetails,
      hubPresenceOnlineAgentIdsSnapshot:
          hubPresenceOnlineAgentIdsSnapshot ??
          this.hubPresenceOnlineAgentIdsSnapshot,
    );
  }

  /// Merges [detail] fields for [section] into this overview (shell cache).
  Overview mergeSection(Overview detail, OverviewProgressiveSection section) {
    return switch (section) {
      OverviewProgressiveSection.dailySales => copyWith(
        dailySalesTrend: detail.dailySalesTrend,
        dailySalesTrendLoadFailed: detail.dailySalesTrendLoadFailed,
        dailySalesTrendLoadFailure: detail.dailySalesTrendLoadFailure,
        dailySalesTrendLoadFailureMessage:
            detail.dailySalesTrendLoadFailureMessage,
      ),
      OverviewProgressiveSection.monthlyParcels => copyWith(
        monthlyParcelTrend: detail.monthlyParcelTrend,
        monthlyParcelTrendLoadFailed: detail.monthlyParcelTrendLoadFailed,
        monthlyParcelTrendLoadFailure: detail.monthlyParcelTrendLoadFailure,
        monthlyParcelTrendLoadFailureMessage:
            detail.monthlyParcelTrendLoadFailureMessage,
      ),
      OverviewProgressiveSection.weekdaySales => copyWith(
        weekdaySalesTrend: detail.weekdaySalesTrend,
        weekdaySalesTrendLoadFailed: detail.weekdaySalesTrendLoadFailed,
        weekdaySalesTrendLoadFailure: detail.weekdaySalesTrendLoadFailure,
        weekdaySalesTrendLoadFailureMessage:
            detail.weekdaySalesTrendLoadFailureMessage,
        partialQueryFailureDetails: detail.partialQueryFailureDetails,
      ),
      OverviewProgressiveSection.weekdayUserSales => copyWith(
        weekdayUserSalesTrend: detail.weekdayUserSalesTrend,
        weekdayUserSalesTrendLoadFailed: detail.weekdayUserSalesTrendLoadFailed,
        weekdayUserSalesTrendLoadFailure:
            detail.weekdayUserSalesTrendLoadFailure,
        weekdayUserSalesTrendLoadFailureMessage:
            detail.weekdayUserSalesTrendLoadFailureMessage,
        partialQueryFailureDetails: detail.partialQueryFailureDetails,
      ),
      OverviewProgressiveSection.lucratividadePeriod => copyWith(
        lucratividadeTrend: detail.lucratividadeTrend,
        lucratividadeTrendLoadFailed: detail.lucratividadeTrendLoadFailed,
        lucratividadeTrendLoadFailure: detail.lucratividadeTrendLoadFailure,
        lucratividadeTrendLoadFailureMessage:
            detail.lucratividadeTrendLoadFailureMessage,
        lucratividadePartialFailureAgentNames:
            detail.lucratividadePartialFailureAgentNames,
        partialQueryFailureDetails: detail.partialQueryFailureDetails,
      ),
      OverviewProgressiveSection.lucratividadeMensal => copyWith(
        lucratividadeMensalTrend: detail.lucratividadeMensalTrend,
        lucratividadeMensalTrendLoadFailed:
            detail.lucratividadeMensalTrendLoadFailed,
        lucratividadeMensalTrendLoadFailure:
            detail.lucratividadeMensalTrendLoadFailure,
        lucratividadeMensalTrendLoadFailureMessage:
            detail.lucratividadeMensalTrendLoadFailureMessage,
      ),
      OverviewProgressiveSection.paymentMix => copyWith(
        paymentMethods: detail.paymentMethods,
        kpis: detail.kpis,
      ),
      OverviewProgressiveSection.userRanking => copyWith(
        userRankings: detail.userRankings,
      ),
      OverviewProgressiveSection.agentRanking => copyWith(
        agentRankings: detail.agentRankings,
      ),
      OverviewProgressiveSection.summary => copyWith(
        kpis: detail.kpis,
        paymentMethods: detail.paymentMethods,
        agentRankings: detail.agentRankings,
        userRankings: detail.userRankings,
        approvedAgentCount: detail.approvedAgentCount,
        agentIdsExcludedFromQueryFailure:
            detail.agentIdsExcludedFromQueryFailure,
        agentNamesExcludedFromQueryFailure:
            detail.agentNamesExcludedFromQueryFailure,
        agentIdsMissingClientToken: detail.agentIdsMissingClientToken,
        agentNamesMissingClientToken: detail.agentNamesMissingClientToken,
        agentIdsSkippedDueToHubPresence: detail.agentIdsSkippedDueToHubPresence,
        agentNamesSkippedDueToHubPresence:
            detail.agentNamesSkippedDueToHubPresence,
        mainResumoHadPlannedTargets: detail.mainResumoHadPlannedTargets,
        partialQueryFailureDetails: detail.partialQueryFailureDetails,
        hubPresenceOnlineAgentIdsSnapshot:
            detail.hubPresenceOnlineAgentIdsSnapshot,
      ),
    };
  }
}

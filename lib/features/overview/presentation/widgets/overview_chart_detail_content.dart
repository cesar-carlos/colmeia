import 'dart:async';

import 'package:colmeia/app/router/app_chart_fullscreen_routes.dart';
import 'package:colmeia/features/overview/domain/entities/overview.dart';
import 'package:colmeia/features/overview/domain/entities/overview_agent_query_failure_detail.dart';
import 'package:colmeia/features/overview/domain/entities/overview_progressive_snapshot.dart';
import 'package:colmeia/features/overview/presentation/overview_sorted_rankings.dart';
import 'package:colmeia/features/overview/presentation/widgets/overview_alert_detail_sheet.dart';
import 'package:colmeia/features/overview/presentation/widgets/overview_chart_load_failure_helpers.dart';
import 'package:colmeia/features/overview/presentation/widgets/overview_lucratividade_chart.dart';
import 'package:colmeia/features/overview/presentation/widgets/overview_payment_mix_card.dart';
import 'package:colmeia/features/overview/presentation/widgets/overview_rankings_section.dart';
import 'package:colmeia/features/overview/presentation/widgets/overview_weekday_sales_trend_chart.dart';
import 'package:colmeia/features/overview/presentation/widgets/overview_weekday_user_sales_trend_chart.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_fade_in.dart';
import 'package:colmeia/shared/widgets/charts/daily_sales_trend_chart.dart';
import 'package:flutter/material.dart';

class OverviewChartDetailContent extends StatefulWidget {
  const OverviewChartDetailContent({
    required this.l10n,
    required this.section,
    required this.overview,
    super.key,
    this.animateEntrance = true,
  });

  final AppLocalizations l10n;
  final OverviewProgressiveSection section;
  final Overview overview;
  final bool animateEntrance;

  @override
  State<OverviewChartDetailContent> createState() =>
      _OverviewChartDetailContentState();
}

class _OverviewChartDetailContentState extends State<OverviewChartDetailContent> {
  final OverviewSortedRankingsCache _rankingsCache =
      OverviewSortedRankingsCache();

  @override
  void didUpdateWidget(covariant OverviewChartDetailContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.overview, widget.overview)) {
      _rankingsCache.invalidate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final overview = widget.overview;
    final section = widget.section;

    VoidCallback? partialDetailsLink(OverviewAgentQueryFailureSource source) {
      if (!overviewHasPartialFailuresForSource(overview, source)) {
        return null;
      }
      return () => unawaited(
        showOverviewPartialFailureDetailsSheet(
          context: context,
          l10n: l10n,
          details: overview.partialQueryFailureDetails,
        ),
      );
    }

    final chart = switch (section) {
      OverviewProgressiveSection.dailySales => DailySalesTrendChart(
        l10n: l10n,
        points: overview.dailySalesTrend,
        loadFailed: overview.dailySalesTrendLoadFailed,
        loadFailure: overview.dailySalesTrendLoadFailure,
        loadFailureMessage: overview.dailySalesTrendLoadFailureMessage,
        onRequestFullscreen: (context, request) =>
            context.pushChartFullscreenFromRequest(request),
        onRequestShare: (context, request) =>
            context.shareChartFromRequest(request),
      ),
      OverviewProgressiveSection.paymentMix => OverviewPaymentMixCard(
        l10n: l10n,
        methods: overview.paymentMethods,
      ),
      OverviewProgressiveSection.weekdaySales => OverviewWeekdaySalesTrendChart(
        l10n: l10n,
        points: overview.weekdaySalesTrend,
        loadFailed: overview.weekdaySalesTrendLoadFailed,
        loadFailure: overview.weekdaySalesTrendLoadFailure,
        loadFailureMessage: overview.weekdaySalesTrendLoadFailureMessage,
        onViewAgentFailureDetails:
            partialDetailsLink(OverviewAgentQueryFailureSource.weekdayTrend),
      ),
      OverviewProgressiveSection.weekdayUserSales =>
        OverviewWeekdayUserSalesTrendChart(
          l10n: l10n,
          points: overview.weekdayUserSalesTrend,
          loadFailed: overview.weekdayUserSalesTrendLoadFailed,
          loadFailure: overview.weekdayUserSalesTrendLoadFailure,
          loadFailureMessage: overview.weekdayUserSalesTrendLoadFailureMessage,
          onViewAgentFailureDetails: partialDetailsLink(
            OverviewAgentQueryFailureSource.weekdayUserTrend,
          ),
        ),
      OverviewProgressiveSection.userRanking => OverviewUserRankingCard(
        l10n: l10n,
        userRankings: _rankingsCache.resolve(overview).users,
      ),
      OverviewProgressiveSection.lucratividadePeriod =>
        OverviewLucratividadeChart(
          l10n: l10n,
          points: overview.lucratividadeTrend,
          loadFailed: overview.lucratividadeTrendLoadFailed,
          loadFailure: overview.lucratividadeTrendLoadFailure,
          loadFailureMessage: overview.lucratividadeTrendLoadFailureMessage,
          overviewApprovedAgentCount: overview.approvedAgentCount,
          onViewAgentFailureDetails: overviewHasPartialFailuresForSource(
            overview,
            OverviewAgentQueryFailureSource.lucratividadePeriod,
          )
              ? () => unawaited(
                  showOverviewPartialFailureDetailsSheet(
                    context: context,
                    l10n: l10n,
                    details: overview.partialQueryFailureDetails,
                  ),
                )
              : null,
        ),
      _ => const SizedBox.shrink(),
    };

    if (!widget.animateEntrance) {
      return chart;
    }
    return AppChartFadeIn(child: chart);
  }
}

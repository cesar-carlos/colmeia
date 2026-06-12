import 'dart:async';

import 'package:colmeia/app/router/app_chart_fullscreen_routes.dart';
import 'package:colmeia/features/overview/domain/entities/overview.dart';
import 'package:colmeia/features/overview/domain/entities/overview_agent_query_failure_detail.dart';
import 'package:colmeia/features/overview/domain/entities/overview_progressive_snapshot.dart';
import 'package:colmeia/features/overview/presentation/overview_sorted_rankings.dart';
import 'package:colmeia/features/overview/presentation/widgets/overview_alert_detail_sheet.dart';
import 'package:colmeia/features/overview/presentation/widgets/overview_chart_load_failure_helpers.dart';
import 'package:colmeia/features/overview/presentation/widgets/overview_lucratividade_chart.dart';
import 'package:colmeia/features/overview/presentation/widgets/overview_lucratividade_mensal_chart.dart';
import 'package:colmeia/features/overview/presentation/widgets/overview_payment_mix_card.dart';
import 'package:colmeia/features/overview/presentation/widgets/overview_rankings_section.dart';
import 'package:colmeia/features/overview/presentation/widgets/overview_weekday_sales_trend_chart.dart';
import 'package:colmeia/features/overview/presentation/widgets/overview_weekday_user_sales_trend_chart.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
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
    this.isSingleAgentSelected = false,
  });

  final AppLocalizations l10n;
  final OverviewProgressiveSection section;
  final Overview overview;
  final bool animateEntrance;
  final bool isSingleAgentSelected;

  @override
  State<OverviewChartDetailContent> createState() =>
      _OverviewChartDetailContentState();
}

class _OverviewChartDetailContentState
    extends State<OverviewChartDetailContent> {
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

    final dailySalesEmptyMessage = section == OverviewProgressiveSection.dailySales
        ? _dailySalesEmptyMessage(l10n, overview)
        : null;

    final chart = switch (section) {
      OverviewProgressiveSection.dailySales => DailySalesTrendChart(
        l10n: l10n,
        points: overview.dailySalesTrend,
        emptyMessage: dailySalesEmptyMessage!,
        emptyPlaceholder: overviewChartEmptyPlaceholder(
          emptyMessage: dailySalesEmptyMessage,
          textStyle: Theme.of(context).textTheme.bodyMedium,
          verticalPadding: Theme.of(context)
              .extension<AppThemeTokens>()!
              .contentSpacing,
          loadFailure: overview.dailySalesTrendLoadFailed
              ? overview.dailySalesTrendLoadFailure
              : null,
        ),
        onRequestFullscreen: (context, request) =>
            context.pushChartFullscreenFromRequest(request),
        onRequestShare: (context, request) =>
            context.shareChartFromRequest(request),
      ),
      OverviewProgressiveSection.paymentMix => OverviewPaymentMixCard(
        l10n: l10n,
        methods: overview.paymentMethods,
        onRequestFullscreen: (context, request) =>
            context.pushChartFullscreenFromRequest(request),
        onRequestShare: (context, request) =>
            context.shareChartFromRequest(request),
      ),
      OverviewProgressiveSection.weekdaySales => OverviewWeekdaySalesTrendChart(
        l10n: l10n,
        points: overview.weekdaySalesTrend,
        loadFailed: overview.weekdaySalesTrendLoadFailed,
        loadFailure: overview.weekdaySalesTrendLoadFailure,
        loadFailureMessage: overview.weekdaySalesTrendLoadFailureMessage,
        onViewAgentFailureDetails: partialDetailsLink(
          OverviewAgentQueryFailureSource.weekdayTrend,
        ),
        onRequestFullscreen: (context, request) =>
            context.pushChartFullscreenFromRequest(request),
        onRequestShare: (context, request) =>
            context.shareChartFromRequest(request),
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
          onRequestFullscreen: (context, request) =>
              context.pushChartFullscreenFromRequest(request),
          onRequestShare: (context, request) =>
              context.shareChartFromRequest(request),
        ),
      OverviewProgressiveSection.userRanking => OverviewUserRankingCard(
        l10n: l10n,
        userRankings: _rankingsCache.resolve(overview).users,
        onRequestFullscreen: (context, request) =>
            context.pushChartFullscreenFromRequest(request),
        onRequestShare: (context, request) =>
            context.shareChartFromRequest(request),
      ),
      OverviewProgressiveSection.lucratividadePeriod =>
        OverviewLucratividadeChart(
          l10n: l10n,
          points: overview.lucratividadeTrend,
          loadFailed: overview.lucratividadeTrendLoadFailed,
          loadFailure: overview.lucratividadeTrendLoadFailure,
          loadFailureMessage: overview.lucratividadeTrendLoadFailureMessage,
          overviewApprovedAgentCount: overview.approvedAgentCount,
          onViewAgentFailureDetails:
              overviewHasPartialFailuresForSource(
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
          onRequestFullscreen: (context, request) =>
              context.pushChartFullscreenFromRequest(request),
          onRequestShare: (context, request) =>
              context.shareChartFromRequest(request),
        ),
      OverviewProgressiveSection.lucratividadeMensal =>
        OverviewLucratividadeMensalChart(
          l10n: l10n,
          points: overview.lucratividadeMensalTrend,
          loadFailed: overview.lucratividadeMensalTrendLoadFailed,
          loadFailure: overview.lucratividadeMensalTrendLoadFailure,
          loadFailureMessage:
              overview.lucratividadeMensalTrendLoadFailureMessage,
          isSingleAgentSelected: widget.isSingleAgentSelected,
          onViewAgentFailureDetails: partialDetailsLink(
            OverviewAgentQueryFailureSource.lucratividadeMensalTrend,
          ),
          onRequestFullscreen: (context, request) =>
              context.pushChartFullscreenFromRequest(request),
          onRequestShare: (context, request) =>
              context.shareChartFromRequest(request),
        ),
      _ => const SizedBox.shrink(),
    };

    if (!widget.animateEntrance) {
      return chart;
    }
    return AppChartFadeIn(child: chart);
  }

  String _dailySalesEmptyMessage(AppLocalizations l10n, Overview overview) {
    return overviewChartLoadFailureMessage(
      l10n: l10n,
      loadFailed: overview.dailySalesTrendLoadFailed,
      loadFailure: overview.dailySalesTrendLoadFailure,
      legacyMessage: overview.dailySalesTrendLoadFailureMessage,
      genericFallback: overview.dailySalesTrendLoadFailed
          ? l10n.overviewDailySalesLoadFailed
          : l10n.overviewDailySalesEmpty,
    );
  }
}

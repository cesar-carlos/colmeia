import 'dart:async';

import 'package:colmeia/app/router/app_chart_fullscreen_routes.dart';
import 'package:colmeia/features/overview/domain/entities/overview.dart';
import 'package:colmeia/features/overview/domain/entities/overview_agent_query_failure_detail.dart';
import 'package:colmeia/features/overview/domain/entities/overview_progressive_snapshot.dart';
import 'package:colmeia/features/overview/presentation/overview_sorted_rankings.dart';
import 'package:colmeia/features/overview/presentation/widgets/overview_alert_detail_sheet.dart';
import 'package:colmeia/features/overview/presentation/widgets/overview_chart_load_failure_helpers.dart';
import 'package:colmeia/features/overview/presentation/widgets/overview_chart_staged_block.dart';
import 'package:colmeia/features/overview/presentation/widgets/overview_monthly_parcels_combo_chart.dart';
import 'package:colmeia/features/overview/presentation/widgets/overview_rankings_section.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_motion_tokens.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:flutter/material.dart';

/// Charts that remain embedded on the overview home (monthly trend + agent ranking).
class OverviewHomeChartsBelowKpis extends StatefulWidget {
  const OverviewHomeChartsBelowKpis({
    required this.tokens,
    required this.l10n,
    required this.showSkeleton,
    required this.displayOverview,
    required this.completedSections,
    super.key,
  });

  final AppThemeTokens tokens;
  final AppLocalizations l10n;
  final bool showSkeleton;
  final Overview displayOverview;
  final Set<OverviewProgressiveSection> completedSections;

  @override
  State<OverviewHomeChartsBelowKpis> createState() =>
      _OverviewHomeChartsBelowKpisState();
}

class _OverviewHomeChartsBelowKpisState extends State<OverviewHomeChartsBelowKpis> {
  final OverviewSortedRankingsCache _rankingsCache =
      OverviewSortedRankingsCache();

  @override
  void didUpdateWidget(covariant OverviewHomeChartsBelowKpis oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.displayOverview, widget.displayOverview)) {
      _rankingsCache.invalidate();
    }
  }

  bool _sectionReady(OverviewProgressiveSection section) {
    return widget.showSkeleton || widget.completedSections.contains(section);
  }

  @override
  Widget build(BuildContext context) {
    final motion = context.appMotion;
    final tokens = widget.tokens;
    final l10n = widget.l10n;
    final chartBlockHeight = tokens.chartStandardHeight + tokens.contentSpacing;
    final overview = widget.displayOverview;
    final agentRankings = widget.showSkeleton
        ? OverviewSortedRankings.empty.agents
        : _rankingsCache.resolve(overview).agents;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        OverviewChartStagedBlock(
          visualState: _resolveVisualState(
            OverviewProgressiveSection.monthlyParcels,
          ),
          placeholderHeight: chartBlockHeight,
          showDelay: motion.dashboardStageDelay(0),
          loadingSemanticsLabel: l10n.overviewLoadingMonthlyParcelsSemantics,
          child: OverviewMonthlyParcelsComboChart(
            l10n: l10n,
            points: overview.monthlyParcelTrend,
            loadFailed: overview.monthlyParcelTrendLoadFailed,
            loadFailure: overview.monthlyParcelTrendLoadFailure,
            loadFailureMessage: overview.monthlyParcelTrendLoadFailureMessage,
            onRequestFullscreen: (context, request) =>
                context.pushChartFullscreenFromRequest(request),
            onRequestShare: (context, request) =>
                context.shareChartFromRequest(request),
            onViewAgentFailureDetails:
                overviewHasPartialFailuresForSource(
                  overview,
                  OverviewAgentQueryFailureSource.monthlyTrend,
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
        ),
        SizedBox(height: tokens.sectionSpacing),
        OverviewChartStagedBlock(
          visualState: _resolveVisualState(
            OverviewProgressiveSection.agentRanking,
          ),
          placeholderHeight: chartBlockHeight,
          showDelay: motion.dashboardStageDelay(1),
          loadingSemanticsLabel: l10n.overviewLoadingRankingsSemantics,
          child: OverviewAgentRankingCard(
            l10n: l10n,
            agentRankings: agentRankings,
            onRequestFullscreen: (context, request) =>
                context.pushChartFullscreenFromRequest(request),
            onRequestShare: (context, request) =>
                context.shareChartFromRequest(request),
          ),
        ),
      ],
    );
  }

  OverviewChartStageVisualState _resolveVisualState(
    OverviewProgressiveSection section,
  ) {
    if (widget.showSkeleton) {
      return OverviewChartStageVisualState.skeletonWithChart;
    }
    return _sectionReady(section)
        ? OverviewChartStageVisualState.ready
        : OverviewChartStageVisualState.placeholder;
  }
}

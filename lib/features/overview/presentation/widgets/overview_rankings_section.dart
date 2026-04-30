import 'dart:async';

import 'package:colmeia/app/router/app_chart_fullscreen_routes.dart';
import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/features/overview/domain/entities/overview_agent_ranking.dart';
import 'package:colmeia/features/overview/domain/entities/overview_user_ranking.dart';
import 'package:colmeia/features/overview/presentation/widgets/overview_bar_chart_style.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/charts/app_comparison_bar_chart.dart';
import 'package:flutter/material.dart';

class OverviewRankingsSection extends StatefulWidget {
  const OverviewRankingsSection({
    required this.l10n,
    required this.agentRankings,
    required this.userRankings,
    super.key,
  });

  final AppLocalizations l10n;
  final List<OverviewAgentRanking> agentRankings;
  final List<OverviewUserRanking> userRankings;

  @override
  State<OverviewRankingsSection> createState() =>
      _OverviewRankingsSectionState();
}

class _OverviewRankingsSectionState extends State<OverviewRankingsSection> {
  List<OverviewAgentRanking>? _agentsRef;
  List<OverviewUserRanking>? _usersRef;
  late List<OverviewAgentRanking> _sortedAgents;
  late List<OverviewUserRanking> _sortedUsers;

  void _recomputeSortedIfNeeded() {
    if (!identical(_agentsRef, widget.agentRankings)) {
      _agentsRef = widget.agentRankings;
      final sorted = List<OverviewAgentRanking>.of(widget.agentRankings)
        ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
      _sortedAgents = [
        for (final a in sorted)
          if (a.totalAmount > 0) a,
      ];
    }
    if (!identical(_usersRef, widget.userRankings)) {
      _usersRef = widget.userRankings;
      final sorted = List<OverviewUserRanking>.of(widget.userRankings)
        ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
      _sortedUsers = [
        for (final u in sorted)
          if (u.totalAmount > 0) u,
      ];
    }
  }

  @override
  void initState() {
    super.initState();
    _agentsRef = null;
    _usersRef = null;
    _recomputeSortedIfNeeded();
  }

  @override
  void didUpdateWidget(covariant OverviewRankingsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    _recomputeSortedIfNeeded();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        OverviewAgentRankingCard(
          l10n: widget.l10n,
          agentRankings: _sortedAgents,
        ),
        SizedBox(height: tokens.sectionSpacing),
        OverviewUserRankingCard(
          l10n: widget.l10n,
          userRankings: _sortedUsers,
        ),
      ],
    );
  }
}

class OverviewAgentRankingCard extends StatelessWidget {
  const OverviewAgentRankingCard({
    required this.l10n,
    required this.agentRankings,
    super.key,
  });

  final AppLocalizations l10n;
  final List<OverviewAgentRanking> agentRankings;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final showEmpty = agentRankings.isEmpty;
    void openFullscreen() {
      final rankingsSnapshot = List<OverviewAgentRanking>.of(
        agentRankings,
        growable: false,
      );
      unawaited(
        context.pushChartFullscreen<void>(
          extra: AppChartFullscreenRouteExtra(
            title: l10n.dashboardAgentRankingTitle,
            subtitle: l10n.dashboardAgentRankingSubtitle,
            chartSemanticsLabel: l10n.dashboardAgentRankingTitle,
            chartBuilder: (fullscreenContext) {
              final fullscreenTokens = Theme.of(
                fullscreenContext,
              ).extension<AppThemeTokens>()!;
              return LayoutBuilder(
                builder: (context, constraints) {
                  return AppComparisonBarChart<OverviewAgentRanking>(
                    items: rankingsSnapshot,
                    plotFloorAccessibilityNotice:
                        l10n.chartComparisonPlotFloorNotice,
                    extremeSpreadAccessibilityNotice:
                        l10n.chartComparisonExtremeValueSpreadNotice,
                    labelBuilder: (a) => a.displayName,
                    valueBuilder: (a) => a.totalAmount,
                    tooltipLabelBuilder: (a, v) =>
                        '${a.displayName}: ${AppBrFormatters.currency(v)}',
                    dataLabelBuilder: (a, v) => AppBrFormatters.compactCurrency(v),
                    style: overviewHomeComparisonBarChartStyle(
                      tokens: fullscreenTokens,
                      kind: OverviewHomeBarChartKind.ranking,
                      l10n: l10n,
                      heightOverride: constraints.maxHeight,
                    ),
                    emptyPlaceholder: showEmpty
                        ? Center(
                            child: Text(
                              l10n.overviewAgentRankingEmpty,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          )
                        : null,
                  );
                },
              );
            },
          ),
        ),
      );
    }

    return AppComparisonBarChart<OverviewAgentRanking>(
      title: l10n.dashboardAgentRankingTitle,
      subtitle: l10n.dashboardAgentRankingSubtitle,
      onOpenFullscreen: openFullscreen,
      items: agentRankings,
      plotFloorAccessibilityNotice: l10n.chartComparisonPlotFloorNotice,
      extremeSpreadAccessibilityNotice:
          l10n.chartComparisonExtremeValueSpreadNotice,
      labelBuilder: (a) => a.displayName,
      valueBuilder: (a) => a.totalAmount,
      tooltipLabelBuilder: (a, v) =>
          '${a.displayName}: ${AppBrFormatters.currency(v)}',
      dataLabelBuilder: (a, v) => AppBrFormatters.compactCurrency(v),
      style: overviewHomeComparisonBarChartStyle(
        tokens: tokens,
        kind: OverviewHomeBarChartKind.ranking,
        l10n: l10n,
      ),
      emptyPlaceholder: showEmpty
          ? Padding(
              padding: EdgeInsets.symmetric(vertical: tokens.contentSpacing),
              child: Center(
                child: Text(
                  l10n.overviewAgentRankingEmpty,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            )
          : null,
    );
  }
}

class OverviewUserRankingCard extends StatelessWidget {
  const OverviewUserRankingCard({
    required this.l10n,
    required this.userRankings,
    super.key,
  });

  final AppLocalizations l10n;
  final List<OverviewUserRanking> userRankings;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final showEmpty = userRankings.isEmpty;
    void openFullscreen() {
      final rankingsSnapshot = List<OverviewUserRanking>.of(
        userRankings,
        growable: false,
      );
      unawaited(
        context.pushChartFullscreen<void>(
          extra: AppChartFullscreenRouteExtra(
            title: l10n.dashboardUserRankingTitle,
            subtitle: l10n.dashboardUserRankingSubtitle,
            chartSemanticsLabel: l10n.dashboardUserRankingTitle,
            chartBuilder: (fullscreenContext) {
              final fullscreenTokens = Theme.of(
                fullscreenContext,
              ).extension<AppThemeTokens>()!;
              return LayoutBuilder(
                builder: (context, constraints) {
                  return AppComparisonBarChart<OverviewUserRanking>(
                    items: rankingsSnapshot,
                    plotFloorAccessibilityNotice:
                        l10n.chartComparisonPlotFloorNotice,
                    extremeSpreadAccessibilityNotice:
                        l10n.chartComparisonExtremeValueSpreadNotice,
                    labelBuilder: (u) => u.userName,
                    valueBuilder: (u) => u.totalAmount,
                    tooltipLabelBuilder: (u, v) =>
                        '${u.userName}: ${AppBrFormatters.currency(v)}',
                    dataLabelBuilder: (u, v) => AppBrFormatters.compactCurrency(v),
                    style: overviewHomeComparisonBarChartStyle(
                      tokens: fullscreenTokens,
                      kind: OverviewHomeBarChartKind.ranking,
                      l10n: l10n,
                      heightOverride: constraints.maxHeight,
                    ),
                    emptyPlaceholder: showEmpty
                        ? Center(
                            child: Text(
                              l10n.overviewUserRankingEmpty,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          )
                        : null,
                  );
                },
              );
            },
          ),
        ),
      );
    }

    return AppComparisonBarChart<OverviewUserRanking>(
      title: l10n.dashboardUserRankingTitle,
      subtitle: l10n.dashboardUserRankingSubtitle,
      onOpenFullscreen: openFullscreen,
      items: userRankings,
      plotFloorAccessibilityNotice: l10n.chartComparisonPlotFloorNotice,
      extremeSpreadAccessibilityNotice:
          l10n.chartComparisonExtremeValueSpreadNotice,
      labelBuilder: (u) => u.userName,
      valueBuilder: (u) => u.totalAmount,
      tooltipLabelBuilder: (u, v) =>
          '${u.userName}: ${AppBrFormatters.currency(v)}',
      dataLabelBuilder: (u, v) => AppBrFormatters.compactCurrency(v),
      style: overviewHomeComparisonBarChartStyle(
        tokens: tokens,
        kind: OverviewHomeBarChartKind.ranking,
        l10n: l10n,
      ),
      emptyPlaceholder: showEmpty
          ? Padding(
              padding: EdgeInsets.symmetric(vertical: tokens.contentSpacing),
              child: Center(
                child: Text(
                  l10n.overviewUserRankingEmpty,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            )
          : null,
    );
  }
}

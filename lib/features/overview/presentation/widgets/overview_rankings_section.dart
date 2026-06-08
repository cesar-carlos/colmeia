import 'dart:async';

import 'package:colmeia/app/router/app_chart_fullscreen_routes.dart';
import 'package:colmeia/app/router/app_chart_share_actions.dart';
import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/features/overview/domain/entities/overview_agent_ranking.dart';
import 'package:colmeia/features/overview/domain/entities/overview_user_ranking.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/charts/app_comparison_bar_chart.dart';
import 'package:colmeia/shared/widgets/charts/app_dashboard_comparison_bar_chart_preset.dart';
import 'package:flutter/material.dart';

String _overviewUserRankingTooltip(
  AppLocalizations l10n,
  OverviewUserRanking u,
  num barValue,
) {
  final v = barValue.toDouble();
  return '${u.userName}: ${AppBrFormatters.currency(v)}\n'
      '${l10n.overviewKpiAvgTicket}: ${AppBrFormatters.currency(u.averageTicket)}';
}

String _overviewUserRankingDataLabel(
  AppLocalizations l10n,
  OverviewUserRanking u,
  num barValue,
) {
  final v = barValue.toDouble();
  return '${AppBrFormatters.compactCurrency(v)}\n'
      '${l10n.overviewKpiAvgTicket}: ${AppBrFormatters.compactCurrency(u.averageTicket)}';
}

class OverviewAgentRankingCard extends StatefulWidget {
  const OverviewAgentRankingCard({
    required this.l10n,
    required this.agentRankings,
    super.key,
  });

  final AppLocalizations l10n;
  final List<OverviewAgentRanking> agentRankings;

  @override
  State<OverviewAgentRankingCard> createState() =>
      _OverviewAgentRankingCardState();
}

class _OverviewAgentRankingCardState extends State<OverviewAgentRankingCard> {
  final GlobalKey _shareKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final agentRankings = widget.agentRankings;
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final showEmpty = agentRankings.isEmpty;
    final shareTitle = l10n.dashboardAgentRankingTitle;

    void openFullscreen() {
      final rankingsSnapshot = List<OverviewAgentRanking>.of(
        agentRankings,
        growable: false,
      );
      final fullscreenShareKey = GlobalKey();
      unawaited(
        context.pushChartFullscreen<void>(
          extra: AppChartFullscreenRouteExtra(
            title: shareTitle,
            subtitle: l10n.dashboardAgentRankingSubtitle,
            chartSemanticsLabel: shareTitle,
            headerTrailing: buildChartFullscreenShareTrailing(
              context: context,
              shareKey: fullscreenShareKey,
              subject: shareTitle,
            ),
            chartBuilder: (fullscreenContext) {
              final fullscreenTokens = Theme.of(
                fullscreenContext,
              ).extension<AppThemeTokens>()!;
              return RepaintBoundary(
                key: fullscreenShareKey,
                child: LayoutBuilder(
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
                      dataLabelBuilder: (a, v) =>
                          AppBrFormatters.compactCurrency(v),
                      style: appDashboardComparisonBarChartStyle(
                        tokens: fullscreenTokens,
                        kind: AppDashboardComparisonBarChartKind.ranking,
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
                ),
              );
            },
          ),
        ),
      );
    }

    return RepaintBoundary(
      key: _shareKey,
      child: AppComparisonBarChart<OverviewAgentRanking>(
        title: shareTitle,
        subtitle: l10n.dashboardAgentRankingSubtitle,
        onShare: () => unawaited(
          shareChartCapture(context, _shareKey, subject: shareTitle),
        ),
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
        style: appDashboardComparisonBarChartStyle(
          tokens: tokens,
          kind: AppDashboardComparisonBarChartKind.ranking,
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
      ),
    );
  }
}

class OverviewUserRankingCard extends StatefulWidget {
  const OverviewUserRankingCard({
    required this.l10n,
    required this.userRankings,
    super.key,
  });

  final AppLocalizations l10n;
  final List<OverviewUserRanking> userRankings;

  @override
  State<OverviewUserRankingCard> createState() =>
      _OverviewUserRankingCardState();
}

class _OverviewUserRankingCardState extends State<OverviewUserRankingCard> {
  final GlobalKey _shareKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final userRankings = widget.userRankings;
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final colorScheme = Theme.of(context).colorScheme;
    final rankingChartStyle = appDashboardComparisonBarChartStyle(
      tokens: tokens,
      kind: AppDashboardComparisonBarChartKind.ranking,
      l10n: l10n,
      rankingValueLabelBackground: colorScheme.surface,
    );
    final showEmpty = userRankings.isEmpty;
    final shareTitle = l10n.dashboardUserRankingTitle;

    void openFullscreen() {
      final rankingsSnapshot = List<OverviewUserRanking>.of(
        userRankings,
        growable: false,
      );
      final fullscreenShareKey = GlobalKey();
      unawaited(
        context.pushChartFullscreen<void>(
          extra: AppChartFullscreenRouteExtra(
            title: shareTitle,
            subtitle: l10n.dashboardUserRankingSubtitle,
            chartSemanticsLabel: shareTitle,
            headerTrailing: buildChartFullscreenShareTrailing(
              context: context,
              shareKey: fullscreenShareKey,
              subject: shareTitle,
            ),
            chartBuilder: (fullscreenContext) {
              final fullscreenTokens = Theme.of(
                fullscreenContext,
              ).extension<AppThemeTokens>()!;
              return RepaintBoundary(
                key: fullscreenShareKey,
                child: LayoutBuilder(
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
                          _overviewUserRankingTooltip(l10n, u, v),
                      dataLabelBuilder: (u, v) =>
                          _overviewUserRankingDataLabel(l10n, u, v),
                      style: appDashboardComparisonBarChartStyle(
                        tokens: fullscreenTokens,
                        kind: AppDashboardComparisonBarChartKind.ranking,
                        l10n: l10n,
                        heightOverride: constraints.maxHeight,
                        rankingValueLabelBackground: Theme.of(
                          fullscreenContext,
                        ).colorScheme.surface,
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
                ),
              );
            },
          ),
        ),
      );
    }

    return RepaintBoundary(
      key: _shareKey,
      child: AppComparisonBarChart<OverviewUserRanking>(
        title: shareTitle,
        subtitle: l10n.dashboardUserRankingSubtitle,
        onShare: () => unawaited(
          shareChartCapture(context, _shareKey, subject: shareTitle),
        ),
        onOpenFullscreen: openFullscreen,
        items: userRankings,
        plotFloorAccessibilityNotice: l10n.chartComparisonPlotFloorNotice,
        extremeSpreadAccessibilityNotice:
            l10n.chartComparisonExtremeValueSpreadNotice,
        labelBuilder: (u) => u.userName,
        valueBuilder: (u) => u.totalAmount,
        tooltipLabelBuilder: (u, v) => _overviewUserRankingTooltip(l10n, u, v),
        dataLabelBuilder: (u, v) => _overviewUserRankingDataLabel(l10n, u, v),
        style: rankingChartStyle,
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
      ),
    );
  }
}

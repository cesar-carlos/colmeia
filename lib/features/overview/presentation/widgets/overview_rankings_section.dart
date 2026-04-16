import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/features/overview/domain/entities/overview_agent_ranking.dart';
import 'package:colmeia/features/overview/domain/entities/overview_user_ranking.dart';
import 'package:colmeia/features/overview/presentation/widgets/overview_bar_chart_style.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/charts/app_comparison_bar_chart.dart';
import 'package:flutter/material.dart';

class OverviewRankingsSection extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final sortedAgents = List<OverviewAgentRanking>.of(agentRankings)
      ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
    final sortedUsers = List<OverviewUserRanking>.of(userRankings)
      ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        OverviewAgentRankingCard(
          l10n: l10n,
          agentRankings: sortedAgents,
        ),
        SizedBox(height: tokens.sectionSpacing),
        OverviewUserRankingCard(
          l10n: l10n,
          userRankings: sortedUsers,
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
    return AppComparisonBarChart<OverviewAgentRanking>(
      title: l10n.dashboardAgentRankingTitle,
      subtitle: l10n.dashboardAgentRankingSubtitle,
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
    return AppComparisonBarChart<OverviewUserRanking>(
      title: l10n.dashboardUserRankingTitle,
      subtitle: l10n.dashboardUserRankingSubtitle,
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
    );
  }
}

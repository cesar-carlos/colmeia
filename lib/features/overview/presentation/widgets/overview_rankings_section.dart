import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/features/overview/domain/entities/overview_agent_ranking.dart';
import 'package:colmeia/features/overview/domain/entities/overview_user_ranking.dart';
import 'package:colmeia/features/overview/presentation/share/overview_rankings_share.dart';
import 'package:colmeia/features/overview/presentation/widgets/overview_chart_load_failure_helpers.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_fullscreen_request.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_share_request.dart';
import 'package:colmeia/shared/widgets/charts/app_comparison_bar_chart.dart';
import 'package:colmeia/shared/widgets/charts/app_dashboard_comparison_bar_chart_preset.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_actions.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_export_header_context.dart';
import 'package:flutter/material.dart';

class OverviewAgentRankingCard extends StatefulWidget {
  const OverviewAgentRankingCard({
    required this.l10n,
    required this.agentRankings,
    required this.loadFailed,
    this.loadFailure,
    this.exportHeaderContext,
    this.onRequestFullscreen,
    this.onRequestShare,
    super.key,
  });

  final AppLocalizations l10n;
  final ChartShareExportHeaderContext? exportHeaderContext;
  final List<OverviewAgentRanking> agentRankings;
  final bool loadFailed;
  final AppFailure? loadFailure;
  final AppChartFullscreenRequestCallback? onRequestFullscreen;
  final AppChartShareRequestCallback? onRequestShare;

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
    final failureMessage = overviewChartLoadFailureMessage(
      l10n: l10n,
      loadFailed: widget.loadFailed,
      loadFailure: widget.loadFailure,
      genericFallback: l10n.overviewLoadFailedUserMessage,
    );
    final showEmpty = widget.loadFailed || agentRankings.isEmpty;
    final emptyMessage = widget.loadFailed
        ? failureMessage
        : l10n.overviewAgentRankingEmpty;
    final emptyPlaceholder = overviewChartEmptyPlaceholder(
      emptyMessage: emptyMessage,
      textStyle: Theme.of(context).textTheme.bodyMedium,
      verticalPadding: tokens.contentSpacing,
      loadFailure: widget.loadFailed ? widget.loadFailure : null,
    );
    final shareTitle = l10n.dashboardAgentRankingTitle;
    final inlineStyle = appDashboardComparisonBarChartStyle(
      tokens: tokens,
      kind: AppDashboardComparisonBarChartKind.ranking,
      l10n: l10n,
    );
    final metadata = buildOverviewAgentRankingShareMetadata(
      l10n: l10n,
      agentRankings: agentRankings,
      exportHeaderContext: widget.exportHeaderContext,
    );
    final shareActions = ChartShareActions(
      context: context,
      captureKey: _shareKey,
      metadata: metadata,
      onRequestShare: widget.onRequestShare,
      onRequestFullscreen: widget.onRequestFullscreen,
    );

    void openFullscreen() {
      final rankingsSnapshot = List<OverviewAgentRanking>.of(
        agentRankings,
        growable: false,
      );
      final fullscreenShareKey = GlobalKey();
      shareActions.openFullscreen(
        metadata.toFullscreenRequest(
          shareCaptureKey: fullscreenShareKey,
          semanticsLabel: shareTitle,
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
                    emptyPlaceholder: showEmpty ? emptyPlaceholder : null,
                  );
                },
              ),
            );
          },
        ),
      );
    }

    return RepaintBoundary(
      key: _shareKey,
      child: AppComparisonBarChart<OverviewAgentRanking>(
        title: shareTitle,
        subtitle: l10n.dashboardAgentRankingSubtitle,
        onShare: shareActions.shareCallback(),
        shareProgressKey: _shareKey,
        onOpenFullscreen: shareActions.fullscreenCallback(openFullscreen),
        items: agentRankings,
        plotFloorAccessibilityNotice: l10n.chartComparisonPlotFloorNotice,
        extremeSpreadAccessibilityNotice:
            l10n.chartComparisonExtremeValueSpreadNotice,
        labelBuilder: (a) => a.displayName,
        valueBuilder: (a) => a.totalAmount,
        tooltipLabelBuilder: (a, v) =>
            '${a.displayName}: ${AppBrFormatters.currency(v)}',
        dataLabelBuilder: (a, v) => AppBrFormatters.compactCurrency(v),
        style: inlineStyle,
        emptyPlaceholder: showEmpty ? emptyPlaceholder : null,
      ),
    );
  }
}

class OverviewUserRankingCard extends StatefulWidget {
  const OverviewUserRankingCard({
    required this.l10n,
    required this.userRankings,
    required this.loadFailed,
    this.loadFailure,
    this.exportHeaderContext,
    this.onRequestFullscreen,
    this.onRequestShare,
    super.key,
  });

  final AppLocalizations l10n;
  final ChartShareExportHeaderContext? exportHeaderContext;
  final List<OverviewUserRanking> userRankings;
  final bool loadFailed;
  final AppFailure? loadFailure;
  final AppChartFullscreenRequestCallback? onRequestFullscreen;
  final AppChartShareRequestCallback? onRequestShare;

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
    final failureMessage = overviewChartLoadFailureMessage(
      l10n: l10n,
      loadFailed: widget.loadFailed,
      loadFailure: widget.loadFailure,
      genericFallback: l10n.overviewLoadFailedUserMessage,
    );
    final showEmpty = widget.loadFailed || userRankings.isEmpty;
    final emptyMessage = widget.loadFailed
        ? failureMessage
        : l10n.overviewUserRankingEmpty;
    final emptyPlaceholder = overviewChartEmptyPlaceholder(
      emptyMessage: emptyMessage,
      textStyle: Theme.of(context).textTheme.bodyMedium,
      verticalPadding: tokens.contentSpacing,
      loadFailure: widget.loadFailed ? widget.loadFailure : null,
    );
    final rankingChartStyle = appDashboardComparisonBarChartStyle(
      tokens: tokens,
      kind: AppDashboardComparisonBarChartKind.ranking,
      l10n: l10n,
      rankingValueLabelBackground: colorScheme.surface,
    );
    final shareTitle = l10n.dashboardUserRankingTitle;
    final metadata = buildOverviewUserRankingShareMetadata(
      l10n: l10n,
      userRankings: userRankings,
      exportHeaderContext: widget.exportHeaderContext,
    );
    final shareActions = ChartShareActions(
      context: context,
      captureKey: _shareKey,
      metadata: metadata,
      onRequestShare: widget.onRequestShare,
      onRequestFullscreen: widget.onRequestFullscreen,
    );

    void openFullscreen() {
      final rankingsSnapshot = List<OverviewUserRanking>.of(
        userRankings,
        growable: false,
      );
      final fullscreenShareKey = GlobalKey();
      shareActions.openFullscreen(
        metadata.toFullscreenRequest(
          shareCaptureKey: fullscreenShareKey,
          semanticsLabel: shareTitle,
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
                        overviewUserRankingShareTooltip(l10n, u, v),
                    dataLabelBuilder: (u, v) =>
                        overviewUserRankingShareDataLabel(l10n, u, v),
                    style: appDashboardComparisonBarChartStyle(
                      tokens: fullscreenTokens,
                      kind: AppDashboardComparisonBarChartKind.ranking,
                      l10n: l10n,
                      heightOverride: constraints.maxHeight,
                      rankingValueLabelBackground: Theme.of(
                        fullscreenContext,
                      ).colorScheme.surface,
                    ),
                    emptyPlaceholder: showEmpty ? emptyPlaceholder : null,
                  );
                },
              ),
            );
          },
        ),
      );
    }

    return RepaintBoundary(
      key: _shareKey,
      child: AppComparisonBarChart<OverviewUserRanking>(
        title: shareTitle,
        subtitle: l10n.dashboardUserRankingSubtitle,
        onShare: shareActions.shareCallback(),
        shareProgressKey: _shareKey,
        onOpenFullscreen: shareActions.fullscreenCallback(openFullscreen),
        items: userRankings,
        plotFloorAccessibilityNotice: l10n.chartComparisonPlotFloorNotice,
        extremeSpreadAccessibilityNotice:
            l10n.chartComparisonExtremeValueSpreadNotice,
        labelBuilder: (u) => u.userName,
        valueBuilder: (u) => u.totalAmount,
        tooltipLabelBuilder: (u, v) =>
            overviewUserRankingShareTooltip(l10n, u, v),
        dataLabelBuilder: (u, v) =>
            overviewUserRankingShareDataLabel(l10n, u, v),
        style: rankingChartStyle,
        emptyPlaceholder: showEmpty ? emptyPlaceholder : null,
      ),
    );
  }
}

import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/features/overview/domain/entities/overview_agent_ranking.dart';
import 'package:colmeia/features/overview/domain/entities/overview_user_ranking.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_fullscreen_request.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_share_request.dart';
import 'package:colmeia/shared/widgets/charts/app_comparison_bar_chart.dart';
import 'package:colmeia/shared/widgets/charts/app_dashboard_comparison_bar_chart_preset.dart';
import 'package:colmeia/shared/widgets/charts/chart_export_capture.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_metadata.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_table_data.dart';
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
    this.onRequestFullscreen,
    this.onRequestShare,
    super.key,
  });

  final AppLocalizations l10n;
  final List<OverviewAgentRanking> agentRankings;
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
    final showEmpty = agentRankings.isEmpty;
    final shareTitle = l10n.dashboardAgentRankingTitle;
    final inlineStyle = appDashboardComparisonBarChartStyle(
      tokens: tokens,
      kind: AppDashboardComparisonBarChartKind.ranking,
      l10n: l10n,
    );
    final metadata = ChartShareMetadata(
      title: shareTitle,
      subtitle: l10n.dashboardAgentRankingSubtitle,
      tableData: ChartShareTableData.fromRanking(
        rankHeader: l10n.chartSharePdfColumnRank,
        nameHeader: l10n.chartSharePdfColumnName,
        amountHeader: l10n.chartSharePdfColumnAmount,
        salesCountHeader: l10n.chartSharePdfColumnSalesCount,
        salesCounts: <String>[
          for (final ranking in agentRankings)
            ranking.totalSalesCount.toString(),
        ],
        items: <({String name, String amount})>[
          for (final ranking in agentRankings)
            (
              name: ranking.displayName,
              amount: AppBrFormatters.currency(ranking.totalAmount),
            ),
        ],
      ),
      chartExportBuilder: agentRankings.isEmpty
          ? null
          : (exportContext) {
              final exportStyle = inlineStyle.forPdfExport();
              return wrapCartesianChartForPdfExport(
                context: exportContext,
                itemCount: agentRankings.length,
                minSlotWidth: comparisonBarMinSlotWidth(
                  minBarWidth: exportStyle.minBarWidth,
                ),
                height: exportStyle.height,
                chart: AppComparisonBarChart<OverviewAgentRanking>(
                  items: agentRankings,
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
                  style: exportStyle,
                ),
              );
            },
    );

    void openFullscreen() {
      final emit = widget.onRequestFullscreen;
      if (emit == null) {
        return;
      }
      final rankingsSnapshot = List<OverviewAgentRanking>.of(
        agentRankings,
        growable: false,
      );
      final fullscreenShareKey = GlobalKey();
      emit(
        context,
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
      );
    }

    void openShare() {
      final emit = widget.onRequestShare;
      if (emit == null) {
        return;
      }
      emit(context, metadata.toShareRequest(_shareKey));
    }

    return RepaintBoundary(
      key: _shareKey,
      child: AppComparisonBarChart<OverviewAgentRanking>(
        title: shareTitle,
        subtitle: l10n.dashboardAgentRankingSubtitle,
        onShare: widget.onRequestShare == null ? null : openShare,
        shareProgressKey: _shareKey,
        onOpenFullscreen:
            widget.onRequestFullscreen == null ? null : openFullscreen,
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
    this.onRequestFullscreen,
    this.onRequestShare,
    super.key,
  });

  final AppLocalizations l10n;
  final List<OverviewUserRanking> userRankings;
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
    final rankingChartStyle = appDashboardComparisonBarChartStyle(
      tokens: tokens,
      kind: AppDashboardComparisonBarChartKind.ranking,
      l10n: l10n,
      rankingValueLabelBackground: colorScheme.surface,
    );
    final showEmpty = userRankings.isEmpty;
    final shareTitle = l10n.dashboardUserRankingTitle;
    final metadata = ChartShareMetadata(
      title: shareTitle,
      subtitle: l10n.dashboardUserRankingSubtitle,
      tableData: ChartShareTableData.fromRanking(
        rankHeader: l10n.chartSharePdfColumnRank,
        nameHeader: l10n.chartSharePdfColumnUser,
        amountHeader: l10n.chartSharePdfColumnAmount,
        salesCountHeader: l10n.chartSharePdfColumnSalesCount,
        salesCounts: <String>[
          for (final ranking in userRankings)
            ranking.totalSalesCount.toString(),
        ],
        items: <({String name, String amount})>[
          for (final ranking in userRankings)
            (
              name: ranking.userName,
              amount: AppBrFormatters.currency(ranking.totalAmount),
            ),
        ],
      ),
      chartExportBuilder: userRankings.isEmpty
          ? null
          : (exportContext) {
              final exportStyle = rankingChartStyle.forPdfExport();
              return wrapCartesianChartForPdfExport(
                context: exportContext,
                itemCount: userRankings.length,
                minSlotWidth: comparisonBarMinSlotWidth(
                  minBarWidth: exportStyle.minBarWidth,
                ),
                height: exportStyle.height,
                chart: AppComparisonBarChart<OverviewUserRanking>(
                  items: userRankings,
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
                  style: exportStyle,
                ),
              );
            },
    );

    void openFullscreen() {
      final emit = widget.onRequestFullscreen;
      if (emit == null) {
        return;
      }
      final rankingsSnapshot = List<OverviewUserRanking>.of(
        userRankings,
        growable: false,
      );
      final fullscreenShareKey = GlobalKey();
      emit(
        context,
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
      );
    }

    void openShare() {
      final emit = widget.onRequestShare;
      if (emit == null) {
        return;
      }
      emit(context, metadata.toShareRequest(_shareKey));
    }

    return RepaintBoundary(
      key: _shareKey,
      child: AppComparisonBarChart<OverviewUserRanking>(
        title: shareTitle,
        subtitle: l10n.dashboardUserRankingSubtitle,
        onShare: widget.onRequestShare == null ? null : openShare,
        shareProgressKey: _shareKey,
        onOpenFullscreen:
            widget.onRequestFullscreen == null ? null : openFullscreen,
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

import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/features/overview/domain/entities/overview_agent_ranking.dart';
import 'package:colmeia/features/overview/domain/entities/overview_user_ranking.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/charts/app_comparison_bar_chart.dart';
import 'package:colmeia/shared/widgets/charts/chart_export_capture.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_metadata.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_pdf_limits.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_pdf_orientation.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_table_data.dart';

String overviewUserRankingShareTooltip(
  AppLocalizations l10n,
  OverviewUserRanking user,
  num barValue,
) {
  final value = barValue.toDouble();
  return '${user.userName}: ${AppBrFormatters.currency(value)}\n'
      '${l10n.overviewKpiAvgTicket}: ${AppBrFormatters.currency(user.averageTicket)}';
}

String overviewUserRankingShareDataLabel(
  AppLocalizations l10n,
  OverviewUserRanking user,
  num barValue,
) {
  final value = barValue.toDouble();
  return '${AppBrFormatters.compactCurrency(value)}\n'
      '${l10n.overviewKpiAvgTicket}: ${AppBrFormatters.compactCurrency(user.averageTicket)}';
}

ChartShareMetadata buildOverviewAgentRankingShareMetadata({
  required AppLocalizations l10n,
  required AppThemeTokens tokens,
  required List<OverviewAgentRanking> agentRankings,
  required AppComparisonBarChartStyle inlineStyle,
}) {
  final tableLimit = applyChartShareTableRowLimit(
    tableData: ChartShareTableData.fromRanking(
      rankHeader: l10n.chartSharePdfColumnRank,
      nameHeader: l10n.chartSharePdfColumnName,
      amountHeader: l10n.chartSharePdfColumnAmount,
      salesCountHeader: l10n.chartSharePdfColumnSalesCount,
      salesCounts: <String>[
        for (final ranking in agentRankings) ranking.totalSalesCount.toString(),
      ],
      items: <({String name, String amount})>[
        for (final ranking in agentRankings)
          (
            name: ranking.displayName,
            amount: AppBrFormatters.currency(ranking.totalAmount),
          ),
      ],
    ),
    truncationNoticeBuilder: l10n.chartSharePdfTableRowsTruncated,
  );

  return ChartShareMetadata(
    title: l10n.dashboardAgentRankingTitle,
    subtitle: l10n.dashboardAgentRankingSubtitle,
    filterSummary: tableLimit.truncationNotice,
    tableData: tableLimit.tableData,
    pdfOrientation: ChartSharePdfOrientation.landscape,
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
                labelBuilder: (agent) => agent.displayName,
                valueBuilder: (agent) => agent.totalAmount,
                tooltipLabelBuilder: (agent, value) =>
                    '${agent.displayName}: ${AppBrFormatters.currency(value)}',
                dataLabelBuilder: (agent, value) =>
                    AppBrFormatters.compactCurrency(value),
                style: exportStyle,
              ),
            );
          },
  );
}

ChartShareMetadata buildOverviewUserRankingShareMetadata({
  required AppLocalizations l10n,
  required List<OverviewUserRanking> userRankings,
  required AppComparisonBarChartStyle rankingChartStyle,
}) {
  final tableLimit = applyChartShareTableRowLimit(
    tableData: ChartShareTableData.fromRanking(
      rankHeader: l10n.chartSharePdfColumnRank,
      nameHeader: l10n.chartSharePdfColumnUser,
      amountHeader: l10n.chartSharePdfColumnAmount,
      salesCountHeader: l10n.chartSharePdfColumnSalesCount,
      salesCounts: <String>[
        for (final ranking in userRankings) ranking.totalSalesCount.toString(),
      ],
      items: <({String name, String amount})>[
        for (final ranking in userRankings)
          (
            name: ranking.userName,
            amount: AppBrFormatters.currency(ranking.totalAmount),
          ),
      ],
    ),
    truncationNoticeBuilder: l10n.chartSharePdfTableRowsTruncated,
  );

  return ChartShareMetadata(
    title: l10n.dashboardUserRankingTitle,
    subtitle: l10n.dashboardUserRankingSubtitle,
    filterSummary: tableLimit.truncationNotice,
    tableData: tableLimit.tableData,
    pdfOrientation: ChartSharePdfOrientation.landscape,
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
                labelBuilder: (user) => user.userName,
                valueBuilder: (user) => user.totalAmount,
                tooltipLabelBuilder: (user, value) =>
                    overviewUserRankingShareTooltip(l10n, user, value),
                dataLabelBuilder: (user, value) =>
                    overviewUserRankingShareDataLabel(l10n, user, value),
                style: exportStyle,
              ),
            );
          },
  );
}

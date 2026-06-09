import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/features/agent_queries/domain/entities/ranking_produtos_faturamento_row.dart';
import 'package:colmeia/features/sales/presentation/utils/sales_ranking_produtos_faturamento_branch_metrics.dart';
import 'package:colmeia/features/sales/presentation/utils/sales_ranking_produtos_faturamento_donut_segments.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_ranking_produtos_faturamento_grid_columns.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/widgets/charts/app_category_donut_card.dart';
import 'package:colmeia/shared/widgets/charts/app_category_donut_card_models.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_theme.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_metadata.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_pdf_limits.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_table_data.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

ChartShareMetadata buildSalesRankingProdutosFaturamentoShareMetadata({
  required AppLocalizations l10n,
  required String branchTitle,
  required String metricSubtitle,
  required List<RankingProdutosFaturamentoRow> displayRows,
  required List<RankingProdutosFaturamentoRow> chartRows,
}) {
  final tableLimit = applyChartShareTableRowLimit(
    tableData: ChartShareTableData.fromReportColumns(
      columns: rankingProdutosFaturamentoGridColumns(l10n),
      rows: displayRows,
    ),
    truncationNoticeBuilder: (shownRows, totalRows) =>
        l10n.chartSharePdfTableRowsTruncated(shownRows, totalRows),
  );

  return ChartShareMetadata(
    title: branchTitle,
    subtitle: metricSubtitle,
    filterSummary: tableLimit.truncationNotice,
    tableData: tableLimit.tableData,
    chartExportBuilder: chartRows.isEmpty
        ? null
        : (exportContext) => _RankingFaturamentoPieExport(
            l10n: l10n,
            rows: chartRows,
            segments: rankingProdutosFaturamentoDonutSegments(
              rows: chartRows,
              diversosLabel: l10n.salesRankingProdutosFaturamentoDiversosLabel,
              palette: AppChartTheme.fromContext(
                exportContext,
                preset: AppChartPreset.standard,
              ).palette,
              diversosColor: Theme.of(
                exportContext,
              ).colorScheme.outline.withValues(alpha: 0.55),
            ),
          ),
  );
}

class _RankingFaturamentoPieExport extends StatelessWidget {
  const _RankingFaturamentoPieExport({
    required this.l10n,
    required this.rows,
    required this.segments,
  });

  final AppLocalizations l10n;
  final List<RankingProdutosFaturamentoRow> rows;
  final List<AppCategoryDonutSegment> segments;

  static const AppCategoryDonutCardStyle _pieStyle = AppCategoryDonutCardStyle(
    innerRadius: '0%',
    outerRadius: '88%',
    doughnutAnimationDurationMs: 0,
    showLegend: false,
    chartSize: 300,
    chartMinHeight: 300,
  );

  @override
  Widget build(BuildContext context) {
    final total = branchRevenueTotal(rows);
    final percentFormat = NumberFormat('#,##0.0', 'pt_BR');

    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: SizedBox(
        width: _pieStyle.chartSize,
        height: _pieStyle.chartSize,
        child: AppCategoryDonutCard(
          title: l10n.salesRankingProdutosFaturamentoChartTitle,
          showHeader: false,
          wrapInSectionCard: false,
          segments: segments,
          centerPrimaryLabel:
              total > 0 ? AppBrFormatters.compactCurrency(total) : null,
          centerSecondaryLabel: rows.isEmpty
              ? null
              : '${percentFormat.format(branchPercentSum(rows))}%',
          style: _pieStyle,
        ),
      ),
    );
  }
}

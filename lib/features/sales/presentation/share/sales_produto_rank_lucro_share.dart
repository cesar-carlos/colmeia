import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_produto_rank_lucro_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_produto_rank_lucro_sort_by.dart';
import 'package:colmeia/features/sales/presentation/share/sales_chart_share_export_filter.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:colmeia/shared/widgets/charts/app_horizontal_progress_chart.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_export_header_context.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_metadata.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_pdf_limits.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_table_data.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

const double _kRankLucroExportWidth = 720;

/// Logical height for offscreen horizontal progress chart PDF export (no title).
double salesProdutoRankLucroExportHeight({
  required int rowCount,
  required AppHorizontalProgressChartStyle style,
  required AppThemeTokens tokens,
  bool showDividers = false,
}) {
  if (rowCount <= 0) {
    return 0;
  }

  const labelRowHeight = 40.0;
  final rowPadding = style.rowPadding?.resolve(TextDirection.ltr);
  final verticalPad = rowPadding?.vertical ?? 0;
  final rowSpacing = style.rowSpacing ?? tokens.gapMd;
  final gapSm = tokens.gapSm;
  final barHeight = style.barHeight;
  final singleRowHeight = verticalPad + labelRowHeight + gapSm + barHeight;
  final betweenRows = showDividers
      ? (style.dividerPadding?.resolve(TextDirection.ltr).vertical ??
                rowSpacing) +
            1
      : rowSpacing;

  return rowCount * singleRowHeight + (rowCount - 1) * betweenRows;
}

num _chartValueForRow(
  ProdutoVendidoProdutoRankLucroRow row,
  ProdutoVendidoProdutoRankLucroSortBy sortBy,
) {
  return switch (sortBy) {
    ProdutoVendidoProdutoRankLucroSortBy.totalValorLucro => row.totalValorLucro,
    _ => row.qtdItensVendido,
  };
}

ChartShareMetadata buildSalesProdutoRankLucroShareMetadata({
  required AppLocalizations l10n,
  required List<ProdutoVendidoProdutoRankLucroRow> rows,
  required ProdutoVendidoProdutoRankLucroSortBy sortBy,
  required String periodSubtitle,
  required String branchName,
  required String metricLabel,
  required double maxValue,
  ChartShareExportHeaderContext? exportHeaderContext,
}) {
  final metricProfit =
      sortBy == ProdutoVendidoProdutoRankLucroSortBy.totalValorLucro;
  final quantityFormat = NumberFormat.decimalPattern(l10n.localeName);
  final axisFormat = metricProfit
      ? AppBrFormatters.compactCurrencyFormat
      : NumberFormat.decimalPattern('pt_BR');

  final tableLimit = applyChartShareTableRowLimit(
    tableData: ChartShareTableData.fromRanking(
      rankHeader: l10n.chartSharePdfColumnRank,
      nameHeader: l10n.chartSharePdfColumnName,
      amountHeader: metricProfit
          ? l10n.chartSharePdfColumnProfit
          : l10n.salesProdutoRankLucroSortQuantity,
      items: <({String name, String amount})>[
        for (final row in rows)
          (
            name: row.nomeProduto.trim(),
            amount: metricProfit
                ? AppBrFormatters.currency(row.totalValorLucro)
                : quantityFormat.format(row.qtdItensVendido),
          ),
      ],
    ),
    truncationNoticeBuilder: (shownRows, totalRows) =>
        l10n.chartSharePdfTableRowsTruncated(shownRows, totalRows),
  );

  return ChartShareMetadata(
    title: l10n.salesProdutoRankLucroChartTitle,
    filterSummary: buildChartSharePdfFilterSummary(
      exportHeaderContext:
          exportHeaderContext ??
          buildSalesSingleAgentChartShareExportHeaderContext(
            l10n: l10n,
            agentName: branchName,
            parameters: <ChartShareExportHeaderParameter>[
              ChartShareExportHeaderParameter(
                label: l10n.salesProdutoRankLucroFilterSortBy,
                value: metricLabel,
              ),
              if (periodSubtitle.trim().isNotEmpty)
                ChartShareExportHeaderParameter(
                  label: l10n.salesProdutoRankLucroFilterPeriod,
                  value: periodSubtitle,
                ),
            ],
          ),
      truncationNotice: tableLimit.truncationNotice,
    ),
    tableData: tableLimit.tableData,
    chartExportBuilder: rows.isEmpty
        ? null
        : (exportContext) {
            final theme = Theme.of(exportContext);
            final tokens =
                theme.extension<AppThemeTokens>() ?? AppThemeTokens.light;
            final chartStyle = AppHorizontalProgressChartStyle(
              barColor: theme.appColors.primary,
              trackColor: theme.colorScheme.surfaceContainerHigh,
              rowSpacing: tokens.gapMd,
              barHeight: 10,
              rowPadding: EdgeInsets.symmetric(vertical: tokens.gapXs),
              valueTextStyle: theme.appTypography.body.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.appColors.primary,
              ),
            );
            final exportHeight = salesProdutoRankLucroExportHeight(
              rowCount: rows.length,
              style: chartStyle,
              tokens: tokens,
              showDividers: true,
            );
            final rowsSnapshot = List<ProdutoVendidoProdutoRankLucroRow>.of(
              rows,
              growable: false,
            );
            final rankByRow = <ProdutoVendidoProdutoRankLucroRow, int>{
              for (var i = 0; i < rowsSnapshot.length; i++)
                rowsSnapshot[i]: i + 1,
            };

            return ColoredBox(
              color: theme.colorScheme.surface,
              child: SizedBox(
                width: _kRankLucroExportWidth,
                height: exportHeight,
                child:
                    AppHorizontalProgressChart<
                      ProdutoVendidoProdutoRankLucroRow
                    >(
                      items: rowsSnapshot,
                      labelBuilder: (row) => row.nomeProduto.trim(),
                      valueBuilder: (row) =>
                          _chartValueForRow(row, sortBy).toDouble(),
                      maxValue: maxValue,
                      rowLeadingBuilder: (context, row) => _RankBadge(
                        rank: rankByRow[row] ?? 0,
                      ),
                      rowTooltipBuilder: (row, value, _) {
                        final name = row.nomeProduto.trim();
                        final text = metricProfit
                            ? AppBrFormatters.smartCompactCurrency(value)
                            : axisFormat.format(value);
                        return '$name • $text';
                      },
                      valueLabelBuilder: (row, value, _) => metricProfit
                          ? AppBrFormatters.smartCompactCurrency(value)
                          : axisFormat.format(value),
                      showDividers: true,
                      style: chartStyle,
                      wrapInCard: false,
                    ),
              ),
            );
          },
  );
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank});

  final int rank;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.appTokens;
    final colors = theme.appColors;

    final (background, foreground, icon) = switch (rank) {
      1 => (
        colors.primaryContainer,
        colors.onPrimaryContainer,
        Icons.workspace_premium_rounded,
      ),
      2 => (
        colors.secondaryContainer,
        colors.onSecondaryContainer,
        Icons.military_tech_rounded,
      ),
      3 => (
        colors.tertiaryFixed,
        colors.onTertiaryFixed,
        Icons.stars_rounded,
      ),
      _ => (
        theme.colorScheme.surfaceContainerHigh,
        colors.onSurfaceVariant,
        null,
      ),
    };
    final showMedal = rank >= 1 && rank <= 3;

    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(tokens.formFieldRadius),
      ),
      child: showMedal
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(icon, size: 12, color: foreground),
                Text(
                  '$rank',
                  style: theme.appTypography.caption.copyWith(
                    fontWeight: FontWeight.w800,
                    color: foreground,
                    height: 1,
                  ),
                ),
              ],
            )
          : Text(
              rank > 0 ? '$rank' : '–',
              style: theme.appTypography.caption.copyWith(
                fontWeight: FontWeight.w800,
                color: foreground,
              ),
            ),
    );
  }
}

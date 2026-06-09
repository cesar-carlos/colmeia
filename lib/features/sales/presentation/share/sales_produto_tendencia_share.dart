import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_summary_row.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_produto_tendencia_classificacao_chart_support.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/charts/app_comparison_bar_chart.dart';
import 'package:colmeia/shared/widgets/charts/chart_export_capture.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_metadata.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_pdf_limits.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_pdf_orientation.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_table_data.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SalesProdutoTendenciaClassBucket {
  const SalesProdutoTendenciaClassBucket({
    required this.classificacao,
    required this.count,
    required this.impacto,
  });

  final String classificacao;
  final int count;
  final double impacto;
}

String salesProdutoTendenciaClassificacaoLabel(
  AppLocalizations l10n,
  String? value,
) {
  final raw = value?.trim().toUpperCase();
  return switch (raw) {
    'PAROU DE VENDER' => l10n.salesProdutoTendenciaClassificacaoStopped,
    'NOVO PRODUTO' => l10n.salesProdutoTendenciaClassificacaoNew,
    'CRESCENDO' => l10n.salesProdutoTendenciaClassificacaoGrowing,
    'CAINDO' => l10n.salesProdutoTendenciaClassificacaoFalling,
    'ESTAVEL' => l10n.salesProdutoTendenciaClassificacaoStable,
    _ => l10n.salesProdutoTendenciaFilterAllOption,
  };
}

class SalesProdutoTendenciaSummary {
  const SalesProdutoTendenciaSummary({
    required this.countGrowing,
    required this.countFalling,
    required this.countNew,
    required this.countStopped,
    required this.countStable,
    required this.netImpact,
    required this.buckets,
  });

  final int countGrowing;
  final int countFalling;
  final int countNew;
  final int countStopped;
  final int countStable;
  final double netImpact;
  final List<SalesProdutoTendenciaClassBucket> buckets;
}

SalesProdutoTendenciaSummary buildSalesProdutoTendenciaSummary(
  List<ProdutoVendidoTendenciaDeVendaSummaryRow> summaryRows,
) {
  final counts = <String, int>{};
  final impacts = <String, double>{};
  var netImpact = 0.0;

  for (final row in summaryRows) {
    final classificacao = row.classificacao.trim().toUpperCase();
    counts[classificacao] =
        (counts[classificacao] ?? 0) + row.quantidadeProdutos;
    impacts[classificacao] = (impacts[classificacao] ?? 0) + row.impactoLiquido;
    netImpact += row.impactoLiquido;
  }

  final buckets =
      counts.entries
          .map(
            (entry) => SalesProdutoTendenciaClassBucket(
              classificacao: entry.key,
              count: entry.value,
              impacto: impacts[entry.key] ?? 0,
            ),
          )
          .toList(growable: false)
        ..sort((a, b) => b.count.compareTo(a.count));

  return SalesProdutoTendenciaSummary(
    countGrowing: counts['CRESCENDO'] ?? 0,
    countFalling: counts['CAINDO'] ?? 0,
    countNew: counts['NOVO PRODUTO'] ?? 0,
    countStopped: counts['PAROU DE VENDER'] ?? 0,
    countStable: counts['ESTAVEL'] ?? 0,
    netImpact: netImpact,
    buckets: buckets,
  );
}

List<SalesProdutoTendenciaClassBucket> salesProdutoTendenciaBucketsFromSummary(
  List<ProdutoVendidoTendenciaDeVendaSummaryRow> summaryRows,
) {
  return buildSalesProdutoTendenciaSummary(summaryRows).buckets;
}

ChartShareMetadata buildSalesProdutoTendenciaClassificacaoShareMetadata({
  required AppLocalizations l10n,
  required List<ProdutoVendidoTendenciaDeVendaSummaryRow> summaryRows,
  required List<SalesProdutoTendenciaClassBucket> buckets,
  required AppThemeTokens tokens,
}) {
  final legend = salesProdutoTendenciaClassificacaoPdfLegend(l10n, buckets);
  return ChartShareMetadata(
    title: l10n.salesProdutoTendenciaSummaryByClassificacaoTitle,
    subtitle:
        '${l10n.salesProdutoTendenciaSummaryByClassificacaoSubtitle}\n$legend',
    pdfOrientation: ChartSharePdfOrientation.landscape,
    tableData: ChartShareTableData(
      headers: <String>[
        l10n.chartSharePdfColumnLabel,
        l10n.chartSharePdfColumnSalesCount,
        l10n.chartSharePdfColumnAmount,
      ],
      rows: <List<String>>[
        for (final row in summaryRows)
          <String>[
            salesProdutoTendenciaClassificacaoLabel(l10n, row.classificacao),
            row.quantidadeProdutos.toString(),
            NumberFormat.decimalPattern(l10n.localeName).format(
              row.impactoLiquido.round(),
            ),
          ],
      ],
    ),
    chartExportBuilder: buckets.isEmpty
        ? null
        : (exportContext) => _classificacaoComparisonExport(
            exportContext: exportContext,
            l10n: l10n,
            tokens: tokens,
            buckets: buckets,
          ),
  );
}

ChartShareMetadata buildSalesProdutoTendenciaTopGainersShareMetadata({
  required AppLocalizations l10n,
  required List<ProdutoVendidoTendenciaDeVendaRow> rows,
  required AppThemeTokens tokens,
}) {
  final tableLimit = applyChartShareTableRowLimit(
    tableData: ChartShareTableData(
      headers: <String>[
        l10n.chartSharePdfColumnName,
        l10n.chartSharePdfColumnValue,
      ],
      rows: <List<String>>[
        for (final row in rows)
          <String>[
            row.nomeProduto,
            NumberFormat.decimalPattern(l10n.localeName).format(row.diferenca),
          ],
      ],
    ),
    truncationNoticeBuilder: (shownRows, totalRows) =>
        l10n.chartSharePdfTableRowsTruncated(shownRows, totalRows),
  );

  return ChartShareMetadata(
    title: l10n.salesProdutoTendenciaTopGainersTitle,
    subtitle: l10n.salesProdutoTendenciaTopGainersSubtitle,
    filterSummary: tableLimit.truncationNotice,
    tableData: tableLimit.tableData,
    pdfOrientation: ChartSharePdfOrientation.landscape,
    chartExportBuilder: rows.isEmpty
        ? null
        : (exportContext) => _topMoversComparisonExport(
            exportContext: exportContext,
            l10n: l10n,
            tokens: tokens,
            items: rows,
            useAbsolutePercentForLosers: false,
          ),
  );
}

ChartShareMetadata buildSalesProdutoTendenciaTopLosersShareMetadata({
  required AppLocalizations l10n,
  required List<ProdutoVendidoTendenciaDeVendaRow> rows,
  required AppThemeTokens tokens,
}) {
  final tableLimit = applyChartShareTableRowLimit(
    tableData: ChartShareTableData(
      headers: <String>[
        l10n.chartSharePdfColumnName,
        l10n.chartSharePdfColumnValue,
      ],
      rows: <List<String>>[
        for (final row in rows)
          <String>[
            row.nomeProduto,
            NumberFormat.decimalPattern(l10n.localeName).format(row.diferenca),
          ],
      ],
    ),
    truncationNoticeBuilder: (shownRows, totalRows) =>
        l10n.chartSharePdfTableRowsTruncated(shownRows, totalRows),
  );

  return ChartShareMetadata(
    title: l10n.salesProdutoTendenciaTopLosersTitle,
    subtitle: l10n.salesProdutoTendenciaTopLosersSubtitle,
    filterSummary: tableLimit.truncationNotice,
    tableData: tableLimit.tableData,
    pdfOrientation: ChartSharePdfOrientation.landscape,
    chartExportBuilder: rows.isEmpty
        ? null
        : (exportContext) => _topMoversComparisonExport(
            exportContext: exportContext,
            l10n: l10n,
            tokens: tokens,
            items: rows,
            useAbsolutePercentForLosers: true,
          ),
  );
}

Widget _classificacaoComparisonExport({
  required BuildContext exportContext,
  required AppLocalizations l10n,
  required AppThemeTokens tokens,
  required List<SalesProdutoTendenciaClassBucket> buckets,
}) {
  final colors = Theme.of(exportContext).appColors;
  final exportStyle = salesTrendClassificacaoComparisonBarChartStyle(
    tokens: tokens,
    l10n: l10n,
    yAxisFormat: NumberFormat.decimalPattern(l10n.localeName),
  ).forPdfExport();
  final orderedBuckets = buckets.isEmpty
      ? buckets
      : salesProdutoTendenciaOrderedClassBuckets(
          buckets
              .map(
                (bucket) => ProdutoVendidoTendenciaDeVendaSummaryRow(
                  classificacao: bucket.classificacao,
                  quantidadeProdutos: bucket.count,
                  impactoLiquido: bucket.impacto,
                ),
              )
              .toList(growable: false),
        );

  return wrapCartesianChartForPdfExport(
    context: exportContext,
    itemCount: orderedBuckets.length,
    minSlotWidth: comparisonBarMinSlotWidth(
      minBarWidth: exportStyle.minBarWidth,
    ),
    height: exportStyle.height,
    chart: AppComparisonBarChart<SalesProdutoTendenciaClassBucket>(
      items: orderedBuckets,
      labelBuilder: (bucket) =>
          salesProdutoTendenciaClassificacaoLabel(l10n, bucket.classificacao),
      valueBuilder: (bucket) => bucket.count,
      colorBuilder: (bucket) => salesProdutoTendenciaClassificacaoColor(
        colors,
        bucket.classificacao,
      ),
      plotFloorAccessibilityNotice: l10n.chartComparisonPlotFloorNotice,
      extremeSpreadAccessibilityNotice:
          l10n.chartComparisonExtremeValueSpreadNotice,
      style: exportStyle,
      dataLabelBuilder: (bucket, _) =>
          NumberFormat.decimalPattern(l10n.localeName).format(bucket.count),
      tooltipLabelBuilder: (bucket, _) =>
          '${salesProdutoTendenciaClassificacaoLabel(l10n, bucket.classificacao)} • '
          '${bucket.count} • '
          '${NumberFormat.decimalPattern(l10n.localeName).format(bucket.impacto.round())}',
    ),
  );
}

Widget _topMoversComparisonExport({
  required BuildContext exportContext,
  required AppLocalizations l10n,
  required AppThemeTokens tokens,
  required List<ProdutoVendidoTendenciaDeVendaRow> items,
  required bool useAbsolutePercentForLosers,
}) {
  final exportStyle = AppComparisonBarChartStyle(
    animationDuration: const Duration(milliseconds: 350),
    stickyPrimaryYAxisWhileScrolling: false,
    enableTapHighlight: true,
    yAxisFormat: NumberFormat.decimalPattern(l10n.localeName),
    horizontalScrollSemanticsHint:
        l10n.overviewComparisonBarHorizontalScrollHint,
    loadingLabel: l10n.overviewComparisonChartLoading,
    showDataLabels: true,
    wrapXAxisLabelsInTwoLines: true,
    wrapXAxisCharsPerLine: 18,
    chartPadding: EdgeInsets.only(bottom: tokens.gapSm),
    dataLabelOffset: Offset(0, tokens.gapSm),
    tooltipLabelMaxChars: 56,
    height: tokens.chartStandardHeight + tokens.contentSpacing * 2,
  ).forPdfExport();

  return wrapCartesianChartForPdfExport(
    context: exportContext,
    itemCount: items.length,
    minSlotWidth: comparisonBarMinSlotWidth(
      minBarWidth: exportStyle.minBarWidth,
    ),
    height: exportStyle.height,
    chart: AppComparisonBarChart<ProdutoVendidoTendenciaDeVendaRow>(
      items: items,
      labelBuilder: (row) => row.nomeProduto,
      valueBuilder: (row) => useAbsolutePercentForLosers
          ? row.percentualTendencia.abs()
          : row.percentualTendencia,
      plotFloorAccessibilityNotice: l10n.chartComparisonPlotFloorNotice,
      extremeSpreadAccessibilityNotice:
          l10n.chartComparisonExtremeValueSpreadNotice,
      style: exportStyle,
      dataLabelBuilder: (row, _) =>
          '${row.percentualTendencia.toStringAsFixed(1)}%',
      tooltipLabelBuilder: (row, _) =>
          '${row.nomeProduto} • '
          '${row.percentualTendencia.toStringAsFixed(2)}% • '
          '${NumberFormat.decimalPattern(l10n.localeName).format(row.diferenca.round())}',
    ),
  );
}

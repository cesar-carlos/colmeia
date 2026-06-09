import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_media_movel_row.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_produto_tendencia_media_movel_classificacao_chart_support.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_produto_tendencia_media_movel_classificacao_labels.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_produto_tendencia_media_movel_summary_section.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_metadata.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_pdf_limits.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_pdf_orientation.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_table_data.dart';
import 'package:intl/intl.dart';

ChartShareMetadata buildSalesProdutoTendenciaMediaMovelCountShareMetadata({
  required AppLocalizations l10n,
  required List<SalesProdutoTendenciaMediaMovelClassBucket> buckets,
}) {
  final legend = salesProdutoTendenciaMediaMovelClassificacaoPdfLegend(
    l10n,
    buckets,
  );
  final tableLimit = applyChartShareTableRowLimit(
    tableData: ChartShareTableData(
      headers: <String>[
        l10n.chartSharePdfColumnLabel,
        l10n.chartSharePdfColumnSalesCount,
      ],
      rows: <List<String>>[
        for (final bucket in buckets)
          <String>[
            produtoTendenciaMediaMovelClassificacaoLabel(
              l10n,
              bucket.classificacao,
            ),
            bucket.count.toString(),
          ],
      ],
    ),
    truncationNoticeBuilder: (shownRows, totalRows) =>
        l10n.chartSharePdfTableRowsTruncated(shownRows, totalRows),
  );

  return ChartShareMetadata(
    title: l10n.salesProdutoTendenciaMediaMovelSummaryByClassificacaoTitle,
    subtitle:
        '${l10n.salesProdutoTendenciaMediaMovelSummaryByClassificacaoSubtitle}\n$legend',
    filterSummary: tableLimit.truncationNotice,
    pdfOrientation: ChartSharePdfOrientation.landscape,
    tableData: tableLimit.tableData,
  );
}

ChartShareMetadata buildSalesProdutoTendenciaMediaMovelImpactShareMetadata({
  required AppLocalizations l10n,
  required List<SalesProdutoTendenciaMediaMovelClassBucket> buckets,
}) {
  final impactFormat = NumberFormat.decimalPattern(l10n.localeName);
  final legend = salesProdutoTendenciaMediaMovelClassificacaoPdfLegend(
    l10n,
    buckets,
  );
  final tableLimit = applyChartShareTableRowLimit(
    tableData: ChartShareTableData(
      headers: <String>[
        l10n.chartSharePdfColumnLabel,
        l10n.chartSharePdfColumnValue,
      ],
      rows: <List<String>>[
        for (final bucket in buckets)
          <String>[
            produtoTendenciaMediaMovelClassificacaoLabel(
              l10n,
              bucket.classificacao,
            ),
            impactFormat.format(bucket.impacto),
          ],
      ],
    ),
    truncationNoticeBuilder: (shownRows, totalRows) =>
        l10n.chartSharePdfTableRowsTruncated(shownRows, totalRows),
  );

  return ChartShareMetadata(
    title: l10n.salesProdutoTendenciaMediaMovelSummaryByImpactTitle,
    subtitle:
        '${l10n.salesProdutoTendenciaMediaMovelSummaryByImpactSubtitle}\n$legend',
    filterSummary: tableLimit.truncationNotice,
    pdfOrientation: ChartSharePdfOrientation.landscape,
    tableData: tableLimit.tableData,
  );
}

ChartShareMetadata buildSalesProdutoTendenciaMediaMovelDetailsShareMetadata({
  required AppLocalizations l10n,
  required List<ProdutoVendidoTendenciaDeVendaMediaMovelRow> rows,
  required String filterSummary,
}) {
  final decimalFormat = NumberFormat.decimalPattern(l10n.localeName);
  final tableLimit = applyChartShareTableRowLimit(
    tableData: ChartShareTableData(
      headers: <String>[
        l10n.salesProdutoTendenciaMediaMovelColProduct,
        l10n.salesProdutoTendenciaMediaMovelColClassificacao,
        l10n.salesProdutoTendenciaMediaMovelColGrupo,
        l10n.salesProdutoTendenciaMediaMovelColMediaAtual,
        l10n.salesProdutoTendenciaMediaMovelColMediaAnterior,
        l10n.salesProdutoTendenciaMediaMovelColDiferenca,
        l10n.salesProdutoTendenciaMediaMovelColPercentual,
      ],
      rows: <List<String>>[
        for (final row in rows)
          <String>[
            row.nomeProduto,
            produtoTendenciaMediaMovelClassificacaoLabel(
              l10n,
              row.classificacao,
            ),
            row.nomeGrupoProduto ?? '',
            decimalFormat.format(row.mediaAtual),
            decimalFormat.format(row.mediaAnterior),
            decimalFormat.format(row.diferenca),
            decimalFormat.format(row.tendenciaPercentual),
          ],
      ],
    ),
    truncationNoticeBuilder: (shownRows, totalRows) =>
        l10n.chartSharePdfTableRowsTruncated(shownRows, totalRows),
  );
  return ChartShareMetadata(
    title: l10n.salesProdutoTendenciaMediaMovelDetailsTitle,
    subtitle: l10n.salesProdutoTendenciaMediaMovelDetailsSubtitle,
    pdfOrientation: ChartSharePdfOrientation.landscape,
    filterSummary: joinChartShareFilterSummary(
      filterSummary: filterSummary,
      truncationNotice: tableLimit.truncationNotice,
    ),
    tableData: tableLimit.tableData,
  );
}

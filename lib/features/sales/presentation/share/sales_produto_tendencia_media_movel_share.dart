import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_media_movel_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_media_movel_summary_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/sales_trend_classificacao.dart';
import 'package:colmeia/features/sales/presentation/share/mappers/sales_produto_tendencia_media_movel_share_mapper.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_export_header_context.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_metadata.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_pdf_limits.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_pdf_orientation.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_table_data.dart';
import 'package:intl/intl.dart';

class SalesProdutoTendenciaMediaMovelClassBucket {
  const SalesProdutoTendenciaMediaMovelClassBucket({
    required this.classificacao,
    required this.count,
    required this.impacto,
  });

  final String classificacao;
  final int count;
  final double impacto;
}

class SalesProdutoTendenciaMediaMovelSummary {
  const SalesProdutoTendenciaMediaMovelSummary({
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
  final List<SalesProdutoTendenciaMediaMovelClassBucket> buckets;
}

SalesProdutoTendenciaMediaMovelSummary
buildSalesProdutoTendenciaMediaMovelSummary(
  List<ProdutoVendidoTendenciaDeVendaMediaMovelSummaryRow> summaryRows,
) {
  final counts = <String, int>{};
  final impacts = <String, double>{};
  var netImpact = 0.0;

  for (final row in summaryRows) {
    final classificacao =
        SalesTrendClassificacao.normalize(row.classificacao) ??
        row.classificacao.trim().toUpperCase();
    counts[classificacao] =
        (counts[classificacao] ?? 0) + row.quantidadeProdutos;
    impacts[classificacao] = (impacts[classificacao] ?? 0) + row.impactoLiquido;
    netImpact += row.impactoLiquido;
  }

  final buckets =
      counts.entries
          .map(
            (entry) => SalesProdutoTendenciaMediaMovelClassBucket(
              classificacao: entry.key,
              count: entry.value,
              impacto: impacts[entry.key] ?? 0,
            ),
          )
          .toList(growable: false)
        ..sort((a, b) => b.count.compareTo(a.count));

  return SalesProdutoTendenciaMediaMovelSummary(
    countGrowing: counts[SalesTrendClassificacao.crescendo] ?? 0,
    countFalling: counts[SalesTrendClassificacao.caindo] ?? 0,
    countNew: counts[SalesTrendClassificacao.novo] ?? 0,
    countStopped: counts[SalesTrendClassificacao.parou] ?? 0,
    countStable: counts[SalesTrendClassificacao.estavel] ?? 0,
    netImpact: netImpact,
    buckets: buckets,
  );
}

ChartShareMetadata buildSalesProdutoTendenciaMediaMovelCountShareMetadata({
  required AppLocalizations l10n,
  required List<SalesProdutoTendenciaMediaMovelClassBucket> buckets,
  ChartShareExportHeaderContext? exportHeaderContext,
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
    filterSummary: buildChartSharePdfFilterSummary(
      exportHeaderContext: exportHeaderContext,
      truncationNotice: tableLimit.truncationNotice,
    ),
    pdfOrientation: ChartSharePdfOrientation.landscape,
    tableData: tableLimit.tableData,
  );
}

ChartShareMetadata buildSalesProdutoTendenciaMediaMovelImpactShareMetadata({
  required AppLocalizations l10n,
  required List<SalesProdutoTendenciaMediaMovelClassBucket> buckets,
  ChartShareExportHeaderContext? exportHeaderContext,
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
    filterSummary: buildChartSharePdfFilterSummary(
      exportHeaderContext: exportHeaderContext,
      truncationNotice: tableLimit.truncationNotice,
    ),
    pdfOrientation: ChartSharePdfOrientation.landscape,
    tableData: tableLimit.tableData,
  );
}

ChartShareMetadata buildSalesProdutoTendenciaMediaMovelDetailsShareMetadata({
  required AppLocalizations l10n,
  required List<ProdutoVendidoTendenciaDeVendaMediaMovelRow> rows,
  ChartShareExportHeaderContext? exportHeaderContext,
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
    filterSummary: buildChartSharePdfFilterSummary(
      exportHeaderContext: exportHeaderContext,
      truncationNotice: tableLimit.truncationNotice,
    ),
    tableData: tableLimit.tableData,
  );
}

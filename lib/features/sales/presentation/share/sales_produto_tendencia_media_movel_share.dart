import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_media_movel_row.dart';
import 'package:colmeia/features/sales/presentation/pages/sales_produto_tendencia_media_movel_widgets.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_trend_comparison_bar_chart_style.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/charts/app_comparison_bar_chart.dart';
import 'package:colmeia/shared/widgets/charts/chart_export_capture.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_metadata.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_table_data.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

ChartShareMetadata buildSalesProdutoTendenciaMediaMovelCountShareMetadata({
  required AppLocalizations l10n,
  required List<SalesProdutoTendenciaMediaMovelClassBucket> buckets,
  required AppThemeTokens tokens,
}) {
  return ChartShareMetadata(
    title: l10n.salesProdutoTendenciaMediaMovelSummaryByClassificacaoTitle,
    subtitle: l10n.salesProdutoTendenciaMediaMovelSummaryByClassificacaoSubtitle,
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
    chartExportBuilder: buckets.isEmpty
        ? null
        : (exportContext) => _mediaMovelComparisonExport(
            exportContext: exportContext,
            l10n: l10n,
            tokens: tokens,
            buckets: buckets,
            useImpactValues: false,
          ),
  );
}

ChartShareMetadata buildSalesProdutoTendenciaMediaMovelImpactShareMetadata({
  required AppLocalizations l10n,
  required List<SalesProdutoTendenciaMediaMovelClassBucket> buckets,
  required AppThemeTokens tokens,
}) {
  final impactFormat = NumberFormat.decimalPattern('pt_BR');
  return ChartShareMetadata(
    title: l10n.salesProdutoTendenciaMediaMovelSummaryByImpactTitle,
    subtitle: l10n.salesProdutoTendenciaMediaMovelSummaryByImpactSubtitle,
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
    chartExportBuilder: buckets.isEmpty
        ? null
        : (exportContext) => _mediaMovelComparisonExport(
            exportContext: exportContext,
            l10n: l10n,
            tokens: tokens,
            buckets: buckets,
            useImpactValues: true,
          ),
  );
}

ChartShareMetadata buildSalesProdutoTendenciaMediaMovelDetailsShareMetadata({
  required AppLocalizations l10n,
  required List<ProdutoVendidoTendenciaDeVendaMediaMovelRow> rows,
  required String filterSummary,
}) {
  final decimalFormat = NumberFormat.decimalPattern('pt_BR');
  return ChartShareMetadata(
    title: l10n.salesProdutoTendenciaMediaMovelDetailsTitle,
    subtitle: l10n.salesProdutoTendenciaMediaMovelDetailsSubtitle,
    filterSummary: filterSummary,
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
  );
}

Widget _mediaMovelComparisonExport({
  required BuildContext exportContext,
  required AppLocalizations l10n,
  required AppThemeTokens tokens,
  required List<SalesProdutoTendenciaMediaMovelClassBucket> buckets,
  required bool useImpactValues,
}) {
  final locale = Localizations.localeOf(exportContext).toLanguageTag();
  final exportStyle = salesTrendHomeLikeComparisonBarChartStyle(
    tokens: tokens,
    l10n: l10n,
    yAxisFormat: NumberFormat.compact(locale: locale),
    minPlottedValueShareOfMax: useImpactValues ? 0 : 0.045,
  ).forPdfExport();

  return wrapCartesianChartForPdfExport(
    context: exportContext,
    itemCount: buckets.length,
    minSlotWidth: comparisonBarMinSlotWidth(
      minBarWidth: exportStyle.minBarWidth,
    ),
    height: exportStyle.height,
    chart: AppComparisonBarChart<SalesProdutoTendenciaMediaMovelClassBucket>(
      items: buckets,
      labelBuilder: (bucket) => produtoTendenciaMediaMovelClassificacaoLabel(
        l10n,
        bucket.classificacao,
      ),
      valueBuilder: (bucket) =>
          useImpactValues ? bucket.impacto : bucket.count,
      plotFloorAccessibilityNotice: l10n.chartComparisonPlotFloorNotice,
      extremeSpreadAccessibilityNotice:
          l10n.chartComparisonExtremeValueSpreadNotice,
      style: exportStyle,
      dataLabelBuilder: (bucket, value) => useImpactValues
          ? NumberFormat.decimalPattern('pt_BR').format(bucket.impacto)
          : '${bucket.count}',
      tooltipLabelBuilder: (bucket, value) =>
          '${produtoTendenciaMediaMovelClassificacaoLabel(l10n, bucket.classificacao)}: '
          '${useImpactValues ? NumberFormat.decimalPattern('pt_BR').format(bucket.impacto) : bucket.count}',
    ),
  );
}

import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_produto_rank_lucro_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_produto_rank_lucro_sort_by.dart';
import 'package:colmeia/features/sales/presentation/share/sales_produto_rank_lucro_share.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/charts/app_horizontal_progress_chart.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_pdf_limits.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_pdf_orientation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ProdutoVendidoProdutoRankLucroRow _row({
  required int codProduto,
  required String nome,
  required double lucro,
  required double qtd,
}) {
  return ProdutoVendidoProdutoRankLucroRow(
    codEmpresa: 1,
    codFilial: 1,
    codProduto: codProduto,
    nomeProduto: nome,
    qtdItensVendido: qtd,
    valorTotal: 1000,
    custoTotal: 700,
    lucroUnitario: lucro / qtd,
    totalValorLucro: lucro,
  );
}

void main() {
  late AppLocalizations l10n;

  setUp(() {
    l10n = lookupAppLocalizations(const Locale('pt', 'BR'));
  });

  test('share metadata includes product rows and dedicated chart export', () {
    final rows = <ProdutoVendidoProdutoRankLucroRow>[
      _row(codProduto: 1, nome: 'Cafe', lucro: 320, qtd: 40),
      _row(codProduto: 2, nome: 'Acucar', lucro: 180, qtd: 25),
    ];

    final metadata = buildSalesProdutoRankLucroShareMetadata(
      l10n: l10n,
      rows: rows,
      sortBy: ProdutoVendidoProdutoRankLucroSortBy.totalValorLucro,
      periodSubtitle: '01/05/2026 â€“ 31/05/2026',
      branchName: 'Lucas Centro',
      metricLabel: l10n.salesProdutoRankLucroSortProfit,
      maxValue: 320,
    );

    expect(metadata.title, l10n.salesProdutoRankLucroChartTitle);
    expect(metadata.subject, l10n.salesProdutoRankLucroChartTitle);
    expect(metadata.subtitle, '01/05/2026 â€“ 31/05/2026');
    expect(
      metadata.tableData?.headers,
      <String>[
        l10n.chartSharePdfColumnRank,
        l10n.chartSharePdfColumnName,
        l10n.chartSharePdfColumnProfit,
      ],
    );
    expect(metadata.tableData?.rows.length, 2);
    expect(metadata.tableData?.rows.first[1], 'Cafe');
    expect(metadata.chartExportBuilder, isNotNull);
    expect(metadata.filterSummary, contains('Lucas Centro'));
    expect(metadata.pdfOrientation, ChartSharePdfOrientation.portrait);
  });

  test('share metadata omits chart export when rows are empty', () {
    final metadata = buildSalesProdutoRankLucroShareMetadata(
      l10n: l10n,
      rows: const <ProdutoVendidoProdutoRankLucroRow>[],
      sortBy: ProdutoVendidoProdutoRankLucroSortBy.qtdItensVendido,
      periodSubtitle: '01/05/2026 â€“ 31/05/2026',
      branchName: 'Lucas Centro',
      metricLabel: l10n.salesProdutoRankLucroSortQuantity,
      maxValue: 0,
    );

    expect(metadata.chartExportBuilder, isNull);
  });

  test('share metadata uses quantity column when sorted by quantity', () {
    final rows = <ProdutoVendidoProdutoRankLucroRow>[
      _row(codProduto: 1, nome: 'Cafe', lucro: 320, qtd: 40),
    ];

    final metadata = buildSalesProdutoRankLucroShareMetadata(
      l10n: l10n,
      rows: rows,
      sortBy: ProdutoVendidoProdutoRankLucroSortBy.qtdItensVendido,
      periodSubtitle: '01/05/2026 â€“ 31/05/2026',
      branchName: 'Lucas Centro',
      metricLabel: l10n.salesProdutoRankLucroSortQuantity,
      maxValue: 40,
    );

    expect(
      metadata.tableData?.headers.last,
      l10n.salesProdutoRankLucroSortQuantity,
    );
    expect(metadata.tableData?.rows.single.last, '40');
  });

  test('share metadata truncates table rows over limit', () {
    final rows = List<ProdutoVendidoProdutoRankLucroRow>.generate(
      ChartSharePdfLimits.maxTableRows + 1,
      (index) => _row(
        codProduto: index,
        nome: 'Product $index',
        lucro: (100 + index).toDouble(),
        qtd: 10,
      ),
    );

    final metadata = buildSalesProdutoRankLucroShareMetadata(
      l10n: l10n,
      rows: rows,
      sortBy: ProdutoVendidoProdutoRankLucroSortBy.totalValorLucro,
      periodSubtitle: '01/05/2026 â€“ 31/05/2026',
      branchName: 'Lucas Centro',
      metricLabel: l10n.salesProdutoRankLucroSortProfit,
      maxValue: 600,
    );

    const totalRows = ChartSharePdfLimits.maxTableRows + 1;
    expect(metadata.tableData?.rows.length, ChartSharePdfLimits.maxTableRows);
    expect(
      metadata.filterSummary,
      contains('${ChartSharePdfLimits.maxTableRows}'),
    );
    expect(metadata.filterSummary, contains('$totalRows'));
  });

  test('export height grows with row count', () {
    const style = AppHorizontalProgressChartStyle(
      barHeight: 10,
      rowSpacing: 12,
      rowPadding: EdgeInsets.symmetric(vertical: 4),
    );
    final tokens = AppThemeTokens.light;

    final shortHeight = salesProdutoRankLucroExportHeight(
      rowCount: 3,
      style: style,
      tokens: tokens,
      showDividers: true,
    );
    final tallHeight = salesProdutoRankLucroExportHeight(
      rowCount: 15,
      style: style,
      tokens: tokens,
      showDividers: true,
    );

    expect(tallHeight, greaterThan(shortHeight));
  });
}

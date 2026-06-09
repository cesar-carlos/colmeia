import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_produto_rank_lucro_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_produto_rank_lucro_sort_by.dart';
import 'package:colmeia/features/sales/presentation/share/sales_produto_rank_lucro_share.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/charts/app_horizontal_progress_chart.dart';
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
      periodSubtitle: '01/05/2026 – 31/05/2026',
      branchName: 'Lucas Centro',
      metricLabel: l10n.salesProdutoRankLucroSortProfit,
      maxValue: 320,
    );

    expect(metadata.title, l10n.salesProdutoRankLucroChartTitle);
    expect(metadata.subtitle, '01/05/2026 – 31/05/2026');
    expect(metadata.tableData?.rows.length, 2);
    expect(metadata.tableData?.rows.first[1], 'Cafe');
    expect(metadata.chartExportBuilder, isNotNull);
    expect(metadata.filterSummary, contains('Lucas Centro'));
  });

  test('share metadata omits chart export when rows are empty', () {
    final metadata = buildSalesProdutoRankLucroShareMetadata(
      l10n: l10n,
      rows: const <ProdutoVendidoProdutoRankLucroRow>[],
      sortBy: ProdutoVendidoProdutoRankLucroSortBy.qtdItensVendido,
      periodSubtitle: '01/05/2026 – 31/05/2026',
      branchName: 'Lucas Centro',
      metricLabel: l10n.salesProdutoRankLucroSortQuantity,
      maxValue: 0,
    );

    expect(metadata.chartExportBuilder, isNull);
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

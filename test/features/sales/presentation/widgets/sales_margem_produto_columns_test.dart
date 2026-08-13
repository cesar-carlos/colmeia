import 'package:checks/checks.dart';
import 'package:colmeia/core/layout/app_breakpoints.dart';
import 'package:colmeia/features/agent_queries/domain/entities/margem_produto_row.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_margem_produto_columns.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_margem_produto_sort.dart';
import 'package:flutter_test/flutter_test.dart';

const _labels = SalesMargemProdutoColumnLabels(
  produto: 'Product',
  custo: 'Replacement cost',
  preco: 'Sale price',
  markup: 'Markup %',
  margem: 'Gross margin %',
  grupo: 'Group',
  marca: 'Brand',
);

void main() {
  group('buildSalesMargemProdutoColumns', () {
    final columns = buildSalesMargemProdutoColumns(labels: _labels);

    test('exposes product frozen and the three SQL-sortable metrics', () {
      check(
        columns.map((column) => column.key).toList(),
      ).deepEquals(<String>[
        SalesMargemProdutoSort.columnProduto,
        SalesMargemProdutoSort.columnCustoReposicao,
        SalesMargemProdutoSort.columnPrecoVenda,
        SalesMargemProdutoSort.columnMarkup,
        SalesMargemProdutoSort.columnMargem,
        SalesMargemProdutoSort.columnGrupo,
        SalesMargemProdutoSort.columnMarca,
      ]);

      final byKey = <String, bool>{
        for (final column in columns) column.key: column.sortable,
      };
      check(byKey[SalesMargemProdutoSort.columnProduto]).equals(false);
      check(byKey[SalesMargemProdutoSort.columnCustoReposicao]).equals(true);
      check(byKey[SalesMargemProdutoSort.columnPrecoVenda]).equals(false);
      check(byKey[SalesMargemProdutoSort.columnMarkup]).equals(true);
      check(byKey[SalesMargemProdutoSort.columnMargem]).equals(true);
      check(byKey[SalesMargemProdutoSort.columnGrupo]).equals(false);
      check(byKey[SalesMargemProdutoSort.columnMarca]).equals(false);

      final produto = columns.firstWhere(
        (column) => column.key == SalesMargemProdutoSort.columnProduto,
      );
      check(produto.pinned).equals(true);
    });

    test('hides group and brand below the narrow report breakpoint', () {
      for (final key in <String>[
        SalesMargemProdutoSort.columnGrupo,
        SalesMargemProdutoSort.columnMarca,
      ]) {
        final column = columns.firstWhere((item) => item.key == key);
        check(
          column.hideBelowBreakpoint,
        ).equals(AppBreakpoints.reportColumnHideNarrow);
      }
    });

    test('formats currency and percent values', () {
      check(formatSalesMargemProdutoCurrency(12.5)).contains('12,50');
      check(formatSalesMargemProdutoPercent(33.3)).equals('33,3%');
      check(formatSalesMargemProdutoCurrency(null)).equals('');
      check(formatSalesMargemProdutoPercent(null)).equals('');
    });

    test('reads metric fields from the row', () {
      const row = MargemProdutoRow(
        codEmpresa: 1,
        codFilial: 2,
        nomeFilial: 'Loja',
        codProduto: 10,
        nomeProduto: 'Mel',
        custoReposicao: 4.5,
        precoVendaProduto: 9,
        percentualMarkupCustoCompraProduto: 100,
        margemLucroProduto: 50,
        nomeGrupoProduto: 'Alimentos',
        nomeMarca: 'Casa',
      );

      Object? valueOf(String key) {
        return columns
            .firstWhere((column) => column.key == key)
            .valueGetter(row);
      }

      check(valueOf(SalesMargemProdutoSort.columnProduto)).equals('Mel');
      check(valueOf(SalesMargemProdutoSort.columnCustoReposicao)).equals(4.5);
      check(valueOf(SalesMargemProdutoSort.columnPrecoVenda)).equals(9);
      check(valueOf(SalesMargemProdutoSort.columnMarkup)).equals(100);
      check(valueOf(SalesMargemProdutoSort.columnMargem)).equals(50);
      check(
        valueOf(SalesMargemProdutoSort.columnGrupo),
      ).equals('Alimentos');
      check(valueOf(SalesMargemProdutoSort.columnMarca)).equals('Casa');
    });
  });
}

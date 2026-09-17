import 'package:checks/checks.dart';
import 'package:colmeia/core/layout/app_breakpoints.dart';
import 'package:colmeia/features/agent_queries/domain/entities/margem_produto_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/margem_produto_sort_by.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_margem_produto_columns.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_margem_produto_sort.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _labels = SalesMargemProdutoColumnLabels(
  codigo: 'Code',
  produto: 'Product name',
  grupo: 'Group',
  custo: 'Replacement cost',
  preco: 'Sale price',
  markup: '% Markup',
  margem: '% Margin',
);

void main() {
  group('buildSalesMargemProdutoColumns', () {
    final columns = buildSalesMargemProdutoColumns(labels: _labels);

    test('exposes pinned code and sortable catalog columns', () {
      check(
        columns.map((column) => column.key).toList(),
      ).deepEquals(<String>[
        SalesMargemProdutoSort.columnCodigo,
        SalesMargemProdutoSort.columnProduto,
        SalesMargemProdutoSort.columnCustoReposicao,
        SalesMargemProdutoSort.columnPrecoVenda,
        SalesMargemProdutoSort.columnMarkup,
        SalesMargemProdutoSort.columnMargem,
        SalesMargemProdutoSort.columnGrupo,
      ]);

      for (final column in columns) {
        check(column.sortable).equals(true);
      }

      final codigo = columns.firstWhere(
        (column) => column.key == SalesMargemProdutoSort.columnCodigo,
      );
      check(codigo.pinned).equals(true);
      check(codigo.numeric).equals(true);
      check(codigo.width).equals(104);
      check(codigo.minWidth).equals(104);

      final produto = columns.firstWhere(
        (column) => column.key == SalesMargemProdutoSort.columnProduto,
      );
      check(produto.pinned).equals(false);
      check(produto.width).isNull();
      check(produto.minWidth).equals(220);

      check(
        columns
            .firstWhere(
              (column) => column.key == SalesMargemProdutoSort.columnGrupo,
            )
            .hideBelowBreakpoint,
      ).equals(AppBreakpoints.reportColumnHideWide);
    });

    test('tints markup and margin percent columns', () {
      final byKey = <String, bool>{
        for (final column in columns) column.key: column.valueColor != null,
      };
      check(byKey[SalesMargemProdutoSort.columnCodigo]).equals(false);
      check(byKey[SalesMargemProdutoSort.columnProduto]).equals(false);
      check(byKey[SalesMargemProdutoSort.columnGrupo]).equals(false);
      check(byKey[SalesMargemProdutoSort.columnCustoReposicao]).equals(false);
      check(byKey[SalesMargemProdutoSort.columnPrecoVenda]).equals(false);
      check(byKey[SalesMargemProdutoSort.columnMarkup]).equals(true);
      check(byKey[SalesMargemProdutoSort.columnMargem]).equals(true);
    });

    test('formats currency and percent values', () {
      check(formatSalesMargemProdutoCurrency(12.5)).contains('12,50');
      check(formatSalesMargemProdutoPercent(33.3)).equals('33,3%');
      check(
        formatSalesMargemProdutoCurrency(null),
      ).equals(kSalesMargemProdutoMissingGlyph);
      check(
        formatSalesMargemProdutoPercent(null),
      ).equals(kSalesMargemProdutoMissingGlyph);
      check(
        formatSalesMargemProdutoOptionalText(null),
      ).equals(kSalesMargemProdutoMissingGlyph);
      check(
        formatSalesMargemProdutoOptionalText('  '),
      ).equals(kSalesMargemProdutoMissingGlyph);
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

      check(valueOf(SalesMargemProdutoSort.columnCodigo)).equals(10);
      check(valueOf(SalesMargemProdutoSort.columnProduto)).equals('Mel');
      check(valueOf(SalesMargemProdutoSort.columnGrupo)).equals('Alimentos');
      check(valueOf(SalesMargemProdutoSort.columnCustoReposicao)).equals(4.5);
      check(valueOf(SalesMargemProdutoSort.columnPrecoVenda)).equals(9);
      check(valueOf(SalesMargemProdutoSort.columnMarkup)).equals(100);
      check(valueOf(SalesMargemProdutoSort.columnMargem)).equals(50);
    });

    test('uses a missing glyph for empty cost, percents and group', () {
      const row = MargemProdutoRow(
        codEmpresa: 1,
        codFilial: 2,
        nomeFilial: 'Loja',
        codProduto: 10,
        nomeProduto: 'Mel',
        precoVendaProduto: 9,
      );

      Object? valueOf(String key) {
        return columns
            .firstWhere((column) => column.key == key)
            .valueGetter(row);
      }

      String displayOf(String key) {
        final column = columns.firstWhere((column) => column.key == key);
        return column.formatValue(column.valueGetter(row));
      }

      check(
        valueOf(SalesMargemProdutoSort.columnCustoReposicao),
      ).equals(kSalesMargemProdutoMissingGlyph);
      check(
        valueOf(SalesMargemProdutoSort.columnMarkup),
      ).equals(kSalesMargemProdutoMissingGlyph);
      check(
        valueOf(SalesMargemProdutoSort.columnMargem),
      ).equals(kSalesMargemProdutoMissingGlyph);
      check(
        displayOf(SalesMargemProdutoSort.columnGrupo),
      ).equals(kSalesMargemProdutoMissingGlyph);
    });
  });

  group('salesMargemProdutoSignedPercentColor', () {
    const scheme = ColorScheme.light(
      tertiary: Color(0xFF006D3B),
      error: Color(0xFFBA1A1A),
    );

    test('should use tertiary for non-negative values', () {
      check(
        salesMargemProdutoSignedPercentColor(scheme, 12.5),
      ).equals(scheme.tertiary);
      check(
        salesMargemProdutoSignedPercentColor(scheme, 0),
      ).equals(scheme.tertiary);
    });

    test('should use error for negative values', () {
      check(
        salesMargemProdutoSignedPercentColor(scheme, -3.2),
      ).equals(scheme.error);
    });

    test('should ignore non-numeric values', () {
      check(salesMargemProdutoSignedPercentColor(scheme, null)).isNull();
      check(salesMargemProdutoSignedPercentColor(scheme, '12')).isNull();
    });
  });

  group('SalesMargemProdutoSort mapping', () {
    test('should map column keys to domain sort whitelist', () {
      check(
        SalesMargemProdutoSort.sortByFromColumnKey(
          SalesMargemProdutoSort.columnMarkup,
        ),
      ).equals(MargemProdutoSortBy.percentualMarkup);
      check(
        SalesMargemProdutoSort.columnKeyFor(MargemProdutoSortBy.margemLucro),
      ).equals(SalesMargemProdutoSort.columnMargem);
    });

    test('should default unknown column keys to product name', () {
      check(
        SalesMargemProdutoSort.sortByFromColumnKey('unknown'),
      ).equals(MargemProdutoSortBy.nomeProduto);
    });

    test('should sanitize empty sorts to the name default', () {
      check(SalesMargemProdutoSort.sanitizeSorts(const [])).deepEquals(
        SalesMargemProdutoSort.defaultSorts,
      );
    });
  });
}

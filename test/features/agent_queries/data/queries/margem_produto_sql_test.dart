import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/data/queries/margem_produto_sql.dart';
import 'package:colmeia/features/agent_queries/domain/entities/margem_produto_sort_by.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_sort_direction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('nomeProduto sort places NomeProduto then CodProduto ASC', () {
    final sql = MargemProdutoSql.pagedQuery(
      sortBy: MargemProdutoSortBy.nomeProduto,
      sortDirection: ResumoProdutoVendaSortDirection.ascending,
    );
    final numbered = sql.split('Numbered AS (').last;
    final nome = numbered.indexOf('m.NomeProduto ASC');
    final produto = numbered.indexOf('m.CodProduto ASC');
    check(nome).isGreaterOrEqual(0);
    check(produto).isGreaterOrEqual(0);
    check(nome).isLessThan(produto);
  });

  test('margemLucroProduto sort places MargemLucroProduto then CodProduto', () {
    final sql = MargemProdutoSql.pagedQuery(
      sortBy: MargemProdutoSortBy.margemLucroProduto,
      sortDirection: ResumoProdutoVendaSortDirection.descending,
    );
    final numbered = sql.split('Numbered AS (').last;
    final margem = numbered.indexOf('m.MargemLucroProduto DESC');
    final produto = numbered.indexOf('m.CodProduto ASC');
    check(margem).isGreaterOrEqual(0);
    check(produto).isGreaterOrEqual(0);
    check(margem).isLessThan(produto);
  });

  test('custoReposicao sortBy places CustoReposicao in ROW_NUMBER', () {
    final sql = MargemProdutoSql.pagedQuery(
      sortBy: MargemProdutoSortBy.custoReposicao,
      sortDirection: ResumoProdutoVendaSortDirection.descending,
    );
    final numbered = sql.split('Numbered AS (').last;
    check(numbered).contains('m.CustoReposicao DESC');
    check(numbered).contains('m.CodProduto ASC');
  });

  test(
    'percentualMarkup sortBy places PercentualMarkupCustoCompraProduto',
    () {
      final sql = MargemProdutoSql.pagedQuery(
        sortBy: MargemProdutoSortBy.percentualMarkup,
        sortDirection: ResumoProdutoVendaSortDirection.descending,
      );
      final numbered = sql.split('Numbered AS (').last;
      check(numbered).contains('m.PercentualMarkupCustoCompraProduto DESC');
    },
  );

  test('sortDirection ASC applies to chosen sort column', () {
    final sql = MargemProdutoSql.pagedQuery(
      sortBy: MargemProdutoSortBy.custoReposicao,
      sortDirection: ResumoProdutoVendaSortDirection.ascending,
    );
    check(sql).contains('m.CustoReposicao ASC');
  });

  test('CodProduto ASC tie-breaker is always present', () {
    for (final sortBy in MargemProdutoSortBy.values) {
      final sql = MargemProdutoSql.pagedQuery(
        sortBy: sortBy,
        sortDirection: ResumoProdutoVendaSortDirection.descending,
      );
      check(sql).contains('m.CodProduto ASC');
    }
  });

  test('binds empresa, filial, and page window once each', () {
    final sql = MargemProdutoSql.pagedQuery(
      sortBy: MargemProdutoSortBy.margemLucroProduto,
      sortDirection: ResumoProdutoVendaSortDirection.descending,
    );
    check(_count(sql, ':codEmpresa')).equals(1);
    check(_count(sql, ':codFilial')).equals(1);
    check(_count(sql, ':startRow')).equals(1);
    check(_count(sql, ':endRow')).equals(1);
  });

  test('does not send DECLARE or block comments', () {
    final sql = MargemProdutoSql.pagedQuery(
      sortBy: MargemProdutoSortBy.margemLucroProduto,
      sortDirection: ResumoProdutoVendaSortDirection.descending,
    );
    check(sql.contains('DECLARE')).isFalse();
    check(sql.contains('/*')).isFalse();
  });

  test('uses Tot LEFT JOIN Numbered page window', () {
    final sql = MargemProdutoSql.pagedQuery(
      sortBy: MargemProdutoSortBy.margemLucroProduto,
      sortDirection: ResumoProdutoVendaSortDirection.descending,
    );
    check(sql).contains('SELECT COUNT(*) AS TotalCount FROM MargemProduto');
    check(sql).contains(
      'LEFT JOIN Numbered N ON N.Rn BETWEEN :startRow AND :endRow',
    );
    check(sql).contains('ORDER BY COALESCE(N.Rn, 2147483647)');
  });
}

int _count(String source, String needle) {
  var count = 0;
  var from = 0;
  while (true) {
    final index = source.indexOf(needle, from);
    if (index < 0) {
      return count;
    }
    count += 1;
    from = index + needle.length;
  }
}

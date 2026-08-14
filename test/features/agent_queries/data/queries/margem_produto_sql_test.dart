import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/data/queries/margem_produto_sql.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ROW_NUMBER orders by NomeProduto then CodProduto ASC', () {
    final sql = MargemProdutoSql.pagedQuery();
    final numbered = sql.split('Numbered AS (').last;
    final nome = numbered.indexOf('m.NomeProduto ASC');
    final produto = numbered.indexOf('m.CodProduto ASC');
    check(nome).isGreaterOrEqual(0);
    check(produto).isGreaterOrEqual(0);
    check(nome).isLessThan(produto);
  });

  test('does not expose other sort columns in ROW_NUMBER', () {
    final numbered = MargemProdutoSql.pagedQuery().split('Numbered AS (').last;
    check(numbered.contains('m.CustoReposicao')).isFalse();
    check(numbered.contains('m.PrecoVendaProduto')).isFalse();
    check(numbered.contains('m.PercentualMarkupCustoCompraProduto')).isFalse();
    check(numbered.contains('m.MargemLucroProduto DESC')).isFalse();
  });

  test('binds empresa, filial, name pattern, and page window once each', () {
    final sql = MargemProdutoSql.pagedQuery();
    check(_count(sql, ':codEmpresa')).equals(1);
    check(_count(sql, ':codFilial')).equals(1);
    check(_count(sql, ':nomeProdutoPattern')).equals(1);
    check(_count(sql, ':startRow')).equals(1);
    check(_count(sql, ':endRow')).equals(1);
  });

  test('filters NomeProduto with optional LIKE before counting', () {
    final sql = MargemProdutoSql.pagedQuery();
    check(sql).contains('prm.NomeProdutoPattern IS NULL');
    check(sql).contains(
      'UPPER(TRIM(p.Nome)) LIKE UPPER(prm.NomeProdutoPattern)',
    );
    check(sql).contains('SELECT COUNT(*) AS TotalCount FROM MargemProduto');
  });

  test('does not send DECLARE or block comments', () {
    final sql = MargemProdutoSql.pagedQuery();
    check(sql.contains('DECLARE')).isFalse();
    check(sql.contains('/*')).isFalse();
  });

  test('uses Tot LEFT JOIN Numbered page window', () {
    final sql = MargemProdutoSql.pagedQuery();
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

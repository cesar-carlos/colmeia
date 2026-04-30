import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/data/queries/grupo_produto_options_sql.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const sql = GrupoProdutoOptionsSql.pagedQuery;

  test('query selects group code and name alias', () {
    check(sql).contains('CodGrupoProduto');
    check(sql).contains('Nome AS NomeGrupoProduto');
    check(sql).contains('FROM GrupoProduto');
  });

  test('query paginates with row number bounds', () {
    check(sql).contains('ROW_NUMBER() OVER');
    check(sql).contains('WHERE Rn BETWEEN :startRow AND :endRow');
    check(sql).contains('ORDER BY\n      Rn ASC');
  });

  test('query supports optional NomeGrupoProduto filter', () {
    check(sql).contains('CAST(:nomeGrupoProduto AS VARCHAR(255))');
    check(sql).contains('p.NomeGrupoProduto IS NULL');
    check(sql).contains('UPPER(gp.Nome) LIKE UPPER(p.NomeGrupoProduto)');
  });
}

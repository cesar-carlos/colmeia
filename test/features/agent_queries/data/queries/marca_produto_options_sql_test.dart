import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/data/queries/marca_produto_options_sql.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const sql = MarcaProdutoOptionsSql.pagedQuery;

  test('query selects brand code and name alias', () {
    check(sql).contains('CodMarca');
    check(sql).contains('Nome AS NomeMarca');
    check(sql).contains('FROM Marca');
  });

  test('query paginates with row number bounds', () {
    check(sql).contains('ROW_NUMBER() OVER');
    check(sql).contains('WHERE Rn BETWEEN :startRow AND :endRow');
    check(sql).contains('ORDER BY\n      Rn ASC');
  });

  test('query supports optional NomeMarca filter', () {
    check(sql).contains('CAST(:nomeMarca AS VARCHAR(255))');
    check(sql).contains('p.NomeMarca IS NULL');
    check(sql).contains('UPPER(m.Nome) LIKE UPPER(p.NomeMarca)');
  });
}

import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/data/queries/marca_produto_options_sql.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const sql = MarcaProdutoOptionsSql.query;

  test('query selects brand code and name alias', () {
    check(sql).contains('CodMarca');
    check(sql).contains('Nome AS NomeMarca');
    check(sql).contains('FROM Marca');
  });

  test('query orders by Nome', () {
    final orderBlock = sql.split('ORDER BY').last;
    check(orderBlock).contains('Nome');
  });
}

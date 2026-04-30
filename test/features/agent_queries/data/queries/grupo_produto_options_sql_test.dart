import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/data/queries/grupo_produto_options_sql.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const sql = GrupoProdutoOptionsSql.query;

  test('query selects group code and name alias', () {
    check(sql).contains('CodGrupoProduto');
    check(sql).contains('Nome AS NomeGrupoProduto');
    check(sql).contains('FROM GrupoProduto');
  });

  test('query orders by Nome', () {
    final orderBlock = sql.split('ORDER BY').last;
    check(orderBlock).contains('Nome');
  });
}

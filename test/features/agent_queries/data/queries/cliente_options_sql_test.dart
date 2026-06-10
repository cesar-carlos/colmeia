import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/data/queries/cliente_options_sql.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const sql = ClienteOptionsSql.pagedQuery;

  test('query selects cliente columns joined with municipio', () {
    check(sql).contains('FROM Cliente c');
    check(sql).contains('INNER JOIN Municipio m');
    check(sql).contains('CodCliente');
    check(sql).contains('NomeCliente');
    check(sql).contains('NomeMunicipio');
    check(sql).contains('UFMunicipio');
    check(sql).contains('m.CodigoIBGE');
    check(sql).contains('N.CodigoIBGE');
  });

  test('query paginates with row number bounds and stable order', () {
    check(sql).contains('ROW_NUMBER() OVER');
    check(sql).contains('NomeCliente ASC');
    check(sql).contains('CodCliente ASC');
    check(sql).contains('N.Rn BETWEEN :startRow AND :endRow');
    check(sql).contains('ORDER BY COALESCE(N.Rn, 2147483647)');
  });

  test('query includes total count subquery', () {
    check(sql).contains('COUNT(*) AS TotalCount');
    check(sql).contains('FROM Tot');
    check(sql).contains('LEFT JOIN Numbered N');
  });

  test('query supports optional searchPattern across cliente fields', () {
    check(sql).contains('CAST(:searchPattern AS VARCHAR(255))');
    check(sql).contains('p.SearchPattern IS NULL');
    check(sql).contains('UPPER(c.Nome) LIKE UPPER(p.SearchPattern)');
    check(sql).contains('UPPER(c.NomeFantasia) LIKE UPPER(p.SearchPattern)');
    check(sql).contains('UPPER(c.CNPJ_CPF) LIKE UPPER(p.SearchPattern)');
    check(sql).contains('UPPER(c.EMail) LIKE UPPER(p.SearchPattern)');
    check(sql).contains('UPPER(m.Nome) LIKE UPPER(p.SearchPattern)');
    check(sql).contains('CAST(:searchDigitsPattern AS VARCHAR(255))');
    check(
      sql,
    ).contains('CAST(m.CodigoIBGE AS VARCHAR(20)) LIKE p.SearchDigitsPattern');
  });
}

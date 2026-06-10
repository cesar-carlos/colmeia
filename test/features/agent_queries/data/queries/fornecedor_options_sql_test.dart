import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/data/queries/fornecedor_options_sql.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const sql = FornecedorOptionsSql.pagedQuery;

  test('query selects fornecedor columns joined with municipio', () {
    check(sql).contains('FROM Fornecedor f');
    check(sql).contains('INNER JOIN Municipio m');
    check(sql).contains('CodFornecedor');
    check(sql).contains('RazaoSocial AS NomeFornecedor');
    check(sql).contains('NomeMunicipio');
    check(sql).contains('UFMunicipio');
    check(sql).contains('m.CodigoIBGE');
    check(sql).contains('N.CodigoIBGE');
  });

  test('query paginates with row number bounds and stable order', () {
    check(sql).contains('ROW_NUMBER() OVER');
    check(sql).contains('NomeFornecedor ASC');
    check(sql).contains('CodFornecedor ASC');
    check(sql).contains('N.Rn BETWEEN :startRow AND :endRow');
    check(sql).contains('ORDER BY COALESCE(N.Rn, 2147483647)');
  });

  test('query includes total count subquery', () {
    check(sql).contains('COUNT(*) AS TotalCount');
    check(sql).contains('FROM Tot');
    check(sql).contains('LEFT JOIN Numbered N');
  });

  test('query supports optional searchPattern across fornecedor fields', () {
    check(sql).contains('CAST(:searchPattern AS VARCHAR(255))');
    check(sql).contains('p.SearchPattern IS NULL');
    check(sql).contains('UPPER(f.RazaoSocial) LIKE UPPER(p.SearchPattern)');
    check(sql).contains('UPPER(f.NomeFantasia) LIKE UPPER(p.SearchPattern)');
    check(sql).contains('UPPER(f.CNPJ_CPF) LIKE UPPER(p.SearchPattern)');
    check(sql).contains('UPPER(f.EMail) LIKE UPPER(p.SearchPattern)');
    check(sql).contains('UPPER(m.Nome) LIKE UPPER(p.SearchPattern)');
    check(sql).contains('CAST(:searchDigitsPattern AS VARCHAR(255))');
    check(
      sql,
    ).contains('CAST(m.CodigoIBGE AS VARCHAR(20)) LIKE p.SearchDigitsPattern');
  });
}

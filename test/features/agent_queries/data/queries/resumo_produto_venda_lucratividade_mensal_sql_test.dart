import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/data/queries/resumo_produto_venda_lucratividade_mensal_sql.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const sql = ResumoProdutoVendaLucratividadeMensalSql.query;

  test('query contains DetalheProdutoVenda CTE', () {
    check(sql).contains('DetalheProdutoVenda AS');
    check(sql).contains('Agregada AS');
  });

  test('query groups by CodEmpresa, CodFilial, Ano, Mes', () {
    check(sql).contains('GROUP BY');
    check(sql).contains('CodEmpresa,');
    check(sql).contains('CodFilial,');
    check(sql).contains('Ano,');
    check(sql).contains('Mes');
  });

  test('query uses named params dataVendaInicio, dataVendaFim, origem', () {
    check(sql).contains(':dataVendaInicio');
    check(sql).contains(':dataVendaFim');
    check(sql).contains(':origem');
  });

  test('query selects AnoMes as formatted YYYY/MM', () {
    check(sql).contains('AnoMes');
    check(sql).contains("CAST(Ano AS VARCHAR(4)) + '/'");
    check(sql).contains('CASE WHEN Mes < 10');
  });

  test('query orders by CodEmpresa, CodFilial, Ano, Mes ascending', () {
    final orderBlock = sql.split('ORDER BY').last;
    final empresa = orderBlock.indexOf('CodEmpresa ASC');
    final filial = orderBlock.indexOf('CodFilial ASC');
    final ano = orderBlock.indexOf('Ano ASC');
    final mes = orderBlock.indexOf('Mes ASC');
    check(empresa).isGreaterThan(-1);
    check(empresa).isLessThan(filial);
    check(filial).isLessThan(ano);
    check(ano).isLessThan(mes);
  });

  test('query applies GeraFinanceiro and PreVenda filters', () {
    check(sql).contains("tos.GeraFinanceiro = 'S'");
    check(sql).contains("pv.PreVenda = 'N'");
  });

  test('query does not contain pagination ROW_NUMBER', () {
    check(sql.contains('ROW_NUMBER')).isFalse();
    check(sql.contains(':startRow')).isFalse();
    check(sql.contains(':endRow')).isFalse();
  });
}

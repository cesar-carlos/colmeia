import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/data/queries/resumo_produto_venda_lucratividade_mensal_sql.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const sql = ResumoProdutoVendaLucratividadeMensalSql.query;

  test('query uses nested DetalheProdutoVenda then month bucket layer', () {
    check(sql.contains('WITH DetalheProdutoVenda AS')).isFalse();
    check(sql).contains(') DetalheProdutoVenda');
    check(sql).contains(') ResumoProdutoVendaLucratividadeMensal');
    check(sql).contains('FROM (');
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

  test('query uses half-open sargable DataVenda predicates', () {
    check(sql).contains('pv.DataVenda >= CAST(:dataVendaInicio AS DATE)');
    check(sql).contains(
      'pv.DataVenda < DATEADD(day, 1, CAST(:dataVendaFim AS DATE))',
    );
    check(sql.contains('CAST(pv.DataVenda AS DATE) BETWEEN')).isFalse();
  });

  test('query selects AnoMes via MAX like parcelas mensal', () {
    check(sql).contains('AnoMes');
    check(sql).contains('MAX(');
    check(sql).contains("CAST(Ano AS VARCHAR(4)) + '/'");
    check(sql).contains('CASE WHEN Mes < 10');
  });

  test('query derives Ano/Mes from DataVenda in middle layer', () {
    check(sql).contains('YEAR(DataVenda) AS Ano');
    check(sql).contains('MONTH(DataVenda) AS Mes');
    check(sql.contains('YEAR(pv.DataVenda)')).isFalse();
  });

  test('query counts distinct sale Id like period lucratividade', () {
    check(sql).contains('COUNT(DISTINCT Id)');
    check(sql).contains("CAST(pv.CodEmpresa AS VARCHAR) + '-'");
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

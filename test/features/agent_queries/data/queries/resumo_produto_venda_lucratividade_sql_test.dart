import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/data/queries/resumo_produto_venda_lucratividade_sql.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const sql = ResumoProdutoVendaLucratividadeSql.query;

  test('query uses DetalheProdutoVenda subquery (no CTEs)', () {
    check(sql).contains('DetalheProdutoVenda');
    check(sql.contains('WITH ')).isFalse();
  });

  test('query groups by CodEmpresa, CodFilial only', () {
    check(sql).contains('GROUP BY');
    check(sql).contains('CodEmpresa,');
    check(sql).contains('CodFilial');
    check(sql.contains('Ano,')).isFalse();
    check(sql.contains('Mes')).isFalse();
  });

  test('query uses named params dataVendaInicio, dataVendaFim, origem', () {
    check(sql).contains(':dataVendaInicio');
    check(sql).contains(':dataVendaFim');
    check(sql).contains(':origem');
  });

  test('query orders by CodEmpresa, CodFilial ascending', () {
    final orderBlock = sql.split('ORDER BY').last;
    final empresa = orderBlock.indexOf('CodEmpresa ASC');
    final filial = orderBlock.indexOf('CodFilial ASC');
    check(empresa).isGreaterThan(-1);
    check(empresa).isLessThan(filial);
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

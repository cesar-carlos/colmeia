import 'package:colmeia/features/agent_queries/data/queries/ranking_produtos_faturamento_sql.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('default query ranks per branch with five named params', () {
    final sql = RankingProdutosFaturamentoSql.buildQuery(
      restrictToSingleBranch: false,
      origem: 'FrenteLoja',
      preVenda: 'N',
    );

    expect(sql, contains(':dataVendaInicio'));
    expect(sql, contains(':dataVendaFim'));
    expect(sql, contains(':quantidadeProdutos'));
    expect(sql, contains(':origem'));
    expect(sql, contains(':preVenda'));
    expect(sql, isNot(contains(':codEmpresa')));
    expect(sql, contains('PARTITION BY CodEmpresa, CodFilial'));
    expect(sql, contains('WHERE Posicao <= :quantidadeProdutos'));
    expect(sql, contains('r.Posicao > :quantidadeProdutos'));
    expect(sql, contains('DiversosBase'));
    expect(sql, contains('WHERE d.ValorVenda > 0'));
    expect(sql, contains('TotaisPorFilial'));
    expect(sql, contains('NULLIF(t.TotalVenda, 0)'));
    expect(sql, contains('Posicao'));
    expect(sql, isNot(contains('9999')));
    expect(sql, contains('CAST(pv.DataVenda AS DATE) BETWEEN'));
    expect(sql, contains("CAST('DIVERSOS' AS VARCHAR(50))"));
  });

  test('avoids constructs that break SQL Server and SQL Anywhere', () {
    final sql = RankingProdutosFaturamentoSql.buildQuery(
      restrictToSingleBranch: false,
      origem: 'FrenteLoja',
      preVenda: 'N',
    );

    expect(sql, isNot(contains('SELECT *')));
    expect(sql, isNot(contains('SELECT *,')));
    expect(sql, isNot(contains('SUM(CASE')));
    expect(sql, isNot(contains('SUM(r.ValorVenda) OVER')));
    expect(sql, contains('INNER JOIN TotaisPorFilial t'));
  });

  test('single-branch query inlines origem and preVenda for param limit', () {
    final sql = RankingProdutosFaturamentoSql.buildQuery(
      restrictToSingleBranch: true,
      origem: 'FrenteLoja',
      preVenda: 'N',
    );

    expect(sql, contains(':codEmpresa'));
    expect(sql, contains(':codFilial'));
    expect(sql, contains("pv.Origem = 'FrenteLoja'"));
    expect(sql, contains("pv.PreVenda = 'N'"));
    expect(sql, isNot(contains(':origem')));
    expect(sql, isNot(contains(':preVenda')));
  });
}

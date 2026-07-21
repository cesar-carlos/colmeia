import 'package:colmeia/features/agent_queries/data/queries/ranking_produtos_faturamento_sql.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('default query ranks per branch with four named params', () {
    final sql = RankingProdutosFaturamentoSql.buildQuery(
      restrictToSingleBranch: false,
      origem: 'FrenteLoja',
      preVenda: 'N',
      quantidadeProdutos: 15,
    );

    expect(sql, contains(':dataVendaInicio'));
    expect(sql, contains(':dataVendaFim'));
    expect(sql, contains(':origem'));
    expect(sql, contains(':preVenda'));
    expect(sql, isNot(contains(':quantidadeProdutos')));
    expect(sql, isNot(contains(':codEmpresa')));
    expect(sql, contains('PARTITION BY CodEmpresa, CodFilial'));
    expect(sql, contains('WHERE Posicao <= 15'));
    expect(sql, contains('r.Posicao > 15'));
    expect(sql, contains('DiversosBase'));
    expect(sql, contains('WHERE d.ValorVenda > 0'));
    expect(sql, contains('TotaisPorFilial'));
    expect(sql, contains('NULLIF(t.TotalVenda, 0)'));
    expect(sql, contains('Posicao'));
    expect(sql, isNot(contains('9999')));
    expect(sql, contains('pv.DataVenda >= CAST(:dataVendaInicio AS DATE)'));
    expect(
      sql,
      contains(
        'pv.DataVenda < DATEADD(day, 1, CAST(:dataVendaFim AS DATE))',
      ),
    );
    expect(sql, isNot(contains('CAST(pv.DataVenda AS DATE) BETWEEN')));
    expect(sql, contains("CAST('DIVERSOS' AS VARCHAR(50))"));
    expect(sql, contains('LEFT JOIN GrupoProduto gp'));
    expect(sql, isNot(contains('INNER JOIN GrupoProduto')));
  });

  test('avoids constructs that break SQL Server and SQL Anywhere', () {
    final sql = RankingProdutosFaturamentoSql.buildQuery(
      restrictToSingleBranch: false,
      origem: 'FrenteLoja',
      preVenda: 'N',
      quantidadeProdutos: 15,
    );

    expect(sql, isNot(contains('SELECT *')));
    expect(sql, isNot(contains('SELECT *,')));
    expect(sql, isNot(contains('SUM(CASE')));
    expect(sql, isNot(contains('SUM(r.ValorVenda) OVER')));
    expect(sql, contains('INNER JOIN TotaisPorFilial t'));
    expect(sql, isNot(contains(':quantidadeProdutos')));
  });

  test('single-branch query inlines origem, preVenda, and top-N', () {
    final sql = RankingProdutosFaturamentoSql.buildQuery(
      restrictToSingleBranch: true,
      origem: 'FrenteLoja',
      preVenda: 'N',
      quantidadeProdutos: 5,
    );

    expect(sql, contains(':codEmpresa'));
    expect(sql, contains(':codFilial'));
    expect(sql, contains("pv.Origem = 'FrenteLoja'"));
    expect(sql, contains("pv.PreVenda = 'N'"));
    expect(sql, contains('WHERE Posicao <= 5'));
    expect(sql, contains('r.Posicao > 5'));
    expect(sql, isNot(contains(':origem')));
    expect(sql, isNot(contains(':preVenda')));
    expect(sql, isNot(contains(':quantidadeProdutos')));
  });

  test('rejects out-of-range quantidadeProdutos', () {
    expect(
      () => RankingProdutosFaturamentoSql.buildQuery(
        restrictToSingleBranch: false,
        origem: 'FrenteLoja',
        preVenda: 'N',
        quantidadeProdutos: 0,
      ),
      throwsArgumentError,
    );
  });

  test('rejects single quote in inlined origem for single-branch', () {
    expect(
      () => RankingProdutosFaturamentoSql.buildQuery(
        restrictToSingleBranch: true,
        origem: "O'Reilly",
        preVenda: 'N',
        quantidadeProdutos: 5,
      ),
      throwsArgumentError,
    );
  });
}

import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/data/queries/produto_vendido_tendencia_de_venda_sql.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final sql = ProdutoVendidoTendenciaDeVendaSql.pagedQuery(
    startRow: 1,
    endRow: 20,
  );

  test(
    'query keeps CTE structure with Parametros, BaseVendas, Vendas, and Pivotado',
    () {
      check(sql).contains('WITH Parametros AS (');
      check(sql).contains('BaseVendas AS (');
      check(sql).contains('Vendas AS (');
      check(sql).contains('Pivotado AS (');
    },
  );

  test('query uses named params for both periods and origem', () {
    check(sql).contains(':periodoAtualInicio');
    check(sql).contains(':periodoAtualFim');
    check(sql).contains(':periodoAnteriorInicio');
    check(sql).contains(':periodoAnteriorFim');
    check(sql).contains(':origem');
  });

  test(
    'query keeps separate BETWEEN clauses for current and previous periods',
    () {
      check(
        sql,
      ).contains('BETWEEN prm.PeriodoAtualInicio AND prm.PeriodoAtualFim');
      check(sql).contains(
        'BETWEEN prm.PeriodoAnteriorInicio AND prm.PeriodoAnteriorFim',
      );
    },
  );

  test('query applies business filters and minimum movement threshold', () {
    check(sql).contains('tos.CodEmpresa = pv.CodEmpresa');
    check(sql).contains(
      'tos.CodTipoOperacaoSaida = pv.CodTipoOperacaoSaida',
    );
    check(sql.contains('tos.CodFilial = pv.CodFilial')).isFalse();
    check(sql).contains("COALESCE(tos.GeraFinanceiro, 'N') = 'S'");
    check(sql).contains("pv.PreVenda = 'N'");
    check(sql).contains('WHERE (QtdAtual + QtdAnterior) >= 10');
  });

  test('query computes trend metrics and classification', () {
    check(sql).contains('AS Diferenca');
    check(sql).contains('AS PercentualTendencia');
    check(sql).contains("THEN 'PAROU DE VENDER'");
    check(sql).contains("THEN 'NOVO PRODUTO'");
    check(sql).contains("THEN 'CRESCENDO'");
    check(sql).contains("THEN 'CAINDO'");
    check(sql).contains("ELSE 'ESTAVEL'");
  });

  test(
    'row_number ordering uses empresa, filial, percentual tendencia DESC',
    () {
      final rowNumberBlock = sql.split('ROW_NUMBER() OVER').last;
      final empresa = rowNumberBlock.indexOf('CodEmpresa ASC');
      final filial = rowNumberBlock.indexOf('CodFilial ASC');
      final tendencia = rowNumberBlock.indexOf('PercentualTendencia DESC');
      check(empresa).isGreaterThan(-1);
      check(empresa).isLessThan(filial);
      check(filial).isLessThan(tendencia);
    },
  );

  test('query applies pagination with row number bounds', () {
    check(sql).contains('ROW_NUMBER() OVER');
    check(sql).contains('WHERE RowNum BETWEEN 1 AND 20');
    check(sql).contains('ORDER BY\n      RowNum ASC');
  });

  test('query keeps default optional filter predicates as tautologies', () {
    check(sql).contains('AND (1 = 1)');
    check(sql).contains('WHERE (1 = 1)');
  });

  test('query inlines custom pagination bounds', () {
    final custom = ProdutoVendidoTendenciaDeVendaSql.pagedQuery(
      startRow: 41,
      endRow: 60,
    );
    check(custom).contains('WHERE RowNum BETWEEN 41 AND 60');
    check(custom.contains(':startRow')).isFalse();
    check(custom.contains(':endRow')).isFalse();
  });

  test('query does not include CustoProduto join', () {
    check(sql.contains('CustoProduto')).isFalse();
  });

  test('query inlines optional detail filters as SQL literals', () {
    final filtered = ProdutoVendidoTendenciaDeVendaSql.pagedQuery(
      startRow: 1,
      endRow: 20,
      searchTerm: "fox' prime",
      classificacao: 'CRESCENDO',
      codGrupoProduto: 14,
      codMarca: 490,
    );

    check(filtered).contains('AND p.CodGrupoProduto = 14');
    check(filtered).contains('AND p.CodMarca = 490');
    check(filtered).contains("N'%fox'' prime%'");
    check(filtered).contains("WHERE Classificacao = N'CRESCENDO'");
  });

  test('pagedQuery validates bounds', () {
    expect(
      () => ProdutoVendidoTendenciaDeVendaSql.pagedQuery(
        startRow: 0,
        endRow: 20,
      ),
      throwsArgumentError,
    );
    expect(
      () => ProdutoVendidoTendenciaDeVendaSql.pagedQuery(
        startRow: 20,
        endRow: 19,
      ),
      throwsArgumentError,
    );
  });
}

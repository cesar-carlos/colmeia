import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/data/queries/produto_vendido_tendencia_de_venda_summary_sql.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final sql = ProdutoVendidoTendenciaDeVendaSummarySql.query();

  test('summary query keeps core CTE pipeline', () {
    check(sql).contains('WITH Parametros AS (');
    check(sql).contains('BaseVendas AS (');
    check(sql).contains('Vendas AS (');
    check(sql).contains('Pivotado AS (');
    check(sql).contains('Resultado AS (');
    check(sql).contains('Filtrado AS (');
  });

  test('summary query uses period and origem named params', () {
    check(sql).contains(':periodoAtualInicio');
    check(sql).contains(':periodoAtualFim');
    check(sql).contains(':periodoAnteriorInicio');
    check(sql).contains(':periodoAnteriorFim');
    check(sql).contains(':origem');
  });

  test('summary query joins product dimensions for detail filters', () {
    check(sql).contains('INNER JOIN Produto p ON');
    check(sql).contains('LEFT JOIN GrupoProduto gp ON');
    check(sql).contains('LEFT JOIN Marca m ON');
    check(sql).contains('tos.CodEmpresa = pv.CodEmpresa');
    check(sql).contains(
      'tos.CodTipoOperacaoSaida = pv.CodTipoOperacaoSaida',
    );
    check(sql.contains('tos.CodFilial = pv.CodFilial')).isFalse();
  });

  test('summary query groups and aggregates by classificacao', () {
    check(sql).contains('COUNT(*) AS QuantidadeProdutos');
    check(sql).contains('SUM(Diferenca) AS ImpactoLiquido');
    check(sql).contains('GROUP BY\n      Classificacao');
  });

  test('summary query inlines optional detail filters', () {
    final filtered = ProdutoVendidoTendenciaDeVendaSummarySql.query(
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
}

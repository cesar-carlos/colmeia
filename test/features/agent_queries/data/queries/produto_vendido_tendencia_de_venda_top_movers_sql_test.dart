import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/data/queries/produto_vendido_tendencia_de_venda_sql.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('top gainers query limits to fifteen positive movers', () {
    final sql = ProdutoVendidoTendenciaDeVendaSql.topGainersQuery();

    check(sql).contains(
      'SELECT TOP ${ProdutoVendidoTendenciaDeVendaSql.topMoversLimit}',
    );
    check(sql).contains('WHERE Diferenca > 0');
    check(sql).contains('PercentualTendencia DESC');
    check(sql).contains('Diferenca DESC');
    check(sql).contains(':periodoAtualInicio');
    check(sql).contains(':origem');
  });

  test('top losers query limits to fifteen negative movers', () {
    final sql = ProdutoVendidoTendenciaDeVendaSql.topLosersQuery();

    check(sql).contains(
      'SELECT TOP ${ProdutoVendidoTendenciaDeVendaSql.topMoversLimit}',
    );
    check(sql).contains('WHERE Diferenca < 0');
    check(sql).contains('PercentualTendencia ASC');
    check(sql).contains('Diferenca ASC');
  });

  test('top movers queries inline optional detail filters', () {
    final sql = ProdutoVendidoTendenciaDeVendaSql.topGainersQuery(
      searchTerm: "fox' prime",
      classificacao: 'CRESCENDO',
      codGrupoProduto: 14,
      codMarca: 490,
    );

    check(sql).contains('AND p.CodGrupoProduto = 14');
    check(sql).contains('AND p.CodMarca = 490');
    check(sql).contains("N'%fox'' prime%'");
    check(sql).contains("WHERE Classificacao = N'CRESCENDO'");
  });
}

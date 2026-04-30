import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/data/queries/produto_vendido_tendencia_de_venda_summary_sql.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const sql = ProdutoVendidoTendenciaDeVendaSummarySql.query;

  test('summary query keeps core CTE pipeline', () {
    check(sql).contains('WITH Parametros AS (');
    check(sql).contains('BaseVendas AS (');
    check(sql).contains('Vendas AS (');
    check(sql).contains('Pivotado AS (');
    check(sql).contains('Resultado AS (');
  });

  test('summary query uses period and origem named params', () {
    check(sql).contains(':periodoAtualInicio');
    check(sql).contains(':periodoAtualFim');
    check(sql).contains(':periodoAnteriorInicio');
    check(sql).contains(':periodoAnteriorFim');
    check(sql).contains(':origem');
  });

  test('summary query groups and aggregates by classificacao', () {
    check(sql).contains('COUNT(*) AS QuantidadeProdutos');
    check(sql).contains('SUM(Diferenca) AS ImpactoLiquido');
    check(sql).contains('GROUP BY\n      Classificacao');
  });
}

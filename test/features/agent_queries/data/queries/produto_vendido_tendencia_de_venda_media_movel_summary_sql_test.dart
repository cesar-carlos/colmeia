import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/data/queries/produto_vendido_tendencia_de_venda_media_movel_summary_sql.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final sql = ProdutoVendidoTendenciaDeVendaMediaMovelSummarySql.query(
    quantidadeDias: 7,
  );

  test(
    'summary query reuses filtered calendar moving-average CTE pipeline',
    () {
      check(sql).contains('WITH BaseVendas AS (');
      check(sql).contains('Pivotado AS (');
      check(sql).contains('Resultado AS (');
      check(sql).contains('Filtrado AS (');
      check(sql).contains("AND pv.Origem = 'FrenteLoja'");
      check(sql.contains('Tot AS (')).isFalse();
      check(sql.contains('Numbered AS (')).isFalse();
      check(sql.contains('Diario AS (')).isFalse();
    },
  );

  test('summary query groups by classificacao and sums impact', () {
    check(sql).contains('COUNT(*) AS QuantidadeProdutos');
    check(sql).contains('SUM(Diferenca) AS ImpactoLiquido');
    check(sql).contains('GROUP BY Classificacao');
    check(sql).contains('ORDER BY');
  });

  test('summary query inlines optional filters as SQL literals', () {
    final filtered = ProdutoVendidoTendenciaDeVendaMediaMovelSummarySql.query(
      quantidadeDias: 21,
      searchTerm: "fox' prime",
      classificacao: 'PAROU',
      codGrupoProduto: 9,
      codMarca: 77,
    );

    check(filtered).contains('AND p.CodGrupoProduto = 9');
    check(filtered).contains('AND p.CodMarca = 77');
    check(filtered).contains("N'%fox'' prime%'");
    check(filtered).contains("WHERE Classificacao = N'PAROU'");
    check(filtered).contains('(QtdAtual * 1.0 / 21) AS MediaAtual');
  });
}

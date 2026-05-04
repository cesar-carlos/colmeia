import 'package:colmeia/features/agent_queries/data/queries/produto_vendido_tendencia_de_venda_media_movel_sql.dart';

/// Summary SQL for `ProdutoVendidoTendenciaDeVendaMediaMovel`.
///
/// Returns one aggregated row per classification over the complete filtered
/// universe, so dashboard KPIs and charts stay independent from page size.
abstract final class ProdutoVendidoTendenciaDeVendaMediaMovelSummarySql {
  static String query({
    required int quantidadeDias,
    String? searchTerm,
    String? classificacao,
    int? codGrupoProduto,
    int? codMarca,
  }) {
    final filteredCtes =
        ProdutoVendidoTendenciaDeVendaMediaMovelSql.filteredUniverseCtes(
          quantidadeDias: quantidadeDias,
          searchTerm: searchTerm,
          classificacao: classificacao,
          codGrupoProduto: codGrupoProduto,
          codMarca: codMarca,
        );

    return '''
$filteredCtes
    SELECT
      Classificacao,
      COUNT(*) AS QuantidadeProdutos,
      SUM(Diferenca) AS ImpactoLiquido
    FROM Filtrado
    GROUP BY Classificacao
    ORDER BY
      QuantidadeProdutos DESC,
      ImpactoLiquido DESC,
      Classificacao ASC
''';
  }
}

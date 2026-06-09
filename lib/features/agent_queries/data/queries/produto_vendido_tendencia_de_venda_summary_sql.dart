import 'package:colmeia/features/agent_queries/data/queries/produto_vendido_tendencia_de_venda_sql.dart';

/// Aggregated summary for product sales trend grouped by `Classificacao`.
///
/// Returns one aggregated row per classification over the complete filtered
/// universe, so dashboard KPIs and charts stay independent from page size.
///
/// Named params:
/// - `:periodoAtualInicio`
/// - `:periodoAtualFim`
/// - `:periodoAnteriorInicio`
/// - `:periodoAnteriorFim`
/// - `:origem`
abstract final class ProdutoVendidoTendenciaDeVendaSummarySql {
  static String query({
    String? searchTerm,
    String? classificacao,
    int? codGrupoProduto,
    int? codMarca,
  }) {
    final filteredCtes = ProdutoVendidoTendenciaDeVendaSql.filteredUniverseCtes(
      searchTerm: searchTerm,
      codGrupoProduto: codGrupoProduto,
      codMarca: codMarca,
    );
    final classificacaoWhere = _whereOptionalClassificacao(classificacao);

    return '''
$filteredCtes,
    Filtrado AS (
      SELECT
        Diferenca,
        Classificacao
      FROM Resultado
$classificacaoWhere
    )
    SELECT
      Classificacao,
      COUNT(*) AS QuantidadeProdutos,
      SUM(Diferenca) AS ImpactoLiquido
    FROM Filtrado
    GROUP BY
      Classificacao
    ORDER BY
      QuantidadeProdutos DESC,
      Classificacao ASC
  ''';
  }

  static String _whereOptionalClassificacao(String? classificacao) {
    final normalized = classificacao?.trim();
    if (normalized == null || normalized.isEmpty) {
      return '      WHERE (1 = 1)';
    }
    final escaped = normalized.replaceAll("'", "''");
    return "      WHERE Classificacao = N'$escaped'";
  }
}

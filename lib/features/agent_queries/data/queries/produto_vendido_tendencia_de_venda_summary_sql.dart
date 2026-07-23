import 'package:colmeia/features/agent_queries/data/queries/produto_vendido_tendencia_de_venda_sql.dart';
import 'package:colmeia/features/agent_queries/domain/entities/sales_trend_filter_limits.dart';
import 'package:colmeia/features/agent_queries/domain/entities/sales_trend_metric_mode.dart';

/// Aggregated summary for product sales trend grouped by `Classificacao`.
abstract final class ProdutoVendidoTendenciaDeVendaSummarySql {
  static String query({
    String? searchTerm,
    String? classificacao,
    int? codGrupoProduto,
    int? codMarca,
    int? codFilial,
    SalesTrendMetricMode metricMode = SalesTrendMetricMode.quantity,
    int minVolumeUnits = SalesTrendFilterLimits.defaultMinVolumeUnits,
    double trendThresholdPercent =
        SalesTrendFilterLimits.defaultTrendThresholdPercent,
  }) {
    final filteredCtes = ProdutoVendidoTendenciaDeVendaSql.filteredUniverseCtes(
      searchTerm: searchTerm,
      codGrupoProduto: codGrupoProduto,
      codMarca: codMarca,
      codFilial: codFilial,
      metricMode: metricMode,
      minVolumeUnits: minVolumeUnits,
      trendThresholdPercent: trendThresholdPercent,
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

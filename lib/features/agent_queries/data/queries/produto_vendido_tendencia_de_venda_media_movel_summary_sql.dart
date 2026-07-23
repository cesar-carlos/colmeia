import 'package:colmeia/features/agent_queries/data/queries/produto_vendido_tendencia_de_venda_media_movel_sql.dart';
import 'package:colmeia/features/agent_queries/domain/entities/sales_trend_filter_limits.dart';
import 'package:colmeia/features/agent_queries/domain/entities/sales_trend_metric_mode.dart';

/// Summary SQL for `ProdutoVendidoTendenciaDeVendaMediaMovel`.
abstract final class ProdutoVendidoTendenciaDeVendaMediaMovelSummarySql {
  static String query({
    required int quantidadeDias,
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
    final filteredCtes =
        ProdutoVendidoTendenciaDeVendaMediaMovelSql.filteredUniverseCtes(
          quantidadeDias: quantidadeDias,
          searchTerm: searchTerm,
          classificacao: classificacao,
          codGrupoProduto: codGrupoProduto,
          codMarca: codMarca,
          codFilial: codFilial,
          metricMode: metricMode,
          minVolumeUnits: minVolumeUnits,
          trendThresholdPercent: trendThresholdPercent,
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

import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_media_movel_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/sales_trend_classificacao.dart';
import 'package:colmeia/features/agent_queries/domain/entities/sales_trend_filter_limits.dart';
import 'package:colmeia/features/agent_queries/domain/entities/sales_trend_metric_mode.dart';

// Product sales trend by calendar moving average
// (`ProdutoVendidoTendenciaDeVendaMediaMovel`) in a single `sql.execute`
// round-trip.
//
// Compares the mean daily metric over the latest N calendar days (ending
// today) against the previous N calendar days. Dividing period totals by N is
// equivalent to a calendar moving average that treats days without sales as
// zero — without materializing a product×day calendar explode (costly on SQL
// Anywhere). Metric is quantity or net line revenue.
//
// One result row per `CodEmpresa` + `CodFilial` + `CodProduto`.
abstract final class ProdutoVendidoTendenciaDeVendaMediaMovelSql {
  static String filteredUniverseCtes({
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
    if (quantidadeDias < 1) {
      throw ArgumentError.value(
        quantidadeDias,
        'quantidadeDias',
        'must be >= 1',
      );
    }

    final currentWindowStartOffset = quantidadeDias - 1;
    final lookbackDays = (quantidadeDias * 2) - 1;
    final codGrupoProdutoLine = _whereIntEquals(
      columnSql: 'p.CodGrupoProduto',
      value: codGrupoProduto,
    );
    final codMarcaLine = _whereIntEquals(
      columnSql: 'p.CodMarca',
      value: codMarca,
    );
    final codFilialLine = _whereIntEquals(
      columnSql: 'pv.CodFilial',
      value: codFilial,
    );
    final searchTermLine = _whereContainsProductDimensions(searchTerm);
    final classificacaoLine = _whereOptionalClassificacao(classificacao);
    final metricSql = metricMode.lineMetricSql;
    final threshold = trendThresholdPercent;

    return '''
    WITH BaseVendas AS (
      SELECT
        pv.CodEmpresa,
        pv.CodFilial,
        ipv.CodProduto,
        p.Nome AS NomeProduto,
        p.CodUnidadeMedida,
        gp.CodGrupoProduto,
        gp.Nome AS NomeGrupoProduto,
        m.CodMarca,
        m.Nome AS NomeMarca,
        CASE
          WHEN pv.DataVenda >= DATEADD(DAY, -$currentWindowStartOffset, CAST(GETDATE() AS DATE))
            AND pv.DataVenda < DATEADD(day, 1, CAST(GETDATE() AS DATE))
            THEN 'ATUAL'
          WHEN pv.DataVenda >= DATEADD(DAY, -$lookbackDays, CAST(GETDATE() AS DATE))
            AND pv.DataVenda < DATEADD(DAY, -$currentWindowStartOffset, CAST(GETDATE() AS DATE))
            THEN 'ANTERIOR'
        END AS Periodo,
        $metricSql AS MetricaLinha
      FROM ItemProdutoVendido ipv
      INNER JOIN ProdutoVendido pv ON
        pv.CodEmpresa = ipv.CodEmpresa
        AND pv.CodProdutoVendido = ipv.CodProdutoVendido
      INNER JOIN Produto p ON
        p.CodProduto = ipv.CodProduto
      LEFT JOIN GrupoProduto gp ON
        gp.CodGrupoProduto = p.CodGrupoProduto
      LEFT JOIN Marca m ON
        m.CodMarca = p.CodMarca
      INNER JOIN TipoOperacaoSaida tos ON
        tos.CodEmpresa = pv.CodEmpresa
        AND tos.CodTipoOperacaoSaida = pv.CodTipoOperacaoSaida
      WHERE pv.DataVenda >= DATEADD(DAY, -$lookbackDays, CAST(GETDATE() AS DATE))
        AND pv.DataVenda < DATEADD(day, 1, CAST(GETDATE() AS DATE))
        AND pv.Origem = 'FrenteLoja'
        AND COALESCE(tos.GeraFinanceiro, 'N') = 'S'
        AND pv.PreVenda = 'N'
$codGrupoProdutoLine
$codMarcaLine
$codFilialLine
$searchTermLine
    ),
    Vendas AS (
      SELECT
        CodEmpresa,
        CodFilial,
        CodProduto,
        NomeProduto,
        CodUnidadeMedida,
        CodGrupoProduto,
        NomeGrupoProduto,
        CodMarca,
        NomeMarca,
        Periodo,
        SUM(MetricaLinha) AS Metrica
      FROM BaseVendas
      WHERE Periodo IS NOT NULL
      GROUP BY
        CodEmpresa,
        CodFilial,
        CodProduto,
        NomeProduto,
        CodUnidadeMedida,
        CodGrupoProduto,
        NomeGrupoProduto,
        CodMarca,
        NomeMarca,
        Periodo
    ),
    Pivotado AS (
      SELECT
        CodEmpresa,
        CodFilial,
        CodProduto,
        NomeProduto,
        CodUnidadeMedida,
        CodGrupoProduto,
        NomeGrupoProduto,
        CodMarca,
        NomeMarca,
        SUM(CASE WHEN Periodo = 'ATUAL' THEN Metrica ELSE 0 END) AS QtdAtual,
        SUM(CASE WHEN Periodo = 'ANTERIOR' THEN Metrica ELSE 0 END)
          AS QtdAnterior
      FROM Vendas
      GROUP BY
        CodEmpresa,
        CodFilial,
        CodProduto,
        NomeProduto,
        CodUnidadeMedida,
        CodGrupoProduto,
        NomeGrupoProduto,
        CodMarca,
        NomeMarca
    ),
    Resultado AS (
      SELECT
        CodEmpresa,
        CodFilial,
        CodProduto,
        NomeProduto,
        CodUnidadeMedida,
        CodGrupoProduto,
        NomeGrupoProduto,
        CodMarca,
        NomeMarca,
        (QtdAtual * 1.0 / $quantidadeDias) AS MediaAtual,
        (QtdAnterior * 1.0 / $quantidadeDias) AS MediaAnterior,
        ((QtdAtual - QtdAnterior) * 1.0 / $quantidadeDias) AS Diferenca,
        CASE
          WHEN QtdAnterior > 0
            THEN ((QtdAtual - QtdAnterior) * 100.0 / QtdAnterior)
          ELSE 0
        END AS TendenciaPercentual,
        CASE
          WHEN QtdAnterior = 0 AND QtdAtual > 0 THEN '${SalesTrendClassificacao.novo}'
          WHEN QtdAtual = 0 AND QtdAnterior > 0 THEN '${SalesTrendClassificacao.parou}'
          WHEN (
            (QtdAtual - QtdAnterior) * 1.0 / NULLIF(QtdAnterior, 0)
          ) > $threshold THEN '${SalesTrendClassificacao.crescendo}'
          WHEN (
            (QtdAtual - QtdAnterior) * 1.0 / NULLIF(QtdAnterior, 0)
          ) < -$threshold THEN '${SalesTrendClassificacao.caindo}'
          ELSE '${SalesTrendClassificacao.estavel}'
        END AS Classificacao
      FROM Pivotado
      WHERE (QtdAtual + QtdAnterior) >= $minVolumeUnits
    ),
    Filtrado AS (
      SELECT
        CodEmpresa,
        CodFilial,
        CodProduto,
        NomeProduto,
        CodUnidadeMedida,
        CodGrupoProduto,
        NomeGrupoProduto,
        CodMarca,
        NomeMarca,
        MediaAtual,
        MediaAnterior,
        Diferenca,
        TendenciaPercentual,
        Classificacao
      FROM Resultado
$classificacaoLine
    )''';
  }

  static String pagedQuery({
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
    ProdutoVendidoTendenciaDeVendaMediaMovelSortBy sortBy =
        ProdutoVendidoTendenciaDeVendaMediaMovelSortBy.tendenciaPercentualDesc,
  }) {
    final filteredCtes = filteredUniverseCtes(
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
$filteredCtes,
    Tot AS (
      SELECT COUNT(*) AS TotalCount FROM Filtrado
    ),
    Numbered AS (
      SELECT
        f.*,
        ROW_NUMBER() OVER (
          ORDER BY ${_numberedOrderByClause(sortBy)}
        ) AS Rn
      FROM Filtrado f
    )
    SELECT
      Tot.TotalCount,
      N.CodEmpresa,
      N.CodFilial,
      N.CodProduto,
      N.NomeProduto,
      N.CodUnidadeMedida,
      N.CodGrupoProduto,
      N.NomeGrupoProduto,
      N.CodMarca,
      N.NomeMarca,
      N.MediaAtual,
      N.MediaAnterior,
      N.Diferenca,
      N.TendenciaPercentual,
      N.Classificacao
    FROM Tot
    LEFT JOIN Numbered N ON N.Rn BETWEEN :startRow AND :endRow
    ORDER BY COALESCE(N.Rn, 2147483647)
  ''';
  }

  static String _whereIntEquals({
    required String columnSql,
    required int? value,
  }) {
    if (value == null) {
      return '        AND (1 = 1)';
    }
    return '        AND $columnSql = $value';
  }

  static String _whereContainsProductDimensions(String? searchTerm) {
    final normalized = searchTerm?.trim();
    if (normalized == null || normalized.isEmpty) {
      return '        AND (1 = 1)';
    }
    final escaped = normalized.replaceAll("'", "''");
    final likeLiteral = "N'%$escaped%'";
    return '''
        AND (
          UPPER(p.Nome) LIKE UPPER($likeLiteral)
          OR UPPER(COALESCE(gp.Nome, '')) LIKE UPPER($likeLiteral)
          OR UPPER(COALESCE(m.Nome, '')) LIKE UPPER($likeLiteral)
        )''';
  }

  static String _whereOptionalClassificacao(String? classificacao) {
    final normalized = SalesTrendClassificacao.normalize(classificacao);
    if (normalized == null) {
      return '      WHERE (1 = 1)';
    }
    final escaped = normalized.replaceAll("'", "''");
    return "      WHERE Classificacao = N'$escaped'";
  }

  static String _numberedOrderByClause(
    ProdutoVendidoTendenciaDeVendaMediaMovelSortBy sortBy,
  ) {
    return switch (sortBy) {
      ProdutoVendidoTendenciaDeVendaMediaMovelSortBy.tendenciaPercentualDesc =>
        '''
            f.CodEmpresa ASC,
            f.CodFilial ASC,
            f.TendenciaPercentual DESC,
            f.Diferenca DESC,
            f.NomeProduto ASC''',
      ProdutoVendidoTendenciaDeVendaMediaMovelSortBy.diferencaDesc =>
        '''
            f.CodEmpresa ASC,
            f.CodFilial ASC,
            f.Diferenca DESC,
            f.TendenciaPercentual DESC,
            f.NomeProduto ASC''',
      ProdutoVendidoTendenciaDeVendaMediaMovelSortBy.nomeProdutoAsc =>
        '''
            f.CodEmpresa ASC,
            f.CodFilial ASC,
            f.NomeProduto ASC,
            f.TendenciaPercentual DESC''',
    };
  }
}

import 'package:colmeia/features/agent_queries/domain/entities/sales_trend_classificacao.dart';
import 'package:colmeia/features/agent_queries/domain/entities/sales_trend_filter_limits.dart';
import 'package:colmeia/features/agent_queries/domain/entities/sales_trend_metric_mode.dart';

// Product sales trend (`ProdutoVendidoTendenciaDeVenda`) in a single
// `sql.execute` round-trip.
//
// Compares two explicit periods (`ATUAL` and `ANTERIOR`) and returns one row
// per empresa/filial/product with difference, percentage trend, and
// classification. Metric is quantity or net line revenue
// (`Quantidade * ValorUnitarioLiquido`).
//
// ---
//
// ## Active joins and relationships
//
// | Alias | Table | Relationship / role |
// |---|---|---|
// | ipv | ItemProdutoVendido | Sale item line (`Quantidade`, `ValorUnitarioLiquido`, `CodProduto`) |
// | pv | ProdutoVendido | `pv.CodEmpresa = ipv.CodEmpresa` and `pv.CodProdutoVendido = ipv.CodProdutoVendido`; provides `DataVenda`, `Origem`, `PreVenda`, `CodFilial` |
// | tos | TipoOperacaoSaida | `tos.CodEmpresa = pv.CodEmpresa`, `tos.CodTipoOperacaoSaida = pv.CodTipoOperacaoSaida`; validates financeiro rows |
// | p | Produto | `p.CodProduto = ipv.CodProduto`; provides product identity and `CodUnidadeMedida` |
// | gp | GrupoProduto | `gp.CodGrupoProduto = p.CodGrupoProduto` (optional metadata) |
// | m | Marca | `m.CodMarca = p.CodMarca` (optional metadata) |
//
// ## Tables intentionally removed from active SQL
//
// | Alias | Table | Why removed now | Notes for reintroduction |
// |---|---|---|---|
// | cp | CustoProduto | Not referenced by current select or filters | Re-add with `cp.CodEmpresa = pv.CodEmpresa`, `cp.CodFilial = pv.CodFilial`, `cp.CodProduto = ipv.CodProduto` when trend needs cost/profit dimensions |
//
// ---
//
// ## Query parameters
//
// Named params:
// - `:periodoAtualInicio`
// - `:periodoAtualFim`
// - `:periodoAnteriorInicio`
// - `:periodoAnteriorFim`
// - `:origem`
//
// Pagination bounds are inlined as validated integer literals to keep the query
// under bridge named-bind limits.
abstract final class ProdutoVendidoTendenciaDeVendaSql {
  static const int topMoversLimit = 15;

  static String filteredUniverseCtes({
    String? searchTerm,
    int? codGrupoProduto,
    int? codMarca,
    int? codFilial,
    SalesTrendMetricMode metricMode = SalesTrendMetricMode.quantity,
    int minVolumeUnits = SalesTrendFilterLimits.defaultMinVolumeUnits,
    double trendThresholdPercent =
        SalesTrendFilterLimits.defaultTrendThresholdPercent,
  }) {
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
    final metricSql = metricMode.lineMetricSql;
    final threshold = trendThresholdPercent;

    return '''
    WITH Parametros AS (
      SELECT
        CAST(:periodoAtualInicio AS DATE) AS PeriodoAtualInicio,
        CAST(:periodoAtualFim AS DATE) AS PeriodoAtualFim,
        CAST(:periodoAnteriorInicio AS DATE) AS PeriodoAnteriorInicio,
        CAST(:periodoAnteriorFim AS DATE) AS PeriodoAnteriorFim
    ),
    BaseVendas AS (
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
          WHEN pv.DataVenda >= prm.PeriodoAtualInicio
            AND pv.DataVenda < DATEADD(day, 1, prm.PeriodoAtualFim)
            THEN 'ATUAL'
          WHEN pv.DataVenda >= prm.PeriodoAnteriorInicio
            AND pv.DataVenda < DATEADD(day, 1, prm.PeriodoAnteriorFim)
            THEN 'ANTERIOR'
        END AS Periodo,
        $metricSql AS MetricaLinha
      FROM ItemProdutoVendido ipv
      INNER JOIN ProdutoVendido pv ON
        pv.CodEmpresa = ipv.CodEmpresa
        AND pv.CodProdutoVendido = ipv.CodProdutoVendido
      INNER JOIN TipoOperacaoSaida tos ON
        tos.CodEmpresa = pv.CodEmpresa
        AND tos.CodTipoOperacaoSaida = pv.CodTipoOperacaoSaida
      INNER JOIN Produto p ON
        p.CodProduto = ipv.CodProduto
      LEFT JOIN GrupoProduto gp ON
        gp.CodGrupoProduto = p.CodGrupoProduto
      LEFT JOIN Marca m ON
        m.CodMarca = p.CodMarca
      CROSS JOIN Parametros prm
      WHERE (
        (
          pv.DataVenda >= prm.PeriodoAtualInicio
          AND pv.DataVenda < DATEADD(day, 1, prm.PeriodoAtualFim)
        )
        OR (
          pv.DataVenda >= prm.PeriodoAnteriorInicio
          AND pv.DataVenda < DATEADD(day, 1, prm.PeriodoAnteriorFim)
        )
      )
        AND pv.Origem = :origem
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
        SUM(CASE WHEN Periodo = 'ANTERIOR' THEN Metrica ELSE 0 END) AS QtdAnterior
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
        QtdAnterior,
        QtdAtual,
        (QtdAtual - QtdAnterior) AS Diferenca,
        CASE
          WHEN QtdAnterior > 0
            THEN ((QtdAtual - QtdAnterior) * 100.0 / QtdAnterior)
          ELSE 0
        END AS PercentualTendencia,
        CASE
          WHEN QtdAtual = 0 AND QtdAnterior > 0 THEN '${SalesTrendClassificacao.parou}'
          WHEN QtdAnterior = 0 AND QtdAtual > 0 THEN '${SalesTrendClassificacao.novo}'
          WHEN ((QtdAtual - QtdAnterior) * 1.0 / NULLIF(QtdAnterior, 0)) > $threshold
            THEN '${SalesTrendClassificacao.crescendo}'
          WHEN ((QtdAtual - QtdAnterior) * 1.0 / NULLIF(QtdAnterior, 0)) < -$threshold
            THEN '${SalesTrendClassificacao.caindo}'
          ELSE '${SalesTrendClassificacao.estavel}'
        END AS Classificacao
      FROM Pivotado
      WHERE (QtdAtual + QtdAnterior) >= $minVolumeUnits
    )''';
  }

  static String pagedQuery({
    required int startRow,
    required int endRow,
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
    if (startRow < 1) {
      throw ArgumentError.value(startRow, 'startRow', 'must be >= 1');
    }
    if (endRow < startRow) {
      throw ArgumentError.value(
        endRow,
        'endRow',
        'must be >= startRow',
      );
    }
    final classificacaoLine = _whereOptionalClassificacao(classificacao);
    final filteredCtes = filteredUniverseCtes(
      searchTerm: searchTerm,
      codGrupoProduto: codGrupoProduto,
      codMarca: codMarca,
      codFilial: codFilial,
      metricMode: metricMode,
      minVolumeUnits: minVolumeUnits,
      trendThresholdPercent: trendThresholdPercent,
    );

    return '''
$filteredCtes,
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
        QtdAnterior,
        QtdAtual,
        Diferenca,
        PercentualTendencia,
        Classificacao
      FROM Resultado
$classificacaoLine
    ),
    Tot AS (
      SELECT COUNT(*) AS TotalCount FROM Filtrado
    ),
    Numbered AS (
      SELECT
        ROW_NUMBER() OVER (
          ORDER BY
            CodEmpresa ASC,
            CodFilial ASC,
            PercentualTendencia DESC,
            Diferenca DESC,
            NomeProduto ASC
        ) AS RowNum,
        CodEmpresa,
        CodFilial,
        CodProduto,
        NomeProduto,
        CodUnidadeMedida,
        CodGrupoProduto,
        NomeGrupoProduto,
        CodMarca,
        NomeMarca,
        QtdAnterior,
        QtdAtual,
        Diferenca,
        PercentualTendencia,
        Classificacao
      FROM Filtrado
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
      N.QtdAnterior,
      N.QtdAtual,
      N.Diferenca,
      N.PercentualTendencia,
      N.Classificacao
    FROM Tot
    LEFT JOIN Numbered N ON N.RowNum BETWEEN $startRow AND $endRow
    ORDER BY COALESCE(N.RowNum, 2147483647)
  ''';
  }

  static String topGainersQuery({
    String? searchTerm,
    String? classificacao,
    int? codGrupoProduto,
    int? codMarca,
    int? codFilial,
    SalesTrendMetricMode metricMode = SalesTrendMetricMode.quantity,
    int minVolumeUnits = SalesTrendFilterLimits.defaultMinVolumeUnits,
    double trendThresholdPercent =
        SalesTrendFilterLimits.defaultTrendThresholdPercent,
    SalesTrendTopMoversSortBy topMoversSortBy =
        SalesTrendTopMoversSortBy.diferenca,
  }) {
    return _topMoversQuery(
      searchTerm: searchTerm,
      classificacao: classificacao,
      codGrupoProduto: codGrupoProduto,
      codMarca: codMarca,
      codFilial: codFilial,
      metricMode: metricMode,
      minVolumeUnits: minVolumeUnits,
      trendThresholdPercent: trendThresholdPercent,
      topMoversSortBy: topMoversSortBy,
      gainers: true,
    );
  }

  static String topLosersQuery({
    String? searchTerm,
    String? classificacao,
    int? codGrupoProduto,
    int? codMarca,
    int? codFilial,
    SalesTrendMetricMode metricMode = SalesTrendMetricMode.quantity,
    int minVolumeUnits = SalesTrendFilterLimits.defaultMinVolumeUnits,
    double trendThresholdPercent =
        SalesTrendFilterLimits.defaultTrendThresholdPercent,
    SalesTrendTopMoversSortBy topMoversSortBy =
        SalesTrendTopMoversSortBy.diferenca,
  }) {
    return _topMoversQuery(
      searchTerm: searchTerm,
      classificacao: classificacao,
      codGrupoProduto: codGrupoProduto,
      codMarca: codMarca,
      codFilial: codFilial,
      metricMode: metricMode,
      minVolumeUnits: minVolumeUnits,
      trendThresholdPercent: trendThresholdPercent,
      topMoversSortBy: topMoversSortBy,
      gainers: false,
    );
  }

  static String _topMoversQuery({
    required String? searchTerm,
    required String? classificacao,
    required int? codGrupoProduto,
    required int? codMarca,
    required int? codFilial,
    required SalesTrendMetricMode metricMode,
    required int minVolumeUnits,
    required double trendThresholdPercent,
    required SalesTrendTopMoversSortBy topMoversSortBy,
    required bool gainers,
  }) {
    final classificacaoLine = _whereOptionalClassificacao(classificacao);
    final filteredCtes = filteredUniverseCtes(
      searchTerm: searchTerm,
      codGrupoProduto: codGrupoProduto,
      codMarca: codMarca,
      codFilial: codFilial,
      metricMode: metricMode,
      minVolumeUnits: minVolumeUnits,
      trendThresholdPercent: trendThresholdPercent,
    );
    // NOVO has PercentualTendencia = 0 and can dominate "top altas" by raw
    // delta. Exclude it so gainers reflect products that also sold before.
    final percentPredicate = gainers
        ? "Diferenca > 0 AND Classificacao <> N'${SalesTrendClassificacao.novo}'"
        : 'Diferenca < 0';
    final orderBy = switch ((gainers, topMoversSortBy)) {
      (true, SalesTrendTopMoversSortBy.diferenca) =>
        '''
      Diferenca DESC,
      PercentualTendencia DESC,
      CodEmpresa ASC,
      CodFilial ASC,
      NomeProduto ASC''',
      (true, SalesTrendTopMoversSortBy.percentual) =>
        '''
      PercentualTendencia DESC,
      Diferenca DESC,
      CodEmpresa ASC,
      CodFilial ASC,
      NomeProduto ASC''',
      (false, SalesTrendTopMoversSortBy.diferenca) =>
        '''
      Diferenca ASC,
      PercentualTendencia ASC,
      CodEmpresa ASC,
      CodFilial ASC,
      NomeProduto ASC''',
      (false, SalesTrendTopMoversSortBy.percentual) =>
        '''
      PercentualTendencia ASC,
      Diferenca ASC,
      CodEmpresa ASC,
      CodFilial ASC,
      NomeProduto ASC''',
    };

    return '''
$filteredCtes,
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
        QtdAnterior,
        QtdAtual,
        Diferenca,
        PercentualTendencia,
        Classificacao
      FROM Resultado
$classificacaoLine
    )
    SELECT TOP $topMoversLimit
      CodEmpresa,
      CodFilial,
      CodProduto,
      NomeProduto,
      CodUnidadeMedida,
      CodGrupoProduto,
      NomeGrupoProduto,
      CodMarca,
      NomeMarca,
      QtdAnterior,
      QtdAtual,
      Diferenca,
      PercentualTendencia,
      Classificacao
    FROM Filtrado
    WHERE $percentPredicate
    ORDER BY
$orderBy
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
    final normalized = classificacao?.trim();
    if (normalized == null || normalized.isEmpty) {
      return '      WHERE (1 = 1)';
    }
    final escaped = normalized.replaceAll("'", "''");
    return "      WHERE Classificacao = N'$escaped'";
  }
}

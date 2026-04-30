/// Aggregated summary for product sales trend grouped by `Classificacao`.
///
/// Named params:
/// - `:periodoAtualInicio`
/// - `:periodoAtualFim`
/// - `:periodoAnteriorInicio`
/// - `:periodoAnteriorFim`
/// - `:origem`
abstract final class ProdutoVendidoTendenciaDeVendaSummarySql {
  static const String query = '''
    WITH Parametros AS (
      SELECT
        CAST(:periodoAtualInicio AS DATE) AS PeriodoAtualInicio,
        CAST(:periodoAtualFim AS DATE) AS PeriodoAtualFim,
        CAST(:periodoAnteriorInicio AS DATE) AS PeriodoAnteriorInicio,
        CAST(:periodoAnteriorFim AS DATE) AS PeriodoAnteriorFim
    ),
    BaseVendas AS (
      SELECT
        ipv.CodProduto,
        CASE
          WHEN CAST(pv.DataVenda AS DATE)
            BETWEEN prm.PeriodoAtualInicio AND prm.PeriodoAtualFim
            THEN 'ATUAL'
          WHEN CAST(pv.DataVenda AS DATE)
            BETWEEN prm.PeriodoAnteriorInicio AND prm.PeriodoAnteriorFim
            THEN 'ANTERIOR'
        END AS Periodo,
        ipv.Quantidade
      FROM ItemProdutoVendido ipv
      INNER JOIN ProdutoVendido pv ON
        pv.CodEmpresa = ipv.CodEmpresa
        AND pv.CodProdutoVendido = ipv.CodProdutoVendido
      INNER JOIN TipoOperacaoSaida tos ON
        tos.CodEmpresa = pv.CodEmpresa
        AND tos.CodFilial = pv.CodFilial
        AND tos.CodTipoOperacaoSaida = pv.CodTipoOperacaoSaida
      CROSS JOIN Parametros prm
      WHERE (
        CAST(pv.DataVenda AS DATE) BETWEEN prm.PeriodoAtualInicio AND prm.PeriodoAtualFim
        OR CAST(pv.DataVenda AS DATE)
          BETWEEN prm.PeriodoAnteriorInicio AND prm.PeriodoAnteriorFim
      )
        AND pv.Origem LIKE :origem
        AND COALESCE(tos.GeraFinanceiro, 'N') = 'S'
        AND pv.PreVenda = 'N'
    ),
    Vendas AS (
      SELECT
        CodProduto,
        Periodo,
        SUM(Quantidade) AS Quantidade
      FROM BaseVendas
      WHERE Periodo IS NOT NULL
      GROUP BY
        CodProduto,
        Periodo
    ),
    Pivotado AS (
      SELECT
        CodProduto,
        SUM(CASE WHEN Periodo = 'ATUAL' THEN Quantidade ELSE 0 END) AS QtdAtual,
        SUM(CASE WHEN Periodo = 'ANTERIOR' THEN Quantidade ELSE 0 END) AS QtdAnterior
      FROM Vendas
      GROUP BY
        CodProduto
    ),
    Resultado AS (
      SELECT
        (QtdAtual - QtdAnterior) AS Diferenca,
        CASE
          WHEN QtdAtual = 0 AND QtdAnterior > 0 THEN 'PAROU DE VENDER'
          WHEN QtdAnterior = 0 AND QtdAtual > 0 THEN 'NOVO PRODUTO'
          WHEN ((QtdAtual - QtdAnterior) * 1.0 / NULLIF(QtdAnterior, 0)) > 0.2
            THEN 'CRESCENDO'
          WHEN ((QtdAtual - QtdAnterior) * 1.0 / NULLIF(QtdAnterior, 0)) < -0.2
            THEN 'CAINDO'
          ELSE 'ESTAVEL'
        END AS Classificacao
      FROM Pivotado
      WHERE (QtdAtual + QtdAnterior) >= 10
    )
    SELECT
      Classificacao,
      COUNT(*) AS QuantidadeProdutos,
      SUM(Diferenca) AS ImpactoLiquido
    FROM Resultado
    GROUP BY
      Classificacao
    ORDER BY
      QuantidadeProdutos DESC,
      Classificacao ASC
  ''';
}

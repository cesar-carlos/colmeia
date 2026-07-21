/// Monthly product profitability summary (`ResumoProdutoVendaLucratividadeMensal`)
/// in a single `sql.execute` round-trip.
///
/// Written for **Microsoft SQL Server** and **SAP SQL Anywhere**. Uses a CTE
/// (same pattern as billing ranking) — nested subqueries with string-built
/// sale ids returned empty success payloads on unary relay for this agent.
///
/// ---
///
/// ## Tables read
///
/// | Alias | Table | Active columns |
/// |---|---|---|
/// | `ipv` | `ItemProdutoVendido` | `Quantidade`, `PontoEquilibrio`, `ValorUnitarioLiquido` |
/// | `pv` | `ProdutoVendido` | `CodEmpresa`, `CodFilial`, `CodProdutoVendido` (sale id), `DataVenda`, `Origem`, `PreVenda`, `CodTipoOperacaoSaida` |
/// | `cp` | `CustoProduto` | `CustoMedioPonderado`, `CustoCompra` (optional; LEFT JOIN) |
/// | `tos` | `TipoOperacaoSaida` | `GeraFinanceiro` (filter) |
///
/// ## Parameters
///
/// Named params: `:dataVendaInicio`, `:dataVendaFim`, `:origem`.
///
/// Result ordered `CodEmpresa`, `CodFilial`, `Ano`, `Mes` ascending.
abstract final class ResumoProdutoVendaLucratividadeMensalSql {
  static const String query = '''
WITH DetalheProdutoVenda AS (
    SELECT
        pv.CodEmpresa,
        pv.CodFilial,
        pv.CodProdutoVendido,
        YEAR(pv.DataVenda) AS Ano,
        MONTH(pv.DataVenda) AS Mes,
        ipv.Quantidade,
        COALESCE(ipv.PontoEquilibrio, 0.00) AS PontoEquilibrio,
        COALESCE(cp.CustoMedioPonderado, 0.00) AS CustoMedio,
        COALESCE(cp.CustoCompra, 0.00) AS CustoReposicao,
        ipv.ValorUnitarioLiquido
    FROM ItemProdutoVendido ipv
    INNER JOIN ProdutoVendido pv ON
        pv.CodEmpresa = ipv.CodEmpresa
    AND pv.CodProdutoVendido = ipv.CodProdutoVendido
    LEFT JOIN CustoProduto cp ON
        cp.CodEmpresa = pv.CodEmpresa
    AND cp.CodFilial = pv.CodFilial
    AND cp.CodProduto = ipv.CodProduto
    INNER JOIN TipoOperacaoSaida tos ON
        tos.CodEmpresa = pv.CodEmpresa
    AND tos.CodTipoOperacaoSaida = pv.CodTipoOperacaoSaida
    WHERE CAST(pv.DataVenda AS DATE) BETWEEN :dataVendaInicio AND :dataVendaFim
      AND pv.Origem = :origem
      AND COALESCE(tos.GeraFinanceiro, 'N') = 'S'
      AND pv.PreVenda = 'N'
)
SELECT
    CodEmpresa,
    CodFilial,
    Ano,
    Mes,
    CAST(Ano AS VARCHAR(4)) + '/' +
      CASE WHEN Mes < 10 THEN '0' ELSE '' END +
      CAST(Mes AS VARCHAR(2)) AS AnoMes,
    COUNT(DISTINCT CodProdutoVendido) AS QtdVendas,
    SUM(Quantidade) AS QtdItensVendido,
    SUM(Quantidade * CustoMedio) AS ValorTotalCustoMedio,
    SUM(Quantidade * CustoReposicao) AS CustoReposicao,
    SUM(Quantidade * PontoEquilibrio) AS PontoEquilibrio,
    SUM(Quantidade * ValorUnitarioLiquido) AS ValorTotalItem
FROM DetalheProdutoVenda
GROUP BY
    CodEmpresa,
    CodFilial,
    Ano,
    Mes
ORDER BY
    CodEmpresa ASC,
    CodFilial ASC,
    Ano ASC,
    Mes ASC
''';
}

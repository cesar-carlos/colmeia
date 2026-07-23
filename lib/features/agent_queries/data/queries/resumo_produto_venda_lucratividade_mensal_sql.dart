/// Monthly product profitability summary (`ResumoProdutoVendaLucratividadeMensal`)
/// in a single `sql.execute` round-trip.
///
/// Written for **Microsoft SQL Server** and **SAP SQL Anywhere**. Uses the same
/// nested-subquery join shape as `ResumoProdutoVendaLucratividadeSql`, with
/// `YEAR`/`MONTH` buckets in a middle layer (same pattern as
/// `ResumoParcelasMensalSql`). Keep `max_rows` in the low hundreds — on the
/// E2E SQL Anywhere agent, values around 1600+ returned empty success for
/// heavy report shapes.
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
SELECT
    CodEmpresa,
    CodFilial,
    Ano,
    Mes,
    MAX(
      CAST(Ano AS VARCHAR(4)) + '/' +
        CASE WHEN Mes < 10 THEN '0' ELSE '' END +
        CAST(Mes AS VARCHAR(2))
    ) AS AnoMes,
    COUNT(DISTINCT Id) AS QtdVendas,
    SUM(Quantidade) AS QtdItensVendido,
    SUM(Quantidade * CustoMedio) AS ValorTotalCustoMedio,
    SUM(Quantidade * CustoReposicao) AS CustoReposicao,
    SUM(Quantidade * PontoEquilibrio) AS PontoEquilibrio,
    SUM(Quantidade * ValorUnitarioLiquido) AS ValorTotalItem
FROM (
    SELECT
        CodEmpresa,
        CodFilial,
        Id,
        Quantidade,
        PontoEquilibrio,
        CustoMedio,
        CustoReposicao,
        ValorUnitarioLiquido,
        YEAR(DataVenda) AS Ano,
        MONTH(DataVenda) AS Mes
    FROM (
        SELECT
            pv.CodEmpresa,
            pv.CodFilial,
            pv.DataVenda,
            CAST(pv.CodEmpresa AS VARCHAR) + '-' +
              CAST(pv.CodFilial AS VARCHAR) + '-' +
              CAST(pv.CodProdutoVendido AS VARCHAR) AS Id,
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
        WHERE pv.DataVenda >= CAST(:dataVendaInicio AS DATE)
          AND pv.DataVenda < DATEADD(day, 1, CAST(:dataVendaFim AS DATE))
          AND pv.Origem = :origem
          AND tos.GeraFinanceiro = 'S'
          AND pv.PreVenda = 'N'
    ) DetalheProdutoVenda
) ResumoProdutoVendaLucratividadeMensal
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

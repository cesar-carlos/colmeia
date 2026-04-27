// Monthly product profitability summary (`ResumoProdutoVendaLucratividadeMensal`)
// in a single `sql.execute` round-trip.
//
// ---
//
// ## Active joins and columns in `DetalheProdutoVenda`
//
// The CTE projects only the columns consumed by `Agregada`. Any addition for
// future display or filtering must be added here first.
//
// | Alias | Table | Active columns |
// |---|---|---|
// | `ipv` | `ItemProdutoVendido` | `Quantidade`, `PontoEquilibrio`, `ValorUnitarioLiquido` |
// | `pv` | `ProdutoVendido` | `CodEmpresa`, `CodFilial`, `CodProdutoVendido` (→ `Id`), `DataVenda` (→ `Ano`, `Mes`), `Origem`, `PreVenda`, `CodTipoOperacaoSaida` |
// | `cp` | `CustoProduto` | `CustoMedioPonderado` (→ `CustoMedio`), `CustoCompra` (→ `CustoReposicao`) |
// | `tos` | `TipoOperacaoSaida` | `GeraFinanceiro` (filter only — not projected) |
//
// ## Columns available from active joins but not currently projected
//
// Add these to the `DetalheProdutoVenda` SELECT when needed:
//
// | Table alias | Column | Use case |
// |---|---|---|
// | `pv` | `CodVendedor` | filter / group by seller |
// | `pv` | `CodCliente`, `NomeCliente` | filter / group by client |
// | `pv` | `CodMunicipio` | prerequisite for Municipio join |
// | `ipv` | `CodProduto`, `NomeProduto` | group by product (add to GROUP BY) |
// | `ipv` | `CodUnidadeMedida`, `PrecoUnitario` | unit display |
// | `cp` | `UltimoPrecoCompra` (→ `CustoCompra`) | last purchase price |
//
// ## Extension joins (not active — add to `DetalheProdutoVenda` to enable)
//
// ```sql
// -- Provides: CodProduto, NomeProduto, CodGrupoProduto, CodMarca; required
// -- to group/filter by product, group, or brand
// INNER JOIN Produto p ON p.CodProduto = ipv.CodProduto
//
// -- Provides: NomeMarca; requires Produto join above
// LEFT JOIN Marca mc ON mc.CodMarca = p.CodMarca
//
// -- Provides: NomeGrupoProduto, CodTipoGrupoProduto; requires Produto join
// LEFT JOIN GrupoProduto gp ON gp.CodGrupoProduto = p.CodGrupoProduto
//
// -- Provides: DescricaoTipoGrupoProduto; requires GrupoProduto join above
// LEFT JOIN TipoGrupoProduto tgp
//   ON tgp.CodTipoGrupoProduto = gp.CodTipoGrupoProduto
//
// -- Provides: CodGrupoCliente, CodRegiao (prerequisite for GrupoCliente
// -- and Regiao joins)
// INNER JOIN Cliente c ON c.CodCliente = pv.CodCliente
//
// -- Provides: NomeMunicipio, UFMunicipio; group/filter by city or state
// INNER JOIN Municipio m ON m.CodMunicipio = pv.CodMunicipio
//
// -- Provides: NomeGrupoCliente; requires Cliente join above
// LEFT JOIN GrupoCliente gc ON gc.CodGrupoCliente = c.CodGrupoCliente
//
// -- Provides: NomeRegiao; requires Cliente join above
// LEFT JOIN Regiao r ON r.CodRegiao = c.CodRegiao
//
// -- Provides: NomeVendedor; group/filter by seller name
// LEFT JOIN Vendedor v ON v.CodVendedor = pv.CodVendedor
// ```
//
// > **Note:** `Cliente` and `Municipio` were `INNER JOIN`s in the original
// > report SQL. If referential integrity is not guaranteed, consider `LEFT JOIN`
// > when re-adding them to avoid silently dropping rows.
//
// ---
//
// ## Query parameters
//
// Named params: `:dataVendaInicio`, `:dataVendaFim`, `:origem`
// (three binds — well within the five-bind bridge cap).
//
// Result is ordered `CodEmpresa ASC, CodFilial ASC, Ano ASC, Mes ASC` (fixed).
// No pagination — the result set is bounded by
// `months-in-range × filiais` rows.

abstract final class ResumoProdutoVendaLucratividadeMensalSql {
  static const String query = '''
    WITH DetalheProdutoVenda AS (
      SELECT
        pv.CodEmpresa,
        pv.CodFilial,
        CAST(pv.CodEmpresa AS VARCHAR) + '-' +
          CAST(pv.CodFilial AS VARCHAR) + '-' +
          CAST(pv.CodProdutoVendido AS VARCHAR) AS Id,
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
        AND pv.Origem LIKE :origem
        AND tos.GeraFinanceiro = 'S'
        AND pv.PreVenda = 'N'
    ),
    Agregada AS (
      SELECT
        CodEmpresa,
        CodFilial,
        Ano,
        Mes,
        COUNT(DISTINCT Id) AS QtdVendas,
        SUM(Quantidade) AS QtdItensVendido,
        SUM(Quantidade * CustoMedio) AS ValorTotalCustoMedio,
        SUM(Quantidade * CustoReposicao) AS CustoReposicao,
        SUM(Quantidade * PontoEquilibrio) AS PontoEquilibrio,
        SUM(Quantidade * ValorUnitarioLiquido) AS ValorTotalItem,
        CASE
          WHEN SUM(Quantidade * CustoReposicao) > 0.00
            AND SUM(Quantidade * ValorUnitarioLiquido) > 0.00 THEN
            (
              SUM(Quantidade * CustoReposicao) /
              SUM(Quantidade * ValorUnitarioLiquido)
            ) * 100
          ELSE 0.00
        END AS PercentualLucro
      FROM DetalheProdutoVenda
      GROUP BY
        CodEmpresa,
        CodFilial,
        Ano,
        Mes
    )
    SELECT
      CodEmpresa,
      CodFilial,
      Ano,
      Mes,
      CAST(Ano AS VARCHAR(4)) + '/' +
        CASE WHEN Mes < 10 THEN '0' ELSE '' END +
        CAST(Mes AS VARCHAR(2)) AS AnoMes,
      QtdVendas,
      QtdItensVendido,
      ValorTotalCustoMedio,
      CustoReposicao,
      PontoEquilibrio,
      ValorTotalItem,
      PercentualLucro
    FROM Agregada
    ORDER BY
      CodEmpresa ASC,
      CodFilial ASC,
      Ano ASC,
      Mes ASC
  ''';
}

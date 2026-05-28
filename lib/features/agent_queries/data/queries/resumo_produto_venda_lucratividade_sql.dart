// Period product profitability summary (`ResumoProdutoVendaLucratividade`)
// in a single `sql.execute` round-trip.
//
// Aggregates by `CodEmpresa + CodFilial` for the selected date range —
// one row per branch representing the full period totals. Designed to run
// per agent in parallel and be concatenated by the caller.
//
// Uses nested subqueries (no CTEs) for compatibility with SQL Server and
// Sybase SQL Anywhere.
//
// ---
//
// ## Active joins and columns in DetalheProdutoVenda (inner subquery)
//
// | Alias | Table | Active columns |
// |---|---|---|
// | ipv | ItemProdutoVendido | Quantidade, PontoEquilibrio, ValorUnitarioLiquido |
// | pv | ProdutoVendido | CodEmpresa, CodFilial, CodProdutoVendido (Id), DataVenda, Origem, PreVenda, CodTipoOperacaoSaida |
// | cp | CustoProduto | CustoMedioPonderado (CustoMedio), CustoCompra (CustoReposicao) |
// | tos | TipoOperacaoSaida | GeraFinanceiro (filter only) |
//
// ## Columns available from active joins but not currently projected
//
// | Alias | Column | Use case |
// |---|---|---|
// | pv | CodVendedor | filter / group by seller |
// | pv | CodCliente, NomeCliente | filter / group by client |
// | pv | CodMunicipio | prerequisite for Municipio join |
// | ipv | CodProduto, NomeProduto | group by product |
// | ipv | CodUnidadeMedida, PrecoUnitario | unit display |
// | cp | UltimoPrecoCompra (CustoCompra) | last purchase price |
//
// ## Extension joins (not active — add to inner subquery to enable)
//
// ```sql
// -- Provides: CodProduto, NomeProduto, CodGrupoProduto, CodMarca
// INNER JOIN Produto p ON p.CodProduto = ipv.CodProduto
//
// -- Provides: NomeMarca; requires Produto join
// LEFT JOIN Marca mc ON mc.CodMarca = p.CodMarca
//
// -- Provides: NomeGrupoProduto, CodTipoGrupoProduto; requires Produto join
// LEFT JOIN GrupoProduto gp ON gp.CodGrupoProduto = p.CodGrupoProduto
//
// -- Provides: DescricaoTipoGrupoProduto; requires GrupoProduto join
// LEFT JOIN TipoGrupoProduto tgp
//   ON tgp.CodTipoGrupoProduto = gp.CodTipoGrupoProduto
//
// -- Provides: CodGrupoCliente, CodRegiao (prerequisite for sub-joins)
// INNER JOIN Cliente c ON c.CodCliente = pv.CodCliente
//
// -- Provides: NomeMunicipio, UFMunicipio; group/filter by city or state
// INNER JOIN Municipio m ON m.CodMunicipio = pv.CodMunicipio
//
// -- Provides: NomeGrupoCliente; requires Cliente join
// LEFT JOIN GrupoCliente gc ON gc.CodGrupoCliente = c.CodGrupoCliente
//
// -- Provides: NomeRegiao; requires Cliente join
// LEFT JOIN Regiao r ON r.CodRegiao = c.CodRegiao
//
// -- Provides: NomeVendedor; group/filter by seller name
// LEFT JOIN Vendedor v ON v.CodVendedor = pv.CodVendedor
// ```
//
// > Note: Cliente and Municipio were INNER JOINs in the original report SQL.
// > If referential integrity is not guaranteed, consider LEFT JOIN when
// > re-adding them to avoid silently dropping rows.
//
// ---
//
// ## Query parameters
//
// Named params: :dataVendaInicio, :dataVendaFim, :origem
// (three binds — well within the five-bind bridge cap).
//
// Result is ordered CodEmpresa ASC, CodFilial ASC (fixed).
// No pagination — one row per branch per query execution.

abstract final class ResumoProdutoVendaLucratividadeSql {
  static const String query = '''
    SELECT
      CodEmpresa,
      CodFilial,
      COUNT(DISTINCT Id) AS QtdVendas,
      SUM(Quantidade) AS QtdItensVendido,
      SUM(Quantidade * CustoMedio) AS ValorTotalCustoMedio,
      SUM(Quantidade * CustoReposicao) AS CustoReposicao,
      SUM(Quantidade * PontoEquilibrio) AS PontoEquilibrio,
      SUM(Quantidade * ValorUnitarioLiquido) AS ValorTotalItem
    FROM (
      SELECT
        pv.CodEmpresa,
        pv.CodFilial,
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
      WHERE CAST(pv.DataVenda AS DATE) BETWEEN :dataVendaInicio AND :dataVendaFim
        AND pv.Origem = :origem
        AND tos.GeraFinanceiro = 'S'
        AND pv.PreVenda = 'N'
    ) DetalheProdutoVenda
    GROUP BY
      CodEmpresa,
      CodFilial
    ORDER BY
      CodEmpresa ASC,
      CodFilial ASC
  ''';
}

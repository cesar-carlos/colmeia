import 'package:colmeia/features/agent_queries/data/queries/agent_queries_sql_accent_fold.dart';

/// Paged product-margin catalog (`MargemProduto`) with total count in one
/// `sql.execute` round-trip.
///
/// List price vs replacement cost for every `Produto`, scoped to company
/// `1` / branch `1` (`MargemProdutoFilter.fixedCodEmpresa` /
/// `fixedCodFilial`). Not a period-sales aggregate (see
/// `ResumoProdutoVendaLucratividade` for that).
///
/// ---
///
/// ## Tables read
///
/// | Alias | Table | Role |
/// |---|---|---|
/// | `p` | `Produto` | `CodProduto`, `Nome`, `PrecoVenda`, `CodUnidadeMedida` (varchar unit code), `CodGrupoProduto`, `CodMarca` |
/// | `f` | `Filial` | `CodEmpresa`, `CodFilial`, `Nome`, `NomeFantasia` (inner — invalid branch yields empty page) |
/// | `cp` | `CustoProduto` | `CustoCompra` (optional; missing cost becomes `0`) |
/// | `gp` | `GrupoProduto` | `Nome` (optional) |
/// | `mc` | `Marca` | `Nome` (optional) |
/// | `und` | `UnidadeMedida` | `Descricao` (optional) |
///
/// ## Parameters and pagination
///
/// Named params: `:codEmpresa`, `:codFilial`, `:nomeProdutoPattern`,
/// `:startRow`, `:endRow` (five binds). Each named param appears **once**
/// — SQL Anywhere ODBC expands every `:name` to a positional `?`.
///
/// `:nomeProdutoPattern` is a contains literal (e.g. `%mel%`) from
/// `ResumoVendasDiariasSuggestionSqlParams.buildSearchPattern`, or `NULL`
/// to skip the name filter. The `LIKE` runs in `MargemProduto` before
/// `Tot` and `ROW_NUMBER`, so `totalCount` and page windows share the
/// same filtered catalog. Both sides of the `LIKE` are accent-folded and
/// uppercased (`AgentQueriesSqlAccentFold`), so `cafe` matches `Café`.
///
/// **Ordering:** fixed `NomeProduto ASC`, then `CodProduto ASC` as the
/// stable page key. `ROW_NUMBER` must stay deterministic or page 2 can
/// overlap or skip rows.
///
/// Pagination: `Parametros` → `MargemProduto` → `Tot` → `Numbered`
/// (`ROW_NUMBER`) → `Tot LEFT JOIN Numbered` on
/// `Rn BETWEEN :startRow AND :endRow`.
abstract final class MargemProdutoSql {
  static String pagedQuery() {
    final nomeFolded = AgentQueriesSqlAccentFold.foldUpper('TRIM(p.Nome)');
    final patternFolded = AgentQueriesSqlAccentFold.foldUpper(
      'prm.NomeProdutoPattern',
    );
    return '''
    WITH Parametros AS (
      SELECT
        CAST(:codEmpresa AS INTEGER) AS CodEmpresa,
        CAST(:codFilial AS INTEGER) AS CodFilial,
        CAST(:nomeProdutoPattern AS VARCHAR(255)) AS NomeProdutoPattern
    ),
    MargemProduto AS (
      SELECT
        f.CodFilial,
        f.CodEmpresa,
        f.Nome AS NomeFilial,
        f.NomeFantasia AS NomeFantasiaFilial,
        p.CodProduto,
        TRIM(p.Nome) AS NomeProduto,
        p.CodUnidadeMedida,
        und.Descricao AS DescricaoUnidadeMedida,
        p.CodGrupoProduto,
        gp.Nome AS NomeGrupoProduto,
        p.CodMarca,
        mc.Nome AS NomeMarca,
        COALESCE(cp.CustoCompra, 0.00) AS CustoReposicao,
        COALESCE(p.PrecoVenda, 0.00) AS PrecoVendaProduto,
        CASE
          WHEN COALESCE(cp.CustoCompra, 0.00) > 0.00
            AND COALESCE(p.PrecoVenda, 0.00) > 0.00
          THEN (p.PrecoVenda - cp.CustoCompra) / cp.CustoCompra * 100
          ELSE 0.00
        END AS PercentualMarkupCustoCompraProduto,
        CASE
          WHEN COALESCE(p.PrecoVenda, 0.00) > 0.00
          THEN (p.PrecoVenda - COALESCE(cp.CustoCompra, 0.00)) / p.PrecoVenda * 100.0
          ELSE 0.00
        END AS MargemLucroProduto
      FROM Produto p
      CROSS JOIN Parametros prm
      INNER JOIN Filial f ON
        f.CodEmpresa = prm.CodEmpresa
        AND f.CodFilial = prm.CodFilial
      LEFT JOIN GrupoProduto gp ON
        gp.CodGrupoProduto = p.CodGrupoProduto
      LEFT JOIN Marca mc ON
        mc.CodMarca = p.CodMarca
      LEFT JOIN UnidadeMedida und ON
        und.CodUnidadeMedida = p.CodUnidadeMedida
      LEFT JOIN CustoProduto cp ON
        cp.CodEmpresa = prm.CodEmpresa
        AND cp.CodFilial = prm.CodFilial
        AND cp.CodProduto = p.CodProduto
      WHERE p.Ativo = 'S'
        AND (
          prm.NomeProdutoPattern IS NULL
          OR $nomeFolded LIKE $patternFolded
        )
    ),
    Tot AS (
      SELECT COUNT(*) AS TotalCount FROM MargemProduto
    ),
    Numbered AS (
      SELECT
        m.*,
        ROW_NUMBER() OVER (
          ORDER BY
            m.NomeProduto ASC,
            m.CodProduto ASC
        ) AS Rn
      FROM MargemProduto m
    )
    SELECT
      Tot.TotalCount,
      N.CodEmpresa,
      N.CodFilial,
      N.NomeFilial,
      N.NomeFantasiaFilial,
      N.CodProduto,
      N.NomeProduto,
      N.CodUnidadeMedida,
      N.DescricaoUnidadeMedida,
      N.CodGrupoProduto,
      N.NomeGrupoProduto,
      N.CodMarca,
      N.NomeMarca,
      N.CustoReposicao,
      N.PrecoVendaProduto,
      N.PercentualMarkupCustoCompraProduto,
      N.MargemLucroProduto,
      N.Rn
    FROM Tot
    LEFT JOIN Numbered N ON N.Rn BETWEEN :startRow AND :endRow
    ORDER BY COALESCE(N.Rn, 2147483647)
  ''';
  }
}

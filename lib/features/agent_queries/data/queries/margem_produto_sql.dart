import 'package:colmeia/features/agent_queries/domain/entities/margem_produto_sort_by.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_sort_direction.dart';

/// Paged product-margin catalog (`MargemProduto`) with total count in one
/// `sql.execute` round-trip.
///
/// List price vs replacement cost for every `Produto`, scoped to one
/// company/branch. Not a period-sales aggregate (see
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
/// Named params: `:codEmpresa`, `:codFilial`, `:startRow`, `:endRow`
/// (four binds). Each named param appears **once** — SQL Anywhere ODBC
/// expands every `:name` to a positional `?`.
///
/// **Ordering:** primary column from [MargemProdutoSortBy] with
/// [ResumoProdutoVendaSortDirection]; stable tie-breaker `CodProduto ASC`.
///
/// Pagination: `Parametros` → `MargemProduto` → `Tot` → `Numbered`
/// (`ROW_NUMBER`) → `Tot LEFT JOIN Numbered` on
/// `Rn BETWEEN :startRow AND :endRow`.
abstract final class MargemProdutoSql {
  static String pagedQuery({
    required MargemProdutoSortBy sortBy,
    required ResumoProdutoVendaSortDirection sortDirection,
  }) {
    final dir = switch (sortDirection) {
      ResumoProdutoVendaSortDirection.ascending => 'ASC',
      ResumoProdutoVendaSortDirection.descending => 'DESC',
    };

    final rowNumberOrderBy = switch (sortBy) {
      MargemProdutoSortBy.nomeProduto =>
        '\n            m.NomeProduto $dir,'
            '\n            m.CodProduto ASC',
      MargemProdutoSortBy.custoReposicao =>
        '\n            m.CustoReposicao $dir,'
            '\n            m.CodProduto ASC',
      MargemProdutoSortBy.percentualMarkup =>
        '\n            m.PercentualMarkupCustoCompraProduto $dir,'
            '\n            m.CodProduto ASC',
      MargemProdutoSortBy.margemLucroProduto =>
        '\n            m.MargemLucroProduto $dir,'
            '\n            m.CodProduto ASC',
    };

    return '''
    WITH Parametros AS (
      SELECT
        CAST(:codEmpresa AS INTEGER) AS CodEmpresa,
        CAST(:codFilial AS INTEGER) AS CodFilial
    ),
    MargemProduto AS (
      SELECT
        f.CodFilial,
        f.CodEmpresa,
        f.Nome AS NomeFilial,
        f.NomeFantasia AS NomeFantasiaFilial,
        p.CodProduto,
        p.Nome AS NomeProduto,
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
    ),
    Tot AS (
      SELECT COUNT(*) AS TotalCount FROM MargemProduto
    ),
    Numbered AS (
      SELECT
        m.*,
        ROW_NUMBER() OVER (
          ORDER BY
            $rowNumberOrderBy
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

import 'package:colmeia/features/agent_queries/data/queries/agent_queries_sql_accent_fold.dart';
import 'package:colmeia/features/agent_queries/domain/entities/margem_produto_sort_by.dart';
import 'package:colmeia/features/agent_queries/domain/entities/margem_produto_sort_direction.dart';

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
/// | `p` | `Produto` | `CodProduto`, `Nome`, `PrecoVenda`, `CodGrupoProduto`, `CodMarca` |
/// | `f` | `Filial` | `CodEmpresa`, `CodFilial`, `Nome`, `NomeFantasia` (inner — invalid branch yields empty page) |
/// | `cp` | `CustoProduto` | `CustoCompra` (optional; missing cost stays `NULL`) |
/// | `gp` | `GrupoProduto` | `Nome` (optional) |
/// | `mc` | `Marca` | `Nome` (optional) |
///
/// ## Parameters and pagination
///
/// Named params: `:codEmpresa`, `:codFilial`, `:startRow`, `:endRow`, and
/// `:nomeProdutoPattern` only when `applySearch` is true. Each named param
/// appears **once** — SQL Anywhere ODBC expands every `:name` to a positional
/// `?`.
///
/// When `applySearch` is false the catalog is unfiltered (`p.Ativo = 'S'`
/// only). That keeps default page loads off accent-folded `LIKE '%…%'` scans.
/// When true, `:nomeProdutoPattern` is a contains literal (e.g. `%mel%`) from
/// `ResumoVendasDiariasSuggestionSqlParams.buildSearchPattern`. The `LIKE`
/// runs in `MargemProduto` before `Tot` and `ROW_NUMBER`, so `totalCount` and
/// page windows share the same filtered catalog. Match is on product name
/// (accent-folded), `CAST(CodProduto)`, group name, or brand name. Both sides
/// of name `LIKE` are accent-folded and uppercased
/// (`AgentQueriesSqlAccentFold`), so `cafe` matches `Café`.
///
/// **Ordering:** `ROW_NUMBER` uses a Dart whitelist ([MargemProdutoSortBy]).
/// Default is `NomeProduto ASC`, then `CodProduto ASC`. `ROW_NUMBER` must
/// stay deterministic or page 2 can overlap or skip rows.
///
/// Pagination: `Parametros` → `MargemProduto` → `Tot` → `Numbered`
/// (`ROW_NUMBER`) → `Tot LEFT JOIN Numbered` on
/// `Rn BETWEEN :startRow AND :endRow`.
abstract final class MargemProdutoSql {
  static String pagedQuery({
    MargemProdutoSortBy sortBy = MargemProdutoSortBy.nomeProduto,
    MargemProdutoSortDirection sortDirection =
        MargemProdutoSortDirection.ascending,
    bool applySearch = false,
  }) {
    final rowNumberOrderBy = _rowNumberOrderBy(
      sortBy: sortBy,
      sortDirection: sortDirection,
    );
    final parametrosSelect = applySearch
        ? '''
        CAST(:codEmpresa AS INTEGER) AS CodEmpresa,
        CAST(:codFilial AS INTEGER) AS CodFilial,
        CAST(:nomeProdutoPattern AS VARCHAR(255)) AS NomeProdutoPattern'''
        : '''
        CAST(:codEmpresa AS INTEGER) AS CodEmpresa,
        CAST(:codFilial AS INTEGER) AS CodFilial''';
    return '''
    WITH Parametros AS (
      SELECT
        $parametrosSelect
    ),
    MargemProduto AS (
      SELECT
        f.CodFilial,
        f.CodEmpresa,
        f.Nome AS NomeFilial,
        f.NomeFantasia AS NomeFantasiaFilial,
        p.CodProduto,
        TRIM(p.Nome) AS NomeProduto,
        p.CodGrupoProduto,
        gp.Nome AS NomeGrupoProduto,
        p.CodMarca,
        mc.Nome AS NomeMarca,
        cp.CustoCompra AS CustoReposicao,
        COALESCE(p.PrecoVenda, 0.00) AS PrecoVendaProduto,
        CASE
          WHEN cp.CustoCompra IS NULL THEN NULL
          WHEN cp.CustoCompra > 0.00
            AND COALESCE(p.PrecoVenda, 0.00) > 0.00
          THEN (p.PrecoVenda - cp.CustoCompra) / cp.CustoCompra * 100
          ELSE 0.00
        END AS PercentualMarkupCustoCompraProduto,
        CASE
          WHEN cp.CustoCompra IS NULL THEN NULL
          WHEN COALESCE(p.PrecoVenda, 0.00) > 0.00
          THEN (p.PrecoVenda - cp.CustoCompra) / p.PrecoVenda * 100.0
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
      LEFT JOIN CustoProduto cp ON
        cp.CodEmpresa = prm.CodEmpresa
        AND cp.CodFilial = prm.CodFilial
        AND cp.CodProduto = p.CodProduto
      WHERE p.Ativo = 'S'${_searchPredicate(applySearch: applySearch)}
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

  static String _searchPredicate({required bool applySearch}) {
    if (!applySearch) {
      return '';
    }
    final nomeFolded = AgentQueriesSqlAccentFold.foldUpper('TRIM(p.Nome)');
    final grupoFolded = AgentQueriesSqlAccentFold.foldUpper(
      "COALESCE(gp.Nome, '')",
    );
    final marcaFolded = AgentQueriesSqlAccentFold.foldUpper(
      "COALESCE(mc.Nome, '')",
    );
    final patternFolded = AgentQueriesSqlAccentFold.foldUpper(
      'prm.NomeProdutoPattern',
    );
    return '''
        AND (
          $nomeFolded LIKE $patternFolded
          OR CAST(p.CodProduto AS VARCHAR(20)) LIKE prm.NomeProdutoPattern
          OR $grupoFolded LIKE $patternFolded
          OR $marcaFolded LIKE $patternFolded
        )''';
  }

  static String _rowNumberOrderBy({
    required MargemProdutoSortBy sortBy,
    required MargemProdutoSortDirection sortDirection,
  }) {
    final dir = switch (sortDirection) {
      MargemProdutoSortDirection.ascending => 'ASC',
      MargemProdutoSortDirection.descending => 'DESC',
    };
    final primary = switch (sortBy) {
      MargemProdutoSortBy.codProduto => 'm.CodProduto',
      MargemProdutoSortBy.nomeProduto => 'm.NomeProduto',
      MargemProdutoSortBy.nomeGrupoProduto => 'm.NomeGrupoProduto',
      MargemProdutoSortBy.nomeMarca => 'm.NomeMarca',
      MargemProdutoSortBy.custoReposicao => 'm.CustoReposicao',
      MargemProdutoSortBy.precoVendaProduto => 'm.PrecoVendaProduto',
      MargemProdutoSortBy.percentualMarkup =>
        'm.PercentualMarkupCustoCompraProduto',
      MargemProdutoSortBy.margemLucro => 'm.MargemLucroProduto',
    };
    final tiebreakers = switch (sortBy) {
      MargemProdutoSortBy.codProduto => 'm.NomeProduto ASC',
      MargemProdutoSortBy.nomeProduto => 'm.CodProduto ASC',
      _ => 'm.NomeProduto ASC,\n            m.CodProduto ASC',
    };
    return '''
            $primary $dir,
            $tiebreakers''';
  }
}

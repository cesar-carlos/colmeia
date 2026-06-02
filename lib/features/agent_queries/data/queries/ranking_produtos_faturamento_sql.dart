/// Product billing ranking by `ValorVenda` (`RankingProdutosFaturamento`) —
/// one `sql.execute` round-trip.
///
/// ## Engine compatibility
///
/// Written for **Microsoft SQL Server** (2005+, window functions) and
/// **SAP SQL Anywhere** (Sybase ODBC). Same text is sent to every agent; do not
/// add dialect-specific branches unless a second validated query is added.
///
/// Patterns avoided on both engines (they caused `Invalid expression near
/// 'SUM'` or `Invalid use of an aggregate` on SQL Anywhere):
///
/// - `SELECT *, ROW_NUMBER() …` in one projection list
/// - `SUM(CASE WHEN …)` plus non-grouped literals in the same `GROUP BY`
/// - `SUM(…) OVER (PARTITION BY …)` on the outer `SELECT` after `UNION ALL`
/// - Inline subquery on `Resultado` for branch totals (use `TotaisPorFilial` CTE)
///
/// DIVERSOS uses `DiversosBase` (aggregate only grouped keys) then `DiversosAgg`
/// (constants in a non-grouped outer select). Percentual uses `TotaisPorFilial`
/// plus `NULLIF`, not windowed `SUM`.
///
/// ## Tables read
///
/// | Alias | Table | Role |
/// | ----- | ----- | ---- |
/// | `ipv` | `ItemProdutoVendido` | quantity and net unit value |
/// | `pv` | `ProdutoVendido` | sale date, origin, branch keys |
/// | `tos` | `TipoOperacaoSaida` | `GeraFinanceiro` filter |
/// | `p` | `Produto` | product name and unit |
/// | `gp` | `GrupoProduto` | product group |
///
/// ## Parameters (bridge limit: 5 named params)
///
/// Default `buildQuery`: `:dataVendaInicio`, `:dataVendaFim`,
/// `:quantidadeProdutos`, `:origem`, `:preVenda`.
///
/// Single-branch `buildQuery` with `restrictToSingleBranch: true`:
/// `:dataVendaInicio`, `:dataVendaFim`, `:quantidadeProdutos`, `:codEmpresa`,
/// `:codFilial`. `pv.Origem` and `pv.PreVenda` are inlined from validated
/// filter values (same literals as named params in the default query).
///
/// ## Ranking scope
///
/// Per branch: `ROW_NUMBER() OVER (PARTITION BY CodEmpresa, CodFilial
/// ORDER BY ValorVenda DESC)`.
///
/// ## DIVERSOS row
///
/// One aggregate per branch for products with `Posicao > :quantidadeProdutos`,
/// using real `CodEmpresa`/`CodFilial` (no 9999 sentinels). Ordering places
/// DIVERSOS after ranked products within each branch.
abstract final class RankingProdutosFaturamentoSql {
  /// Column list shared by `TopProdutos`, `DiversosAgg`, and `Resultado` so
  /// `UNION ALL` types align on SQL Server and SQL Anywhere.
  static const String _resultRowColumns = '''
        CodEmpresa,
        CodFilial,
        CodProduto,
        NomeProduto,
        CodUnidadeMedida,
        CodGrupoProduto,
        NomeGrupoProduto,
        ValorVenda,
        Posicao''';

  static String buildQuery({
    required bool restrictToSingleBranch,
    required String origem,
    required String preVenda,
  }) {
    final salesSourceFilter = restrictToSingleBranch
        ? '''
      AND pv.CodEmpresa = :codEmpresa
      AND pv.CodFilial = :codFilial
      AND pv.Origem = ${_sqlStringLiteral(origem)}
      AND pv.PreVenda = ${_sqlStringLiteral(preVenda)}'''
        : '''
      AND pv.Origem = :origem
      AND pv.PreVenda = :preVenda''';

    return '''
WITH Produtos AS (
    SELECT
        pv.CodEmpresa,
        pv.CodFilial,
        ipv.CodProduto,
        p.Nome AS NomeProduto,
        p.CodUnidadeMedida AS CodUnidadeMedida,
        p.CodGrupoProduto AS CodGrupoProduto,
        gp.Nome AS NomeGrupoProduto,
        SUM(ipv.Quantidade * ipv.ValorUnitarioLiquido) AS ValorVenda
    FROM ItemProdutoVendido ipv
    INNER JOIN ProdutoVendido pv ON
        pv.CodEmpresa = ipv.CodEmpresa
    AND pv.CodProdutoVendido = ipv.CodProdutoVendido
    INNER JOIN TipoOperacaoSaida tos ON
        tos.CodEmpresa = pv.CodEmpresa
    AND tos.CodTipoOperacaoSaida = pv.CodTipoOperacaoSaida
    INNER JOIN Produto p ON
        p.CodProduto = ipv.CodProduto
    INNER JOIN GrupoProduto gp ON
        gp.CodGrupoProduto = p.CodGrupoProduto
    WHERE CAST(pv.DataVenda AS DATE) BETWEEN :dataVendaInicio AND :dataVendaFim
      AND COALESCE(tos.GeraFinanceiro, 'N') = 'S'$salesSourceFilter
    GROUP BY
        pv.CodEmpresa,
        pv.CodFilial,
        ipv.CodProduto,
        p.Nome,
        p.CodUnidadeMedida,
        p.CodGrupoProduto,
        gp.Nome
),
Ranking AS (
    SELECT
        CodEmpresa,
        CodFilial,
        CodProduto,
        NomeProduto,
        CodUnidadeMedida,
        CodGrupoProduto,
        NomeGrupoProduto,
        ValorVenda,
        ROW_NUMBER() OVER (
            PARTITION BY CodEmpresa, CodFilial
            ORDER BY ValorVenda DESC
        ) AS Posicao
    FROM Produtos
),
TopProdutos AS (
    SELECT
$_resultRowColumns
    FROM Ranking
    WHERE Posicao <= :quantidadeProdutos
),
DiversosBase AS (
    SELECT
        r.CodEmpresa,
        r.CodFilial,
        SUM(r.ValorVenda) AS ValorVenda
    FROM Ranking r
    WHERE r.Posicao > :quantidadeProdutos
    GROUP BY r.CodEmpresa, r.CodFilial
),
DiversosAgg AS (
    SELECT
        d.CodEmpresa,
        d.CodFilial,
        CAST(0 AS INTEGER) AS CodProduto,
        CAST('DIVERSOS' AS VARCHAR(50)) AS NomeProduto,
        CAST(NULL AS VARCHAR(50)) AS CodUnidadeMedida,
        CAST(NULL AS INTEGER) AS CodGrupoProduto,
        CAST(NULL AS VARCHAR(50)) AS NomeGrupoProduto,
        d.ValorVenda,
        CAST(NULL AS INTEGER) AS Posicao
    FROM DiversosBase d
    WHERE d.ValorVenda > 0
),
Resultado AS (
    SELECT
$_resultRowColumns
    FROM TopProdutos
    UNION ALL
    SELECT
$_resultRowColumns
    FROM DiversosAgg
),
TotaisPorFilial AS (
    SELECT
        CodEmpresa,
        CodFilial,
        SUM(ValorVenda) AS TotalVenda
    FROM Resultado
    GROUP BY CodEmpresa, CodFilial
)
SELECT
    r.CodEmpresa,
    r.CodFilial,
    r.CodProduto,
    r.NomeProduto,
    r.CodUnidadeMedida,
    r.CodGrupoProduto,
    r.NomeGrupoProduto,
    r.ValorVenda,
    r.Posicao,
    ROUND(
      r.ValorVenda * 100.0 / NULLIF(t.TotalVenda, 0),
      2
    ) AS Percentual
FROM Resultado r
INNER JOIN TotaisPorFilial t ON
    r.CodEmpresa = t.CodEmpresa
AND r.CodFilial = t.CodFilial
ORDER BY
    r.CodEmpresa,
    r.CodFilial,
    CASE WHEN r.NomeProduto = 'DIVERSOS' THEN 1 ELSE 0 END,
    r.ValorVenda DESC
''';
  }

  static String _sqlStringLiteral(String value) {
    if (value.contains("'")) {
      throw ArgumentError('origem/preVenda must not contain single quotes');
    }
    return "'$value'";
  }
}

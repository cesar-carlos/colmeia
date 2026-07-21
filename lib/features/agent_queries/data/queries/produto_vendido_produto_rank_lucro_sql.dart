import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_produto_rank_lucro_sort_by.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_sort_direction.dart';

/// Top product ranking by quantity sold and profit metrics
/// (`ProdutoVendidoProdutoRankLucro`) — one `sql.execute` round-trip.
///
/// ---
///
/// ## Tables read (`Resumo` CTE)
///
/// | Alias | Table | Role |
/// |---|---|---|
/// | `ipv` | `ItemProdutoVendido` | `Quantidade`, `QuantidadeConvertida`, `ValorUnitarioLiquido`, `CodProduto`, `NomeProduto` |
/// | `pv` | `ProdutoVendido` | `CodEmpresa`, `CodFilial`, `DataVenda`, `Origem`, `PreVenda`, `CodTipoOperacaoSaida`, `CodProdutoVendido` |
/// | `tos` | `TipoOperacaoSaida` | `GeraFinanceiro` (filter) |
/// | `p` | `Produto` | `CodProduto` (join key) |
/// | `gp` | `GrupoProduto` | `CodGrupoProduto`, `Nome` (optional) |
/// | `m` | `Marca` | `CodMarca`, `Nome` (optional) |
/// | `cp` | `CustoProduto` | `CustoCompra` (optional) |
///
/// ## Parameters
///
/// Named params: `:dataVendaInicio`, `:dataVendaFim`, `:origem` (three binds).
///
/// **Ordering:** outer `Resultado` — primary column from
/// [ProdutoVendidoProdutoRankLucroSortBy]; stable tie-breakers:
/// `CodEmpresa ASC`, `CodFilial ASC`, `CodProduto ASC`.
///
/// Result capped at 15 rows (`TOP 15`).

abstract final class ProdutoVendidoProdutoRankLucroSql {
  static String query({
    required ProdutoVendidoProdutoRankLucroSortBy sortBy,
    ResumoProdutoVendaSortDirection sortDirection =
        ResumoProdutoVendaSortDirection.descending,
  }) {
    final orderBy = _orderByClause(
      sortBy: sortBy,
      sortDirection: sortDirection,
    );
    return '''
WITH Resumo AS (
    SELECT
        pv.CodEmpresa,
        pv.CodFilial,
        ipv.CodProduto,
        ipv.NomeProduto,
        gp.CodGrupoProduto,
        gp.Nome NomeGrupoProduto,
        m.CodMarca,
        m.Nome NomeMarca,
        COALESCE(SUM(ipv.Quantidade), 0) AS QtdItensVendido,
        COALESCE(SUM(ipv.Quantidade * ipv.ValorUnitarioLiquido), 0) AS ValorTotal,
        COALESCE(SUM(ipv.QuantidadeConvertida * cp.CustoCompra), 0) AS CustoTotal
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
    LEFT JOIN CustoProduto cp ON
        cp.CodEmpresa = pv.CodEmpresa
        AND cp.CodFilial = pv.CodFilial
        AND cp.CodProduto = ipv.CodProduto
    WHERE pv.DataVenda >= CAST(:dataVendaInicio AS DATE)
      AND pv.DataVenda < DATEADD(day, 1, CAST(:dataVendaFim AS DATE))
      AND pv.Origem = :origem
      AND COALESCE(tos.GeraFinanceiro, 'N') = 'S'
      AND pv.PreVenda = 'N'
    GROUP BY
        pv.CodEmpresa,
        pv.CodFilial,
        ipv.CodProduto,
        ipv.NomeProduto,
        p.CodProduto,
        gp.CodGrupoProduto,
        gp.Nome,
        m.CodMarca,
        m.Nome
)
SELECT TOP 15 *
FROM (
    SELECT
        CodEmpresa,
        CodFilial,
        CodProduto,
        NomeProduto,
        CodGrupoProduto,
        NomeGrupoProduto,
        CodMarca,
        NomeMarca,
        QtdItensVendido,
        ValorTotal,
        CustoTotal,
        CASE WHEN QtdItensVendido > 0
            THEN ROUND(((ValorTotal - CustoTotal) / QtdItensVendido), 4)
            ELSE 0
        END LucroUnitario,
        (ValorTotal - CustoTotal) AS TotalValorLucro
    FROM Resumo
) Resultado
ORDER BY
    $orderBy
''';
  }

  static String _orderByClause({
    required ProdutoVendidoProdutoRankLucroSortBy sortBy,
    required ResumoProdutoVendaSortDirection sortDirection,
  }) {
    final dir = switch (sortDirection) {
      ResumoProdutoVendaSortDirection.ascending => 'ASC',
      ResumoProdutoVendaSortDirection.descending => 'DESC',
    };
    final primary = switch (sortBy) {
      ProdutoVendidoProdutoRankLucroSortBy.qtdItensVendido =>
        'Resultado.QtdItensVendido $dir',
      ProdutoVendidoProdutoRankLucroSortBy.totalValorLucro =>
        'Resultado.TotalValorLucro $dir',
    };
    return '$primary,\n'
        '        Resultado.CodEmpresa ASC,\n'
        '        Resultado.CodFilial ASC,\n'
        '        Resultado.CodProduto ASC';
  }
}

import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_sort_by.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_sort_direction.dart';

/// Paged product sales summary (`ResumoProdutoVenda`) with total count in one
/// `sql.execute` round-trip.
///
/// ---
///
/// ## Active joins and columns in `DetalheProdutoVenda`
///
/// The CTE only projects the columns consumed by `Agregada`. Any addition for
/// future display or filtering must be added here first.
///
/// | Alias | Table | Active columns |
/// |---|---|---|
/// | `ipv` | `ItemProdutoVendido` | `CodProduto`, `NomeProduto`, `Quantidade`, `PontoEquilibrio`, `ValorUnitarioLiquido` |
/// | `pv` | `ProdutoVendido` | `CodEmpresa`, `CodFilial`, `CodProdutoVendido` (→ `Id`), `DataVenda`, `Origem`, `PreVenda`, `CodTipoOperacaoSaida` |
/// | `p` | `Produto` | `CodGrupoProduto`, `CodMarca` |
/// | `cp` | `CustoProduto` | `CustoMedioPonderado` (→ `CustoMedio`), `CustoCompra` (→ `CustoReposicao`) |
/// | `mc` | `Marca` | `Nome` (→ `NomeMarca`) |
/// | `gp` | `GrupoProduto` | `Nome` (→ `NomeGrupoProduto`), `CodTipoGrupoProduto` |
/// | `tgp` | `TipoGrupoProduto` | `Descricao` (→ `DescricaoTipoGrupoProduto`) |
/// | `tos` | `TipoOperacaoSaida` | `GeraFinanceiro` (filter only — not projected) |
///
/// ## Columns available from active joins but not currently projected
///
/// Add these to the `DetalheProdutoVenda` SELECT when needed:
///
/// | Table alias | Column | Use case |
/// |---|---|---|
/// | `pv` | `CodVendedor` | filter / group by seller |
/// | `pv` | `CodCliente`, `NomeCliente` | filter / group by client |
/// | `pv` | `CodMunicipio` | prerequisite for Municipio join |
/// | `ipv` | `CodUnidadeMedida` | unit-of-measure display |
/// | `ipv` | `PrecoUnitario` | unit price display or margin analysis |
/// | `ipv` | `ItemProdutoVendido` | line-item reference |
/// | `cp` | `UltimoPrecoCompra` (→ `CustoCompra`) | last purchase price display |
///
/// ## Extension joins (not active — add to `DetalheProdutoVenda` to enable)
///
/// These joins and their columns were removed because they do not contribute
/// to the current aggregation. Re-add them to support the corresponding
/// filters or display columns:
///
/// ```sql
/// -- Provides: CodGrupoCliente, CodRegiao (prerequisite for GrupoCliente and Regiao joins)
/// INNER JOIN Cliente c ON c.CodCliente = pv.CodCliente
///
/// -- Provides: NomeMunicipio, UFMunicipio; group/filter by city or state
/// INNER JOIN Municipio m ON m.CodMunicipio = pv.CodMunicipio
///
/// -- Provides: NomeGrupoCliente; requires Cliente join above
/// LEFT JOIN GrupoCliente gc ON gc.CodGrupoCliente = c.CodGrupoCliente
///
/// -- Provides: NomeRegiao; requires Cliente join above
/// LEFT JOIN Regiao r ON r.CodRegiao = c.CodRegiao
///
/// -- Provides: NomeVendedor; group/filter by seller name
/// LEFT JOIN Vendedor v ON v.CodVendedor = pv.CodVendedor
/// ```
///
/// > **Note:** `Cliente` and `Municipio` were previously `INNER JOIN`s. If
/// > referential integrity is not guaranteed (orphaned sales), consider using
/// > `LEFT JOIN` when re-adding them to avoid silently dropping rows.
///
/// ---
///
/// ## Query parameters and pagination
///
/// Named params: `:dataVendaInicio`, `:dataVendaFim`, `:origem`, `:startRow`,
/// `:endRow` (five binds — bridge cap).
///
/// **Ordering:** `CodEmpresa ASC, CodFilial ASC` always lead. The sort column
/// chosen via the filter sets the next primary column; remaining group-by
/// columns follow as stable tiebreakers. Default (`nomeProduto ASC`) produces:
/// empresa, filial, nomeProduto ASC, codProduto ASC, qtdVendas DESC.
///
/// Pagination: `Agregada` → `Tot` → `Numbered` (`ROW_NUMBER`) →
/// `Tot LEFT JOIN Numbered` on `Rn BETWEEN :startRow AND :endRow`.

abstract final class ResumoProdutoVendaSql {
  static String pagedQuery({
    required ResumoProdutoVendaSortBy sortBy,
    ResumoProdutoVendaSortDirection sortDirection =
        ResumoProdutoVendaSortDirection.ascending,
  }) {
    final dir = switch (sortDirection) {
      ResumoProdutoVendaSortDirection.ascending => 'ASC',
      ResumoProdutoVendaSortDirection.descending => 'DESC',
    };

    // empresa/filial are always the leading sort columns (fixed, non-removable).
    // Each sortBy value defines the primary column and the stable tiebreaker
    // sequence that follows.
    final rowNumberOrderBy = switch (sortBy) {
      ResumoProdutoVendaSortBy.codProduto =>
        '\n            a.CodEmpresa ASC,\n            a.CodFilial ASC,'
            '\n            a.CodProduto $dir,'
            '\n            a.NomeProduto ASC,'
            '\n            a.QtdVendas DESC,'
            '\n            a.CodGrupoProduto ASC,'
            '\n            a.NomeGrupoProduto ASC,'
            '\n            a.CodMarca ASC,'
            '\n            a.NomeMarca ASC,'
            '\n            a.CodTipoGrupoProduto ASC,'
            '\n            a.DescricaoTipoGrupoProduto ASC',
      ResumoProdutoVendaSortBy.qtdVendas =>
        '\n            a.CodEmpresa ASC,\n            a.CodFilial ASC,'
            '\n            a.QtdVendas $dir,'
            '\n            a.CodProduto ASC,'
            '\n            a.NomeProduto ASC,'
            '\n            a.CodGrupoProduto ASC,'
            '\n            a.NomeGrupoProduto ASC,'
            '\n            a.CodMarca ASC,'
            '\n            a.NomeMarca ASC,'
            '\n            a.CodTipoGrupoProduto ASC,'
            '\n            a.DescricaoTipoGrupoProduto ASC',
      ResumoProdutoVendaSortBy.nomeProduto =>
        '\n            a.CodEmpresa ASC,\n            a.CodFilial ASC,'
            '\n            a.NomeProduto $dir,'
            '\n            a.CodProduto ASC,'
            '\n            a.QtdVendas DESC,'
            '\n            a.CodGrupoProduto ASC,'
            '\n            a.NomeGrupoProduto ASC,'
            '\n            a.CodMarca ASC,'
            '\n            a.NomeMarca ASC,'
            '\n            a.CodTipoGrupoProduto ASC,'
            '\n            a.DescricaoTipoGrupoProduto ASC',
    };

    return '''
    WITH DetalheProdutoVenda AS (
      SELECT
        pv.CodEmpresa,
        pv.CodFilial,
        CAST(pv.CodEmpresa AS VARCHAR) + '-' +
          CAST(pv.CodFilial AS VARCHAR) + '-' +
          CAST(pv.CodProdutoVendido AS VARCHAR) AS Id,
        ipv.CodProduto,
        ipv.NomeProduto,
        p.CodGrupoProduto,
        gp.Nome AS NomeGrupoProduto,
        gp.CodTipoGrupoProduto,
        tgp.Descricao AS DescricaoTipoGrupoProduto,
        p.CodMarca,
        mc.Nome AS NomeMarca,
        ipv.Quantidade,
        COALESCE(ipv.PontoEquilibrio, 0.00) AS PontoEquilibrio,
        COALESCE(cp.CustoMedioPonderado, 0.00) AS CustoMedio,
        COALESCE(cp.CustoCompra, 0.00) AS CustoReposicao,
        ipv.ValorUnitarioLiquido
      FROM ItemProdutoVendido ipv
      INNER JOIN ProdutoVendido pv ON
        pv.CodEmpresa = ipv.CodEmpresa
        AND pv.CodProdutoVendido = ipv.CodProdutoVendido
      INNER JOIN Produto p ON
        p.CodProduto = ipv.CodProduto
      LEFT JOIN CustoProduto cp ON
        cp.CodEmpresa = pv.CodEmpresa
        AND cp.CodFilial = pv.CodFilial
        AND cp.CodProduto = ipv.CodProduto
      LEFT JOIN Marca mc ON
        mc.CodMarca = p.CodMarca
      LEFT JOIN GrupoProduto gp ON
        gp.CodGrupoProduto = p.CodGrupoProduto
      LEFT JOIN TipoGrupoProduto tgp ON
        tgp.CodTipoGrupoProduto = gp.CodTipoGrupoProduto
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
        CodProduto,
        NomeProduto,
        CodGrupoProduto,
        NomeGrupoProduto,
        CodMarca,
        NomeMarca,
        CodTipoGrupoProduto,
        DescricaoTipoGrupoProduto,
        COUNT(DISTINCT Id) AS QtdVendas,
        SUM(Quantidade) AS QtdItensVendido,
        SUM(Quantidade * CustoMedio) AS ValorTotalCustoMedio,
        SUM(Quantidade * CustoReposicao) AS CustoReposicao,
        SUM(Quantidade * PontoEquilibrio) AS PontoEquilibrio,
        SUM(Quantidade * ValorUnitarioLiquido) AS ValorTotalItem
      FROM DetalheProdutoVenda
      GROUP BY
        CodEmpresa,
        CodFilial,
        CodProduto,
        NomeProduto,
        CodGrupoProduto,
        NomeGrupoProduto,
        CodMarca,
        NomeMarca,
        CodTipoGrupoProduto,
        DescricaoTipoGrupoProduto
    ),
    Tot AS (
      SELECT COUNT(*) AS TotalCount FROM Agregada
    ),
    Numbered AS (
      SELECT
        a.*,
        ROW_NUMBER() OVER (
          ORDER BY
            $rowNumberOrderBy
        ) AS Rn
      FROM Agregada a
    )
    SELECT
      Tot.TotalCount,
      N.CodEmpresa,
      N.CodFilial,
      N.CodProduto,
      N.NomeProduto,
      N.CodGrupoProduto,
      N.NomeGrupoProduto,
      N.CodMarca,
      N.NomeMarca,
      N.CodTipoGrupoProduto,
      N.DescricaoTipoGrupoProduto,
      N.QtdVendas,
      N.QtdItensVendido,
      N.ValorTotalCustoMedio,
      N.CustoReposicao,
      N.PontoEquilibrio,
      N.ValorTotalItem,
      N.Rn
    FROM Tot
    LEFT JOIN Numbered N ON N.Rn BETWEEN :startRow AND :endRow
    ORDER BY COALESCE(N.Rn, 2147483647)
  ''';
  }
}

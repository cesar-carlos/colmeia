import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_row_number_ordering.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_sort_by.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_sort_direction.dart';

/// Paged product sales summary (`ResumoProdutoVenda`) with total count in one
/// `sql.execute` round-trip.
///
/// **Tables read:** `ItemProdutoVendido`, `Produto`, `Marca`, `GrupoProduto`,
/// `TipoGrupoProduto`, `ProdutoVendido`, `ParcelaProdutoVendido` (first parcel
/// row per sale for `GeraFinanceiro`, matching `ParcelaProdutoVendidoDetalheSql`),
/// `TipoOperacaoSaida`, `Cliente`, `Municipio`, `GrupoCliente`, `Regiao`,
/// `Vendedor`.
///
/// Named params: `:dataVendaInicio`, `:dataVendaFim`, `:origem`, `:startRow`,
/// `:endRow` (five binds — bridge cap).
///
/// **Performance:** `CAST(pv.DataVenda AS DATE)` and `PreVenda` are applied on
/// the `ProdutoVendido` join to shrink the working set before optional joins.
/// `ParcelaProdutoVendido` is touched only via an aggregate that picks the
/// minimum `NumeroParcela` per sale — index `(CodEmpresa, CodProdutoVendido,
/// NumeroParcela)` helps.
///
/// `PreVenda = 'N'` and financeiro `= 'S'` stay in SQL for v1 (named-param
/// budget). Inner projection stays wide for future `WHERE` filters; the outer
/// aggregate lists explicit columns only.
///
/// Pagination: `Agregada` → `Tot` → `Numbered` (`ROW_NUMBER` with stable
/// `ORDER BY`) → `Tot LEFT JOIN Numbered` on `Rn BETWEEN :startRow AND :endRow`.
///
/// `pagedQuery`: `sortBy` / `sortDirection` definem a métrica. `rowNumberOrdering`
/// escolhe se empresa/filial vêm antes da métrica (`ledgerDefault`) ou a métrica
/// primeiro para ranking global (`metricGlobal`). Desempates: `CodProduto` e
/// demais colunas do `GROUP BY` em **crescente** (sem bind extra).

abstract final class ResumoProdutoVendaSql {
  static String pagedQuery({
    required ResumoProdutoVendaSortBy sortBy,
    ResumoProdutoVendaSortDirection sortDirection =
        ResumoProdutoVendaSortDirection.descending,
    ResumoProdutoVendaRowNumberOrdering rowNumberOrdering =
        ResumoProdutoVendaRowNumberOrdering.ledgerDefault,
  }) {
    final metricDir = switch (sortDirection) {
      ResumoProdutoVendaSortDirection.ascending => 'ASC',
      ResumoProdutoVendaSortDirection.descending => 'DESC',
    };
    final rowNumberMetricOrder = switch (sortBy) {
      ResumoProdutoVendaSortBy.qtdVendas => 'a.QtdVendas $metricDir',
      ResumoProdutoVendaSortBy.qtdItensVendido =>
        'a.QtdItensVendido $metricDir',
      ResumoProdutoVendaSortBy.percentualLucro =>
        'a.PercentualLucro $metricDir',
    };
    final rowNumberOrderByLeading = switch (rowNumberOrdering) {
      ResumoProdutoVendaRowNumberOrdering.ledgerDefault =>
        'a.CodEmpresa ASC,\n            a.CodFilial ASC,\n            $rowNumberMetricOrder',
      ResumoProdutoVendaRowNumberOrdering.metricGlobal =>
        '$rowNumberMetricOrder,\n            a.CodEmpresa ASC,\n            a.CodFilial ASC',
    };
    return '''
    WITH DetalheProdutoVenda AS (
      SELECT
        pv.CodEmpresa,
        pv.CodFilial,
        pv.CodProdutoVendido,
        pv.Origem AS Origem,
        pv.CodOrigem AS CodOrigem,
        CAST(pv.CodEmpresa AS VARCHAR) + '-' +
          CAST(pv.CodFilial AS VARCHAR) + '-' +
          CAST(pv.CodProdutoVendido AS VARCHAR) AS Id,
        pv.CodTipoOperacaoSaida,
        tos.Descricao AS DescricaoTipoOperacaoSaida,
        COALESCE(
          SUBSTRING(ppv_head.ParcelaGeraFinanceiro, 1, 1),
          tos.GeraFinanceiro
        ) AS GeraFinanceiro,
        pv.PreVenda AS PreVenda,
        pv.CodVendedor,
        v.Nome AS NomeVendedor,
        pv.CodCliente,
        pv.NomeCliente,
        c.CodGrupoCliente,
        gc.nome AS NomeGrupoCliente,
        pv.CodMunicipio,
        m.Nome AS NomeMunicipio,
        m.UF AS UFMunicipio,
        c.CodRegiao,
        r.Nome AS NomeRegiao,
        CAST(pv.DataVenda AS DATE) AS DataVenda,
        ipv.ItemProdutoVendido,
        ipv.CodProduto,
        ipv.NomeProduto,
        p.CodGrupoProduto,
        gp.Nome AS NomeGrupoProduto,
        gp.CodTipoGrupoProduto,
        tgp.Descricao AS DescricaoTipoGrupoProduto,
        p.CodMarca,
        mc.Nome AS NomeMarca,
        ipv.CodUnidadeMedida,
        ipv.Quantidade,
        ipv.PrecoUnitario,
        ipv.PontoEquilibrio,
        ipv.CustoMedio,
        ipv.CustoReposicao,
        ipv.PrecoCompra AS CustoCompra,
        ipv.ValorUnitarioLiquido
      FROM ItemProdutoVendido ipv
      INNER JOIN Produto p ON
        p.CodProduto = ipv.CodProduto
      LEFT JOIN Marca mc ON
        mc.CodMarca = p.CodMarca
      LEFT JOIN GrupoProduto gp ON
        gp.CodGrupoProduto = p.CodGrupoProduto
      LEFT JOIN TipoGrupoProduto tgp ON
        tgp.CodTipoGrupoProduto = gp.CodTipoGrupoProduto
      INNER JOIN ProdutoVendido pv ON
        pv.CodEmpresa = ipv.CodEmpresa
        AND pv.CodProdutoVendido = ipv.CodProdutoVendido
        AND CAST(pv.DataVenda AS DATE) BETWEEN :dataVendaInicio AND :dataVendaFim
        AND pv.PreVenda = 'N'
        AND pv.Origem LIKE :origem
      INNER JOIN TipoOperacaoSaida tos ON
        tos.CodEmpresa = pv.CodEmpresa
        AND tos.CodTipoOperacaoSaida = pv.CodTipoOperacaoSaida
      LEFT JOIN (
        SELECT
          p1.CodEmpresa,
          p1.CodProdutoVendido,
          p1.GeraFinanceiro AS ParcelaGeraFinanceiro
        FROM ParcelaProdutoVendido p1
        INNER JOIN (
          SELECT
            CodEmpresa,
            CodProdutoVendido,
            MIN(NumeroParcela) AS MinNum
          FROM ParcelaProdutoVendido
          GROUP BY CodEmpresa, CodProdutoVendido
        ) pick ON pick.CodEmpresa = p1.CodEmpresa
          AND pick.CodProdutoVendido = p1.CodProdutoVendido
          AND pick.MinNum = p1.NumeroParcela
      ) ppv_head ON ppv_head.CodEmpresa = pv.CodEmpresa
        AND ppv_head.CodProdutoVendido = pv.CodProdutoVendido
      LEFT JOIN Cliente c ON
        c.CodCliente = pv.CodCliente
      LEFT JOIN Municipio m ON
        m.CodMunicipio = pv.CodMunicipio
      LEFT JOIN GrupoCliente gc ON
        gc.CodGrupoCliente = c.CodGrupoCliente
      LEFT JOIN Regiao r ON
        r.CodRegiao = c.CodRegiao
      LEFT JOIN Vendedor v ON
        v.CodVendedor = pv.CodVendedor
      WHERE COALESCE(
          SUBSTRING(ppv_head.ParcelaGeraFinanceiro, 1, 1),
          tos.GeraFinanceiro
        ) = 'S'
    ),
    Agregada AS (
      -- ValorTotalCustoMedio: SUM(qty * custo médio linha). PercentualLucro:
      -- margem (receita líquida - custo reposição) / receita * 100 quando receita > 0.
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
        SUM(Quantidade * ValorUnitarioLiquido) AS ValorTotalItem,
        COALESCE(
          CASE
            WHEN SUM(Quantidade * ValorUnitarioLiquido) > 0.00 THEN
              (
                (
                  SUM(Quantidade * ValorUnitarioLiquido) -
                    SUM(Quantidade * CustoReposicao)
                ) /
                SUM(Quantidade * ValorUnitarioLiquido)
              ) * 100
            ELSE 0.00
          END,
          0.00
        ) AS PercentualLucro
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
            $rowNumberOrderByLeading,
            a.CodProduto ASC,
            a.NomeProduto ASC,
            a.CodGrupoProduto ASC,
            a.NomeGrupoProduto ASC,
            a.CodMarca ASC,
            a.NomeMarca ASC,
            a.CodTipoGrupoProduto ASC,
            a.DescricaoTipoGrupoProduto ASC
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
      N.PercentualLucro,
      N.Rn
    FROM Tot
    LEFT JOIN Numbered N ON N.Rn BETWEEN :startRow AND :endRow
    ORDER BY COALESCE(N.Rn, 2147483647)
  ''';
  }
}

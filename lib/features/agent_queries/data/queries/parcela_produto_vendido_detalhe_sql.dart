/// Shared inner SELECT for parcel-line resumo queries (troco inputs + joins).
///
/// Used by `ResumoParcelaFormaPagamentoDiarioSql`,
/// `ResumoParcelasFormaPagamentoPorMesSql`, `ResumoParcelasDiaSemanaSql`,
/// `ResumoParcelasMensalSql`, `ResumoVendasDiariasPorVendedorSql`, and
/// `ResumoParcelasAnualSql`. When changing troco logic or joins, update this
/// single fragment and verify each caller's outer GROUP BY and filters.
/// `ValorTrocoParcela` is computed here from
/// parcel totals and `TipoForma` so callers only pass it through.
///
/// The outer `SELECT * FROM (…) … ORDER BY` matches the ERP-style shape. On
/// SQL Server, `ORDER BY` in a derived table requires `TOP`; we use
/// `TOP 100 PERCENT` so every row is kept (same set as a plain inner
/// `SELECT`). Final report ordering still comes from each caller's outer
/// `ORDER BY`.
abstract final class ParcelaProdutoVendidoDetalheSql {
  static const String selectFromParcelLinesThroughJoins = '''
    SELECT TOP 100 PERCENT *
    FROM (
      SELECT
        det.*,
        CASE WHEN det.ValorTotalTrocoVenda > 0
          AND det.ValorTotalParcelasRateioTroco >= det.ValorTotalTrocoVenda
          AND det.TipoForma IN ('DH', 'CH', 'VL', 'PX', 'PIX') THEN
          (det.ValorParcela / NULLIF(det.ValorTotalParcelasRateioTroco, 0))
            * det.ValorTotalTrocoVenda
          WHEN det.ValorTotalTrocoVenda > 0 THEN
          (det.ValorParcela / NULLIF(det.ValorTotalParcelas, 0)) * det.ValorTotalTrocoVenda
          ELSE 0
        END AS ValorTrocoParcela
      FROM (
      SELECT
        pv.CodEmpresa,
        pv.CodFilial,
        pv.CodProdutoVendido,
        CAST(pv.CodEmpresa AS VARCHAR) + '-' +
          CAST(pv.CodFilial AS VARCHAR) + '-' +
          CAST(pv.CodProdutoVendido AS VARCHAR) AS Id,
        pv.Origem,
        pv.CodOrigem,
        COALESCE(SUBSTRING(ppv.GeraFinanceiro, 1, 1), tos.GeraFinanceiro) AS GeraFinanceiro,
        pv.PreVenda,
        pv.CodVendedor,
        v.Nome AS NomeVendedor,
        pv.CodCliente,
        pv.NomeCliente,
        c.CodGrupoCliente,
        gc.Nome AS NomeGrupoCliente,
        pv.CodMunicipio,
        pv.Bairro AS Bairro,
        m.Nome AS NomeMunicipio,
        m.UF AS UFMunicipio,
        c.CodRegiao,
        r.Nome AS NomeRegiao,
        CAST(pv.DataVenda AS DATE) AS DataVenda,
        ppv.DataEmissao,
        ppv.DataVencimento,
        ppv.NumeroDocumento,
        COALESCE(
          NULLIF(LTRIM(RTRIM(pv.NomeUsuario)), ''),
          'Usuario nao informado'
        ) AS NomeUsuario,
        ppv.NumeroParcela,
        YEAR(pv.DataVenda) AS AnoDataVenda,
        MONTH(pv.DataVenda) AS MesDataVenda,
        CAST(YEAR(pv.DataVenda) AS VARCHAR) + '/' +
          RIGHT('00' + CAST(MONTH(pv.DataVenda) AS VARCHAR), 2) AS AnoMesDataVenda,
        ppv.TipoForma,
        ppv.CodFormaPagamento,
        fp.Descricao AS DescricaoFormaPagamento,
        (
          SELECT SUM(sppv.ValorParcela)
          FROM ParcelaProdutoVendido sppv
          WHERE sppv.CodEmpresa = ppv.CodEmpresa
            AND sppv.CodProdutoVendido = ppv.CodProdutoVendido
        ) AS ValorTotalParcelas,
        COALESCE((
          SELECT SUM(subppv.ValorParcela)
          FROM ParcelaProdutoVendido subppv
          WHERE subppv.CodEmpresa = ppv.CodEmpresa
            AND subppv.CodProdutoVendido = ppv.CodProdutoVendido
            AND subppv.TipoForma IN ('DH', 'CH', 'VL', 'PX', 'PIX')
        ), 0) AS ValorTotalParcelasRateioTroco,
        COALESCE((
          SELECT SUM(subpvtfp.Valor)
          FROM ProdutoVendidoTrocoFormaPagamento subpvtfp
          WHERE subpvtfp.CodEmpresa = ppv.CodEmpresa
            AND subpvtfp.CodProdutoVendido = ppv.CodProdutoVendido
        ), 0)
        +
        COALESCE((
          SELECT SUM(subvl.Valor)
          FROM Vale subvl
          WHERE subvl.CodEmpresa = pv.CodEmpresa
            AND subvl.CodOrigem = pv.CodOrigem
            AND subvl.Origem = 'OB'
        ), 0) AS ValorTotalTrocoVenda,
        ppv.ValorParcela
      FROM ParcelaProdutoVendido ppv
      INNER JOIN ProdutoVendido pv ON
        pv.CodEmpresa = ppv.CodEmpresa
        AND pv.CodProdutoVendido = ppv.CodProdutoVendido
      INNER JOIN FormaPagamento fp ON
        fp.CodFormaPagamento = ppv.CodFormaPagamento
      INNER JOIN TipoOperacaoSaida tos ON
        tos.CodEmpresa = pv.CodEmpresa
        AND tos.CodTipoOperacaoSaida = pv.CodTipoOperacaoSaida
      INNER JOIN Cliente c ON
        c.CodCliente = pv.CodCliente
      INNER JOIN Municipio m ON
        m.CodMunicipio = pv.CodMunicipio
      LEFT JOIN GrupoCliente gc ON
        gc.CodGrupoCliente = c.CodGrupoCliente
      LEFT JOIN Regiao r ON
        r.CodRegiao = c.CodRegiao
      LEFT JOIN Vendedor v ON
        v.CodVendedor = pv.CodVendedor
      ) det
    ) ParcelaProdutoVendidoDetalhe
    ORDER BY
      CodEmpresa,
      CodFilial,
      CodProdutoVendido
    ''';
}

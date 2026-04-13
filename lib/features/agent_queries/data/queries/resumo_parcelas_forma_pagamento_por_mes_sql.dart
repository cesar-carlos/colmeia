abstract final class ResumoParcelasFormaPagamentoPorMesSql {
  /// Parcel summary by company, branch, user, sale year/month, and payment
  /// method, with distinct sale counts and net parcel totals after troco
  /// allocation.
  ///
  /// Includes optional dimension filters (`:codEmpresa`, `:codFilial`,
  /// `:codVendedor`) bound as null until the app passes concrete values.
  ///
  /// **Agent policy review**: driving rows are `ParcelaProdutoVendido` joined
  /// to `ProdutoVendido`, `FormaPagamento`, `TipoOperacaoSaida`, `Cliente`,
  /// `Municipio`, optional `GrupoCliente`, `Regiao`, `Vendedor`, plus
  /// correlated subqueries on `ParcelaProdutoVendido`,
  /// `ProdutoVendidoTrocoFormaPagamento`, and `Vale`.
  ///
  /// **Performance (SQL Server)**: keep `ProdutoVendido` selective on
  /// `DataVenda`, `Origem`, `CodEmpresa`, and `CodFilial` via supporting
  /// indexes; parcel aggregates benefit from
  /// `(CodEmpresa, CodProdutoVendido)` on `ParcelaProdutoVendido`.
  static const String query = '''
SELECT
  CodEmpresa,
  CodFilial,
  NomeUsuario,
  AnoMesDataVenda,
  CodFormaPagamento,
  DescricaoFormaPagamento,
  COUNT(DISTINCT Id) AS QtdVendas,
  SUM(ValorParcela - ValorTrocoParcela) AS ValorParcela
FROM (
  SELECT
    CodEmpresa,
    CodFilial,
    CodProdutoVendido,
    Id,
    Origem,
    CodOrigem,
    GeraFinanceiro,
    PreVenda,
    CodVendedor,
    NomeVendedor,
    CodCliente,
    NomeCliente,
    CodGrupoCliente,
    NomeGrupoCliente,
    CodMunicipio,
    NomeMunicipio,
    UFMunicipio,
    CodRegiao,
    NomeRegiao,
    DataVenda,
    DataEmissao,
    DataVencimento,
    NumeroDocumento,
    NomeUsuario,
    NumeroParcela,
    AnoDataVenda,
    MesDataVenda,
    AnoMesDataVenda,
    CodFormaPagamento,
    DescricaoFormaPagamento,
    CASE WHEN ValorTotalTrocoVenda > 0
      AND ValorTotalParcelasRateioTroco >= ValorTotalTrocoVenda
      AND TipoForma IN ('DH', 'CH', 'VL', 'PX', 'PIX') THEN
      (ValorParcela / NULLIF(ValorTotalParcelasRateioTroco, 0))
        * ValorTotalTrocoVenda
      WHEN ValorTotalTrocoVenda > 0 THEN
      (ValorParcela / NULLIF(ValorTotalParcelas, 0)) * ValorTotalTrocoVenda
      ELSE 0
    END AS ValorTrocoParcela,
    ValorParcela
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
      COALESCE(SUBSTRING(ppv.GeraFinanceiro, 1, 1), tos.GeraFinanceiro)
        AS GeraFinanceiro,
      pv.PreVenda,
      pv.CodVendedor,
      v.Nome AS NomeVendedor,
      pv.CodCliente,
      pv.NomeCliente,
      c.CodGrupoCliente,
      gc.Nome AS NomeGrupoCliente,
      pv.CodMunicipio,
      m.Nome AS NomeMunicipio,
      m.UF AS UFMunicipio,
      c.CodRegiao,
      r.Nome AS NomeRegiao,
      CAST(pv.DataVenda AS DATE) AS DataVenda,
      ppv.DataEmissao,
      ppv.DataVencimento,
      ppv.NumeroDocumento,
      pv.NomeUsuario,
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
      + COALESCE((
        SELECT SUM(subvl.Valor)
        FROM Vale subvl
        WHERE subvl.CodEmpresa = pv.CodEmpresa
          AND subvl.CodOrigem = pv.CodOrigem
          AND subvl.Origem = 'OB'
      ), 0) AS ValorTotalTrocoVenda,
      ppv.ValorParcela
    FROM ParcelaProdutoVendido ppv
    INNER JOIN ProdutoVendido pv
      ON pv.CodEmpresa = ppv.CodEmpresa
      AND pv.CodProdutoVendido = ppv.CodProdutoVendido
    INNER JOIN FormaPagamento fp
      ON fp.CodFormaPagamento = ppv.CodFormaPagamento
    INNER JOIN TipoOperacaoSaida tos
      ON tos.CodEmpresa = pv.CodEmpresa
      AND tos.CodTipoOperacaoSaida = pv.CodTipoOperacaoSaida
    INNER JOIN Cliente c
      ON c.CodCliente = pv.CodCliente
    INNER JOIN Municipio m
      ON m.CodMunicipio = pv.CodMunicipio
    LEFT JOIN GrupoCliente gc
      ON gc.CodGrupoCliente = c.CodGrupoCliente
    LEFT JOIN Regiao r
      ON r.CodRegiao = c.CodRegiao
    LEFT JOIN Vendedor v
      ON v.CodVendedor = pv.CodVendedor
  ) Detalhe
) ResumoParcelasFormaPagamentoPorMes
WHERE DataVenda BETWEEN :dataVendaInicio AND :dataVendaFim
  AND Origem LIKE :origem
  AND GeraFinanceiro = :geraFinanceiro
  AND PreVenda = :preVenda
  AND (:codEmpresa IS NULL OR CodEmpresa = :codEmpresa)
  AND (:codFilial IS NULL OR CodFilial = :codFilial)
  AND (:codVendedor IS NULL OR CodVendedor = :codVendedor)
GROUP BY
  CodEmpresa,
  CodFilial,
  NomeUsuario,
  AnoMesDataVenda,
  CodFormaPagamento,
  DescricaoFormaPagamento
ORDER BY
  AnoMesDataVenda,
  CodEmpresa,
  CodFilial,
  NomeUsuario,
  CodFormaPagamento,
  DescricaoFormaPagamento
''';
}

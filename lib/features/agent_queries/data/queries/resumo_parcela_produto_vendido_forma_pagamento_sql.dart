abstract final class ResumoParcelaProdutoVendidoFormaPagamentoSql {
  /// Named-parameter version of the original report query.
  static const String query = '''
SELECT
  CodEmpresa,
  CodFilial,
  NomeUsuario,
  AnoDataVenda,
  MesDataVenda,
  AnoMesDataVenda,
  CodFormaPagamento,
  DescricaoFormaPagamento,
  COUNT(DISTINCT Id) AS QtdVendas,
  SUM(ValorParcela) AS ValorParcela
FROM (
  SELECT
    pv.CodEmpresa,
    pv.CodFilial,
    pv.CodProdutoVendido,
    CAST(pv.CodEmpresa AS VARCHAR) +
      CAST(pv.CodFilial AS VARCHAR) +
      CAST(pv.CodProdutoVendido AS VARCHAR) AS Id,
    pv.Origem,
    pv.CodOrigem,
    COALESCE(SUBSTRING(ppv.GeraFinanceiro, 1, 1), tos.GeraFinanceiro)
      AS GeraFinanceiro,
    pv.PreVenda,
    pv.DataVenda,
    COALESCE(
      NULLIF(LTRIM(RTRIM(pv.NomeUsuario)), ''),
      'Usuario nao informado'
    ) AS NomeUsuario,
    ppv.DataEmissao,
    YEAR(pv.DataVenda) AS AnoDataVenda,
    MONTH(pv.DataVenda) AS MesDataVenda,
    CAST(YEAR(pv.DataVenda) AS VARCHAR(4)) + '/' +
      RIGHT(
        '0' + CAST(MONTH(pv.DataVenda) AS VARCHAR(2)),
        2
      ) AS AnoMesDataVenda,
    ppv.DataVencimento,
    ppv.NumeroDocumento,
    ppv.NumeroParcela,
    ppv.CodFormaPagamento,
    fp.Descricao AS DescricaoFormaPagamento,
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
) ResumoParcelaProdutoVendidoFormaPagamento
WHERE DataVenda BETWEEN :dataVendaInicio AND :dataVendaFim
  AND Origem LIKE :origem
  AND GeraFinanceiro = :geraFinanceiro
  AND PreVenda = :preVenda
GROUP BY
  CodEmpresa,
  CodFilial,
  NomeUsuario,
  AnoDataVenda,
  MesDataVenda,
  AnoMesDataVenda,
  CodFormaPagamento,
  DescricaoFormaPagamento
ORDER BY
  AnoDataVenda,
  MesDataVenda
''';
}

abstract final class ResumoParcelaFormaPagamentoDiarioSql {
  /// Daily aggregation of parcel lines by sale date and payment method.
  ///
  /// Omits `GrupoCliente`, `Regiao`, and `Vendedor` joins so stricter agent
  /// policies can still authorize the query (see other parcel report SQL in
  /// this feature).
  static const String query = '''
SELECT
  DataVenda,
  DescricaoFormaPagamento,
  COUNT(*) AS Quantidade,
  SUM(ValorParcela) AS ValorTotal
FROM (
  SELECT
    CAST(pv.DataVenda AS DATE) AS DataVenda,
    pv.Origem,
    COALESCE(SUBSTRING(ppv.GeraFinanceiro, 1, 1), tos.GeraFinanceiro)
      AS GeraFinanceiro,
    pv.PreVenda,
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
  INNER JOIN Cliente c ON
    c.CodCliente = pv.CodCliente
  INNER JOIN Municipio m ON
    m.CodMunicipio = pv.CodMunicipio
) ResumoParcelaFormaPagamentoDiario
WHERE DataVenda BETWEEN :dataVendaInicio AND :dataVendaFim
  AND Origem LIKE :origem
  AND GeraFinanceiro = :geraFinanceiro
  AND PreVenda = :preVenda
GROUP BY
  DataVenda,
  DescricaoFormaPagamento
ORDER BY
  DataVenda,
  DescricaoFormaPagamento
''';
}

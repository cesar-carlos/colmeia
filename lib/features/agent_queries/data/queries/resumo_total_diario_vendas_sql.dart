abstract final class ResumoTotalDiarioVendasSql {
  static const String query = '''
SELECT
  CodEmpresa,
  CodFilial,
  DataVenda,
  COUNT(DISTINCT CodProdutoVendido) AS QtdVendas,
  SUM(ValorTotalVenda) AS ValorTotalDiarioVenda
FROM (
  SELECT
    pv.CodEmpresa,
    pv.CodFilial,
    pv.CodProdutoVendido,
    CAST(pv.DataVenda AS DATE) AS DataVenda,
    pv.ValorLiquido AS ValorTotalVenda
  FROM ProdutoVendido pv
  INNER JOIN TipoOperacaoSaida tos ON
    tos.CodEmpresa = pv.CodEmpresa
    AND tos.CodFilial = pv.CodFilial
    AND tos.CodTipoOperacaoSaida = pv.CodTipoOperacaoSaida
  WHERE pv.DataVenda BETWEEN :dataVendaInicio AND :dataVendaFim
    AND pv.Origem LIKE :origem
    AND tos.GeraFinanceiro = :geraFinanceiro
    AND pv.PreVenda = :preVenda
) AS ResumoTotalDiarioVendasInner
GROUP BY
  CodEmpresa,
  CodFilial,
  DataVenda
ORDER BY
  CodEmpresa,
  CodFilial,
  DataVenda
''';
}

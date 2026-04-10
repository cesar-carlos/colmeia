abstract final class ResumoParcelasMensalSql {
  /// Monthly aggregation of parcel lines by `YEAR(DataVenda)` and
  /// `MONTH(DataVenda)`.
  ///
  /// Omits `GrupoCliente`, `Regiao`, and `Vendedor` joins so stricter agent
  /// policies can still authorize the query (see other parcel report SQL in
  /// this feature). `Vendedor` is unused in the projected columns.
  static const String query = '''
SELECT
  Ano,
  Mes,
  COUNT(*) AS Quantidade,
  SUM(ValorParcela) AS ValorTotal
FROM (
  SELECT
    YEAR(DataVenda) AS Ano,
    MONTH(DataVenda) AS Mes,
    ValorParcela
  FROM (
    SELECT
      -- `DATE` uses the SQL Server session timezone for `datetime` sources.
      CAST(pv.DataVenda AS DATE) AS DataVenda,
      pv.Origem,
      COALESCE(SUBSTRING(ppv.GeraFinanceiro, 1, 1), tos.GeraFinanceiro)
        AS GeraFinanceiro,
      pv.PreVenda,
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
  ) Detalhe
  WHERE DataVenda BETWEEN :dataVendaInicio AND :dataVendaFim
    AND Origem LIKE :origem
    AND GeraFinanceiro = :geraFinanceiro
    AND PreVenda = :preVenda
) ResumoParcelasMensal
GROUP BY Ano, Mes
ORDER BY Ano, Mes
''';
}

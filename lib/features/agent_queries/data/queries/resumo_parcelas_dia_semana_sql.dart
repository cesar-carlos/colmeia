abstract final class ResumoParcelasDiaSemanaSql {
  /// Weekday aggregation of parcel lines by calendar weekday of sale date.
  ///
  /// Column DiaSemanaNumero uses day difference from a known Sunday
  /// (`2000-01-02`) so it does not depend on `DATEFIRST` or locale.
  /// Sunday = 1 … Saturday = 7, matching app weekday labels.
  ///
  /// Omits `GrupoCliente`, `Regiao`, `Vendedor`, and `FormaPagamento` joins
  /// so stricter agent policies can still authorize the query.
  static const String query = '''
SELECT
  DiaSemanaNumero,
  CASE DiaSemanaNumero
    WHEN 1 THEN 'Domingo'
    WHEN 2 THEN 'Segunda'
    WHEN 3 THEN 'Terça'
    WHEN 4 THEN 'Quarta'
    WHEN 5 THEN 'Quinta'
    WHEN 6 THEN 'Sexta'
    WHEN 7 THEN 'Sábado'
  END AS DiaSemana,
  COUNT(*) AS Quantidade,
  SUM(ValorParcela) AS ValorTotal
FROM (
  SELECT
    ((DATEDIFF(DAY, CAST('2000-01-02' AS DATE), DataVenda) % 7) + 7) % 7
      + 1 AS DiaSemanaNumero,
    ValorParcela
  FROM (
    SELECT
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
) ResumoParcelasDiaSemana
GROUP BY DiaSemanaNumero
ORDER BY DiaSemanaNumero
''';
}

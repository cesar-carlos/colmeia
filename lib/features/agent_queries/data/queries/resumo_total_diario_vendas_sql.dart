/// Daily sales totals per company, branch, calendar day.
///
/// Performance notes:
/// - Date filter is **sargable**: no `CAST`/`CONVERT` on `pv.DataVenda` in the
///   predicate (half-open range `[inicio, fim]` by calendar day).
/// - `pv.Origem = :origem` (exact match); wildcards are rejected in
///   `resumo_vendas_produto_vendido_sql_periodo_filter.dart`.
///
/// **Diverges from parcel-line resumos** (see
/// `parcela_produto_vendido_detalhe_sql.dart` for the full caveat list):
/// - Filters by `tos.GeraFinanceiro` only; parcel resumos override the
///   operation flag with `ppv.GeraFinanceiro` when present.
/// - Sums `pv.ValorLiquido` (gross liquid sale value), while parcel resumos
///   compute `SUM(ValorParcela − ValorTrocoParcela)`. These two values are
///   not guaranteed to match for sales with troco or partial financial
///   parcels — that is a known data-model gap pending product decision.
///
/// Suggested indexes (validate with DBA / actual plans):
///
/// ```sql
/// CREATE NONCLUSTERED INDEX IX_ProdutoVendido_ResumoDiario
/// ON ProdutoVendido (CodEmpresa, CodFilial, DataVenda)
/// INCLUDE (CodProdutoVendido, Origem, PreVenda, CodTipoOperacaoSaida, ValorLiquido);
///
/// CREATE NONCLUSTERED INDEX IX_TipoOperacaoSaida_Join
/// ON TipoOperacaoSaida (CodEmpresa, CodTipoOperacaoSaida)
/// INCLUDE (GeraFinanceiro);
/// ```
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
    AND tos.CodTipoOperacaoSaida = pv.CodTipoOperacaoSaida
  WHERE pv.DataVenda >= CAST(:dataVendaInicio AS DATE)
    AND pv.DataVenda < DATEADD(day, 1, CAST(:dataVendaFim AS DATE))
    AND pv.Origem = :origem
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

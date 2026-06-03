/// Shared inner SELECT for parcel-line resumo queries (troco inputs + joins).
///
/// Used by `ResumoParcelaFormaPagamentoSql`,
/// `ResumoParcelaFormaPagamentoSqlV2`,
/// `ResumoParcelaPorUsuarioSql`,
/// `ResumoParcelaFormaPagamentoDiarioSql`,
/// `ResumoParcelasFormaPagamentoPorMesSql`, `ResumoParcelasDiaSemanaSql`,
/// `ResumoParcelasDiaSemanaUsuarioSql`, `ResumoParcelasMensalSql`,
/// `ResumoVendasDiariasPorVendedorSql`, and `ResumoParcelasAnualSql`. When changing troco logic or joins, update this
/// single fragment and verify each caller's outer GROUP BY and filters.
/// `ValorTrocoParcela` is computed here from
/// parcel totals and `TipoForma` so callers only pass it through.
///
/// **Projections:** [selectFromParcelLinesThroughJoins] keeps cliente/municipio/
/// vendedor/regiao columns for reports that filter or display them.
/// [selectFromParcelLinesForOverviewAggregate] omits those joins and columns
/// for overview resumos that only GROUP BY branch, calendar, payment method,
/// or user — use that variant in outer queries that do not need dimension
/// drill-down columns.
///
/// **Performance:** per-sale totals (`ValorTotalParcelas`, troco inputs) use
/// `LEFT JOIN` to pre-aggregated subqueries instead of correlated scalar
/// subqueries on each parcel row — friendlier to SQL Server and SAP SQL
/// Anywhere 16 optimizers while preserving semantics.
///
/// The outer shape is `SELECT * FROM (…) alias`. No `ORDER BY` inside this
/// fragment: callers aggregate or sort in their outer query.
///
/// **Pending product decisions** (kept here so every parcel resumo inherits
/// the same caveat — see `docs/Features/charts_design_system.md` and
/// `docs/server_adjustments/README.md`):
///
/// 1. `GeraFinanceiro` source divergence vs `ResumoTotalDiarioVendasSql`:
///    this fragment computes `COALESCE(SUBSTRING(ppv.GeraFinanceiro, 1, 1),
///    tos.GeraFinanceiro)` — i.e. the parcel flag overrides the operation
///    flag. `ResumoTotalDiarioVendasSql` filters by `tos.GeraFinanceiro`
///    only. Sales with mixed-flag parcels are counted differently between
///    parcel-based and daily reports.
/// 2. Value semantics: parcel-based aggregates use
///    `SUM(ValorParcela − ValorTrocoParcela)` (net of troco rateio);
///    `ResumoTotalDiarioVendasSql` uses `SUM(pv.ValorLiquido)`. They are
///    only guaranteed to match when sales have no troco AND
///    `SUM(ValorParcela) == ValorLiquido`.
/// 3. Cancelled sales: no `Cancelado` / `Situacao` filter is applied here
///    or in the daily resumo. If the ERP marks cancelled sales with a
///    column that should exclude them (and `GeraFinanceiro` does not catch
///    them), totals will overstate.
/// 4. Multi-agent disjointness: `ResumoParcelasMensalRowMerger` and
///    siblings sum across agents — correct only when the agents query
///    disjoint datasets. Mirror/replica agents over-count silently.
abstract final class ParcelaProdutoVendidoDetalheSql {
  /// Full parcel-line detail (cliente, municipio, vendedor, regiao, document).
  static const String selectFromParcelLinesThroughJoins =
      _selectWithTrocoLayerPrefix +
      _detSelectFull +
      _fromJoinsFull +
      _selectWithTrocoLayerSuffix;

  /// Slim inner slice for overview aggregate resumos (no cliente/municipio joins).
  static const String selectFromParcelLinesForOverviewAggregate =
      _selectWithTrocoLayerPrefix +
      _detSelectOverviewAggregate +
      _fromJoinsOverviewAggregate +
      _selectWithTrocoLayerSuffix;

  static const String _selectWithTrocoLayerPrefix = '''
    SELECT *
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
  ''';

  static const String _selectWithTrocoLayerSuffix = '''
      ) det
    ) ParcelaProdutoVendidoDetalhe
  ''';

  static const String _detSelectOverviewAggregate = '''
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
        CAST(pv.DataVenda AS DATE) AS DataVenda,
        COALESCE(
          NULLIF(LTRIM(RTRIM(pv.NomeUsuario)), ''),
          'Usuario nao informado'
        ) AS NomeUsuario,
        ppv.TipoForma,
        ppv.CodFormaPagamento,
        fp.Descricao AS DescricaoFormaPagamento,
        COALESCE(par_tot.ValorTotalParcelas, 0) AS ValorTotalParcelas,
        COALESCE(par_tot.ValorTotalParcelasRateioTroco, 0) AS ValorTotalParcelasRateioTroco,
        COALESCE(troco_fp.TotalTrocoForma, 0) + COALESCE(vale_ob.ValeOb, 0) AS ValorTotalTrocoVenda,
        ppv.ValorParcela
  ''';

  static const String _detSelectFull = '''
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
        COALESCE(par_tot.ValorTotalParcelas, 0) AS ValorTotalParcelas,
        COALESCE(par_tot.ValorTotalParcelasRateioTroco, 0) AS ValorTotalParcelasRateioTroco,
        COALESCE(troco_fp.TotalTrocoForma, 0) + COALESCE(vale_ob.ValeOb, 0) AS ValorTotalTrocoVenda,
        ppv.ValorParcela
  ''';

  static const String _fromJoinsOverviewAggregate = '''
      FROM ParcelaProdutoVendido ppv
      INNER JOIN ProdutoVendido pv ON
        pv.CodEmpresa = ppv.CodEmpresa
        AND pv.CodProdutoVendido = ppv.CodProdutoVendido
      INNER JOIN FormaPagamento fp ON
        fp.CodFormaPagamento = ppv.CodFormaPagamento
      INNER JOIN TipoOperacaoSaida tos ON
        tos.CodEmpresa = pv.CodEmpresa
        AND tos.CodTipoOperacaoSaida = pv.CodTipoOperacaoSaida
$_parcelAggregateJoins
  ''';

  static const String _fromJoinsFull = '''
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
$_parcelAggregateJoins
  ''';

  static const String _parcelAggregateJoins = '''
      LEFT JOIN (
        SELECT
          CodEmpresa,
          CodProdutoVendido,
          SUM(ValorParcela) AS ValorTotalParcelas,
          SUM(
            CASE WHEN TipoForma IN ('DH', 'CH', 'VL', 'PX', 'PIX')
              THEN ValorParcela
              ELSE 0
            END
          ) AS ValorTotalParcelasRateioTroco
        FROM ParcelaProdutoVendido
        GROUP BY CodEmpresa, CodProdutoVendido
      ) par_tot ON
        par_tot.CodEmpresa = ppv.CodEmpresa
        AND par_tot.CodProdutoVendido = ppv.CodProdutoVendido
      LEFT JOIN (
        SELECT
          CodEmpresa,
          CodProdutoVendido,
          SUM(Valor) AS TotalTrocoForma
        FROM ProdutoVendidoTrocoFormaPagamento
        GROUP BY CodEmpresa, CodProdutoVendido
      ) troco_fp ON
        troco_fp.CodEmpresa = ppv.CodEmpresa
        AND troco_fp.CodProdutoVendido = ppv.CodProdutoVendido
      LEFT JOIN (
        SELECT
          CodEmpresa,
          CodOrigem,
          SUM(Valor) AS ValeOb
        FROM Vale
        WHERE Origem = 'OB'
        GROUP BY CodEmpresa, CodOrigem
      ) vale_ob ON
        vale_ob.CodEmpresa = pv.CodEmpresa
        AND vale_ob.CodOrigem = pv.CodOrigem
  ''';
}

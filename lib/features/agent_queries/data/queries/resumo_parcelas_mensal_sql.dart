import 'package:colmeia/features/agent_queries/data/queries/parcela_produto_vendido_detalhe_sql.dart';

abstract final class ResumoParcelasMensalSql {
  /// Monthly parcel summary by company, branch, and calendar month, with
  /// distinct sale counts and net parcel totals after troco allocation.
  ///
  /// Inner `Detalhe` comes from `ParcelaProdutoVendidoDetalheSql`; extra
  /// columns exist for future filters.
  ///
  /// Includes optional dimension filters (`:codEmpresa`, `:codFilial`,
  /// `:codVendedor`). Unused dimensions must be sent as SQL nulls in the
  /// execute payload so `IS NULL` branches apply (same contract as
  /// `ResumoParcelasSqlDimensionFilters.namedParams`).
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
  static const String _queryHead = '''
    SELECT
      CodEmpresa,
      CodFilial,
      Ano,
      Mes,
      MAX(
        CAST(Ano AS VARCHAR(4)) + '/' +
          CASE WHEN Mes < 10 THEN '0' ELSE '' END + CAST(Mes AS VARCHAR(2))
      ) AS AnoMes,
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
        YEAR(DataVenda) AS Ano,
        MONTH(DataVenda) AS Mes,
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
        ValorTrocoParcela,
        ValorParcela
      FROM (
  ''';

  static const String _queryTail = '''
      ) Detalhe
    ) ResumoParcelasMensal
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
      Ano,
      Mes
    ORDER BY
      CodEmpresa,
      CodFilial,
      Ano,
      Mes
  ''';

  static const String query =
      _queryHead +
      ParcelaProdutoVendidoDetalheSql.selectFromParcelLinesThroughJoins +
      _queryTail;
}

import 'package:colmeia/features/agent_queries/data/queries/parcela_produto_vendido_detalhe_sql.dart';

abstract final class ResumoParcelasDiaSemanaSql {
  /// Weekday parcel summary by company, branch, and calendar weekday of sale
  /// date, with distinct sale counts and net parcel totals after troco
  /// allocation.
  ///
  /// Inner `Detalhe` comes from `ParcelaProdutoVendidoDetalheSql`; extra
  /// columns exist for future filters.
  ///
  /// Includes optional dimension filters (`:codEmpresa`, `:codFilial`,
  /// `:codVendedor`). Unused dimensions must be sent as SQL nulls in the
  /// execute payload so `IS NULL` branches apply (same contract as
  /// `ResumoParcelasSqlDimensionFilters.namedParams`).
  ///
  /// Column `DiaSemanaNumero` uses day difference from a known Sunday
  /// (`2000-01-02`) in the middle layer so it does not depend on `DATEFIRST`
  /// or locale. Sunday = 1 … Saturday = 7, matching app weekday labels.
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
        ((DATEDIFF(DAY, CAST('2000-01-02' AS DATE), DataVenda) % 7) + 7) % 7
          + 1 AS DiaSemanaNumero,
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
    ) ResumoParcelasDiaSemana
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
      DiaSemanaNumero
    ORDER BY
      CodEmpresa,
      CodFilial,
      DiaSemanaNumero
  ''';

  static const String query =
      _queryHead +
      ParcelaProdutoVendidoDetalheSql.selectFromParcelLinesThroughJoins +
      _queryTail;
}

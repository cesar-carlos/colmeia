import 'package:colmeia/features/agent_queries/data/queries/parcela_produto_vendido_detalhe_sql.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_sql_dimension_filters.dart';

abstract final class ResumoParcelasMensalSql {
  /// Monthly parcel summary by company, branch, and calendar month, with
  /// distinct sale counts and net parcel totals after troco allocation.
  ///
  /// Inner `Detalhe` comes from
  /// `ParcelaProdutoVendidoDetalheSql.selectFromParcelLinesForOverviewAggregate`.
  ///
  /// Optional dimensions are inlined (see [ResumoParcelasSqlDimensionFilters])
  /// for the Agent SQL bridge named-parameter limit.
  ///
  /// **Bridge named-parameter limit**: at most five named binds are sent;
  /// optional dimensions are inlined as integer literals (see
  /// [ResumoParcelasSqlDimensionFilters]).
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
        Id,
        Origem,
        GeraFinanceiro,
        PreVenda,
        CodVendedor,
        DataVenda,
        YEAR(DataVenda) AS Ano,
        MONTH(DataVenda) AS Mes,
        ValorTrocoParcela,
        ValorParcela
      FROM (
  ''';

  static const String _queryTail = '''
      ) Detalhe
    ) ResumoParcelasMensal
    WHERE DataVenda BETWEEN :dataVendaInicio AND :dataVendaFim
      AND Origem = :origem
      AND GeraFinanceiro = :geraFinanceiro
      AND PreVenda = :preVenda
__RESUMO_PARCELAS_DIMENSION_WHERE__
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

  static String query({
    int? codEmpresa,
    int? codFilial,
    int? codVendedor,
  }) {
    final tail = ResumoParcelasSqlDimensionFilters.embedLiteralDimensionWhere(
      _queryTail,
      codEmpresa: codEmpresa,
      codFilial: codFilial,
      codVendedor: codVendedor,
    );
    return _queryHead +
        ParcelaProdutoVendidoDetalheSql
            .selectFromParcelLinesForOverviewAggregate +
        tail;
  }
}

import 'package:colmeia/features/agent_queries/data/queries/parcela_produto_vendido_detalhe_sql.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_sql_dimension_filters.dart';

abstract final class ResumoParcelasFormaPagamentoPorMesSql {
  /// Parcel summary by company, branch, user, sale year/month, and payment
  /// method, with distinct sale counts and net parcel totals after troco
  /// allocation.
  ///
  /// Inner `Detalhe` comes from `ParcelaProdutoVendidoDetalheSql`; extra
  /// columns exist for future filters and are not all projected in the outer
  /// `SELECT`.
  ///
  /// Optional dimensions are inlined (see [ResumoParcelasSqlDimensionFilters])
  /// for the Agent SQL bridge named-parameter limit.
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
      NomeUsuario,
      AnoMesDataVenda,
      CodFormaPagamento,
      DescricaoFormaPagamento,
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
    ) ResumoParcelasFormaPagamentoPorMes
    WHERE DataVenda >= CAST(:dataVendaInicio AS DATE)
      AND DataVenda < DATEADD(day, 1, CAST(:dataVendaFim AS DATE))
      AND Origem = :origem
      AND GeraFinanceiro = :geraFinanceiro
      AND PreVenda = :preVenda
__RESUMO_PARCELAS_DIMENSION_WHERE__
    GROUP BY
      CodEmpresa,
      CodFilial,
      NomeUsuario,
      AnoMesDataVenda,
      CodFormaPagamento,
      DescricaoFormaPagamento
    ORDER BY
      CodEmpresa,
      CodFilial,
      AnoMesDataVenda,
      CodFormaPagamento,
      DescricaoFormaPagamento
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
        ParcelaProdutoVendidoDetalheSql.selectFromParcelLinesThroughJoins +
        tail;
  }
}

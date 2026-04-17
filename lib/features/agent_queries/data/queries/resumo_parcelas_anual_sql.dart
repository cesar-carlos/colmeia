import 'package:colmeia/features/agent_queries/data/queries/parcela_produto_vendido_detalhe_sql.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_sql_dimension_filters.dart';

abstract final class ResumoParcelasAnualSql {
  /// Annual parcel summary by company, branch, and sale calendar year (no
  /// payment-method dimension in the outer aggregate).
  ///
  /// Distinct sale count and net total after troco on parcel lines.
  ///
  /// Inner slices keep extra columns (including forma de pagamento) for future
  /// filters; they are not in the outer `SELECT` until exposed.
  ///
  /// Optional dimensions are inlined (see [ResumoParcelasSqlDimensionFilters])
  /// so the bridge stays within its named-parameter limit.
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
  ///
  /// When new filters use inner-only columns, push predicates into the inner
  /// slice where possible and re-check indexes on the ERP side if this query
  /// becomes hot.
  static const String _queryHead = '''
    SELECT
      CodEmpresa,
      CodFilial,
      AnoDataVenda,
      COUNT(DISTINCT Id) AS QtdVendas,
      SUM(ValorParcela - ValorTrocoParcela) AS ValorTotalVenda
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
        Bairro,
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
    ) ResumoParcelasAnual
    WHERE DataVenda BETWEEN :dataVendaInicio AND :dataVendaFim
      AND Origem LIKE :origem
      AND GeraFinanceiro = :geraFinanceiro
      AND PreVenda = :preVenda
__RESUMO_PARCELAS_DIMENSION_WHERE__
    GROUP BY
      CodEmpresa,
      CodFilial,
      AnoDataVenda
    ORDER BY
      CodEmpresa,
      CodFilial,
      AnoDataVenda
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

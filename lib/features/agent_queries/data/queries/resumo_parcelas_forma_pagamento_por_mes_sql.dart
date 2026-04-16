import 'package:colmeia/features/agent_queries/data/queries/parcela_produto_vendido_detalhe_sql.dart';

abstract final class ResumoParcelasFormaPagamentoPorMesSql {
  /// Parcel summary by company, branch, user, sale year/month, and payment
  /// method, with distinct sale counts and net parcel totals after troco
  /// allocation.
  ///
  /// Inner `Detalhe` comes from `ParcelaProdutoVendidoDetalheSql`; extra
  /// columns exist for future filters and are not all projected in the outer
  /// `SELECT`.
  ///
  /// Includes optional dimension filters (`:codEmpresa`, `:codFilial`,
  /// `:codVendedor`) bound as null until the app passes concrete values.
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

  static const String query =
      _queryHead +
      ParcelaProdutoVendidoDetalheSql.selectFromParcelLinesThroughJoins +
      _queryTail;
}

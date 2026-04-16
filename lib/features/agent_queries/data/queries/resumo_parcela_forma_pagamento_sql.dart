import 'package:colmeia/features/agent_queries/data/queries/parcela_produto_vendido_detalhe_sql.dart';

abstract final class ResumoParcelaFormaPagamentoSql {
  /// Named-parameter version of the report query.
  ///
  /// Inner slice is [ParcelaProdutoVendidoDetalheSql] so `ValorTrocoParcela`
  /// matches other parcel resumos; outer aggregate nets parcel value after
  /// troco allocation (`SUM(ValorParcela - ValorTrocoParcela)`).
  ///
  /// Outer aggregate groups by month label and payment method, counting
  /// distinct sales via the composite `Id` expression in the inner select.
  static const String _queryHead = '''
    SELECT
      CodEmpresa,
      CodFilial,
      NomeUsuario,
      MAX(AnoDataVenda) AS AnoDataVenda,
      MAX(MesDataVenda) AS MesDataVenda,
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
    ) ResumoParcelaFormaPagamento
    WHERE DataVenda BETWEEN :dataVendaInicio AND :dataVendaFim
      AND Origem LIKE :origem
      AND GeraFinanceiro = :geraFinanceiro
      AND PreVenda = :preVenda
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
      AnoDataVenda,
      MesDataVenda
  ''';

  static const String query =
      _queryHead +
      ParcelaProdutoVendidoDetalheSql.selectFromParcelLinesThroughJoins +
      _queryTail;
}

import 'package:colmeia/features/agent_queries/data/queries/parcela_produto_vendido_detalhe_sql.dart';

abstract final class ResumoParcelaFormaPagamentoSql {
  /// Named-parameter version of the report query.
  ///
  /// Inner slice is [ParcelaProdutoVendidoDetalheSql] so `ValorTrocoParcela`
  /// matches other parcel resumos; outer aggregate nets parcel value after
  /// troco allocation (`SUM(ValorParcela - ValorTrocoParcela)`).
  ///
  /// The middle `SELECT` projects only columns consumed by the outer aggregate
  /// (filters, `GROUP BY`, `COUNT(DISTINCT Id)`, and sums). Additional
  /// `Detalhe` columns are listed in a SQL block comment so they are not lost
  /// when extending this resumo — see [_queryMiddleSelect].
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
''';

  /// Middle projection: only columns referenced by the outer resumo.
  ///
  /// Other [ParcelaProdutoVendidoDetalheSql] outputs are documented in the SQL
  /// comment block and can be added here when a new slice needs them.
  static const String _queryMiddleSelect = '''
      SELECT
        /*
          Detalhe columns NOT projected (still emitted by
          ParcelaProdutoVendidoDetalheSql — uncomment in this list when needed):
            CodProdutoVendido,
            CodOrigem,
            CodVendedor,
            NomeVendedor,
            CodCliente,
            NomeCliente,
            CodGrupoCliente,
            NomeGrupoCliente,
            CodMunicipio,
            NomeMunicipio,
            UFMunicipio,
            Bairro,
            CodRegiao,
            NomeRegiao,
            DataEmissao,
            DataVencimento,
            NumeroDocumento,
            NumeroParcela,
            TipoForma,
            ValorTotalParcelas,
            ValorTotalParcelasRateioTroco,
            ValorTotalTrocoVenda
        */
        CodEmpresa,
        CodFilial,
        Id,
        Origem,
        GeraFinanceiro,
        PreVenda,
        DataVenda,
        NomeUsuario,
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
      _queryMiddleSelect +
      ParcelaProdutoVendidoDetalheSql.selectFromParcelLinesThroughJoins +
      _queryTail;
}

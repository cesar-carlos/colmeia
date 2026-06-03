import 'package:colmeia/features/agent_queries/data/queries/parcela_produto_vendido_detalhe_sql.dart';

abstract final class ResumoParcelaFormaPagamentoSqlV2 {
  /// Coarser-grain payment-method resumo for overview and dashboards.
  ///
  /// Groups by branch and payment method only (`CodEmpresa`, `CodFilial`,
  /// `CodFormaPagamento`, `DescricaoFormaPagamento`). Operator rankings and
  /// month series come from `ResumoParcelaPorUsuarioSql` and
  /// `ResumoParcelasMensalSql`, not from this query.
  ///
  /// Inner slice is [ParcelaProdutoVendidoDetalheSql.selectFromParcelLinesForOverviewAggregate]
  /// for troco semantics; outer aggregate uses `SUM(ValorParcela - ValorTrocoParcela)`
  /// and `COUNT(DISTINCT Id)`.
  ///
  /// Date filter uses a half-open calendar range on `DataVenda` (sargable, aligned
  /// with map/daily SQL).
  static const String _queryHead = '''
    SELECT
      CodEmpresa,
      CodFilial,
      CodFormaPagamento,
      DescricaoFormaPagamento,
      COUNT(DISTINCT Id) AS QtdVendas,
      SUM(ValorParcela - ValorTrocoParcela) AS ValorParcela
    FROM (
''';

  static const String _queryMiddleSelect = '''
      SELECT
        CodEmpresa,
        CodFilial,
        Id,
        Origem,
        GeraFinanceiro,
        PreVenda,
        DataVenda,
        CodFormaPagamento,
        DescricaoFormaPagamento,
        ValorTrocoParcela,
        ValorParcela
      FROM (
''';

  static const String _queryTail = '''
      ) Detalhe
    ) ResumoParcelaFormaPagamentoV2
    WHERE DataVenda >= CAST(:dataVendaInicio AS DATE)
      AND DataVenda < DATEADD(day, 1, CAST(:dataVendaFim AS DATE))
      AND Origem = :origem
      AND GeraFinanceiro = :geraFinanceiro
      AND PreVenda = :preVenda
    GROUP BY
      CodEmpresa,
      CodFilial,
      CodFormaPagamento,
      DescricaoFormaPagamento
    ORDER BY
      CodEmpresa,
      CodFilial,
      ValorParcela DESC,
      CodFormaPagamento
  ''';

  static const String query =
      _queryHead +
      _queryMiddleSelect +
      ParcelaProdutoVendidoDetalheSql.selectFromParcelLinesForOverviewAggregate +
      _queryTail;
}

import 'package:colmeia/features/agent_queries/data/queries/parcela_produto_vendido_detalhe_sql.dart';

/// Parcel resumo aggregated by sale user only (no payment method dimension).
///
/// Used for correct per-operator distinct sale counts and ticket averages
/// across multi-payment sales. Same inner slice as
/// `ResumoParcelaFormaPagamentoSql` for troco semantics.
///
/// **Overview note:** home/overview loads `ResumoParcelaFormaPagamentoSql` in
/// the main batch; per-user rankings use payment-method aggregation as fallback
/// when a dedicated per-user batch command is not run.
abstract final class ResumoParcelaPorUsuarioSql {
  static const String _queryHead = '''
    SELECT
      CodEmpresa,
      CodFilial,
      NomeUsuario,
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
        NomeUsuario,
        ValorTrocoParcela,
        ValorParcela
      FROM (
''';

  static const String _queryTail = '''
      ) Detalhe
    ) ResumoParcelaPorUsuario
    WHERE DataVenda BETWEEN :dataVendaInicio AND :dataVendaFim
      AND Origem LIKE :origem
      AND GeraFinanceiro = :geraFinanceiro
      AND PreVenda = :preVenda
    GROUP BY
      CodEmpresa,
      CodFilial,
      NomeUsuario
    ORDER BY
      CodEmpresa,
      CodFilial,
      ValorParcela DESC
  ''';

  static const String query =
      _queryHead +
      _queryMiddleSelect +
      ParcelaProdutoVendidoDetalheSql.selectFromParcelLinesThroughJoins +
      _queryTail;
}

import 'package:colmeia/features/agent_queries/data/queries/parcela_produto_vendido_detalhe_sql.dart';

abstract final class ResumoParcelaFormaPagamentoDiarioSql {
  /// One row per sold product line (CodProdutoVendido) in the filtered period,
  /// with distinct sale count and net value after troco on parcel lines.
  ///
  /// Inner slice uses LEFT JOIN for GrupoCliente, Regiao, and Vendedor; columns
  /// from those joins may be SQL NULL when no matching row exists.
  ///
  /// The inner query selects many columns for future filters; when those land,
  /// push predicates into the inner slice where possible and validate indexes
  /// on the ERP side if this becomes hot.
  static const String _queryHead = '''
    SELECT
      CodEmpresa,
      CodFilial,
      CodProdutoVendido,
      Origem,
      CodOrigem,
      DataVenda,
      AnoMesDataVenda,
      NomeUsuario,
      CodVendedor,
      NomeVendedor,
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
  ) ResumoVendaProdutoDiario
  WHERE DataVenda >= CAST(:dataVendaInicio AS DATE)
    AND DataVenda < DATEADD(day, 1, CAST(:dataVendaFim AS DATE))
    AND Origem = :origem
    AND GeraFinanceiro = :geraFinanceiro
    AND PreVenda = :preVenda
  GROUP BY
    CodEmpresa,
    CodFilial,
    CodProdutoVendido,
    Origem,
    CodOrigem,
    DataVenda,
    AnoMesDataVenda,
    NomeUsuario,
    CodVendedor,
    NomeVendedor
  ORDER BY
    CodEmpresa,
    CodFilial,
    CodProdutoVendido,
    DataVenda
  ''';

  static const String query =
      _queryHead +
      ParcelaProdutoVendidoDetalheSql.selectFromParcelLinesThroughJoins +
      _queryTail;
}

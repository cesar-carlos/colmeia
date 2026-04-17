import 'package:colmeia/features/agent_queries/data/queries/parcela_produto_vendido_detalhe_sql.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_sql_dimension_filters.dart';

abstract final class ResumoParcelasDiaSemanaUsuarioSql {
  /// Weekday parcel summary by company, branch, sale user name, and calendar
  /// weekday of sale date, with distinct sale counts and net parcel totals
  /// after troco allocation.
  ///
  /// Inner `Detalhe` comes from `ParcelaProdutoVendidoDetalheSql`; `NomeUsuario`
  /// is normalized there (empty → `Usuario nao informado`).
  ///
  /// Optional dimensions are inlined (see [ResumoParcelasSqlDimensionFilters])
  /// for the Agent SQL bridge named-parameter limit.
  ///
  /// Column `DiaSemanaNumero` uses day difference from a known Sunday
  /// (`2000-01-02`) in the middle layer so it does not depend on `DATEFIRST`
  /// or locale. Sunday = 1 … Saturday = 7, matching app weekday labels.
  ///
  /// Cardinality is up to users × 7 weekdays × branches in filter scope.
  ///
  /// **Agent policy review**: driving rows are `ParcelaProdutoVendido` joined
  /// to `ProdutoVendido`, `FormaPagamento`, `TipoOperacaoSaida`, `Cliente`,
  /// `Municipio`, optional `GrupoCliente`, `Regiao`, `Vendedor`, plus
  /// pre-aggregated joins for parcel totals and troco (see
  /// `ParcelaProdutoVendidoDetalheSql`).
  ///
  /// **Performance (SQL Server)**: keep `ProdutoVendido` selective on
  /// `DataVenda`, `Origem`, `CodEmpresa`, and `CodFilial` via supporting
  /// indexes; parcel aggregates benefit from
  /// `(CodEmpresa, CodProdutoVendido)` on `ParcelaProdutoVendido`.
  ///
  /// **Bridge named-parameter caps**: at most five named binds are sent;
  /// optional dimensions are inlined as integer literals (see
  /// [ResumoParcelasSqlDimensionFilters]).
  static const String _queryHead = '''
    SELECT
      CodEmpresa,
      CodFilial,
      NomeUsuario,
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
    ) ResumoParcelasDiaSemanaUsuario
    WHERE DataVenda BETWEEN :dataVendaInicio AND :dataVendaFim
      AND Origem LIKE :origem
      AND GeraFinanceiro = :geraFinanceiro
      AND PreVenda = :preVenda
__RESUMO_PARCELAS_DIMENSION_WHERE__
    GROUP BY
      CodEmpresa,
      CodFilial,
      NomeUsuario,
      DiaSemanaNumero
    ORDER BY
      CodEmpresa,
      CodFilial,
      NomeUsuario,
      DiaSemanaNumero
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

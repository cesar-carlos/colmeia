/// Conservative `max_rows` for `sql.execute` on aggregate queries with bounded
/// row counts (safety net if SQL or grouping changes).
abstract final class AgentQueriesBoundedResultMaxRows {
  /// Shared cap for aggregates that return many buckets across companies and
  /// branches (e.g. weekday or month per filial).
  static const int aggregateMultiBranchCap = 1600;

  /// `GROUP BY` company, branch, and weekday (up to seven buckets per branch).
  static const int resumoParcelasDiaSemana = aggregateMultiBranchCap;

  /// Company, branch, user, and weekday — higher cardinality than
  /// [resumoParcelasDiaSemana].
  static const int resumoParcelasDiaSemanaUsuario = 5000;

  /// One row per calendar month per company/branch; deployments with many
  /// branches exceed [aggregateMultiBranchCap] (12 months × filiais).
  static const int resumoParcelasMensal = 8000;

  /// Company, branch, sale year, and payment method buckets in the range.
  static const int resumoParcelasAnual = aggregateMultiBranchCap;

  /// Payment method × month × user (and similar); overview forma pagamento.
  static const int resumoParcelaFormaPagamento = 5000;

  /// Same cardinality as `resumoParcelaFormaPagamento` (por-mes report).
  static const int resumoParcelasFormaPagamentoPorMes = 5000;

  /// One row per sold product line in the filtered period.
  static const int resumoParcelaFormaPagamentoDiario = 10000;

  /// Daily sales by seller grid rows.
  static const int resumoVendasDiariasPorVendedor = 5000;

  /// Suggestion lists for vendedor/bairro/município (`TOP` limits; bridge cap).
  static const int vendasDiariasSuggestionOptions = 128;

  /// One page of `Municipio` list rows (same order of magnitude as list filter
  /// max page size in domain).
  static const int municipioListPage = 100;

  /// Monthly product profitability buckets: `(months in range) × filiais`.
  /// At most ~13 months × many branches; 2 000 is a conservative safety cap.
  static const int resumoProdutoVendaLucratividadeMensal = 2000;

  /// Period product profitability: one row per `CodEmpresa/CodFilial`.
  /// Bounded by the number of active branches; 200 is a generous safety cap.
  static const int resumoProdutoVendaLucratividade = 200;

  /// `TOP 15` product ranking rows — margin above the nominal cap as a safety net.
  static const int produtoVendidoProdutoRankLucro = 32;
}

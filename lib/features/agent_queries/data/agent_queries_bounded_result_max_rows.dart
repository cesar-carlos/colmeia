/// Conservative `max_rows` for `sql.execute` on aggregate queries with bounded
/// row counts (safety net if SQL or grouping changes).
abstract final class AgentQueriesBoundedResultMaxRows {
  /// Shared cap for aggregates that return many buckets across companies and
  /// branches (e.g. weekday or month per filial).
  static const int aggregateMultiBranchCap = 1600;

  /// `GROUP BY` company, branch, and weekday (up to seven buckets per branch).
  static const int resumoParcelasDiaSemana = aggregateMultiBranchCap;

  /// One row per calendar month in the filtered range.
  static const int resumoParcelasMensal = aggregateMultiBranchCap;

  /// Company, branch, sale year, and payment method buckets in the range.
  static const int resumoParcelasAnual = aggregateMultiBranchCap;
}

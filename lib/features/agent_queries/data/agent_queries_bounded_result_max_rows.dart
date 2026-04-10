/// Conservative `max_rows` for `sql.execute` on aggregate queries with bounded
/// row counts (safety net if SQL or grouping changes).
abstract final class AgentQueriesBoundedResultMaxRows {
  /// `GROUP BY` weekday yields at most seven rows.
  static const int resumoParcelasDiaSemana = 32;

  /// One row per calendar month in the filtered range.
  static const int resumoParcelasMensal = 1600;
}

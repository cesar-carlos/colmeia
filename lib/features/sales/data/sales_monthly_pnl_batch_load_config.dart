import 'package:colmeia/features/agent_queries/data/agent_queries_bounded_result_max_rows.dart';

/// Timeouts and row caps for the Resultado mensal `sql.executeBatch` path.
abstract final class SalesMonthlyPnlBatchLoadConfig {
  /// Matches the unary monthly/daily sales use-case bridge timeout (300s).
  static const int bridgeTimeoutMs = 300000;

  static const int sqlTimeoutMs = 300000;

  /// Batch-level `max_rows` shared by both slots. Uses the daily totals cap so
  /// custom day grids are not truncated under the monthly (400) ceiling.
  /// Monthly slot still warns against
  /// [AgentQueriesBoundedResultMaxRows.resumoProdutoVendaLucratividadeMensal].
  static const int batchMaxRows =
      AgentQueriesBoundedResultMaxRows.resumoTotalDiarioVendas;

  static const int monthlyWarnMaxRows =
      AgentQueriesBoundedResultMaxRows.resumoProdutoVendaLucratividadeMensal;

  static const int dailyWarnMaxRows =
      AgentQueriesBoundedResultMaxRows.resumoTotalDiarioVendas;
}

import 'package:colmeia/features/agent_queries/data/agent_queries_bounded_result_max_rows.dart';

/// Timeouts and row caps for the Resultado mensal `sql.executeBatch` path.
abstract final class SalesMonthlyPnlBatchLoadConfig {
  /// Matches the unary monthly/daily sales use-case bridge timeout (300s).
  static const int bridgeTimeoutMs = 300000;

  static const int sqlTimeoutMs = 300000;

  /// Shared batch `max_rows`. Kept at the monthly report cap (400) because
  /// higher values returned empty success for the ItemProdutoVendido monthly
  /// shape on the E2E SQL Anywhere agent. Single-branch daily months fit under
  /// this; multi-branch day grids may truncate (warned at the use case).
  static const int batchMaxRows =
      AgentQueriesBoundedResultMaxRows.resumoProdutoVendaLucratividadeMensal;
}

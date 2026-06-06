import 'package:colmeia/features/agent_queries/data/agent_queries_bounded_result_max_rows.dart';

/// Shared timeout and row-cap settings for overview SQL batch loads.
abstract final class OverviewBatchLoadConfig {
  /// Hub validates `sql.executeBatch` `options.timeout_ms` at <= 300_000.
  static const int bridgeTimeoutMs = 300000;
  static const int sqlTimeoutMs = 300000;
  static const int maxRows =
      AgentQueriesBoundedResultMaxRows.resumoParcelasMensal;
}

import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_batch_request.dart';

/// Shared [AgentSqlExecuteBatchOptions] for read-only dashboard-style batches.
///
/// Centralizes `max_parallel_read_only_batch_items` from
/// [AppEnvironment.agentSqlOverviewBatchMaxParallelReadOnlyItems] so feature
/// batch loaders match overview tuning without duplicating literals.
abstract final class AgentSqlReadOnlyBatchOptions {
  const AgentSqlReadOnlyBatchOptions._();

  /// Read-only batch: `transaction: false`, hub parallelism from env.
  static AgentSqlExecuteBatchOptions dashboard({
    required int sqlTimeoutMs,
    required int maxRows,
    int? maxParallelReadOnlyBatchItems,
  }) {
    return AgentSqlExecuteBatchOptions(
      sqlTimeoutMs: sqlTimeoutMs,
      maxRows: maxRows,
      transaction: false,
      maxParallelReadOnlyBatchItems:
          maxParallelReadOnlyBatchItems ??
          AppEnvironment.agentSqlOverviewBatchMaxParallelReadOnlyItems,
    );
  }
}

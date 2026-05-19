import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_batch_execution_result.dart';

/// Rows (or failure) parsed from one [AgentSqlBatchExecutionItem] slot.
final class AgentSqlBatchItemRowsResult<Row> {
  const AgentSqlBatchItemRowsResult({
    required this.rows,
    this.failure,
  });

  final List<Row> rows;
  final AppFailure? failure;
}

/// Maps batch execution items to typed rows for non-overview batch paths.
abstract final class AgentSqlBatchItemRowsMapper {
  static AgentSqlBatchItemRowsResult<Row> mapRowsForIndex<Row extends Object>(
    Map<int, AgentSqlBatchExecutionItem> byIndex,
    int index,
    Row Function(Map<String, dynamic> row) mapRow, {
    String operation = 'sql.executeBatch',
  }) {
    final item = byIndex[index];
    if (item == null) {
      return AgentSqlBatchItemRowsResult<Row>(
        rows: List<Row>.empty(),
        failure: RpcFailure(
          message: 'sql.executeBatch item $index is missing',
          userMessage: 'Nao foi possivel carregar esta consulta.',
          rpcCode: null,
          retryable: false,
          reason: 'missing_batch_item',
          context: <String, Object?>{
            'operation': operation,
            'batchItemIndex': index,
          },
        ),
      );
    }
    if (!item.ok) {
      return AgentSqlBatchItemRowsResult<Row>(
        rows: List<Row>.empty(),
        failure: RpcFailure(
          message: item.error ?? 'sql.executeBatch item failed',
          userMessage: item.error ?? 'Nao foi possivel carregar esta consulta.',
          rpcCode: null,
          retryable: false,
          reason: 'batch_item_failed',
          context: <String, Object?>{
            'operation': operation,
            'batchItemIndex': index,
          },
        ),
      );
    }

    try {
      return AgentSqlBatchItemRowsResult<Row>(
        rows: item.rows.map(mapRow).toList(growable: false),
      );
    } on Object catch (error, stackTrace) {
      return AgentSqlBatchItemRowsResult<Row>(
        rows: List<Row>.empty(),
        failure: UnknownFailure(
          message: 'Unable to parse sql.executeBatch item $index rows',
          userMessage: 'Nao foi possivel interpretar esta consulta.',
          cause: error,
          stackTrace: stackTrace,
          context: <String, Object?>{
            'operation': operation,
            'batchItemIndex': index,
          },
        ),
      );
    }
  }
}

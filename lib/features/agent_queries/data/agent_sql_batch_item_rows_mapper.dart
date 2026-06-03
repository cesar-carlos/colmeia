import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/data/agent_sql_batch_item_rpc_failure_mapper.dart';
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
        failure: AgentSqlBatchItemRpcFailureMapper.missingItem(
          index: index,
          operation: operation,
        ),
      );
    }
    if (!item.ok) {
      return AgentSqlBatchItemRowsResult<Row>(
        rows: List<Row>.empty(),
        failure: AgentSqlBatchItemRpcFailureMapper.fromFailedItem(
          item: item,
          operation: operation,
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

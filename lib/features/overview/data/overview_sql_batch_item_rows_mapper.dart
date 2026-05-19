import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/data/agent_sql_batch_item_rows_mapper.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_batch_execution_result.dart';

/// Rows (or failure) parsed from one [AgentSqlBatchExecutionItem] slot in an
/// overview `sql.executeBatch` response.
final class OverviewSqlBatchItemRowsResult<Row> {
  const OverviewSqlBatchItemRowsResult({
    required this.rows,
    this.failure,
  });

  final List<Row> rows;
  final AppFailure? failure;
}

/// Maps batch execution items to typed rows for the overview batch load path.
abstract final class OverviewSqlBatchItemRowsMapper {
  static OverviewSqlBatchItemRowsResult<Row>
  mapRowsForIndex<Row extends Object>(
    Map<int, AgentSqlBatchExecutionItem> byIndex,
    int index,
    Row Function(Map<String, dynamic> row) mapRow,
  ) {
    final inner = AgentSqlBatchItemRowsMapper.mapRowsForIndex(
      byIndex,
      index,
      mapRow,
      operation: 'loadOverviewBatch',
    );
    return OverviewSqlBatchItemRowsResult<Row>(
      rows: inner.rows,
      failure: inner.failure,
    );
  }
}

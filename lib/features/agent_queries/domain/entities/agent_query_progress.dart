import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';

class AgentQueryProgress<Row> {
  AgentQueryProgress({
    required Iterable<Row> rows,
    required this.isComplete,
    required this.receivedRowCount,
  }) : rows = List.unmodifiable(rows);

  /// Partial events contain new rows; the final event contains the full snapshot.
  final List<Row> rows;
  final bool isComplete;
  final int receivedRowCount;
}

class AgentQueryProgressObserver {
  AgentQueryProgressObserver(this.onRows);
  final void Function(AgentSqlExecutionResult) onRows;
  bool hasPublishedRows = false;

  void publish(AgentSqlExecutionResult result) {
    if (result.rows.isEmpty) return;
    hasPublishedRows = true;
    onRows(result);
  }
}

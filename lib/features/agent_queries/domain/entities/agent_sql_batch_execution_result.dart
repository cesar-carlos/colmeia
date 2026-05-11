class AgentSqlBatchExecutionResult {
  const AgentSqlBatchExecutionResult({
    required this.items,
    required this.totalCommands,
    required this.successfulCommands,
    required this.failedCommands,
    this.executionId,
  });

  final List<AgentSqlBatchExecutionItem> items;
  final int totalCommands;
  final int successfulCommands;
  final int failedCommands;
  final String? executionId;
}

class AgentSqlBatchExecutionItem {
  const AgentSqlBatchExecutionItem({
    required this.index,
    required this.ok,
    required this.rows,
    required this.rowCount,
    this.affectedRows,
    this.error,
    this.columnMetadata = const <Map<String, dynamic>>[],
  });

  final int index;
  final bool ok;
  final List<Map<String, dynamic>> rows;
  final int rowCount;
  final int? affectedRows;
  final String? error;
  final List<Map<String, dynamic>> columnMetadata;
}

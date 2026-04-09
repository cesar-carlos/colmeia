import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_pagination_result.dart';

/// Normalized outcome of a successful `sql.execute` RPC (bridge envelope
/// already unwrapped).
class AgentSqlExecutionResult {
  const AgentSqlExecutionResult({
    required this.rows,
    required this.rowCount,
    this.executionId,
    this.affectedRows,
    this.pagination,
  });

  final List<Map<String, dynamic>> rows;
  final int rowCount;
  final String? executionId;
  final int? affectedRows;

  /// Present when the request used hub pagination or agent returned cursors.
  final AgentSqlPaginationResult? pagination;
}

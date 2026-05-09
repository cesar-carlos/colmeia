import 'package:colmeia/core/logging/app_logger.dart';

/// Logs when the bridge returned at least [maxRows] rows — the agent may have
/// truncated the result set at the requested cap.
void agentQueriesWarnIfSqlRowsAtCap({
  required String operation,
  required String agentId,
  required int returnedRowCount,
  required int maxRows,
}) {
  if (returnedRowCount >= maxRows) {
    AppLogger.warning(
      'Agent SQL row count reached max_rows; result may be truncated',
      context: <String, Object?>{
        'operation': operation,
        'agentId': agentId,
        'returnedRowCount': returnedRowCount,
        'maxRows': maxRows,
      },
    );
  }
}

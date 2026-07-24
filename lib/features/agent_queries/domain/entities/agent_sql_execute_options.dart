import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_bridge_limits.dart';

/// Agent-side execution flags for `sql.execute` (`params.options` in JSON-RPC).
class AgentSqlExecuteOptions {
  const AgentSqlExecuteOptions({
    this.maxRows,
    this.sqlTimeoutMs,
    this.executionMode,
    this.preferDbStreaming,
  });

  /// Maps to `options.max_rows` on the agent.
  final int? maxRows;

  /// Maps to `options.timeout_ms` (SQL execution timeout on the agent).
  final int? sqlTimeoutMs;

  /// Maps to `options.execution_mode` (`managed` is the agent default).
  final AgentSqlExecutionMode? executionMode;

  /// Maps to `options.prefer_db_streaming`.
  ///
  /// This is a bridge-side performance hint. `null` omits the field so the
  /// agent keeps its default behavior.
  final bool? preferDbStreaming;

  String? validationError() {
    final max = maxRows;
    if (max != null && max < 1) {
      return 'maxRows must be >= 1';
    }
    if (max != null && max > AgentSqlBridgeLimits.maxRowsMax) {
      return 'maxRows must be <= ${AgentSqlBridgeLimits.maxRowsMax}';
    }

    final timeout = sqlTimeoutMs;
    if (timeout != null && timeout < 1) {
      return 'sqlTimeoutMs must be >= 1';
    }
    if (timeout != null && timeout > AgentSqlBridgeLimits.sqlTimeoutMsMax) {
      return 'sqlTimeoutMs must be <= ${AgentSqlBridgeLimits.sqlTimeoutMsMax}';
    }

    return null;
  }

  /// `null` when every field is null (omit `options` in the payload).
  Map<String, Object?>? toRpcOptions() {
    final map = <String, Object?>{};
    final max = maxRows;
    if (max != null) {
      map['max_rows'] = max;
    }
    final timeout = sqlTimeoutMs;
    if (timeout != null) {
      map['timeout_ms'] = timeout;
    }
    final mode = executionMode;
    if (mode != null) {
      map['execution_mode'] = switch (mode) {
        AgentSqlExecutionMode.managed => 'managed',
        AgentSqlExecutionMode.preserve => 'preserve',
      };
    }
    final preferStreaming = preferDbStreaming;
    if (preferStreaming != null) {
      map['prefer_db_streaming'] = preferStreaming;
    }
    return map.isEmpty ? null : map;
  }
}

enum AgentSqlExecutionMode {
  managed,
  preserve,
}

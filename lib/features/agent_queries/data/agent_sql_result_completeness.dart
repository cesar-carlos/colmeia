import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/domain/agent_sql_rpc_failure_ui_key.dart';

/// Rejects bounded aggregates whose completeness cannot be established.
abstract final class AgentSqlResultCompleteness {
  static AppFailure? failure({
    required int rowCount,
    required int receivedRows,
    required int maxRows,
  }) {
    if (rowCount == receivedRows && receivedRows < maxRows) return null;
    return UnknownFailure(
      message:
          'Incomplete aggregate result: refine the period or branch filters',
      context: <String, Object?>{
        'rowCount': rowCount,
        'receivedRows': receivedRows,
        'maxRows': maxRows,
        AgentSqlRpcFailureUiKey.field:
            AgentSqlRpcFailureUiKey.unexpectedAgentResponse,
      },
    );
  }
}

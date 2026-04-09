import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_bridge_pagination.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_options.dart';

/// Semantic input for a single `sql.execute` call through the bridge.
class AgentSqlExecuteRequest {
  const AgentSqlExecuteRequest({
    required this.agentId,
    required this.sql,
    this.namedParams = const <String, Object?>{},
    this.clientToken,
    this.bridgeTimeoutMs,
    this.pagination,
    this.executeOptions,
  });

  final String agentId;
  final String sql;
  final Map<String, Object?> namedParams;
  final String? clientToken;

  /// HTTP bridge wait timeout (`timeoutMs` in the request body).
  final int? bridgeTimeoutMs;

  /// HTTP body pagination injected by the hub into `params.options`.
  final AgentSqlBridgePagination? pagination;

  /// Agent-side execution flags under `params.options`.
  final AgentSqlExecuteOptions? executeOptions;

  String get trimmedAgentId => agentId.trim();
  String get trimmedSql => sql.trim();
  String? get trimmedClientToken => clientToken?.trim();

  String? validationError() {
    if (trimmedAgentId.isEmpty) {
      return 'agentId must not be empty';
    }
    if (trimmedSql.isEmpty) {
      return 'sql must not be empty';
    }

    final timeout = bridgeTimeoutMs;
    if (timeout != null && timeout < 1) {
      return 'bridgeTimeoutMs must be >= 1';
    }

    final token = trimmedClientToken;
    if (clientToken != null && (token == null || token.isEmpty)) {
      return 'clientToken must be null or non-empty';
    }

    final pagePagination = pagination;
    if (pagePagination is AgentSqlPagePagination) {
      if (pagePagination.page < 1) {
        return 'pagination.page must be >= 1';
      }
      if (pagePagination.pageSize < 1) {
        return 'pagination.pageSize must be >= 1';
      }
    }
    if (pagePagination is AgentSqlCursorPagination) {
      if (pagePagination.cursor.trim().isEmpty) {
        return 'pagination.cursor must be non-empty';
      }
    }

    final optionsError = executeOptions?.validationError();
    if (optionsError != null) {
      return optionsError;
    }
    if (pagination != null &&
        executeOptions?.executionMode == AgentSqlExecutionMode.preserve) {
      return 'pagination cannot be combined with executionMode.preserve';
    }

    return null;
  }
}

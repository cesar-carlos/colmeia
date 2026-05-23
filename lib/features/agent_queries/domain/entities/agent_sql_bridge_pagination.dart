/// Hub body `pagination` for `POST /agents/commands` (injected into
/// `command.params.options` by the server).
///
/// Use [AgentSqlPagePagination] or [AgentSqlCursorPagination], not both.
sealed class AgentSqlBridgePagination {
  const AgentSqlBridgePagination();

  /// JSON fragment under the HTTP `pagination` key.
  Map<String, Object?> toHttpBody();

  /// Pagination fields merged into `params.options` on relay (no REST body
  /// envelope).
  Map<String, Object?> toRpcOptions();
}

/// Offset pagination (`page` + `pageSize`, 1-based page).
///
/// SQL must include a stable `ORDER BY` when using pagination (hub/agent
/// contract).
final class AgentSqlPagePagination extends AgentSqlBridgePagination {
  const AgentSqlPagePagination({
    required this.page,
    required this.pageSize,
  }) : assert(page >= 1, 'page must be >= 1'),
       assert(pageSize >= 1, 'pageSize must be >= 1');

  final int page;
  final int pageSize;

  @override
  Map<String, Object?> toHttpBody() => <String, Object?>{
    'page': page,
    'pageSize': pageSize,
    'page_size': pageSize,
  };

  @override
  Map<String, Object?> toRpcOptions() => <String, Object?>{
    'page': page,
    'page_size': pageSize,
  };
}

/// Keyset continuation token from a previous response
/// (`result.pagination.next_cursor`).
final class AgentSqlCursorPagination extends AgentSqlBridgePagination {
  AgentSqlCursorPagination({required this.cursor})
    : assert(cursor.isNotEmpty, 'cursor must be non-empty');

  final String cursor;

  @override
  Map<String, Object?> toHttpBody() => <String, Object?>{
    'cursor': cursor,
  };

  @override
  Map<String, Object?> toRpcOptions() => <String, Object?>{
    'cursor': cursor,
  };
}

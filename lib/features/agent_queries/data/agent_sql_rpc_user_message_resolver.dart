import 'package:colmeia/features/agent_queries/data/models/agent_sql_bridge_response.dart';
import 'package:colmeia/features/agent_queries/domain/agent_sql_rpc_failure_ui_key.dart';

/// Policy (SQL/RPC → user-visible text):
///
/// - **Known RPC codes/reasons** resolve to a stable
///   [AgentSqlRpcUserMessageResolution.uiKey] so presentation can localize via
///   `AppLocalizations`.
/// - **Auth / permission**: transport auth failures such as
///   `authentication_failed`, `missing_client_token` and `token_revoked` map to
///   an authentication message; `unauthorized`/`forbidden` map to permission
///   denied and may prefer bridge `user_message` when it adds useful context.
/// - **Validation**: JSON-RPC `invalid_params` (`-32602`) is treated as query
///   validation for UX, even when the technical detail mentions SQL or
///   pagination. When `error.data.odbc_reason` is `invalid_policy`, the hub may
///   still use `-32002` + `unauthorized`; that case is classified as query
///   validation (policy / SQL classification), not generic permission denial.
/// - **Unclassified** errors: prefer bridge `user_message` when non-empty; else
///   generic English with [AgentSqlRpcFailureUiKey.generic].
///
/// [userMessage] is for logs and callers without localization; the dashboard
/// maps [uiKey] via `AppLocalizations`.
class AgentSqlRpcUserMessageResolution {
  const AgentSqlRpcUserMessageResolution({
    required this.userMessage,
    this.uiKey,
    this.preferBridgeUserMessage = false,
  });

  final String userMessage;

  /// When null, callers should surface [userMessage] as-is (e.g. bridge text).
  final String? uiKey;

  /// When true, UI should show the bridge `user_message` (see [userMessage]).
  final bool preferBridgeUserMessage;
}

/// English defaults: must match `lib/l10n/app_en.arb` `agentSqlError*`.
abstract final class _En {
  static const authenticationFailed =
      'Authentication is required to query this agent.';
  static const permissionDenied =
      'You do not have permission to query this data on this agent.';
  static const transportTimeout =
      'The agent took too long to respond. Please try again.';
  static const networkError =
      'Could not reach the agent right now. Please try again.';
  static const rateLimited =
      'Too many query attempts were made. Please wait a moment and try again.';
  static const sqlValidationFailed = 'The query is invalid.';
  static const sqlExecutionFailed = 'The query could not be executed.';
  static const transactionFailed =
      'The query transaction could not be completed.';
  static const connectionPoolExhausted =
      'The server is busy processing queries. Please try again shortly.';
  static const resultTooLarge =
      'The query returned too much data. Narrow filters and try again.';
  static const databaseConnectionFailed =
      'Could not connect to the database to run the query.';
  static const queryTimeout = 'The query took longer than expected.';
  static const invalidDatabaseConfig =
      "This agent's database access configuration is invalid.";
  static const executionNotFound = 'The requested execution was not found.';
  static const executionCancelled = 'The query was cancelled.';
  static const batchUnsupported =
      'This agent does not support batched SQL queries yet.';
  static const generic = 'The query could not be completed on the agent.';
}

String? _nonEmptyStringFromMap(Map<String, dynamic>? map, String key) {
  if (map == null) {
    return null;
  }
  final value = map[key];
  if (value is String && value.trim().isNotEmpty) {
    return value.trim();
  }
  return null;
}

/// Hub may return JSON-RPC `-32002` + `unauthorized` while
/// [AgentSqlRpcErrorDetails.errorData] carries `odbc_reason: invalid_policy`
/// for SQL policy / classification rejections (not generic permission denial).
String? _odbcReasonLower(Map<String, dynamic>? data) {
  if (data == null) {
    return null;
  }
  final raw = data['odbc_reason'] ?? data['odbcReason'];
  if (raw is String && raw.trim().isNotEmpty) {
    return raw.trim().toLowerCase();
  }
  return null;
}

AgentSqlRpcUserMessageResolution _localizedResolution({
  required String userMessage,
  required String uiKey,
  bool preferBridgeUserMessage = false,
}) {
  return AgentSqlRpcUserMessageResolution(
    userMessage: userMessage,
    uiKey: uiKey,
    preferBridgeUserMessage: preferBridgeUserMessage,
  );
}

bool _isRateLimitedReason(String? reasonLower) {
  if (reasonLower == null || reasonLower.isEmpty) {
    return false;
  }
  if (reasonLower == 'rate_limited' || reasonLower == 'rate_window_exceeded') {
    return true;
  }
  return reasonLower.endsWith('_rate_limited');
}

AgentSqlRpcUserMessageResolution _sqlValidationResolution(String bridge) {
  final trimmed = bridge.trim();
  if (trimmed.isNotEmpty) {
    return _localizedResolution(
      userMessage: trimmed,
      uiKey: AgentSqlRpcFailureUiKey.sqlValidationFailed,
      preferBridgeUserMessage: true,
    );
  }
  return const AgentSqlRpcUserMessageResolution(
    userMessage: _En.sqlValidationFailed,
    uiKey: AgentSqlRpcFailureUiKey.sqlValidationFailed,
  );
}

/// Maps bridge/RPC metadata to a stable UI key and English fallback copy.
AgentSqlRpcUserMessageResolution resolveAgentSqlRpcUserMessage(
  AgentSqlRpcErrorDetails details,
) {
  final code = details.code;
  final bridge = details.userMessage.trim();
  final data = details.errorData;
  final reason = details.reason ?? _nonEmptyStringFromMap(data, 'reason');
  final category = details.category ?? _nonEmptyStringFromMap(data, 'category');
  final reasonLower = reason?.toLowerCase();
  final categoryLower = category?.toLowerCase();
  final messageLower = details.message.toLowerCase();
  final methodLower =
      _nonEmptyStringFromMap(data, 'method')?.toLowerCase() ??
      _nonEmptyStringFromMap(data, 'rpc_method')?.toLowerCase() ??
      _nonEmptyStringFromMap(data, 'rpcMethod')?.toLowerCase();

  final isSqlExecuteBatchUnsupported =
      (code == -32601 ||
          reasonLower == 'method_not_found' ||
          reasonLower == 'method_not_supported' ||
          reasonLower == 'unsupported_method' ||
          messageLower.contains('method not found') ||
          messageLower.contains('unsupported method')) &&
      (methodLower == 'sql.executebatch' ||
          messageLower.contains('sql.executebatch'));
  if (isSqlExecuteBatchUnsupported) {
    return const AgentSqlRpcUserMessageResolution(
      userMessage: _En.batchUnsupported,
    );
  }

  final isAuthenticationFailure =
      code == -32001 ||
      reasonLower == 'authentication_failed' ||
      reasonLower == 'missing_client_token' ||
      reasonLower == 'token_revoked';
  if (isAuthenticationFailure) {
    return const AgentSqlRpcUserMessageResolution(
      userMessage: _En.authenticationFailed,
      uiKey: AgentSqlRpcFailureUiKey.authenticationFailed,
    );
  }

  // JSON-RPC / catalog codes for SQL validation must run before the broad
  // permission check: bridges may set `category: auth` for SQL policy or
  // authorization-layer rejections while still using -32602 / -32101.
  if (code == -32602 || code == -32101) {
    return _sqlValidationResolution(bridge);
  }

  final odbcReasonLower = _odbcReasonLower(data);
  if (odbcReasonLower == 'invalid_policy') {
    return _sqlValidationResolution(bridge);
  }

  final isPermissionDenied =
      code == -32002 ||
      categoryLower == 'auth' ||
      reasonLower == 'unauthorized' ||
      reasonLower == 'forbidden' ||
      messageLower.contains('not authorized') ||
      messageLower.contains('forbidden');
  if (isPermissionDenied) {
    if (bridge.isNotEmpty) {
      return _localizedResolution(
        userMessage: bridge,
        uiKey: AgentSqlRpcFailureUiKey.permissionDenied,
        preferBridgeUserMessage: true,
      );
    }
    return const AgentSqlRpcUserMessageResolution(
      userMessage: _En.permissionDenied,
      uiKey: AgentSqlRpcFailureUiKey.permissionDenied,
    );
  }

  if (code == -32008 ||
      (reasonLower == 'timeout' && categoryLower == 'transport')) {
    return const AgentSqlRpcUserMessageResolution(
      userMessage: _En.transportTimeout,
      uiKey: AgentSqlRpcFailureUiKey.transportTimeout,
    );
  }

  if (code == -32012 || reasonLower == 'network_error') {
    return const AgentSqlRpcUserMessageResolution(
      userMessage: _En.networkError,
      uiKey: AgentSqlRpcFailureUiKey.networkError,
    );
  }

  if (code == -32013 || _isRateLimitedReason(reasonLower)) {
    return const AgentSqlRpcUserMessageResolution(
      userMessage: _En.rateLimited,
      uiKey: AgentSqlRpcFailureUiKey.rateLimited,
    );
  }

  // replay_detected (-32014): hub idempotency guard fired (typically from
  // network-level packet duplication). RetryingAgentQueriesRepository retries
  // with a fresh UUID automatically; this mapping only applies when all retry
  // attempts are exhausted, in which case a generic transient message is shown.
  if (code == -32014 || reasonLower == 'replay_detected') {
    return const AgentSqlRpcUserMessageResolution(
      userMessage: _En.networkError,
      uiKey: AgentSqlRpcFailureUiKey.networkError,
    );
  }

  switch (code) {
    case -32102:
      return const AgentSqlRpcUserMessageResolution(
        userMessage: _En.sqlExecutionFailed,
        uiKey: AgentSqlRpcFailureUiKey.sqlExecutionFailed,
      );
    case -32103:
      return const AgentSqlRpcUserMessageResolution(
        userMessage: _En.transactionFailed,
        uiKey: AgentSqlRpcFailureUiKey.transactionFailed,
      );
    case -32104:
      return const AgentSqlRpcUserMessageResolution(
        userMessage: _En.connectionPoolExhausted,
        uiKey: AgentSqlRpcFailureUiKey.connectionPoolExhausted,
      );
    case -32105:
      return const AgentSqlRpcUserMessageResolution(
        userMessage: _En.resultTooLarge,
        uiKey: AgentSqlRpcFailureUiKey.resultTooLarge,
      );
    case -32106:
      return const AgentSqlRpcUserMessageResolution(
        userMessage: _En.databaseConnectionFailed,
        uiKey: AgentSqlRpcFailureUiKey.databaseConnectionFailed,
      );
    case -32107:
      return const AgentSqlRpcUserMessageResolution(
        userMessage: _En.queryTimeout,
        uiKey: AgentSqlRpcFailureUiKey.queryTimeout,
      );
    case -32108:
      return const AgentSqlRpcUserMessageResolution(
        userMessage: _En.invalidDatabaseConfig,
        uiKey: AgentSqlRpcFailureUiKey.invalidDatabaseConfig,
      );
    case -32109:
      return const AgentSqlRpcUserMessageResolution(
        userMessage: _En.executionNotFound,
        uiKey: AgentSqlRpcFailureUiKey.executionNotFound,
      );
    case -32110:
      return const AgentSqlRpcUserMessageResolution(
        userMessage: _En.executionCancelled,
        uiKey: AgentSqlRpcFailureUiKey.executionCancelled,
      );
    default:
      break;
  }

  switch (reasonLower) {
    case 'invalid_params':
    case 'sql_validation_failed':
      return _sqlValidationResolution(bridge);
    case 'sql_execution_failed':
      return const AgentSqlRpcUserMessageResolution(
        userMessage: _En.sqlExecutionFailed,
        uiKey: AgentSqlRpcFailureUiKey.sqlExecutionFailed,
      );
    case 'transaction_failed':
      return const AgentSqlRpcUserMessageResolution(
        userMessage: _En.transactionFailed,
        uiKey: AgentSqlRpcFailureUiKey.transactionFailed,
      );
    case 'connection_pool_exhausted':
      return const AgentSqlRpcUserMessageResolution(
        userMessage: _En.connectionPoolExhausted,
        uiKey: AgentSqlRpcFailureUiKey.connectionPoolExhausted,
      );
    case 'result_too_large':
      return const AgentSqlRpcUserMessageResolution(
        userMessage: _En.resultTooLarge,
        uiKey: AgentSqlRpcFailureUiKey.resultTooLarge,
      );
    case 'database_connection_failed':
      return const AgentSqlRpcUserMessageResolution(
        userMessage: _En.databaseConnectionFailed,
        uiKey: AgentSqlRpcFailureUiKey.databaseConnectionFailed,
      );
    case 'query_timeout':
      return const AgentSqlRpcUserMessageResolution(
        userMessage: _En.queryTimeout,
        uiKey: AgentSqlRpcFailureUiKey.queryTimeout,
      );
    case 'invalid_database_config':
      return const AgentSqlRpcUserMessageResolution(
        userMessage: _En.invalidDatabaseConfig,
        uiKey: AgentSqlRpcFailureUiKey.invalidDatabaseConfig,
      );
    case 'execution_not_found':
      return const AgentSqlRpcUserMessageResolution(
        userMessage: _En.executionNotFound,
        uiKey: AgentSqlRpcFailureUiKey.executionNotFound,
      );
    case 'execution_cancelled':
      return const AgentSqlRpcUserMessageResolution(
        userMessage: _En.executionCancelled,
        uiKey: AgentSqlRpcFailureUiKey.executionCancelled,
      );
    case 'timeout':
      if (categoryLower == 'sql') {
        return const AgentSqlRpcUserMessageResolution(
          userMessage: _En.queryTimeout,
          uiKey: AgentSqlRpcFailureUiKey.queryTimeout,
        );
      }
  }

  if (bridge.isNotEmpty) {
    return AgentSqlRpcUserMessageResolution(userMessage: bridge);
  }

  return const AgentSqlRpcUserMessageResolution(
    userMessage: _En.generic,
    uiKey: AgentSqlRpcFailureUiKey.generic,
  );
}

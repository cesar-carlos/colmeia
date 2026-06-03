import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/data/agent_sql_rpc_user_message_resolver.dart';
import 'package:colmeia/features/agent_queries/data/models/agent_sql_bridge_response.dart';
import 'package:colmeia/features/agent_queries/domain/agent_sql_rpc_failure_ui_key.dart';

/// Stable UI key for agent-query failures: context first, then RPC resolver.
String? resolveAgentQueryFailureUiKey(AppFailure failure) {
  final fromContext = failure.context[AgentSqlRpcFailureUiKey.field];
  if (fromContext is String && fromContext.isNotEmpty) {
    return fromContext;
  }

  if (failure is RpcFailure && failure.rpcCode != null) {
    return resolveAgentSqlRpcUserMessage(
      _rpcFailureToDetails(failure),
    ).uiKey;
  }

  return null;
}

AgentSqlRpcErrorDetails _rpcFailureToDetails(RpcFailure failure) {
  Map<String, dynamic>? errorData;
  final raw = failure.context[AgentSqlRpcFailureUiKey.errorDataField];
  if (raw is Map<String, dynamic>) {
    errorData = raw;
  } else if (raw is Map) {
    errorData = Map<String, dynamic>.from(raw);
  }

  return AgentSqlRpcErrorDetails(
    userMessage: failure.userMessage ?? '',
    message: failure.message,
    code: failure.rpcCode,
    reason: failure.reason,
    category: failure.category,
    retryable: failure.retryable,
    technicalMessage: failure.technicalMessage,
    correlationId: failure.correlationId,
    timestamp: failure.timestamp,
    errorData: errorData,
  );
}

/// Category-based UI key when transport metadata did not carry one.
String agentQueryFailureCategoryFallbackUiKey(AppFailure failure) {
  if (failure.context[AgentSqlRpcFailureUiKey.field] ==
      AgentSqlRpcFailureUiKey.rateLimited) {
    return AgentSqlRpcFailureUiKey.rateLimited;
  }
  if (failure is RpcFailure && failure.rpcCode == -32013) {
    return AgentSqlRpcFailureUiKey.rateLimited;
  }
  if (failure is SessionFailure) {
    return AgentSqlRpcFailureUiKey.authenticationFailed;
  }
  if (failure is AuthorizationFailure) {
    return AgentSqlRpcFailureUiKey.permissionDenied;
  }
  if (failure is ValidationFailure) {
    return AgentSqlRpcFailureUiKey.sqlValidationFailed;
  }
  if (failure is NetworkFailure || failure.isTransient) {
    return AgentSqlRpcFailureUiKey.networkError;
  }
  return AgentSqlRpcFailureUiKey.generic;
}

String agentQueryFailureResolvedUiKey(AppFailure failure) {
  return resolveAgentQueryFailureUiKey(failure) ??
      agentQueryFailureCategoryFallbackUiKey(failure);
}

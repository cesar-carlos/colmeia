import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/domain/agent_query_failure_context.dart';
import 'package:colmeia/features/agent_queries/domain/agent_sql_rpc_failure_ui_key.dart';

bool isCancelledAgentQueryFailureContext(Map<String, Object?> context) {
  return context[AgentQueryFailureContext.cancelledField] == true;
}

/// Whether [failure] should surface agent-query rate-limit copy (RPC, socket,
/// REST 429 on commands).
bool isAgentQueryRateLimitedFailure(AppFailure failure) {
  if (failure.context[AgentSqlRpcFailureUiKey.field] ==
      AgentSqlRpcFailureUiKey.rateLimited) {
    return true;
  }
  final transportCode =
      failure.context[AgentQueryFailureContext.transportCodeField];
  if (transportCode is String &&
      isAgentQueryTransportRateLimitedCode(transportCode)) {
    return true;
  }
  if (failure is RpcFailure && failure.rpcCode == -32013) {
    return true;
  }
  return false;
}

/// Whether [failure] is a hub replay-detected agent-query RPC (-32014).
bool isAgentQueryReplayDetectedFailure(AppFailure failure) {
  if (failure.context[AgentSqlRpcFailureUiKey.field] ==
      AgentSqlRpcFailureUiKey.replayDetected) {
    return true;
  }
  if (failure is RpcFailure &&
      (failure.rpcCode == -32014 ||
          failure.reason?.toLowerCase() == 'replay_detected')) {
    return true;
  }
  return false;
}

/// True when UI should not show an error surface (navigation away / cancel).
bool shouldSuppressAgentQueryFailureUi(AppFailure failure) {
  if (isCancelledAgentQueryFailureContext(failure.context)) {
    return true;
  }
  if (failure is OperationCancelledFailure) {
    return true;
  }
  final uiKey = failure.context[AgentSqlRpcFailureUiKey.field];
  return uiKey == AgentSqlRpcFailureUiKey.executionCancelled;
}

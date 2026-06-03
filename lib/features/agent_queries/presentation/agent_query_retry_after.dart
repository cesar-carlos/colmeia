import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/retry_after_gate.dart';
import 'package:colmeia/features/agent_queries/domain/agent_sql_rpc_failure_ui_key.dart';
import 'package:colmeia/features/agent_queries/presentation/localization/agent_query_failure_l10n.dart';

/// Short cooldown before retrying after hub replay detection (-32014).
const Duration kAgentQueryReplayDetectedCooldown = Duration(seconds: 3);

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

/// Whether a partial agent-query failure should arm the retry gate.
bool shouldArmRetryAfterFromPartialAgentQueryFailure(AppFailure failure) {
  if (shouldSuppressAgentQueryFailureUi(failure)) {
    return false;
  }
  return isAgentQueryRateLimitedFailure(failure) ||
      isAgentQueryReplayDetectedFailure(failure);
}

/// Arms [gate] when [failure] carries a hub `Retry-After` hint, a replay
/// cooldown applies, and the failure is not a deliberate cancellation.
void armAgentQueryRetryAfterGate(RetryAfterGate gate, AppFailure failure) {
  if (shouldSuppressAgentQueryFailureUi(failure)) {
    return;
  }
  final retryAfter = appFailureRetryAfter(failure);
  if (retryAfter != null) {
    gate.arm(retryAfter);
    return;
  }
  if (isAgentQueryReplayDetectedFailure(failure)) {
    gate.arm(kAgentQueryReplayDetectedCooldown);
  }
}

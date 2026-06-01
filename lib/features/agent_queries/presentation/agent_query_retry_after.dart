import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/retry_after_gate.dart';
import 'package:colmeia/features/agent_queries/presentation/localization/agent_query_failure_l10n.dart';

/// Arms [gate] when [failure] carries a hub `Retry-After` hint and the failure
/// is not a deliberate cancellation.
void armAgentQueryRetryAfterGate(RetryAfterGate gate, AppFailure failure) {
  if (shouldSuppressAgentQueryFailureUi(failure)) {
    return;
  }
  final retryAfter = appFailureRetryAfter(failure);
  if (retryAfter != null) {
    gate.arm(retryAfter);
  }
}

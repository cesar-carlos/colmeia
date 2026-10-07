import 'package:colmeia/core/errors/app_failure.dart';

/// Outcome of whether a single `sql.execute` may proceed for an agent.
class AgentSqlExecutionEligibilityEvaluation {
  const AgentSqlExecutionEligibilityEvaluation({
    required this.allowed,
    this.denialReason,
    this.failure,
  });

  const AgentSqlExecutionEligibilityEvaluation.allowed()
    : allowed = true,
      denialReason = null,
      failure = null;

  const AgentSqlExecutionEligibilityEvaluation.denied(String reason)
    : allowed = false,
      denialReason = reason,
      failure = null;

  const AgentSqlExecutionEligibilityEvaluation.failed(AppFailure error)
    : allowed = false,
      denialReason = null,
      failure = error;

  final bool allowed;
  final String? denialReason;
  final AppFailure? failure;
}

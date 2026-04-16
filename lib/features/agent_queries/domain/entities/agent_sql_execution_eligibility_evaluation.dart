/// Outcome of whether a single `sql.execute` may proceed for an agent.
class AgentSqlExecutionEligibilityEvaluation {
  const AgentSqlExecutionEligibilityEvaluation({
    required this.allowed,
    this.denialReason,
  });

  const AgentSqlExecutionEligibilityEvaluation.allowed()
    : allowed = true,
      denialReason = null;

  const AgentSqlExecutionEligibilityEvaluation.denied(String reason)
    : allowed = false,
      denialReason = reason;

  final bool allowed;
  final String? denialReason;
}

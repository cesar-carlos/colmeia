/// Stable context field names for agent-query failure classification.
abstract final class AgentQueryFailureContext {
  static const String cancelledField = 'cancelled';
  static const String transportCodeField = 'transportCode';
}

const Set<String> _socketRateLimitedCodes = <String>{
  'RATE_LIMITED',
  'TOO_MANY_REQUESTS',
};

bool isAgentQueryTransportRateLimitedCode(String code) {
  return _socketRateLimitedCodes.contains(code.toUpperCase());
}

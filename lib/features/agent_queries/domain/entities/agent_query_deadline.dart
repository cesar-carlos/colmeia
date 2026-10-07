import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_bridge_limits.dart';

class AgentQueryDeadline {
  AgentQueryDeadline(this.budget) : _elapsed = Stopwatch()..start();

  final Duration budget;
  final Stopwatch _elapsed;

  Duration get remaining {
    final value = budget - _elapsed.elapsed;
    return value.isNegative ? Duration.zero : value;
  }

  int clampTimeoutMs(int? timeoutMs) {
    final remainingMs = remaining.inMilliseconds;
    if (timeoutMs == null || timeoutMs > remainingMs) {
      return remainingMs.clamp(1, AgentSqlBridgeLimits.bridgeTimeoutMsMax);
    }
    return timeoutMs;
  }
}

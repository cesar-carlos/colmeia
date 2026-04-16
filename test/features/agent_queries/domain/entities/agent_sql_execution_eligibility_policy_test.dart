import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_eligibility_policy.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_connection_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const policy = AgentSqlExecutionEligibilityPolicy();

  test('allows SQL only for online when snapshot rules apply', () {
    check(policy.sqlAllowedForStatus(AgentConnectionStatus.online)).isTrue();
    check(policy.sqlAllowedForStatus(AgentConnectionStatus.offline)).isFalse();
    check(policy.sqlAllowedForStatus(AgentConnectionStatus.unknown)).isFalse();
  });

  test('cold start path does not blanket-deny', () {
    check(policy.allowWhenPresenceSnapshotUnavailable()).isTrue();
  });
}

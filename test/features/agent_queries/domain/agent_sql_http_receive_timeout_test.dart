import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/domain/agent_sql_http_receive_timeout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('null or invalid bridge timeout uses default receive duration', () {
    check(
      agentSqlHttpReceiveTimeout(),
    ).equals(kAgentSqlHttpDefaultReceiveTimeout);
    check(
      agentSqlHttpReceiveTimeout(bridgeTimeoutMs: 0),
    ).equals(kAgentSqlHttpDefaultReceiveTimeout);
  });

  test('adds buffer to bridge timeout milliseconds', () {
    check(
      agentSqlHttpReceiveTimeout(bridgeTimeoutMs: 45000),
    ).equals(const Duration(milliseconds: 50000));
  });

  test('caps at kAgentSqlHttpReceiveTimeoutMax', () {
    check(
      agentSqlHttpReceiveTimeout(bridgeTimeoutMs: 610000),
    ).equals(kAgentSqlHttpReceiveTimeoutMax);
  });
}

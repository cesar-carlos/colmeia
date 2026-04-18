import 'package:checks/checks.dart';
import 'package:colmeia/core/socket/agent_command_outcome.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AgentCommandOutcome.method', () {
    test('Success carries optional method', () {
      final s = AgentCommandSuccess(
        agentId: 'a',
        rpcId: 'r',
        observedAt: DateTime.utc(2026),
        elapsed: Duration.zero,
        method: 'sql.execute',
      );
      check(s.method).equals('sql.execute');
    });

    test('FailedOffline carries optional method', () {
      final f = AgentCommandFailedOffline(
        agentId: 'a',
        rpcId: 'r',
        observedAt: DateTime.utc(2026),
        elapsed: Duration.zero,
        reasonCode: 'AGENT_OFFLINE',
        method: 'sql.execute',
      );
      check(f.method).equals('sql.execute');
    });

    test('FailedAuth carries optional method', () {
      final f = AgentCommandFailedAuth(
        agentId: 'a',
        rpcId: 'r',
        observedAt: DateTime.utc(2026),
        elapsed: Duration.zero,
        reasonCode: 'AGENT_ACCESS_DENIED',
        method: 'agent.getProfile',
      );
      check(f.method).equals('agent.getProfile');
    });

    test('FailedTransient carries optional method', () {
      final f = AgentCommandFailedTransient(
        agentId: 'a',
        rpcId: 'r',
        observedAt: DateTime.utc(2026),
        elapsed: Duration.zero,
        reasonCode: 'timeout',
        method: 'sql.execute',
      );
      check(f.method).equals('sql.execute');
    });

    test('method is null when omitted', () {
      final s = AgentCommandSuccess(
        agentId: 'a',
        rpcId: 'r',
        observedAt: DateTime.utc(2026),
        elapsed: Duration.zero,
      );
      check(s.method).isNull();
    });
  });
}

import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/retry_after_gate.dart';
import 'package:colmeia/features/agent_queries/domain/agent_sql_rpc_failure_ui_key.dart';
import 'package:colmeia/features/agent_queries/presentation/agent_query_retry_after.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('armAgentQueryRetryAfterGate', () {
    test('arms gate from hub retryAfter hint', () {
      final gate = RetryAfterGate();
      const failure = RpcFailure(
        message: 'Rate limited',
        userMessage: 'Wait',
        rpcCode: -32013,
        retryable: true,
        retryAfter: Duration(seconds: 10),
      );

      armAgentQueryRetryAfterGate(gate, failure);

      check(gate.isOpen).isFalse();
      check(gate.remaining).equals(const Duration(seconds: 10));
      gate.dispose();
    });

    test('arms short cooldown for replay_detected without retryAfter', () {
      final gate = RetryAfterGate();
      const failure = RpcFailure(
        message: 'Replay detected',
        userMessage: 'Duplicate request',
        rpcCode: -32014,
        retryable: false,
        reason: 'replay_detected',
      );

      armAgentQueryRetryAfterGate(gate, failure);

      check(gate.isOpen).isFalse();
      check(gate.remaining).equals(kAgentQueryReplayDetectedCooldown);
      gate.dispose();
    });

    test('prefers hub retryAfter over replay cooldown when both apply', () {
      final gate = RetryAfterGate();
      const failure = RpcFailure(
        message: 'Replay detected',
        userMessage: 'Duplicate request',
        rpcCode: -32014,
        retryable: false,
        reason: 'replay_detected',
        retryAfter: Duration(seconds: 8),
      );

      armAgentQueryRetryAfterGate(gate, failure);

      check(gate.remaining).equals(const Duration(seconds: 8));
      gate.dispose();
    });

    test('does not arm gate for unrelated failures', () {
      final gate = RetryAfterGate();
      const failure = NetworkFailure(message: 'offline');

      armAgentQueryRetryAfterGate(gate, failure);

      check(gate.isOpen).isTrue();
      check(gate.remaining).isNull();
      gate.dispose();
    });
  });

  group('shouldArmRetryAfterFromPartialAgentQueryFailure', () {
    test('returns true for rate-limited and replay failures', () {
      const rateLimited = RpcFailure(
        message: 'Rate limited',
        userMessage: 'Wait',
        rpcCode: -32013,
        retryable: true,
      );
      const replay = RpcFailure(
        message: 'Replay detected',
        userMessage: 'Duplicate request',
        rpcCode: -32014,
        retryable: false,
        reason: 'replay_detected',
      );

      check(shouldArmRetryAfterFromPartialAgentQueryFailure(rateLimited))
          .isTrue();
      check(shouldArmRetryAfterFromPartialAgentQueryFailure(replay)).isTrue();
    });

    test('returns true when replay uiKey is carried in context', () {
      const failure = NetworkFailure(
        message: 'replay',
        context: <String, Object?>{
          AgentSqlRpcFailureUiKey.field:
              AgentSqlRpcFailureUiKey.replayDetected,
        },
      );

      check(shouldArmRetryAfterFromPartialAgentQueryFailure(failure)).isTrue();
    });

    test('returns false for unrelated partial failures', () {
      const failure = NetworkFailure(message: 'offline');

      check(shouldArmRetryAfterFromPartialAgentQueryFailure(failure)).isFalse();
    });
  });
}

import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/socket/relay/relay_dispatch_exception.dart';
import 'package:colmeia/core/socket/socket_dispatch_exception.dart';
import 'package:flutter_test/flutter_test.dart';

import 'e2e_dependency_bootstrap.dart';

void main() {
  group('isTransientE2eAgentSqlBridgeTransportFailure', () {
    test('is true for NetworkFailure with SocketDispatchTimeout cause', () {
      const failure = NetworkFailure(
        message: 'timeout',
        userMessage: 'u',
        cause: SocketDispatchTimeout(message: 't'),
      );
      expect(isTransientE2eAgentSqlBridgeTransportFailure(failure), isTrue);
      expect(isTransientAgentSqlBridgeHttpFailure(failure), isFalse);
    });

    test('is true for NetworkFailure with RelayConversationLost cause', () {
      const failure = NetworkFailure(
        message: 'lost',
        userMessage: 'u',
        cause: RelayConversationLost(message: 'm'),
      );
      expect(isTransientE2eAgentSqlBridgeTransportFailure(failure), isTrue);
    });

    test(
      'is true for NetworkFailure with RelayRequestRejected overload code',
      () {
        const failure = NetworkFailure(
          message: 'r',
          userMessage: 'u',
          cause: RelayRequestRejected(
            message: 'm',
            serverCode: 'SERVICE_UNAVAILABLE',
          ),
        );
        expect(isTransientE2eAgentSqlBridgeTransportFailure(failure), isTrue);
      },
    );

    test('is false for RelayRequestRejected with non-overload code', () {
      const failure = NetworkFailure(
        message: 'r',
        userMessage: 'u',
        cause: RelayRequestRejected(
          message: 'm',
          serverCode: 'AGENT_ACCESS_DENIED',
        ),
      );
      expect(isTransientE2eAgentSqlBridgeTransportFailure(failure), isFalse);
    });

    test('is false for NetworkFailure without dispatch cause', () {
      const failure = NetworkFailure(
        message: 'other',
        userMessage: 'u',
      );
      expect(isTransientE2eAgentSqlBridgeTransportFailure(failure), isFalse);
    });
  });

  group('isKnownE2eAgentSqlCircuitBreakerOpenFailure', () {
    test('returns true when circuitBreakerState is open', () {
      const failure = NetworkFailure(
        message: 'Circuit breaker open: hub overload protection active',
        userMessage: 'u',
        context: <String, Object?>{
          'circuitBreakerState': 'open',
        },
      );

      expect(isKnownE2eAgentSqlCircuitBreakerOpenFailure(failure), isTrue);
      expect(isAcceptableE2eAgentSqlRepositoryFailure(failure), isTrue);
    });

    test('returns false when circuitBreakerState is absent', () {
      const failure = NetworkFailure(
        message: 'Other network failure',
        userMessage: 'u',
      );

      expect(isKnownE2eAgentSqlCircuitBreakerOpenFailure(failure), isFalse);
    });
  });
}

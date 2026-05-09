import 'package:colmeia/core/errors/app_failure.dart';
import 'package:flutter_test/flutter_test.dart';

import 'e2e_dependency_bootstrap.dart';

void main() {
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

import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/socket/relay/relay_dispatch_exception.dart';
import 'package:colmeia/core/socket/socket_dispatch_exception.dart';
import 'package:colmeia/features/agent_queries/domain/agent_sql_rpc_failure_ui_key.dart';
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

  group('isKnownE2eAgentSqlDatabaseConnectionFailure', () {
    test('returns true for database_connection_failed RpcFailure', () {
      const failure = RpcFailure(
        message: 'Connection timeout when connecting to database',
        userMessage:
            'The database connection took longer than expected. '
            'Confirm the server is accessible and try again.',
        rpcCode: -32106,
        retryable: false,
        reason: 'database_connection_failed',
        category: 'database',
        context: <String, Object?>{
          AgentSqlRpcFailureUiKey.field:
              AgentSqlRpcFailureUiKey.databaseConnectionFailed,
        },
      );

      expect(isKnownE2eAgentSqlDatabaseConnectionFailure(failure), isTrue);
      expect(isRetryableE2eAgentSqlHubFailure(failure), isTrue);
      expect(isAcceptableE2eAgentSqlRepositoryFailure(failure), isTrue);
    });

    test('returns false for unrelated RpcFailure', () {
      const failure = RpcFailure(
        message: 'm',
        userMessage: 'u',
        rpcCode: -1,
        retryable: false,
        reason: 'sql_execution_failed',
        category: 'sql',
      );
      expect(isKnownE2eAgentSqlDatabaseConnectionFailure(failure), isFalse);
    });
  });

  group('isKnownE2eAgentDisconnectedAtDispatchFailure', () {
    test('returns true for agent_disconnected_at_dispatch RpcFailure', () {
      const failure = RpcFailure(
        message: 'm',
        userMessage: 'u',
        rpcCode: -32000,
        retryable: false,
        reason: 'agent_disconnected_at_dispatch',
      );
      expect(isKnownE2eAgentDisconnectedAtDispatchFailure(failure), isTrue);
      expect(isAcceptableE2eAgentSqlRepositoryFailure(failure), isTrue);
    });

    test('returns false for other RpcFailure reasons', () {
      const failure = RpcFailure(
        message: 'm',
        userMessage: 'u',
        rpcCode: -1,
        retryable: false,
        reason: 'other',
      );
      expect(isKnownE2eAgentDisconnectedAtDispatchFailure(failure), isFalse);
    });
  });

  group('isKnownE2eAgentSqlHubConcurrencyFailure', () {
    test('returns true for concurrent_handlers_exceeded RpcFailure', () {
      const failure = RpcFailure(
        message: 'Too many query attempts were made.',
        userMessage: 'Wait and try again.',
        rpcCode: -32013,
        retryable: true,
        reason: 'concurrent_handlers_exceeded',
        category: 'transport',
        context: <String, Object?>{
          AgentSqlRpcFailureUiKey.field: AgentSqlRpcFailureUiKey.rateLimited,
        },
      );

      expect(isKnownE2eAgentSqlHubConcurrencyFailure(failure), isTrue);
      expect(isAcceptableE2eAgentSqlRepositoryFailure(failure), isTrue);
    });

    test('returns false for unrelated RpcFailure', () {
      const failure = RpcFailure(
        message: 'm',
        userMessage: 'u',
        rpcCode: -1,
        retryable: false,
        reason: 'sql_execution_failed',
        category: 'sql',
      );

      expect(isKnownE2eAgentSqlHubConcurrencyFailure(failure), isFalse);
    });

    test('returns true for rate_limited RpcFailure reason', () {
      const failure = RpcFailure(
        message: 'Rate limit exceeded.',
        userMessage: 'Wait and try again.',
        rpcCode: -32013,
        retryable: true,
        reason: 'rate_limited',
        category: 'transport',
      );

      expect(isKnownE2eAgentSqlHubConcurrencyFailure(failure), isTrue);
      expect(isAcceptableE2eAgentSqlRepositoryFailure(failure), isTrue);
    });

    test('returns true when only uiKey is rateLimited', () {
      const failure = RpcFailure(
        message: 'Hub busy.',
        userMessage: 'Wait and try again.',
        rpcCode: -32013,
        retryable: true,
        category: 'transport',
        context: <String, Object?>{
          AgentSqlRpcFailureUiKey.field: AgentSqlRpcFailureUiKey.rateLimited,
        },
      );

      expect(isKnownE2eAgentSqlHubConcurrencyFailure(failure), isTrue);
      expect(isAcceptableE2eAgentSqlRepositoryFailure(failure), isTrue);
    });
  });

  group('isKnownE2eAgentSqlResultTooLargeFailure', () {
    test('returns true for result_too_large RpcFailure by rpc code', () {
      const failure = RpcFailure(
        message: 'Result set exceeds size limit',
        userMessage: 'The query returned too many rows.',
        rpcCode: -32105,
        retryable: false,
        reason: 'result_too_large',
        category: 'sql',
        context: <String, Object?>{
          AgentSqlRpcFailureUiKey.field: AgentSqlRpcFailureUiKey.resultTooLarge,
        },
      );

      expect(isKnownE2eAgentSqlResultTooLargeFailure(failure), isTrue);
      expect(isAcceptableE2eAgentSqlRepositoryFailure(failure), isTrue);
    });

    test('returns true when only uiKey is resultTooLarge', () {
      const failure = RpcFailure(
        message: 'Result too large',
        userMessage: 'Too many rows.',
        rpcCode: -32105,
        retryable: false,
        category: 'sql',
        context: <String, Object?>{
          AgentSqlRpcFailureUiKey.field: AgentSqlRpcFailureUiKey.resultTooLarge,
        },
      );

      expect(isKnownE2eAgentSqlResultTooLargeFailure(failure), isTrue);
      expect(isAcceptableE2eAgentSqlRepositoryFailure(failure), isTrue);
    });

    test('returns false for unrelated RpcFailure', () {
      const failure = RpcFailure(
        message: 'm',
        userMessage: 'u',
        rpcCode: -32104,
        retryable: false,
        reason: 'connection_pool_exhausted',
        category: 'sql',
      );

      expect(isKnownE2eAgentSqlResultTooLargeFailure(failure), isFalse);
      expect(isAcceptableE2eAgentSqlRepositoryFailure(failure), isFalse);
    });
  });

  group('isKnownE2eAgentSqlStreamCapacityReachedFailure', () {
    test(
      'returns true when error data code is AGENT_STREAM_CAPACITY_REACHED',
      () {
        const failure = RpcFailure(
          message: 'Relay stream capacity reached',
          userMessage: 'Wait and try again.',
          rpcCode: -32000,
          retryable: true,
          reason: 'stream_capacity_reached',
          category: 'transport',
          context: <String, Object?>{
            AgentSqlRpcFailureUiKey.errorDataField: <String, Object?>{
              'code': 'AGENT_STREAM_CAPACITY_REACHED',
            },
          },
        );

        expect(isKnownE2eAgentSqlStreamCapacityReachedFailure(failure), isTrue);
        expect(isAcceptableE2eAgentSqlRepositoryFailure(failure), isTrue);
      },
    );

    test('returns false for unrelated error data code', () {
      const failure = RpcFailure(
        message: 'm',
        userMessage: 'u',
        rpcCode: -32000,
        retryable: true,
        category: 'transport',
        context: <String, Object?>{
          AgentSqlRpcFailureUiKey.errorDataField: <String, Object?>{
            'code': 'RATE_LIMITED',
          },
        },
      );

      expect(isKnownE2eAgentSqlStreamCapacityReachedFailure(failure), isFalse);
    });

    test('returns false for non-RpcFailure', () {
      const failure = NetworkFailure(
        message: 'other',
        userMessage: 'u',
      );

      expect(isKnownE2eAgentSqlStreamCapacityReachedFailure(failure), isFalse);
    });
  });

  group('isKnownE2eAgentSqlHttpForbiddenFailure', () {
    test('accepts batch Agent SQL authorization failures', () {
      const failure = AuthorizationFailure(
        message: 'forbidden',
        context: <String, Object?>{
          'operation': 'executeAgentSqlBatch',
          'httpStatusCode': 403,
        },
      );

      expect(isKnownE2eAgentSqlHttpForbiddenFailure(failure), isTrue);
      expect(isAcceptableE2eAgentSqlRepositoryFailure(failure), isTrue);
    });

    test('accepts AGENT_ACCESS_DENIED payload after context merge', () {
      const failure = AuthorizationFailure(
        message: 'overview failed',
        userMessage:
            'You do not have access to agent 3183a9f2-429b-46d6-a339-3580e5e5cb31',
        context: <String, Object?>{
          'operation': 'loadOverview',
          'httpStatusCode': 403,
          DioHttpFailureContext.responseBodyField: <String, Object?>{
            'code': 'AGENT_ACCESS_DENIED',
          },
        },
      );

      expect(isKnownE2eAgentSqlHttpForbiddenFailure(failure), isTrue);
      expect(
        isKnownE2eAgentSqlAgentAccessDeniedFailure(failure),
        isTrue,
      );
      expect(isAcceptableE2eAgentSqlRepositoryFailure(failure), isTrue);
    });

    test('does not accept unrelated 403 failures', () {
      const failure = AuthorizationFailure(
        message: 'blocked',
        context: <String, Object?>{
          'operation': 'loadOverview',
          'httpStatusCode': 403,
          DioHttpFailureContext.responseBodyField: <String, Object?>{
            'code': 'ACCOUNT_BLOCKED',
          },
        },
      );

      expect(isKnownE2eAgentSqlHttpForbiddenFailure(failure), isFalse);
      expect(
        isKnownE2eAgentSqlAgentAccessDeniedFailure(failure),
        isFalse,
      );
      expect(isAcceptableE2eAgentSqlRepositoryFailure(failure), isFalse);
    });
  });
}

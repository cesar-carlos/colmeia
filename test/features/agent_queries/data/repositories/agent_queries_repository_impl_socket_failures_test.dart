import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/socket/relay/relay_dispatch_exception.dart';
import 'package:colmeia/core/socket/socket_dispatch_exception.dart';
import 'package:colmeia/features/agent_queries/data/datasources/agent_queries_remote_datasource.dart';
import 'package:colmeia/features/agent_queries/data/repositories/agent_queries_failure_codes.dart';
import 'package:colmeia/features/agent_queries/data/repositories/agent_queries_repository_impl.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';
import 'package:flutter_test/flutter_test.dart';

AppFailure _failureOf(AppResult<AgentSqlExecutionResult> result) {
  return result.fold(
    (success) => throw StateError('expected failure, got success'),
    (failure) => failure,
  );
}

class _ThrowingDataSource implements AgentQueriesRemoteDataSource {
  _ThrowingDataSource(this.error);
  final Exception error;

  @override
  Future<Map<String, dynamic>> postSqlExecute(AgentSqlExecuteRequest request) {
    throw error;
  }
}

void main() {
  const request = AgentSqlExecuteRequest(
    agentId: 'agent-1',
    sql: 'SELECT 1',
  );

  group('AgentQueriesRepositoryImpl Socket failure mapping', () {
    test('maps SocketDispatchUnauthorized to SessionFailure', () async {
      final repo = AgentQueriesRepositoryImpl(
        _ThrowingDataSource(
          const SocketDispatchUnauthorized(message: 'no token'),
        ),
      );
      final failure = _failureOf(await repo.executeSql(request));
      check(failure).isA<SessionFailure>();
      check(failure.context[AgentQueriesFailureContext.transportField])
          .equals('socket');
      check(failure.context[AgentQueriesFailureContext.transportCodeField])
          .equals('unauthorized');
    });

    test(
      'maps SocketDispatchAppError(AGENT_ACCESS_DENIED) to AuthorizationFailure',
      () async {
        final repo = AgentQueriesRepositoryImpl(
          _ThrowingDataSource(
            const SocketDispatchAppError(
              message: 'denied',
              serverCode: 'AGENT_ACCESS_DENIED',
            ),
          ),
        );
        final failure = _failureOf(await repo.executeSql(request));
        check(failure).isA<AuthorizationFailure>();
        check(failure.context[AgentQueriesFailureContext.transportCodeField])
            .equals('AGENT_ACCESS_DENIED');
      },
    );

    test(
      'maps SocketDispatchAppError(FORBIDDEN) to AuthorizationFailure '
      '(BUG #2: widened auth-like allowlist)',
      () async {
        final repo = AgentQueriesRepositoryImpl(
          _ThrowingDataSource(
            const SocketDispatchAppError(
              message: 'forbidden',
              serverCode: 'FORBIDDEN',
            ),
          ),
        );
        final failure = _failureOf(await repo.executeSql(request));
        check(failure).isA<AuthorizationFailure>();
        check(failure.userMessage)
            .isNotNull()
            .contains('nao tem acesso');
      },
    );

    test(
      'maps SocketDispatchAppError(permission_denied lowercase) to '
      'AuthorizationFailure (case-insensitive)',
      () async {
        final repo = AgentQueriesRepositoryImpl(
          _ThrowingDataSource(
            const SocketDispatchAppError(
              message: 'no permission',
              serverCode: 'permission_denied',
            ),
          ),
        );
        final failure = _failureOf(await repo.executeSql(request));
        check(failure).isA<AuthorizationFailure>();
      },
    );

    test(
      'maps SocketDispatchAppError(UNAUTHORIZED) to SessionFailure '
      '(BUG #2: auth-failed codes mapped to session)',
      () async {
        final repo = AgentQueriesRepositoryImpl(
          _ThrowingDataSource(
            const SocketDispatchAppError(
              message: 'token rejected',
              serverCode: 'UNAUTHORIZED',
            ),
          ),
        );
        final failure = _failureOf(await repo.executeSql(request));
        check(failure).isA<SessionFailure>();
        check(failure.userMessage)
            .isNotNull()
            .contains('sessao expirou');
      },
    );

    test(
      'maps SocketDispatchAppError(TOKEN_EXPIRED) to SessionFailure',
      () async {
        final repo = AgentQueriesRepositoryImpl(
          _ThrowingDataSource(
            const SocketDispatchAppError(
              message: 'expired',
              serverCode: 'TOKEN_EXPIRED',
            ),
          ),
        );
        final failure = _failureOf(await repo.executeSql(request));
        check(failure).isA<SessionFailure>();
      },
    );

    test(
      'maps SocketDispatchAppError(SERVICE_UNAVAILABLE) to NetworkFailure',
      () async {
        final repo = AgentQueriesRepositoryImpl(
          _ThrowingDataSource(
            const SocketDispatchAppError(
              message: 'overloaded',
              serverCode: 'SERVICE_UNAVAILABLE',
            ),
          ),
        );
        final failure = _failureOf(await repo.executeSql(request));
        check(failure).isA<NetworkFailure>();
        check(failure.context[AgentQueriesFailureContext.transportCodeField])
            .equals('SERVICE_UNAVAILABLE');
      },
    );

    test('maps SocketDispatchTimeout to NetworkFailure', () async {
      final repo = AgentQueriesRepositoryImpl(
        _ThrowingDataSource(
          const SocketDispatchTimeout(message: 'timed out'),
        ),
      );
      final failure = _failureOf(await repo.executeSql(request));
      check(failure).isA<NetworkFailure>();
      check(failure.context[AgentQueriesFailureContext.transportCodeField])
          .equals('timeout');
    });

    test('maps SocketDispatchDisconnected to NetworkFailure', () async {
      final repo = AgentQueriesRepositoryImpl(
        _ThrowingDataSource(
          const SocketDispatchDisconnected(message: 'gone'),
        ),
      );
      final failure = _failureOf(await repo.executeSql(request));
      check(failure).isA<NetworkFailure>();
      check(failure.context[AgentQueriesFailureContext.transportCodeField])
          .equals('disconnected');
    });

    test(
      'maps SocketDispatchCancelled to UnknownFailure with cancelled flag '
      '(BUG #2: cancellation must be benign for the UI)',
      () async {
        final repo = AgentQueriesRepositoryImpl(
          _ThrowingDataSource(
            const SocketDispatchCancelled(message: 'controller disposed'),
          ),
        );
        final failure = _failureOf(await repo.executeSql(request));
        check(failure).isA<UnknownFailure>();
        check(failure.context[AgentQueriesFailureContext.cancelledField])
            .equals(true);
        check(isCancelledAgentQueryFailure(failure.context)).isTrue();
        check(failure.context[AgentQueriesFailureContext.transportCodeField])
            .equals('cancelled');
      },
    );
  });

  group('AgentQueriesRepositoryImpl Relay failure mapping (BUG #1)', () {
    test('maps RelayRequestTimeout to NetworkFailure with PT user message',
        () async {
      final repo = AgentQueriesRepositoryImpl(
        _ThrowingDataSource(
          const RelayRequestTimeout(
            message: 'no response in 30s',
            conversationId: 'conv-1',
            clientRequestId: 'req-1',
          ),
        ),
      );
      final failure = _failureOf(await repo.executeSql(request));
      check(failure).isA<NetworkFailure>();
      check(failure.userMessage)
          .isNotNull()
          .contains('demorou mais');
      check(failure.context[AgentQueriesFailureContext.transportField])
          .equals('relay');
      check(failure.context[AgentQueriesFailureContext.transportCodeField])
          .equals('timeout');
      check(failure.context['conversationId']).equals('conv-1');
      check(failure.context['clientRequestId']).equals('req-1');
    });

    test('maps RelayConversationLost to NetworkFailure (transient)',
        () async {
      final repo = AgentQueriesRepositoryImpl(
        _ThrowingDataSource(
          const RelayConversationLost(
            message: 'socket dropped',
            conversationId: 'conv-1',
          ),
        ),
      );
      final failure = _failureOf(await repo.executeSql(request));
      check(failure).isA<NetworkFailure>();
      check(failure.userMessage)
          .isNotNull()
          .contains('conexao com o servidor caiu');
      check(failure.context[AgentQueriesFailureContext.transportCodeField])
          .equals('conversation_lost');
    });

    test(
      'maps RelayConversationStartFailure to NetworkFailure with specific message',
      () async {
        final repo = AgentQueriesRepositoryImpl(
          _ThrowingDataSource(
            const RelayConversationStartFailure(message: 'hub overloaded'),
          ),
        );
        final failure = _failureOf(await repo.executeSql(request));
        check(failure).isA<NetworkFailure>();
        check(failure.userMessage)
            .isNotNull()
            .contains('abrir o canal');
        check(failure.context[AgentQueriesFailureContext.transportCodeField])
            .equals('conversation_start_failed');
      },
    );

    test(
      'maps RelayRequestRejected(AGENT_ACCESS_DENIED) to AuthorizationFailure '
      '(BUG #1: relay rejection codes go through the same auth allowlist)',
      () async {
        final repo = AgentQueriesRepositoryImpl(
          _ThrowingDataSource(
            const RelayRequestRejected(
              message: 'no access',
              serverCode: 'AGENT_ACCESS_DENIED',
              conversationId: 'conv-1',
              clientRequestId: 'req-1',
            ),
          ),
        );
        final failure = _failureOf(await repo.executeSql(request));
        check(failure).isA<AuthorizationFailure>();
        check(failure.userMessage)
            .isNotNull()
            .contains('nao tem acesso');
      },
    );

    test(
      'maps RelayRequestRejected(UNAUTHORIZED) to SessionFailure',
      () async {
        final repo = AgentQueriesRepositoryImpl(
          _ThrowingDataSource(
            const RelayRequestRejected(
              message: 'token rejected',
              serverCode: 'UNAUTHORIZED',
            ),
          ),
        );
        final failure = _failureOf(await repo.executeSql(request));
        check(failure).isA<SessionFailure>();
      },
    );

    test('maps RelayRequestRejected(RATE_LIMITED) to NetworkFailure',
        () async {
      final repo = AgentQueriesRepositoryImpl(
        _ThrowingDataSource(
          const RelayRequestRejected(
            message: 'too many',
            serverCode: 'RATE_LIMITED',
          ),
        ),
      );
      final failure = _failureOf(await repo.executeSql(request));
      check(failure).isA<NetworkFailure>();
      check(failure.context[AgentQueriesFailureContext.transportCodeField])
          .equals('RATE_LIMITED');
    });

    test('maps RelayStreamTerminated(aborted) to NetworkFailure', () async {
      final repo = AgentQueriesRepositoryImpl(
        _ThrowingDataSource(
          const RelayStreamTerminated(
            message: 'aborted',
            terminalStatus: 'aborted',
            conversationId: 'conv-1',
          ),
        ),
      );
      final failure = _failureOf(await repo.executeSql(request));
      check(failure).isA<NetworkFailure>();
      check(failure.userMessage)
          .isNotNull()
          .contains('interrompida');
      check(failure.context[AgentQueriesFailureContext.transportCodeField])
          .equals('stream_aborted');
    });

    test(
      'maps RelayDecodeFailure to NetworkFailure with format-related message',
      () async {
        final repo = AgentQueriesRepositoryImpl(
          _ThrowingDataSource(
            const RelayDecodeFailure(
              message: 'gzip ratio exceeded',
              conversationId: 'conv-1',
            ),
          ),
        );
        final failure = _failureOf(await repo.executeSql(request));
        check(failure).isA<NetworkFailure>();
        check(failure.userMessage)
            .isNotNull()
            .contains('formato invalido');
      },
    );

    test(
      'maps RelayDuplicateRequestId to UnknownFailure (caller bug, surface in monitoring)',
      () async {
        final repo = AgentQueriesRepositoryImpl(
          _ThrowingDataSource(
            const RelayDuplicateRequestId(
              message: 'duplicated',
              conversationId: 'conv-1',
              clientRequestId: 'req-1',
            ),
          ),
        );
        final failure = _failureOf(await repo.executeSql(request));
        check(failure).isA<UnknownFailure>();
        check(failure.context[AgentQueriesFailureContext.transportCodeField])
            .equals('duplicate_request_id');
      },
    );

    test(
      'maps RelayDispatcherDisposed to UnknownFailure with cancelled flag',
      () async {
        final repo = AgentQueriesRepositoryImpl(
          _ThrowingDataSource(
            const RelayDispatcherDisposed(
              message: 'logging out',
            ),
          ),
        );
        final failure = _failureOf(await repo.executeSql(request));
        check(failure).isA<UnknownFailure>();
        check(failure.context[AgentQueriesFailureContext.cancelledField])
            .equals(true);
        check(isCancelledAgentQueryFailure(failure.context)).isTrue();
      },
    );
  });
}

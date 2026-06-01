import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/core/socket/relay/relay_dispatch_exception.dart';
import 'package:colmeia/core/socket/socket_dispatch_exception.dart';
import 'package:colmeia/features/agent_queries/data/datasources/agent_queries_remote_datasource.dart';
import 'package:colmeia/features/agent_queries/data/repositories/agent_queries_failure_codes.dart';
import 'package:colmeia/features/agent_queries/data/repositories/agent_queries_repository_impl.dart';
import 'package:colmeia/features/agent_queries/domain/agent_sql_rpc_failure_ui_key.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_batch_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_batch_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';

AppFailure _failureOf(AppResult<AgentSqlExecutionResult> result) {
  return result.fold(
    (success) => throw StateError('expected failure, got success'),
    (failure) => failure,
  );
}

AppFailure _batchFailureOf(AppResult<AgentSqlBatchExecutionResult> result) {
  return result.fold(
    (success) => throw StateError('expected failure, got success'),
    (failure) => failure,
  );
}

class _ThrowingDataSource implements AgentQueriesRemoteDataSource {
  _ThrowingDataSource(this.error);
  final Exception error;

  @override
  Future<Map<String, dynamic>> postSqlExecute(
    AgentSqlExecuteRequest request, {
    AgentQueriesCancelScope? cancelScope,
  }) {
    throw error;
  }

  @override
  Future<Map<String, dynamic>> postSqlExecuteBatch(
    AgentSqlExecuteBatchRequest request, {
    AgentQueriesCancelScope? cancelScope,
  }) {
    throw error;
  }
}

void main() {
  late Level previousLogLevel;

  setUpAll(() {
    previousLogLevel = AppLogger.minimumLevel;
    AppLogger.minimumLevel = Level.off;
  });

  tearDownAll(() {
    AppLogger.minimumLevel = previousLogLevel;
  });

  const request = AgentSqlExecuteRequest(
    agentId: 'agent-1',
    sql: 'SELECT 1',
  );
  const batchRequest = AgentSqlExecuteBatchRequest(
    agentId: 'agent-1',
    commands: <AgentSqlExecuteBatchCommand>[
      AgentSqlExecuteBatchCommand(sql: 'SELECT 1'),
    ],
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
      check(
        failure.context[AgentQueriesFailureContext.transportField],
      ).equals('socket');
      check(
        failure.context[AgentQueriesFailureContext.transportCodeField],
      ).equals('unauthorized');
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
        check(
          failure.context[AgentQueriesFailureContext.transportCodeField],
        ).equals('AGENT_ACCESS_DENIED');
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
        check(
          failure.context[AgentSqlRpcFailureUiKey.field],
        ).equals(AgentSqlRpcFailureUiKey.permissionDenied);
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
        check(
          failure.context[AgentSqlRpcFailureUiKey.field],
        ).equals(AgentSqlRpcFailureUiKey.authenticationFailed);
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
              retryAfter: Duration(milliseconds: 750),
            ),
          ),
        );
        final failure = _failureOf(await repo.executeSql(request));
        check(failure).isA<NetworkFailure>();
        check((failure as NetworkFailure).retryAfter).equals(
          const Duration(milliseconds: 750),
        );
        check(
          failure.context[AgentQueriesFailureContext.transportCodeField],
        ).equals('SERVICE_UNAVAILABLE');
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
      check(
        failure.context[AgentQueriesFailureContext.transportCodeField],
      ).equals('timeout');
    });

    test('maps SocketDispatchDisconnected to NetworkFailure', () async {
      final repo = AgentQueriesRepositoryImpl(
        _ThrowingDataSource(
          const SocketDispatchDisconnected(message: 'gone'),
        ),
      );
      final failure = _failureOf(await repo.executeSql(request));
      check(failure).isA<NetworkFailure>();
      check(
        failure.context[AgentQueriesFailureContext.transportCodeField],
      ).equals('disconnected');
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
        check(
          failure.context[AgentQueriesFailureContext.cancelledField],
        ).equals(true);
        check(isCancelledAgentQueryFailure(failure.context)).isTrue();
        check(
          failure.context[AgentQueriesFailureContext.transportCodeField],
        ).equals('cancelled');
      },
    );
  });

  group('AgentQueriesRepositoryImpl Relay failure mapping (BUG #1)', () {
    test(
      'maps RelayRequestTimeout to NetworkFailure with PT user message',
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
        check(
          failure.context[AgentSqlRpcFailureUiKey.field],
        ).equals(AgentSqlRpcFailureUiKey.transportTimeout);
        check(
          failure.context[AgentQueriesFailureContext.transportField],
        ).equals('relay');
        check(
          failure.context[AgentQueriesFailureContext.transportCodeField],
        ).equals('timeout');
        check(failure.context['conversationId']).equals('conv-1');
        check(failure.context['clientRequestId']).equals('req-1');
      },
    );

    test('maps RelayConversationLost to NetworkFailure (transient)', () async {
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
      check(
        failure.context[AgentSqlRpcFailureUiKey.field],
      ).equals(AgentSqlRpcFailureUiKey.networkError);
      check(
        failure.context[AgentQueriesFailureContext.transportCodeField],
      ).equals('conversation_lost');
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
        check(
          failure.context[AgentSqlRpcFailureUiKey.field],
        ).equals(AgentSqlRpcFailureUiKey.networkError);
        check(
          failure.context[AgentQueriesFailureContext.transportCodeField],
        ).equals('conversation_start_failed');
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
        check(
          failure.context[AgentSqlRpcFailureUiKey.field],
        ).equals(AgentSqlRpcFailureUiKey.permissionDenied);
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

    test('maps RelayRequestRejected(RATE_LIMITED) to NetworkFailure', () async {
      final repo = AgentQueriesRepositoryImpl(
        _ThrowingDataSource(
          const RelayRequestRejected(
            message: 'too many',
            serverCode: 'RATE_LIMITED',
            retryAfter: Duration(seconds: 2),
          ),
        ),
      );
      final failure = _failureOf(await repo.executeSql(request));
      check(failure).isA<NetworkFailure>();
      check((failure as NetworkFailure).retryAfter).equals(
        const Duration(seconds: 2),
      );
      check(
        failure.context[AgentQueriesFailureContext.transportCodeField],
      ).equals('RATE_LIMITED');
      check(
        failure.context[AgentSqlRpcFailureUiKey.field],
      ).equals(AgentSqlRpcFailureUiKey.rateLimited);
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
      check(
        failure.context[AgentSqlRpcFailureUiKey.field],
      ).equals(AgentSqlRpcFailureUiKey.networkError);
      check(
        failure.context[AgentQueriesFailureContext.transportCodeField],
      ).equals('stream_aborted');
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
        check(
          failure.context[AgentSqlRpcFailureUiKey.field],
        ).equals(AgentSqlRpcFailureUiKey.generic);
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
        check(
          failure.context[AgentQueriesFailureContext.transportCodeField],
        ).equals('duplicate_request_id');
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
        check(
          failure.context[AgentQueriesFailureContext.cancelledField],
        ).equals(true);
        check(isCancelledAgentQueryFailure(failure.context)).isTrue();
      },
    );
  });

  group('AgentQueriesRepositoryImpl batch Socket/Relay failure mapping', () {
    test('maps SocketDispatchTimeout to transient NetworkFailure', () async {
      final repo = AgentQueriesRepositoryImpl(
        _ThrowingDataSource(
          const SocketDispatchTimeout(message: 'timed out'),
        ),
      );

      final failure = _batchFailureOf(await repo.executeSqlBatch(batchRequest));

      check(failure).isA<NetworkFailure>();
      check(failure.isTransient).isTrue();
      check(
        failure.context[AgentQueriesFailureContext.transportField],
      ).equals('socket');
      check(
        failure.context[AgentQueriesFailureContext.transportCodeField],
      ).equals('timeout');
    });

    test(
      'maps SocketDispatchDisconnected to transient NetworkFailure',
      () async {
        final repo = AgentQueriesRepositoryImpl(
          _ThrowingDataSource(
            const SocketDispatchDisconnected(message: 'reconnect exhausted'),
          ),
        );

        final failure = _batchFailureOf(
          await repo.executeSqlBatch(batchRequest),
        );

        check(failure).isA<NetworkFailure>();
        check(failure.isTransient).isTrue();
        check(
          failure.context[AgentQueriesFailureContext.transportCodeField],
        ).equals('disconnected');
      },
    );

    test('maps SocketDispatchUnauthorized to SessionFailure', () async {
      final repo = AgentQueriesRepositoryImpl(
        _ThrowingDataSource(
          const SocketDispatchUnauthorized(message: 'no token'),
        ),
      );

      final failure = _batchFailureOf(await repo.executeSqlBatch(batchRequest));

      check(failure).isA<SessionFailure>();
      check(
        failure.context[AgentQueriesFailureContext.transportCodeField],
      ).equals('unauthorized');
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

        final failure = _batchFailureOf(
          await repo.executeSqlBatch(batchRequest),
        );

        check(failure).isA<AuthorizationFailure>();
        check(
          failure.context[AgentQueriesFailureContext.transportCodeField],
        ).equals('AGENT_ACCESS_DENIED');
      },
    );

    test(
      'maps SocketDispatchAppError(SERVICE_UNAVAILABLE) with retryAfter',
      () async {
        final repo = AgentQueriesRepositoryImpl(
          _ThrowingDataSource(
            const SocketDispatchAppError(
              message: 'overloaded',
              serverCode: 'SERVICE_UNAVAILABLE',
              retryAfter: Duration(milliseconds: 750),
            ),
          ),
        );

        final failure = _batchFailureOf(
          await repo.executeSqlBatch(batchRequest),
        );

        check(failure).isA<NetworkFailure>();
        check((failure as NetworkFailure).retryAfter).equals(
          const Duration(milliseconds: 750),
        );
        check(
          failure.context[AgentQueriesFailureContext.transportCodeField],
        ).equals('SERVICE_UNAVAILABLE');
      },
    );

    test(
      'maps SocketDispatchNamespaceForbidden to AuthorizationFailure',
      () async {
        final repo = AgentQueriesRepositoryImpl(
          _ThrowingDataSource(
            const SocketDispatchNamespaceForbidden(
              message: 'role forbidden',
              role: 'client',
              namespace: '/consumers',
            ),
          ),
        );

        final failure = _batchFailureOf(
          await repo.executeSqlBatch(batchRequest),
        );

        check(failure).isA<AuthorizationFailure>();
        check(
          failure.context[AgentQueriesFailureContext.transportCodeField],
        ).equals('namespace_forbidden');
        check(failure.context['role']).equals('client');
        check(failure.context['namespace']).equals('/consumers');
      },
    );

    test(
      'maps SocketDispatchLegacyStreamingUnsupported to UnknownFailure',
      () async {
        final repo = AgentQueriesRepositoryImpl(
          _ThrowingDataSource(
            const SocketDispatchLegacyStreamingUnsupported(
              message: 'stream',
              streamId: 'stream-1',
            ),
          ),
        );

        final failure = _batchFailureOf(
          await repo.executeSqlBatch(batchRequest),
        );

        check(failure).isA<UnknownFailure>();
        check(
          failure.context[AgentQueriesFailureContext.transportCodeField],
        ).equals('legacy_streaming_unsupported');
        check(failure.context['streamId']).equals('stream-1');
      },
    );

    test('maps RelayRequestTimeout to transient NetworkFailure', () async {
      final repo = AgentQueriesRepositoryImpl(
        _ThrowingDataSource(
          const RelayRequestTimeout(
            message: 'no response in 30s',
            conversationId: 'conv-1',
            clientRequestId: 'req-1',
          ),
        ),
      );

      final failure = _batchFailureOf(await repo.executeSqlBatch(batchRequest));

      check(failure).isA<NetworkFailure>();
      check(failure.isTransient).isTrue();
      check(
        failure.context[AgentQueriesFailureContext.transportField],
      ).equals('relay');
      check(
        failure.context[AgentQueriesFailureContext.transportCodeField],
      ).equals('timeout');
      check(failure.context['conversationId']).equals('conv-1');
      check(failure.context['clientRequestId']).equals('req-1');
    });

    test('maps RelayConversationLost to transient NetworkFailure', () async {
      final repo = AgentQueriesRepositoryImpl(
        _ThrowingDataSource(
          const RelayConversationLost(
            message: 'socket dropped',
            conversationId: 'conv-1',
            clientRequestId: 'req-1',
          ),
        ),
      );

      final failure = _batchFailureOf(await repo.executeSqlBatch(batchRequest));

      check(failure).isA<NetworkFailure>();
      check(failure.isTransient).isTrue();
      check(
        failure.context[AgentQueriesFailureContext.transportCodeField],
      ).equals('conversation_lost');
      check(failure.context['conversationId']).equals('conv-1');
      check(failure.context['clientRequestId']).equals('req-1');
    });

    test(
      'maps RelayConversationStartFailure to transient NetworkFailure',
      () async {
        final repo = AgentQueriesRepositoryImpl(
          _ThrowingDataSource(
            const RelayConversationStartFailure(message: 'hub overloaded'),
          ),
        );

        final failure = _batchFailureOf(
          await repo.executeSqlBatch(batchRequest),
        );

        check(failure).isA<NetworkFailure>();
        check(failure.isTransient).isTrue();
        check(
          failure.context[AgentQueriesFailureContext.transportCodeField],
        ).equals('conversation_start_failed');
      },
    );

    test('maps RelayRequestRejected(UNAUTHORIZED) to SessionFailure', () async {
      final repo = AgentQueriesRepositoryImpl(
        _ThrowingDataSource(
          const RelayRequestRejected(
            message: 'token rejected',
            serverCode: 'UNAUTHORIZED',
            conversationId: 'conv-1',
            clientRequestId: 'req-1',
          ),
        ),
      );

      final failure = _batchFailureOf(await repo.executeSqlBatch(batchRequest));

      check(failure).isA<SessionFailure>();
      check(
        failure.context[AgentQueriesFailureContext.transportCodeField],
      ).equals('UNAUTHORIZED');
      check(failure.context['conversationId']).equals('conv-1');
      check(failure.context['clientRequestId']).equals('req-1');
    });

    test('maps RelayRequestRejected(RATE_LIMITED) with retryAfter', () async {
      final repo = AgentQueriesRepositoryImpl(
        _ThrowingDataSource(
          const RelayRequestRejected(
            message: 'too many',
            serverCode: 'RATE_LIMITED',
            retryAfter: Duration(seconds: 2),
            conversationId: 'conv-1',
            clientRequestId: 'req-1',
          ),
        ),
      );

      final failure = _batchFailureOf(await repo.executeSqlBatch(batchRequest));

      check(failure).isA<NetworkFailure>();
      check((failure as NetworkFailure).retryAfter).equals(
        const Duration(seconds: 2),
      );
      check(
        failure.context[AgentQueriesFailureContext.transportCodeField],
      ).equals('RATE_LIMITED');
      check(failure.context['conversationId']).equals('conv-1');
      check(failure.context['clientRequestId']).equals('req-1');
    });

    test('maps RelayStreamTerminated to transient NetworkFailure', () async {
      final repo = AgentQueriesRepositoryImpl(
        _ThrowingDataSource(
          const RelayStreamTerminated(
            message: 'aborted',
            terminalStatus: 'aborted',
            conversationId: 'conv-1',
            clientRequestId: 'req-1',
          ),
        ),
      );

      final failure = _batchFailureOf(await repo.executeSqlBatch(batchRequest));

      check(failure).isA<NetworkFailure>();
      check(failure.isTransient).isTrue();
      check(
        failure.context[AgentQueriesFailureContext.transportCodeField],
      ).equals('stream_aborted');
      check(failure.context['conversationId']).equals('conv-1');
      check(failure.context['clientRequestId']).equals('req-1');
    });

    test('maps RelayDecodeFailure to transient NetworkFailure', () async {
      final repo = AgentQueriesRepositoryImpl(
        _ThrowingDataSource(
          const RelayDecodeFailure(
            message: 'bad frame',
            conversationId: 'conv-1',
            clientRequestId: 'req-1',
          ),
        ),
      );

      final failure = _batchFailureOf(await repo.executeSqlBatch(batchRequest));

      check(failure).isA<NetworkFailure>();
      check(failure.isTransient).isTrue();
      check(
        failure.context[AgentQueriesFailureContext.transportCodeField],
      ).equals('decode_failed');
      check(failure.context['conversationId']).equals('conv-1');
      check(failure.context['clientRequestId']).equals('req-1');
    });

    test('maps cancellation to UnknownFailure with cancelled flag', () async {
      final repo = AgentQueriesRepositoryImpl(
        _ThrowingDataSource(
          const SocketDispatchCancelled(message: 'controller disposed'),
        ),
      );

      final failure = _batchFailureOf(await repo.executeSqlBatch(batchRequest));

      check(failure).isA<UnknownFailure>();
      check(
        failure.context[AgentQueriesFailureContext.cancelledField],
      ).equals(true);
      check(isCancelledAgentQueryFailure(failure.context)).isTrue();
    });

    test(
      'maps RelayDispatcherDisposed to UnknownFailure with cancelled flag',
      () async {
        final repo = AgentQueriesRepositoryImpl(
          _ThrowingDataSource(
            const RelayDispatcherDisposed(
              message: 'logging out',
              conversationId: 'conv-1',
              clientRequestId: 'req-1',
            ),
          ),
        );

        final failure = _batchFailureOf(
          await repo.executeSqlBatch(batchRequest),
        );

        check(failure).isA<UnknownFailure>();
        check(
          failure.context[AgentQueriesFailureContext.cancelledField],
        ).equals(true);
        check(isCancelledAgentQueryFailure(failure.context)).isTrue();
        check(failure.context['conversationId']).equals('conv-1');
        check(failure.context['clientRequestId']).equals('req-1');
      },
    );
  });
}

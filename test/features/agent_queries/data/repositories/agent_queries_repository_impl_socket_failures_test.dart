import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/socket/socket_dispatch_exception.dart';
import 'package:colmeia/features/agent_queries/data/datasources/agent_queries_remote_datasource.dart';
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
  group('AgentQueriesRepositoryImpl Socket failure mapping', () {
    const request = AgentSqlExecuteRequest(
      agentId: 'agent-1',
      sql: 'SELECT 1',
    );

    test('maps SocketDispatchUnauthorized to SessionFailure', () async {
      final repo = AgentQueriesRepositoryImpl(
        _ThrowingDataSource(
          const SocketDispatchUnauthorized(message: 'no token'),
        ),
      );
      final failure = _failureOf(await repo.executeSql(request));
      check(failure).isA<SessionFailure>();
      check(failure.context['transport']).equals('socket');
      check(failure.context['socketCode']).equals('unauthorized');
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
        check(failure.context['socketCode']).equals('AGENT_ACCESS_DENIED');
      },
    );

    test(
      'maps SocketDispatchAppError(other code) to NetworkFailure',
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
        check(failure.context['socketCode']).equals('SERVICE_UNAVAILABLE');
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
      check(failure.context['socketCode']).equals('timeout');
    });

    test('maps SocketDispatchDisconnected to NetworkFailure', () async {
      final repo = AgentQueriesRepositoryImpl(
        _ThrowingDataSource(
          const SocketDispatchDisconnected(message: 'gone'),
        ),
      );
      final failure = _failureOf(await repo.executeSql(request));
      check(failure).isA<NetworkFailure>();
      check(failure.context['socketCode']).equals('disconnected');
    });
  });
}

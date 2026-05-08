import 'package:checks/checks.dart';
import 'package:colmeia/core/socket/socket_dispatch_exception.dart';
import 'package:colmeia/features/agent_queries/data/datasources/agent_queries_remote_datasource.dart';
import 'package:colmeia/features/agent_queries/data/datasources/socket_with_rest_fallback_agent_queries_remote_datasource.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_outbound_compression.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SocketWithRestFallbackAgentQueriesRemoteDataSource', () {
    final request = _request('SELECT 1');

    test(
      'happy path: socket succeeds, REST is never touched, latch stays open',
      () async {
        final socket = _RecordingDataSource(
          response: <String, dynamic>{'response': 'ok-from-socket'},
        );
        final rest = _RecordingDataSource(
          response: <String, dynamic>{'response': 'should-not-be-called'},
        );
        final fallback = SocketWithRestFallbackAgentQueriesRemoteDataSource(
          socketDelegate: socket,
          restDelegate: rest,
        );

        final response = await fallback.postSqlExecute(request);

        check(response['response']).equals('ok-from-socket');
        check(socket.callCount).equals(1);
        check(rest.callCount).equals(0);
        check(fallback.isLatchedToRest).isFalse();
      },
    );

    test(
      'namespace forbidden latches to REST and replays the call there '
      '(plus all subsequent calls go straight to REST)',
      () async {
        final socket = _RecordingDataSource(
          throwOn: const SocketDispatchNamespaceForbidden(
            message: 'Role "client" not allowed',
            role: 'client',
            namespace: '/consumers',
          ),
        );
        final rest = _RecordingDataSource(
          response: <String, dynamic>{'response': 'ok-from-rest'},
        );
        SocketDispatchException? observedTrigger;
        final fallback = SocketWithRestFallbackAgentQueriesRemoteDataSource(
          socketDelegate: socket,
          restDelegate: rest,
          onFallback: (trigger) => observedTrigger = trigger,
        );

        final first = await fallback.postSqlExecute(request);
        check(first['response']).equals('ok-from-rest');
        check(socket.callCount).equals(1);
        check(rest.callCount).equals(1);
        check(fallback.isLatchedToRest).isTrue();
        check(observedTrigger).isA<SocketDispatchNamespaceForbidden>();

        // Second call: socket MUST NOT be touched; REST count grows.
        final second = await fallback.postSqlExecute(request);
        check(second['response']).equals('ok-from-rest');
        check(socket.callCount).equals(1);
        check(rest.callCount).equals(2);
      },
    );

    test('unauthorized exhaustion latches to REST too', () async {
      final socket = _RecordingDataSource(
        throwOn: const SocketDispatchUnauthorized(
          message: 'reconnect exhausted',
        ),
      );
      final rest = _RecordingDataSource(
        response: <String, dynamic>{'response': 'rest-took-over'},
      );
      final fallback = SocketWithRestFallbackAgentQueriesRemoteDataSource(
        socketDelegate: socket,
        restDelegate: rest,
      );

      await fallback.postSqlExecute(request);
      check(fallback.isLatchedToRest).isTrue();
    });

    test(
      'transient errors propagate (no fallback): timeout, disconnected, '
      'app:error and decode failures stay on socket',
      () async {
        final transientCases = <SocketDispatchException>[
          const SocketDispatchTimeout(message: 'timeout'),
          const SocketDispatchDisconnected(message: 'disconnected'),
          const SocketDispatchAppError(
            message: 'service unavailable',
            serverCode: 'SERVICE_UNAVAILABLE',
          ),
          const SocketDispatchDecodeFailure(message: 'bad envelope'),
          const SocketDispatchCancelled(message: 'caller cancelled'),
        ];

        for (final transient in transientCases) {
          final socket = _RecordingDataSource(throwOn: transient);
          final rest = _RecordingDataSource(
            response: <String, dynamic>{'response': 'rest-must-not-be-touched'},
          );
          final fallback = SocketWithRestFallbackAgentQueriesRemoteDataSource(
            socketDelegate: socket,
            restDelegate: rest,
          );

          final raised = await _capture(fallback.postSqlExecute(request));
          check(raised).isA<SocketDispatchException>();
          check(
            (raised! as SocketDispatchException).code,
          ).equals(transient.code);
          // Critical: the transient case MUST NOT pivot — the
          // socket layer's own RetryAfterGate / circuit breaker
          // owns recovery for these.
          check(fallback.isLatchedToRest).isFalse();
          check(rest.callCount).equals(0);
        }
      },
    );

    test('fallback observability hook firing exception is swallowed', () async {
      // Observability MUST NOT break the dispatch path that just
      // decided to fall back. Otherwise the user gets the same
      // "blank screen" the fallback was designed to prevent.
      final socket = _RecordingDataSource(
        throwOn: const SocketDispatchNamespaceForbidden(
          message: 'forbidden',
        ),
      );
      final rest = _RecordingDataSource(
        response: <String, dynamic>{'response': 'still-works'},
      );
      final fallback = SocketWithRestFallbackAgentQueriesRemoteDataSource(
        socketDelegate: socket,
        restDelegate: rest,
        onFallback: (_) => throw StateError('boom'),
      );

      // No try/catch around the call: if the hook leaked the test
      // would fail with an uncaught exception.
      final response = await fallback.postSqlExecute(request);
      check(response).deepEquals(<String, dynamic>{'response': 'still-works'});
    });
  });
}

class _RecordingDataSource implements AgentQueriesRemoteDataSource {
  _RecordingDataSource({this.response, this.throwOn});

  final Map<String, dynamic>? response;
  final SocketDispatchException? throwOn;
  int callCount = 0;

  @override
  Future<Map<String, dynamic>> postSqlExecute(
    AgentSqlExecuteRequest request,
  ) {
    callCount += 1;
    final toThrow = throwOn;
    if (toThrow != null) {
      return Future<Map<String, dynamic>>.error(toThrow);
    }
    return Future<Map<String, dynamic>>.value(
      response ?? const <String, dynamic>{},
    );
  }
}

AgentSqlExecuteRequest _request(String sql) {
  return AgentSqlExecuteRequest(
    agentId: '00000000-0000-0000-0000-000000000001',
    sql: sql,
    clientToken: 'token',
    bridgeTimeoutMs: 1000,
    outboundCompression: AgentOutboundCompression.auto,
  );
}

/// Awaits [future] and returns the error it throws, or `null` when
/// it resolves normally. Avoids the test API friction with
/// `check(...).throws<T>()` not being available on `Future`.
Future<Object?> _capture(Future<Object?> future) async {
  try {
    await future;
    return null;
  } on Object catch (error) {
    return error;
  }
}

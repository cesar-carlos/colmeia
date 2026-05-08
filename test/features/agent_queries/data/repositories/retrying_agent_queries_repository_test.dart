import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/data/repositories/retrying_agent_queries_repository.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

class _MockDelegate extends Mock implements AgentQueriesRepository {}

void main() {
  late _MockDelegate delegate;
  late RetryingAgentQueriesRepository retrying;

  setUpAll(() {
    registerFallbackValue(
      const AgentSqlExecuteRequest(agentId: 'fallback', sql: 'SELECT 1'),
    );
  });

  setUp(() {
    delegate = _MockDelegate();
    retrying = RetryingAgentQueriesRepository(
      delegate: delegate,
      initialRetryDelay: Duration.zero,
    );
  });

  const request = AgentSqlExecuteRequest(
    agentId: 'agent-1',
    sql: 'SELECT 1',
  );

  const successResult = AgentSqlExecutionResult(
    rows: <Map<String, dynamic>>[],
    rowCount: 0,
  );

  test('success on first attempt: delegate called once', () async {
    when(() => delegate.executeSql(any())).thenAnswer(
      (_) async => const Success<AgentSqlExecutionResult, AppFailure>(
        successResult,
      ),
    );

    final result = await retrying.executeSql(request);

    check(result.isSuccess()).isTrue();
    verify(() => delegate.executeSql(request)).called(1);
  });

  test('transient failure then success: delegate called twice', () async {
    var callCount = 0;
    when(() => delegate.executeSql(any())).thenAnswer((_) async {
      callCount++;
      if (callCount == 1) {
        return const Failure<AgentSqlExecutionResult, AppFailure>(
          NetworkFailure(
            message: 'timeout',
            userMessage: 'Network timeout',
          ),
        );
      }
      return const Success<AgentSqlExecutionResult, AppFailure>(
        successResult,
      );
    });

    final result = await retrying.executeSql(request);

    check(result.isSuccess()).isTrue();
    verify(() => delegate.executeSql(request)).called(2);
  });

  test(
    'transient failure thrice: returns last failure after max attempts',
    () async {
      const failure = NetworkFailure(
        message: 'connection reset',
        userMessage: 'Connection lost',
      );
      when(() => delegate.executeSql(any())).thenAnswer(
        (_) async =>
            const Failure<AgentSqlExecutionResult, AppFailure>(failure),
      );

      final result = await retrying.executeSql(request);

      check(result.isError()).isTrue();
      check(result.exceptionOrNull()).isA<NetworkFailure>();
      verify(() => delegate.executeSql(request)).called(3);
    },
  );

  test('non-transient failure: delegate called once, no retry', () async {
    const failure = ValidationFailure(
      message: 'invalid SQL',
      userMessage: 'Query invalid',
    );
    when(() => delegate.executeSql(any())).thenAnswer(
      (_) async => const Failure<AgentSqlExecutionResult, AppFailure>(failure),
    );

    final result = await retrying.executeSql(request);

    check(result.isError()).isTrue();
    check(result.exceptionOrNull()).isA<ValidationFailure>();
    verify(() => delegate.executeSql(request)).called(1);
  });

  test('NetworkFailure with retryAfter: no retry', () async {
    const failure = NetworkFailure(
      message: 'rate limited',
      userMessage: 'Too many requests',
      retryAfter: Duration(seconds: 30),
    );
    when(() => delegate.executeSql(any())).thenAnswer(
      (_) async => const Failure<AgentSqlExecutionResult, AppFailure>(failure),
    );

    final result = await retrying.executeSql(request);

    check(result.isError()).isTrue();
    check(result.exceptionOrNull()).isA<NetworkFailure>();
    verify(() => delegate.executeSql(request)).called(1);
  });

  test('RpcFailure with retryAfter: no retry', () async {
    const failure = RpcFailure(
      message: 'rate limit',
      userMessage: 'Rate limited',
      rpcCode: -32013,
      retryable: true,
      retryAfter: Duration(seconds: 60),
    );
    when(() => delegate.executeSql(any())).thenAnswer(
      (_) async => const Failure<AgentSqlExecutionResult, AppFailure>(failure),
    );

    final result = await retrying.executeSql(request);

    check(result.isError()).isTrue();
    check(result.exceptionOrNull()).isA<RpcFailure>();
    verify(() => delegate.executeSql(request)).called(1);
  });

  test('RpcFailure(retryable: false): no retry', () async {
    const failure = RpcFailure(
      message: 'permanent error',
      userMessage: 'Not retryable',
      rpcCode: -32000,
      retryable: false,
    );
    when(() => delegate.executeSql(any())).thenAnswer(
      (_) async => const Failure<AgentSqlExecutionResult, AppFailure>(failure),
    );

    final result = await retrying.executeSql(request);

    check(result.isError()).isTrue();
    check(result.exceptionOrNull()).isA<RpcFailure>();
    verify(() => delegate.executeSql(request)).called(1);
  });

  test('SessionFailure: no retry (isTransient=false)', () async {
    const failure = SessionFailure(
      message: 'session expired',
      userMessage: 'Please log in again',
    );
    when(() => delegate.executeSql(any())).thenAnswer(
      (_) async => const Failure<AgentSqlExecutionResult, AppFailure>(failure),
    );

    final result = await retrying.executeSql(request);

    check(result.isError()).isTrue();
    check(result.exceptionOrNull()).isA<SessionFailure>();
    verify(() => delegate.executeSql(request)).called(1);
  });

  test('AuthorizationFailure: no retry (isTransient=false)', () async {
    const failure = AuthorizationFailure(
      message: 'access denied',
      userMessage: 'You do not have access',
    );
    when(() => delegate.executeSql(any())).thenAnswer(
      (_) async => const Failure<AgentSqlExecutionResult, AppFailure>(failure),
    );

    final result = await retrying.executeSql(request);

    check(result.isError()).isTrue();
    check(result.exceptionOrNull()).isA<AuthorizationFailure>();
    verify(() => delegate.executeSql(request)).called(1);
  });

  test('StorageFailure: no retry (isTransient=false)', () async {
    const failure = StorageFailure(
      message: 'disk full',
      userMessage: 'Storage error',
    );
    when(() => delegate.executeSql(any())).thenAnswer(
      (_) async => const Failure<AgentSqlExecutionResult, AppFailure>(failure),
    );

    final result = await retrying.executeSql(request);

    check(result.isError()).isTrue();
    check(result.exceptionOrNull()).isA<StorageFailure>();
    verify(() => delegate.executeSql(request)).called(1);
  });

  test('RpcFailure(retryable: true, no retryAfter): retries', () async {
    const failure = RpcFailure(
      message: 'transient rpc error',
      userMessage: 'Temporary error',
      rpcCode: -32002,
      retryable: true,
    );
    var callCount = 0;
    when(() => delegate.executeSql(any())).thenAnswer((_) async {
      callCount++;
      if (callCount == 1) {
        return const Failure<AgentSqlExecutionResult, AppFailure>(failure);
      }
      return const Success<AgentSqlExecutionResult, AppFailure>(
        successResult,
      );
    });

    final result = await retrying.executeSql(request);

    check(result.isSuccess()).isTrue();
    verify(() => delegate.executeSql(request)).called(2);
  });

  test('exponential backoff: 200ms then 400ms delays', () async {
    final retryingWithDelay = RetryingAgentQueriesRepository(
      delegate: delegate,
    );
    const failure = NetworkFailure(
      message: 'service unavailable',
      userMessage: 'Server overload',
    );
    when(() => delegate.executeSql(any())).thenAnswer(
      (_) async => const Failure<AgentSqlExecutionResult, AppFailure>(failure),
    );

    final stopwatch = Stopwatch()..start();
    final result = await retryingWithDelay.executeSql(request);
    stopwatch.stop();

    check(result.isError()).isTrue();
    verify(() => delegate.executeSql(request)).called(3);
    final elapsed = stopwatch.elapsedMilliseconds;
    check(elapsed).isGreaterOrEqual(600);
    check(elapsed).isLessThan(800);
  });
}

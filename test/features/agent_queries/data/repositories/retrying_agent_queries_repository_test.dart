import 'dart:math' as math;

import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/data/repositories/agent_queries_failure_codes.dart';
import 'package:colmeia/features/agent_queries/data/repositories/agent_queries_retry_backoff.dart';
import 'package:colmeia/features/agent_queries/data/repositories/retrying_agent_queries_repository.dart';
import 'package:colmeia/features/agent_queries/domain/agent_sql_rpc_failure_ui_key.dart';
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

  test(
    'RpcFailure protocol negotiation not ready (retryable false): retries',
    () async {
      var callCount = 0;
      when(() => delegate.executeSql(any())).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) {
          return const Failure<AgentSqlExecutionResult, AppFailure>(
            RpcFailure(
              message: 'Agent protocol negotiation is not ready',
              userMessage: 'Busy',
              rpcCode: null,
              retryable: false,
              context: <String, Object?>{
                'code': 'SERVICE_UNAVAILABLE',
              },
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

  test('RpcFailure replay_detected (-32014): no retry', () async {
    const failure = RpcFailure(
      message: 'Replay detected',
      userMessage: 'Duplicate',
      rpcCode: -32014,
      retryable: false,
      reason: 'replay_detected',
    );
    when(() => delegate.executeSql(any())).thenAnswer(
      (_) async => const Failure<AgentSqlExecutionResult, AppFailure>(failure),
    );

    final result = await retrying.executeSql(request);

    check(result.isError()).isTrue();
    check(result.exceptionOrNull()).isA<RpcFailure>();
    verify(() => delegate.executeSql(request)).called(1);
  });

  test('RpcFailure rate limit (-32013) without retryAfter: no retry', () async {
    const failure = RpcFailure(
      message: 'Rate window exceeded',
      userMessage: 'Too many requests',
      rpcCode: -32013,
      retryable: true,
    );
    when(() => delegate.executeSql(any())).thenAnswer(
      (_) async => const Failure<AgentSqlExecutionResult, AppFailure>(failure),
    );

    final result = await retrying.executeSql(request);

    check(result.isError()).isTrue();
    verify(() => delegate.executeSql(request)).called(1);
  });

  test(
    'RpcFailure concurrent_handlers_exceeded reason without rpcCode: no retry',
    () async {
      const failure = RpcFailure(
        message: 'Too many concurrent handlers',
        userMessage: 'Server busy',
        rpcCode: null,
        retryable: true,
        reason: 'concurrent_handlers_exceeded',
      );
      when(() => delegate.executeSql(any())).thenAnswer(
        (_) async =>
            const Failure<AgentSqlExecutionResult, AppFailure>(failure),
      );

      final result = await retrying.executeSql(request);

      check(result.isError()).isTrue();
      verify(() => delegate.executeSql(request)).called(1);
    },
  );

  test(
    'RpcFailure rate limit via uiKey without retryAfter: no retry',
    () async {
      const failure = RpcFailure(
        message: 'Rate window exceeded',
        userMessage: 'Too many requests',
        rpcCode: null,
        retryable: true,
        reason: 'rate_window_exceeded',
        context: <String, Object?>{
          AgentSqlRpcFailureUiKey.field: AgentSqlRpcFailureUiKey.rateLimited,
        },
      );
      when(() => delegate.executeSql(any())).thenAnswer(
        (_) async =>
            const Failure<AgentSqlExecutionResult, AppFailure>(failure),
      );

      final result = await retrying.executeSql(request);

      check(result.isError()).isTrue();
      verify(() => delegate.executeSql(request)).called(1);
    },
  );

  test('NetworkFailure RATE_LIMITED transport code: no retry', () async {
    const failure = NetworkFailure(
      message: 'rate limited',
      userMessage: 'Too many requests',
      context: <String, Object?>{
        AgentQueriesFailureContext.transportCodeField: 'RATE_LIMITED',
      },
    );
    when(() => delegate.executeSql(any())).thenAnswer(
      (_) async => const Failure<AgentSqlExecutionResult, AppFailure>(failure),
    );

    final result = await retrying.executeSql(request);

    check(result.isError()).isTrue();
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

  group('AgentQueriesRetryBackoff', () {
    test('uses exponential ceilings from the initial delay', () {
      check(
        AgentQueriesRetryBackoff.ceiling(
          initialDelay: const Duration(milliseconds: 200),
          failedAttempt: 1,
        ),
      ).equals(const Duration(milliseconds: 200));
      check(
        AgentQueriesRetryBackoff.ceiling(
          initialDelay: const Duration(milliseconds: 200),
          failedAttempt: 2,
        ),
      ).equals(const Duration(milliseconds: 400));
      check(
        AgentQueriesRetryBackoff.ceiling(
          initialDelay: const Duration(milliseconds: 200),
          failedAttempt: 3,
        ),
      ).equals(const Duration(milliseconds: 800));
    });

    test('full jitter samples inside zero and ceiling inclusive', () {
      const ceiling = Duration(milliseconds: 400);
      final random = math.Random(42);

      for (var i = 0; i < 256; i++) {
        final sample = AgentQueriesRetryBackoff.fullJitter(
          ceiling: ceiling,
          random: random,
        );
        check(sample.inMilliseconds).isGreaterOrEqual(0);
        check(sample.inMilliseconds).isLessOrEqual(ceiling.inMilliseconds);
      }
    });

    test('seeded random keeps retry jitter deterministic in tests', () {
      final a = math.Random(7);
      final b = math.Random(7);
      const ceiling = Duration(milliseconds: 400);

      for (var i = 0; i < 16; i++) {
        check(
          AgentQueriesRetryBackoff.fullJitter(
            ceiling: ceiling,
            random: a,
          ),
        ).equals(
          AgentQueriesRetryBackoff.fullJitter(
            ceiling: ceiling,
            random: b,
          ),
        );
      }
    });

    test('zero or invalid ceilings collapse to Duration.zero', () {
      final random = math.Random(1);
      check(
        AgentQueriesRetryBackoff.ceiling(
          initialDelay: Duration.zero,
          failedAttempt: 1,
        ),
      ).equals(Duration.zero);
      check(
        AgentQueriesRetryBackoff.fullJitter(
          ceiling: const Duration(milliseconds: -1),
          random: random,
        ),
      ).equals(Duration.zero);
    });
  });

  test('transient retries accept an injected random source', () async {
    final retryingWithRandom = RetryingAgentQueriesRepository(
      delegate: delegate,
      initialRetryDelay: Duration.zero,
      random: math.Random(123),
    );
    const failure = NetworkFailure(
      message: 'service unavailable',
      userMessage: 'Server overload',
    );
    when(() => delegate.executeSql(any())).thenAnswer(
      (_) async => const Failure<AgentSqlExecutionResult, AppFailure>(failure),
    );

    final result = await retryingWithRandom.executeSql(request);

    check(result.isError()).isTrue();
    verify(() => delegate.executeSql(request)).called(3);
  });
}

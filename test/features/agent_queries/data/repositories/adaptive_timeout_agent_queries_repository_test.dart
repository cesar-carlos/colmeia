import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/data/repositories/adaptive_timeout_agent_queries_repository.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_batch_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_batch_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

class _MockDelegate extends Mock implements AgentQueriesRepository {}

void main() {
  late _MockDelegate delegate;
  late AdaptiveTimeoutAgentQueriesRepository repository;

  const successResult = AgentSqlExecutionResult(
    rows: <Map<String, dynamic>>[],
    rowCount: 0,
  );

  const batchSuccessResult = AgentSqlBatchExecutionResult(
    items: <AgentSqlBatchExecutionItem>[],
    totalCommands: 0,
    successfulCommands: 0,
    failedCommands: 0,
  );

  const batchRequest = AgentSqlExecuteBatchRequest(
    agentId: 'agent-1',
    commands: <AgentSqlExecuteBatchCommand>[
      AgentSqlExecuteBatchCommand(sql: 'SELECT 1'),
    ],
  );

  setUpAll(() {
    registerFallbackValue(
      const AgentSqlExecuteRequest(agentId: 'fallback', sql: 'SELECT 1'),
    );
    registerFallbackValue(
      const AgentSqlExecuteBatchRequest(
        agentId: 'fallback',
        commands: <AgentSqlExecuteBatchCommand>[
          AgentSqlExecuteBatchCommand(sql: 'SELECT 1'),
        ],
      ),
    );
  });

  setUp(() {
    delegate = _MockDelegate();
    repository = AdaptiveTimeoutAgentQueriesRepository(delegate: delegate);
  });

  group('executeSql', () {
    test('delegates to inner repository and forwards request unchanged '
        'when bridgeTimeoutMs is null', () async {
      const request = AgentSqlExecuteRequest(
        agentId: 'agent-1',
        sql: 'SELECT 1',
      );
      when(() => delegate.executeSql(any())).thenAnswer(
        (_) async => const Success<AgentSqlExecutionResult, AppFailure>(
          successResult,
        ),
      );

      final result = await repository.executeSql(request);

      check(result.isSuccess()).isTrue();
      final captured =
          verify(() => delegate.executeSql(captureAny())).captured.single
              as AgentSqlExecuteRequest;
      check(captured.bridgeTimeoutMs).isNull();
    });

    test('preserves original timeout when history is empty', () async {
      const originalTimeoutMs = 20000;
      const request = AgentSqlExecuteRequest(
        agentId: 'agent-1',
        sql: 'SELECT 1',
        bridgeTimeoutMs: originalTimeoutMs,
      );
      when(() => delegate.executeSql(any())).thenAnswer(
        (_) async => const Success<AgentSqlExecutionResult, AppFailure>(
          successResult,
        ),
      );

      final result = await repository.executeSql(request);

      check(result.isSuccess()).isTrue();
      final captured =
          verify(() => delegate.executeSql(captureAny())).captured.single
              as AgentSqlExecuteRequest;
      check(captured.bridgeTimeoutMs).equals(originalTimeoutMs);
    });

    test('records latency on success and applies adaptive timeout '
        'on the next call', () async {
      const request = AgentSqlExecuteRequest(
        agentId: 'agent-1',
        sql: 'SELECT 1',
        bridgeTimeoutMs: 30000,
      );
      when(() => delegate.executeSql(any())).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 30));
        return const Success<AgentSqlExecutionResult, AppFailure>(
          successResult,
        );
      });

      await repository.executeSql(request);
      await repository.executeSql(request);

      check(repository.getAverageLatency('agent-1')).isNotNull();
      final captured = verify(
        () => delegate.executeSql(captureAny()),
      ).captured;
      final secondCallRequest = captured[1] as AgentSqlExecuteRequest;
      check(secondCallRequest.bridgeTimeoutMs).isNotNull();
    });

    test('does not record latency on failure', () async {
      const request = AgentSqlExecuteRequest(
        agentId: 'agent-1',
        sql: 'SELECT 1',
        bridgeTimeoutMs: 20000,
      );
      when(() => delegate.executeSql(any())).thenAnswer(
        (_) async => const Failure<AgentSqlExecutionResult, AppFailure>(
          NetworkFailure(
            message: 'boom',
            userMessage: 'Network failure',
          ),
        ),
      );

      await repository.executeSql(request);

      check(repository.getAverageLatency('agent-1')).isNull();
    });

    test('clamps adaptive timeout to minTimeoutMs floor', () async {
      final repositoryWithBounds = AdaptiveTimeoutAgentQueriesRepository(
        delegate: delegate,
        minTimeout: const Duration(seconds: 30),
      );
      const request = AgentSqlExecuteRequest(
        agentId: 'agent-1',
        sql: 'SELECT 1',
        bridgeTimeoutMs: 60000,
      );
      when(() => delegate.executeSql(any())).thenAnswer(
        (_) async => const Success<AgentSqlExecutionResult, AppFailure>(
          successResult,
        ),
      );

      await repositoryWithBounds.executeSql(request);
      await repositoryWithBounds.executeSql(request);

      final captured = verify(
        () => delegate.executeSql(captureAny()),
      ).captured;
      final secondCallRequest = captured[1] as AgentSqlExecuteRequest;
      check(secondCallRequest.bridgeTimeoutMs).isNotNull();
      check(secondCallRequest.bridgeTimeoutMs!).isGreaterOrEqual(30000);
    });

    test('clamps adaptive timeout to maxTimeoutMs ceiling', () async {
      final repositoryWithBounds = AdaptiveTimeoutAgentQueriesRepository(
        delegate: delegate,
        safetyMultiplier: 1000,
        minTimeout: const Duration(seconds: 1),
        maxTimeout: const Duration(seconds: 5),
      );
      const request = AgentSqlExecuteRequest(
        agentId: 'agent-1',
        sql: 'SELECT 1',
        bridgeTimeoutMs: 60000,
      );
      when(() => delegate.executeSql(any())).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 30));
        return const Success<AgentSqlExecutionResult, AppFailure>(
          successResult,
        );
      });

      await repositoryWithBounds.executeSql(request);
      await repositoryWithBounds.executeSql(request);

      final captured = verify(
        () => delegate.executeSql(captureAny()),
      ).captured;
      final secondCallRequest = captured[1] as AgentSqlExecuteRequest;
      check(secondCallRequest.bridgeTimeoutMs).isNotNull();
      check(secondCallRequest.bridgeTimeoutMs!).isLessOrEqual(5000);
    });

    test('does not accumulate latency history beyond 50 samples per agent',
        () async {
      const request = AgentSqlExecuteRequest(
        agentId: 'agent-1',
        sql: 'SELECT 1',
        bridgeTimeoutMs: 30000,
      );
      when(() => delegate.executeSql(any())).thenAnswer(
        (_) async => const Success<AgentSqlExecutionResult, AppFailure>(
          successResult,
        ),
      );

      for (var i = 0; i < 60; i++) {
        await repository.executeSql(request);
      }

      check(repository.getAverageLatency('agent-1')).isNotNull();
    });

    test('clear() resets latency history for all agents', () async {
      const request = AgentSqlExecuteRequest(
        agentId: 'agent-1',
        sql: 'SELECT 1',
        bridgeTimeoutMs: 30000,
      );
      when(() => delegate.executeSql(any())).thenAnswer(
        (_) async => const Success<AgentSqlExecutionResult, AppFailure>(
          successResult,
        ),
      );
      await repository.executeSql(request);
      check(repository.getAverageLatency('agent-1')).isNotNull();

      repository.clear();

      check(repository.getAverageLatency('agent-1')).isNull();
    });
  });

  group('executeSqlBatch', () {
    test('delegates to inner repository and forwards request unchanged '
        'when bridgeTimeoutMs is null', () async {
      when(() => delegate.executeSqlBatch(any())).thenAnswer(
        (_) async => const Success<AgentSqlBatchExecutionResult, AppFailure>(
          batchSuccessResult,
        ),
      );

      final result = await repository.executeSqlBatch(batchRequest);

      check(result.isSuccess()).isTrue();
      final captured =
          verify(() => delegate.executeSqlBatch(captureAny())).captured.single
              as AgentSqlExecuteBatchRequest;
      check(captured.bridgeTimeoutMs).isNull();
    });

    test('preserves original timeout when history is empty', () async {
      const originalTimeoutMs = 25000;
      const requestWithTimeout = AgentSqlExecuteBatchRequest(
        agentId: 'agent-1',
        commands: <AgentSqlExecuteBatchCommand>[
          AgentSqlExecuteBatchCommand(sql: 'SELECT 1'),
        ],
        bridgeTimeoutMs: originalTimeoutMs,
      );
      when(() => delegate.executeSqlBatch(any())).thenAnswer(
        (_) async => const Success<AgentSqlBatchExecutionResult, AppFailure>(
          batchSuccessResult,
        ),
      );

      final result = await repository.executeSqlBatch(requestWithTimeout);

      check(result.isSuccess()).isTrue();
      final captured =
          verify(() => delegate.executeSqlBatch(captureAny())).captured.single
              as AgentSqlExecuteBatchRequest;
      check(captured.bridgeTimeoutMs).equals(originalTimeoutMs);
    });

    test('records latency on success and applies adaptive timeout '
        'on the next batch call', () async {
      const requestWithTimeout = AgentSqlExecuteBatchRequest(
        agentId: 'agent-1',
        commands: <AgentSqlExecuteBatchCommand>[
          AgentSqlExecuteBatchCommand(sql: 'SELECT 1'),
        ],
        bridgeTimeoutMs: 30000,
      );
      when(() => delegate.executeSqlBatch(any())).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 30));
        return const Success<AgentSqlBatchExecutionResult, AppFailure>(
          batchSuccessResult,
        );
      });

      await repository.executeSqlBatch(requestWithTimeout);
      await repository.executeSqlBatch(requestWithTimeout);

      check(repository.getAverageLatency('agent-1')).isNotNull();
      final captured = verify(
        () => delegate.executeSqlBatch(captureAny()),
      ).captured;
      final secondCallRequest = captured[1] as AgentSqlExecuteBatchRequest;
      check(secondCallRequest.bridgeTimeoutMs).isNotNull();
    });

    test('does not record latency on failure', () async {
      const requestWithTimeout = AgentSqlExecuteBatchRequest(
        agentId: 'agent-1',
        commands: <AgentSqlExecuteBatchCommand>[
          AgentSqlExecuteBatchCommand(sql: 'SELECT 1'),
        ],
        bridgeTimeoutMs: 30000,
      );
      when(() => delegate.executeSqlBatch(any())).thenAnswer(
        (_) async => const Failure<AgentSqlBatchExecutionResult, AppFailure>(
          NetworkFailure(
            message: 'boom',
            userMessage: 'Network failure',
          ),
        ),
      );

      await repository.executeSqlBatch(requestWithTimeout);

      check(repository.getAverageLatency('agent-1')).isNull();
    });
  });

  group('getAverageLatency', () {
    test('returns null when no samples were recorded', () {
      check(repository.getAverageLatency('agent-1')).isNull();
    });
  });
}

import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/socket/per_agent_concurrency_gate.dart';
import 'package:colmeia/features/agent_queries/data/repositories/rest_inflight_agent_queries_repository.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_batch_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

class _MockDelegate extends Mock implements AgentQueriesRepository {}

void main() {
  late _MockDelegate delegate;
  late PerAgentConcurrencyGate gate;

  setUpAll(() {
    registerFallbackValue(
      const AgentSqlExecuteRequest(agentId: 'fallback', sql: 'SELECT 1'),
    );
  });

  setUp(() {
    delegate = _MockDelegate();
    gate = PerAgentConcurrencyGate(maxInflightPerAgent: 1);
  });

  const ok = AgentSqlExecutionResult(
    rows: <Map<String, dynamic>>[],
    rowCount: 0,
  );

  for (final releaseFirst in [false, true]) {
    test(
      'cancellation racing with release does not leak a slot: $releaseFirst',
      () async {
        final repo = RestInflightAgentQueriesRepository(
          delegate: delegate,
          gate: gate,
        );
        final scope = AgentQueriesCancelScope();
        await gate.acquire('a1');
        final pending = repo.executeSql(
          const AgentSqlExecuteRequest(agentId: 'a1', sql: 'SELECT 1'),
          cancelScope: scope,
        );
        await Future<void>.delayed(Duration.zero);
        if (releaseFirst) {
          gate.release('a1');
          scope.cancelAll();
        } else {
          scope.cancelAll();
          gate.release('a1');
        }
        expect(
          (await pending).exceptionOrNull(),
          isA<OperationCancelledFailure>(),
        );
        expect(gate.waitingFor('a1'), 0);
        expect(gate.inflightFor('a1'), 0);
        verifyZeroInteractions(delegate);
      },
    );
  }

  test(
    'should return a typed failure without dispatch when the queue is full',
    () async {
      gate = PerAgentConcurrencyGate(
        maxInflightPerAgent: 1,
        maxWaitersPerAgent: 0,
      );
      await gate.acquire('a1');
      final repo = RestInflightAgentQueriesRepository(
        delegate: delegate,
        gate: gate,
      );
      final result = await repo.executeSql(
        const AgentSqlExecuteRequest(agentId: 'a1', sql: 'SELECT 1'),
      );
      expect(result.exceptionOrNull()?.context['localQueueFull'], true);
      expect(result.exceptionOrNull()?.isTransient, false);
      expect(gate.inflightFor('a1'), 1);
      verifyZeroInteractions(delegate);
      gate.release('a1');
    },
  );

  test('should remove a timed out waiter without consuming a slot', () async {
    gate = PerAgentConcurrencyGate(
      maxInflightPerAgent: 1,
      maxWaitForSlot: const Duration(milliseconds: 10),
    );
    await gate.acquire('a1');
    final repo = RestInflightAgentQueriesRepository(
      delegate: delegate,
      gate: gate,
    );
    final result = await repo.executeSql(
      const AgentSqlExecuteRequest(agentId: 'a1', sql: 'SELECT 1'),
    );
    expect(result.exceptionOrNull()?.context['localQueueWaitExceeded'], true);
    expect(gate.waitingFor('a1'), 0);
    expect(gate.inflightFor('a1'), 1);
    verifyZeroInteractions(delegate);
    gate.release('a1');
  });

  test('serializes concurrent executeSql for the same agent', () async {
    final repo = RestInflightAgentQueriesRepository(
      delegate: delegate,
      gate: gate,
    );
    const req = AgentSqlExecuteRequest(agentId: 'a1', sql: 'SELECT 1');
    var callCount = 0;
    when(() => delegate.executeSql(req)).thenAnswer((_) async {
      callCount++;
      await Future<void>.delayed(const Duration(milliseconds: 15));
      return const Success<AgentSqlExecutionResult, AppFailure>(ok);
    });

    await Future.wait(<Future<AppResult<AgentSqlExecutionResult>>>[
      repo.executeSql(req),
      repo.executeSql(req),
    ]);

    check(callCount).equals(2);
    verify(() => delegate.executeSql(req)).called(2);
  });

  test('empty agentId bypasses gate', () async {
    final repo = RestInflightAgentQueriesRepository(
      delegate: delegate,
      gate: gate,
    );
    const req = AgentSqlExecuteRequest(agentId: '   ', sql: 'SELECT 1');
    when(() => delegate.executeSql(req)).thenAnswer(
      (_) async => const Success<AgentSqlExecutionResult, AppFailure>(ok),
    );

    await repo.executeSql(req);

    verify(() => delegate.executeSql(req)).called(1);
    check(gate.inflightFor('')).equals(0);
  });

  test(
    'should remove a cancelled SQL call from the REST queue promptly',
    () async {
      final repo = RestInflightAgentQueriesRepository(
        delegate: delegate,
        gate: gate,
      );
      const req = AgentSqlExecuteRequest(agentId: 'a1', sql: 'SELECT 1');
      final scope = AgentQueriesCancelScope();
      await gate.acquire('a1');
      addTearDown(() => gate.release('a1'));

      final result = repo.executeSql(req, cancelScope: scope);
      await Future<void>.delayed(Duration.zero);
      expect(gate.waitingFor('a1'), 1);
      scope.cancelAll();

      expect(
        (await result.timeout(const Duration(seconds: 1))).exceptionOrNull(),
        isA<OperationCancelledFailure>(),
      );
      expect(gate.waitingFor('a1'), 0);
      expect(gate.inflightFor('a1'), 1);
      verifyZeroInteractions(delegate);
    },
  );

  test(
    'should remove a cancelled SQL batch from the REST queue promptly',
    () async {
      final repo = RestInflightAgentQueriesRepository(
        delegate: delegate,
        gate: gate,
      );
      const req = AgentSqlExecuteBatchRequest(
        agentId: 'a1',
        commands: <AgentSqlExecuteBatchCommand>[
          AgentSqlExecuteBatchCommand(sql: 'SELECT 1'),
        ],
      );
      final scope = AgentQueriesCancelScope();
      await gate.acquire('a1');
      addTearDown(() => gate.release('a1'));

      final result = repo.executeSqlBatch(req, cancelScope: scope);
      await Future<void>.delayed(Duration.zero);
      expect(gate.waitingFor('a1'), 1);
      scope.cancelAll();

      expect(
        (await result.timeout(const Duration(seconds: 1))).exceptionOrNull(),
        isA<OperationCancelledFailure>(),
      );
      expect(gate.waitingFor('a1'), 0);
      expect(gate.inflightFor('a1'), 1);
      verifyZeroInteractions(delegate);
    },
  );
}

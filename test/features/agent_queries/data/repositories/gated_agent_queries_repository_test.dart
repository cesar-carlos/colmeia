import 'dart:async';

import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/data/repositories/gated_agent_queries_repository.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_batch_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_eligibility_evaluation.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_sql_execution_eligibility_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

class _MockInner extends Mock implements AgentQueriesRepository {}

class _MockEligibility extends Mock
    implements AgentSqlExecutionEligibilityPort {}

void main() {
  late _MockInner inner;
  late _MockEligibility eligibility;
  late GatedAgentQueriesRepository gated;

  setUpAll(() {
    registerFallbackValue(
      const AgentSqlExecuteRequest(agentId: 'fb', sql: 'SELECT 1'),
    );
  });

  setUp(() {
    inner = _MockInner();
    eligibility = _MockEligibility();
    gated = GatedAgentQueriesRepository(
      delegate: inner,
      eligibility: eligibility,
    );
  });

  test(
    'delegates without eligibility when requestingUserId is absent',
    () async {
      const request = AgentSqlExecuteRequest(agentId: 'a1', sql: 'SELECT 1');
      when(() => inner.executeSql(any())).thenAnswer(
        (_) async => const Success<AgentSqlExecutionResult, AppFailure>(
          AgentSqlExecutionResult(rows: <Map<String, dynamic>>[], rowCount: 0),
        ),
      );

      final out = await gated.executeSql(request);

      check(out.isSuccess()).isTrue();
      verifyZeroInteractions(eligibility);
      verify(() => inner.executeSql(request)).called(1);
    },
  );

  test('denies without calling inner when eligibility rejects', () async {
    const request = AgentSqlExecuteRequest(
      agentId: 'a1',
      sql: 'SELECT 1',
      requestingUserId: 'u1',
    );
    when(
      () => eligibility.evaluate(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
        isHubConnected: any(named: 'isHubConnected'),
        hubPresenceOnlineAgentIdsSnapshot: any(
          named: 'hubPresenceOnlineAgentIdsSnapshot',
        ),
      ),
    ).thenAnswer(
      (_) async => const AgentSqlExecutionEligibilityEvaluation.denied('x'),
    );

    final out = await gated.executeSql(request);

    check(out.isError()).isTrue();
    verifyNever(() => inner.executeSql(any()));
  });

  test('calls inner once when eligibility allows', () async {
    const request = AgentSqlExecuteRequest(
      agentId: 'a1',
      sql: 'SELECT 1',
      requestingUserId: 'u1',
    );
    when(
      () => eligibility.evaluate(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
        isHubConnected: any(named: 'isHubConnected'),
        hubPresenceOnlineAgentIdsSnapshot: any(
          named: 'hubPresenceOnlineAgentIdsSnapshot',
        ),
      ),
    ).thenAnswer(
      (_) async => const AgentSqlExecutionEligibilityEvaluation.allowed(),
    );
    when(() => inner.executeSql(any())).thenAnswer(
      (_) async => const Success<AgentSqlExecutionResult, AppFailure>(
        AgentSqlExecutionResult(rows: <Map<String, dynamic>>[], rowCount: 0),
      ),
    );

    final out = await gated.executeSql(request);

    check(out.isSuccess()).isTrue();
    verify(() => inner.executeSql(request)).called(1);
  });

  for (final batch in [false, true]) {
    test(
      'preserves probe failures for ${batch ? 'batch' : 'unary'} queries',
      () async {
        const failure = SessionFailure(message: 'Session expired');
        when(
          () => eligibility.evaluate(
            userId: any(named: 'userId'),
            agentId: any(named: 'agentId'),
            isHubConnected: any(named: 'isHubConnected'),
            hubPresenceOnlineAgentIdsSnapshot: any(
              named: 'hubPresenceOnlineAgentIdsSnapshot',
            ),
          ),
        ).thenAnswer(
          (_) async =>
              const AgentSqlExecutionEligibilityEvaluation.failed(failure),
        );
        final result = batch
            ? await gated.executeSqlBatch(_batchRequest)
            : await gated.executeSql(_request);
        expect(result.exceptionOrNull(), same(failure));
        verifyZeroInteractions(inner);
      },
    );

    test(
      'cancel interrupts presence lookup and prevents a late ${batch ? 'batch' : 'unary'} dispatch',
      () async {
        final pending = Completer<AgentSqlExecutionEligibilityEvaluation>();
        when(
          () => eligibility.evaluate(
            userId: any(named: 'userId'),
            agentId: any(named: 'agentId'),
            isHubConnected: any(named: 'isHubConnected'),
            hubPresenceOnlineAgentIdsSnapshot: any(
              named: 'hubPresenceOnlineAgentIdsSnapshot',
            ),
          ),
        ).thenAnswer((_) => pending.future);
        final scope = AgentQueriesCancelScope();
        final result = batch
            ? gated.executeSqlBatch(_batchRequest, cancelScope: scope)
            : gated.executeSql(_request, cancelScope: scope);
        scope.cancelAll();
        expect(
          (await result).exceptionOrNull(),
          isA<OperationCancelledFailure>(),
        );
        pending.complete(
          const AgentSqlExecutionEligibilityEvaluation.allowed(),
        );
        await Future<void>.delayed(Duration.zero);
        verifyZeroInteractions(inner);
      },
    );

    test(
      'already cancelled ${batch ? 'batch' : 'unary'} skips presence and transport',
      () async {
        final scope = AgentQueriesCancelScope()..cancelAll();
        final result = batch
            ? await gated.executeSqlBatch(_batchRequest, cancelScope: scope)
            : await gated.executeSql(_request, cancelScope: scope);
        expect(result.exceptionOrNull(), isA<OperationCancelledFailure>());
        verifyZeroInteractions(eligibility);
        verifyZeroInteractions(inner);
      },
    );
  }
}

const _request = AgentSqlExecuteRequest(
  agentId: 'a1',
  sql: 'SELECT 1',
  requestingUserId: 'u1',
);
const _batchRequest = AgentSqlExecuteBatchRequest(
  agentId: 'a1',
  requestingUserId: 'u1',
  commands: [AgentSqlExecuteBatchCommand(sql: 'SELECT 1')],
);

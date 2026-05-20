import 'dart:async';

import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/socket/per_agent_concurrency_gate.dart';
import 'package:colmeia/features/agent_queries/data/repositories/rest_inflight_agent_queries_repository.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';
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

  const ok = AgentSqlExecutionResult(rows: <Map<String, dynamic>>[], rowCount: 0);

  test('serializes concurrent executeSql for the same agent', () async {
    final repo = RestInflightAgentQueriesRepository(delegate: delegate, gate: gate);
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
    final repo = RestInflightAgentQueriesRepository(delegate: delegate, gate: gate);
    const req = AgentSqlExecuteRequest(agentId: '   ', sql: 'SELECT 1');
    when(() => delegate.executeSql(req)).thenAnswer(
      (_) async => const Success<AgentSqlExecutionResult, AppFailure>(ok),
    );

    await repo.executeSql(req);

    verify(() => delegate.executeSql(req)).called(1);
    check(gate.inflightFor('')).equals(0);
  });
}

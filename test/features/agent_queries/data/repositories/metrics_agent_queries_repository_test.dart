import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/data/repositories/metrics_agent_queries_repository.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_batch_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_batch_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_options.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:result_dart/result_dart.dart';

void main() {
  group('MetricsAgentQueriesRepository', () {
    test('records relay execute options in recent metrics', () async {
      final delegate = _FakeAgentQueriesRepository(
        executeSqlResult: const Success<AgentSqlExecutionResult, AppFailure>(
          AgentSqlExecutionResult(
            rows: <Map<String, dynamic>>[
              <String, dynamic>{'id': 1},
              <String, dynamic>{'id': 2},
            ],
            rowCount: 2,
          ),
        ),
      );
      final repository = MetricsAgentQueriesRepository(
        delegate: delegate,
        enablePeriodicLogging: false,
      );

      await repository.executeSql(
        const AgentSqlExecuteRequest(
          agentId: 'agent-1',
          sql: 'select * from vendas',
          useRelay: true,
          relayMode: AgentSqlRelayMode.streaming,
          executeOptions: AgentSqlExecuteOptions(preferDbStreaming: true),
        ),
      );

      final metric = repository.getRecentMetrics(limit: 1).single;
      check(metric['operation']).equals('sql.execute');
      check(metric['route']).equals('relay');
      check(metric['relayMode']).equals('streaming');
      check(metric['preferDbStreaming']).equals(true);
      check(metric['apiVersion']).equals('2.10');
      check(metric['rowCount']).equals(2);
    });

    test('records batch parallelism and item counts', () async {
      final delegate = _FakeAgentQueriesRepository(
        executeSqlBatchResult:
            const Success<AgentSqlBatchExecutionResult, AppFailure>(
              AgentSqlBatchExecutionResult(
                totalCommands: 2,
                successfulCommands: 1,
                failedCommands: 1,
                items: <AgentSqlBatchExecutionItem>[
                  AgentSqlBatchExecutionItem(
                    index: 0,
                    ok: true,
                    rows: <Map<String, dynamic>>[
                      <String, dynamic>{'id': 1},
                    ],
                    rowCount: 1,
                  ),
                  AgentSqlBatchExecutionItem(
                    index: 1,
                    ok: false,
                    rows: <Map<String, dynamic>>[],
                    rowCount: 0,
                    error: 'failed',
                  ),
                ],
              ),
            ),
      );
      final repository = MetricsAgentQueriesRepository(
        delegate: delegate,
        enablePeriodicLogging: false,
      );

      await repository.executeSqlBatch(
        const AgentSqlExecuteBatchRequest(
          agentId: 'agent-1',
          commands: <AgentSqlExecuteBatchCommand>[
            AgentSqlExecuteBatchCommand(sql: 'select 1'),
            AgentSqlExecuteBatchCommand(sql: 'select 2'),
          ],
          useRelay: true,
          options: AgentSqlExecuteBatchOptions(
            maxParallelReadOnlyBatchItems: 6,
          ),
        ),
      );

      final metric = repository.getRecentMetrics(limit: 1).single;
      check(metric['operation']).equals('sql.executeBatch');
      check(metric['route']).equals('relay');
      check(metric['relayMode']).equals('unary');
      check(metric['apiVersion']).equals('2.10');
      check(metric['maxParallelReadOnlyBatchItems']).equals(6);
      check(metric['totalCommands']).equals(2);
      check(metric['successfulCommands']).equals(1);
      check(metric['failedCommands']).equals(1);
      check(metric['rowCount']).equals(1);
    });
  });
}

class _FakeAgentQueriesRepository implements AgentQueriesRepository {
  _FakeAgentQueriesRepository({
    this.executeSqlResult,
    this.executeSqlBatchResult,
  });

  final AppResult<AgentSqlExecutionResult>? executeSqlResult;
  final AppResult<AgentSqlBatchExecutionResult>? executeSqlBatchResult;

  @override
  Future<AppResult<AgentSqlExecutionResult>> executeSql(
    AgentSqlExecuteRequest request,
  ) async {
    return executeSqlResult ??
        const Failure<AgentSqlExecutionResult, AppFailure>(
          ValidationFailure(message: 'missing executeSql result'),
        );
  }

  @override
  Future<AppResult<AgentSqlBatchExecutionResult>> executeSqlBatch(
    AgentSqlExecuteBatchRequest request,
  ) async {
    return executeSqlBatchResult ??
        const Failure<AgentSqlBatchExecutionResult, AppFailure>(
          ValidationFailure(message: 'missing executeSqlBatch result'),
        );
  }
}

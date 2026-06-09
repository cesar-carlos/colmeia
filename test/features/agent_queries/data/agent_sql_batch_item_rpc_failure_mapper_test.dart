import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/data/agent_sql_batch_item_rpc_failure_mapper.dart';
import 'package:colmeia/features/agent_queries/domain/agent_sql_rpc_failure_ui_key.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_batch_execution_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AgentSqlBatchItemRpcFailureMapper', () {
    test('maps structured batch item error with retry_after_ms', () {
      const item = AgentSqlBatchExecutionItem(
        index: 2,
        ok: false,
        rows: <Map<String, dynamic>>[],
        rowCount: 0,
        error: 'Rate window exceeded',
        errorPayload: <String, dynamic>{
          'code': -32013,
          'message': 'Rate window exceeded',
          'data': <String, dynamic>{
            'reason': 'rate_window_exceeded',
            'retry_after_ms': 45000,
          },
        },
      );

      final failure = AgentSqlBatchItemRpcFailureMapper.fromFailedItem(
        item: item,
        operation: 'loadOverviewBatch',
      );

      expect(failure.rpcCode, -32013);
      expect(failure.reason, 'rate_window_exceeded');
      expect(failure.retryAfter, const Duration(milliseconds: 45000));
      expect(failure.retryable, isTrue);
      expect(
        failure.context[AgentSqlRpcFailureUiKey.field],
        AgentSqlRpcFailureUiKey.rateLimited,
      );
    });

    test('failureForItemOrNull returns null for ok items', () {
      const byIndex = <int, AgentSqlBatchExecutionItem>{
        0: AgentSqlBatchExecutionItem(
          index: 0,
          ok: true,
          rows: <Map<String, dynamic>>[],
          rowCount: 0,
        ),
      };

      expect(
        AgentSqlBatchItemRpcFailureMapper.failureForItemOrNull(
          byIndex: byIndex,
          index: 0,
          operation: 'sql.executeBatch',
        ),
        isNull,
      );
    });

    test('failureForItemOrNull maps missing batch slots', () {
      final failure = AgentSqlBatchItemRpcFailureMapper.failureForItemOrNull(
        byIndex: const <int, AgentSqlBatchExecutionItem>{},
        index: 2,
        operation: 'loadTrendBatch',
      );

      expect(failure, isA<RpcFailure>());
      expect((failure! as RpcFailure).reason, 'missing_batch_item');
    });

    test('falls back to batch_item_failed for plain string errors', () {
      const item = AgentSqlBatchExecutionItem(
        index: 0,
        ok: false,
        rows: <Map<String, dynamic>>[],
        rowCount: 0,
        error: 'bad sql',
      );

      final failure = AgentSqlBatchItemRpcFailureMapper.fromFailedItem(
        item: item,
        operation: 'sql.executeBatch',
      );

      expect(failure.reason, 'batch_item_failed');
      expect(failure.rpcCode, isNull);
      expect(failure.retryAfter, isNull);
    });
  });
}

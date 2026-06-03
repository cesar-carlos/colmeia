import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_batch_execution_result.dart';
import 'package:colmeia/features/overview/data/overview_sql_batch_item_rows_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OverviewSqlBatchItemRowsMapper', () {
    test('returns failure when batch item index is absent', () {
      final byIndex = <int, AgentSqlBatchExecutionItem>{};
      final result = OverviewSqlBatchItemRowsMapper.mapRowsForIndex<int>(
        byIndex,
        0,
        (row) => row['v']! as int,
      );
      expect(result.rows, isEmpty);
      expect(result.failure, isA<RpcFailure>());
      expect((result.failure! as RpcFailure).reason, 'missing_batch_item');
    });

    test('returns failure when item.ok is false', () {
      final byIndex = <int, AgentSqlBatchExecutionItem>{
        1: const AgentSqlBatchExecutionItem(
          index: 1,
          ok: false,
          rows: <Map<String, dynamic>>[],
          rowCount: 0,
          error: 'boom',
        ),
      };
      final result = OverviewSqlBatchItemRowsMapper.mapRowsForIndex<String>(
        byIndex,
        1,
        (row) => row['k']! as String,
      );
      expect(result.rows, isEmpty);
      expect(result.failure, isA<RpcFailure>());
      expect((result.failure! as RpcFailure).reason, 'batch_item_failed');
    });

    test('propagates structured rate limit metadata from batch item', () {
      final byIndex = <int, AgentSqlBatchExecutionItem>{
        1: const AgentSqlBatchExecutionItem(
          index: 1,
          ok: false,
          rows: <Map<String, dynamic>>[],
          rowCount: 0,
          error: 'Rate window exceeded',
          errorPayload: <String, dynamic>{
            'code': -32013,
            'message': 'Rate window exceeded',
            'data': <String, dynamic>{
              'reason': 'rate_window_exceeded',
              'retry_after_ms': 30000,
            },
          },
        ),
      };
      final result = OverviewSqlBatchItemRowsMapper.mapRowsForIndex<int>(
        byIndex,
        1,
        (row) => row['v']! as int,
      );
      final failure = result.failure! as RpcFailure;
      expect(failure.rpcCode, -32013);
      expect(failure.retryAfter, const Duration(milliseconds: 30000));
    });

    test('maps rows when item is ok', () {
      final byIndex = <int, AgentSqlBatchExecutionItem>{
        2: const AgentSqlBatchExecutionItem(
          index: 2,
          ok: true,
          rows: <Map<String, dynamic>>[
            <String, dynamic>{'v': 10},
            <String, dynamic>{'v': 20},
          ],
          rowCount: 2,
        ),
      };
      final result = OverviewSqlBatchItemRowsMapper.mapRowsForIndex<int>(
        byIndex,
        2,
        (row) => row['v']! as int,
      );
      expect(result.failure, isNull);
      expect(result.rows, <int>[10, 20]);
    });

    test('returns UnknownFailure when mapRow throws', () {
      final byIndex = <int, AgentSqlBatchExecutionItem>{
        0: const AgentSqlBatchExecutionItem(
          index: 0,
          ok: true,
          rows: <Map<String, dynamic>>[
            <String, dynamic>{'v': 'not-int'},
          ],
          rowCount: 1,
        ),
      };
      final result = OverviewSqlBatchItemRowsMapper.mapRowsForIndex<int>(
        byIndex,
        0,
        (row) => row['v']! as int,
      );
      expect(result.rows, isEmpty);
      expect(result.failure, isA<UnknownFailure>());
    });
  });
}

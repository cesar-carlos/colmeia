import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_batch_request.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AgentSqlExecuteBatchOptions.validationError', () {
    test('returns null when all fields are null', () {
      const options = AgentSqlExecuteBatchOptions();
      check(options.validationError()).isNull();
    });

    test('rejects maxParallelReadOnlyBatchItems < 1', () {
      const options = AgentSqlExecuteBatchOptions(
        maxParallelReadOnlyBatchItems: 0,
      );
      check(options.validationError()).equals(
        'maxParallelReadOnlyBatchItems must be >= 1',
      );
    });
  });

  group('AgentSqlExecuteBatchOptions.toRpcOptions', () {
    test('maps max_parallel_read_only_batch_items when provided', () {
      const options = AgentSqlExecuteBatchOptions(
        maxParallelReadOnlyBatchItems: 4,
      );

      final got = options.toRpcOptions();

      check(got).isNotNull();
      check(got!.length).equals(1);
      check(got['max_parallel_read_only_batch_items']).equals(4);
    });

    test('combines all option fields', () {
      const options = AgentSqlExecuteBatchOptions(
        sqlTimeoutMs: 1000,
        maxRows: 200,
        transaction: false,
        maxParallelReadOnlyBatchItems: 4,
      );

      final got = options.toRpcOptions();

      check(got).isNotNull();
      check(got!.length).equals(4);
      check(got['timeout_ms']).equals(1000);
      check(got['max_rows']).equals(200);
      check(got['transaction']).equals(false);
      check(got['max_parallel_read_only_batch_items']).equals(4);
    });
  });

  test('default api version tracks plug-jsonrpc-profile/2.10', () {
    check(kColmeiaAgentBatchApiVersion).equals('2.10');
  });
}

import 'dart:convert';

import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_bridge_limits.dart';
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

    test('rejects maxRows above hub cap', () {
      const options = AgentSqlExecuteBatchOptions(
        maxRows: AgentSqlBridgeLimits.maxRowsMax + 1,
      );
      check(options.validationError()).equals(
        'maxRows must be <= ${AgentSqlBridgeLimits.maxRowsMax}',
      );
    });

    test('rejects sqlTimeoutMs above hub cap', () {
      const options = AgentSqlExecuteBatchOptions(
        sqlTimeoutMs: AgentSqlBridgeLimits.sqlTimeoutMsMax + 1,
      );
      check(options.validationError()).equals(
        'sqlTimeoutMs must be <= ${AgentSqlBridgeLimits.sqlTimeoutMsMax}',
      );
    });
  });

  group('AgentSqlExecuteBatchRequest.validationError', () {
    test('rejects bridgeTimeoutMs above hub cap', () {
      const request = AgentSqlExecuteBatchRequest(
        agentId: 'a',
        commands: <AgentSqlExecuteBatchCommand>[
          AgentSqlExecuteBatchCommand(sql: 'SELECT 1'),
        ],
        bridgeTimeoutMs: AgentSqlBridgeLimits.bridgeTimeoutMsMax + 1,
      );
      check(request.validationError()).equals(
        'bridgeTimeoutMs must be <= '
        '${AgentSqlBridgeLimits.bridgeTimeoutMsMax}',
      );
    });

    test('rejects oversized namedParams on a batch command', () {
      final oversized = _namedParamsAtUtf8JsonByteLength(
        AgentSqlBridgeLimits.namedParamsJsonMaxUtf8Bytes + 1,
      );
      final request = AgentSqlExecuteBatchRequest(
        agentId: 'a',
        commands: <AgentSqlExecuteBatchCommand>[
          const AgentSqlExecuteBatchCommand(sql: 'SELECT 1'),
          AgentSqlExecuteBatchCommand(sql: 'SELECT 2', namedParams: oversized),
        ],
      );
      check(request.validationError()).isNotNull();
      expect(
        request.validationError(),
        startsWith('commands[1].namedParams JSON'),
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

Map<String, Object?> _namedParamsAtUtf8JsonByteLength(int targetBytes) {
  if (targetBytes <= 0) {
    throw ArgumentError.value(targetBytes);
  }

  var low = 0;
  var high = targetBytes;
  while (low < high) {
    final mid = (low + high + 1) ~/ 2;
    final size = utf8
        .encode(jsonEncode(<String, Object?>{'p': 'a' * mid}))
        .length;
    if (size <= targetBytes) {
      low = mid;
    } else {
      high = mid - 1;
    }
  }

  final buffer = StringBuffer('a' * low);
  var size = utf8
      .encode(jsonEncode(<String, Object?>{'p': buffer.toString()}))
      .length;
  while (size < targetBytes) {
    buffer.write('a');
    size = utf8
        .encode(jsonEncode(<String, Object?>{'p': buffer.toString()}))
        .length;
  }
  var value = buffer.toString();
  while (size > targetBytes) {
    value = value.substring(0, value.length - 1);
    size = utf8.encode(jsonEncode(<String, Object?>{'p': value})).length;
  }
  return <String, Object?>{'p': value};
}

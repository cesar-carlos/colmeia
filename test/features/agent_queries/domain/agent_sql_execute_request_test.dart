import 'dart:convert';

import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_bridge_limits.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_bridge_pagination.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_options.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AgentSqlExecuteRequest.validationError', () {
    test('returns null for minimal valid request', () {
      const r = AgentSqlExecuteRequest(agentId: 'a', sql: 'SELECT 1');
      check(r.validationError()).isNull();
    });

    test('trims agentId and sql before validation', () {
      const r = AgentSqlExecuteRequest(agentId: '  x  ', sql: '  SELECT 1  ');
      check(r.validationError()).isNull();
    });

    test('rejects empty agentId after trim', () {
      const r = AgentSqlExecuteRequest(agentId: '   ', sql: 'SELECT 1');
      check(r.validationError()).equals('agentId must not be empty');
    });

    test('rejects empty sql after trim', () {
      const r = AgentSqlExecuteRequest(agentId: 'a', sql: '  ');
      check(r.validationError()).equals('sql must not be empty');
    });

    test('rejects bridgeTimeoutMs < 1', () {
      const r = AgentSqlExecuteRequest(
        agentId: 'a',
        sql: 'SELECT 1',
        bridgeTimeoutMs: 0,
      );
      check(r.validationError()).equals('bridgeTimeoutMs must be >= 1');
    });

    test('rejects whitespace-only clientToken when provided', () {
      const r = AgentSqlExecuteRequest(
        agentId: 'a',
        sql: 'SELECT 1',
        clientToken: '   ',
      );
      check(
        r.validationError(),
      ).equals('clientToken must be null or non-empty');
    });

    test('accepts null clientToken', () {
      const r = AgentSqlExecuteRequest(
        agentId: 'a',
        sql: 'SELECT 1',
      );
      check(r.validationError()).isNull();
    });

    test(
      'rejects empty cursor pagination after trim '
      '(AgentSqlPagePagination already asserts page bounds)',
      () {
        final r = AgentSqlExecuteRequest(
          agentId: 'a',
          sql: 'SELECT 1',
          pagination: AgentSqlCursorPagination(cursor: '  '),
        );
        check(
          r.validationError(),
        ).equals('pagination.cursor must be non-empty');
      },
    );

    test('delegates to executeOptions validation for maxRows', () {
      const r = AgentSqlExecuteRequest(
        agentId: 'a',
        sql: 'SELECT 1',
        executeOptions: AgentSqlExecuteOptions(maxRows: 0),
      );
      check(r.validationError()).equals('maxRows must be >= 1');
    });

    test('delegates to executeOptions validation for sqlTimeoutMs', () {
      const r = AgentSqlExecuteRequest(
        agentId: 'a',
        sql: 'SELECT 1',
        executeOptions: AgentSqlExecuteOptions(sqlTimeoutMs: 0),
      );
      check(r.validationError()).equals('sqlTimeoutMs must be >= 1');
    });

    test('rejects pagination with executionMode preserve', () {
      const r = AgentSqlExecuteRequest(
        agentId: 'a',
        sql: 'SELECT 1',
        pagination: AgentSqlPagePagination(page: 1, pageSize: 10),
        executeOptions: AgentSqlExecuteOptions(
          executionMode: AgentSqlExecutionMode.preserve,
        ),
      );
      check(
        r.validationError(),
      ).equals('pagination cannot be combined with executionMode.preserve');
    });

    test('rejects bridgeTimeoutMs above hub cap', () {
      const r = AgentSqlExecuteRequest(
        agentId: 'a',
        sql: 'SELECT 1',
        bridgeTimeoutMs: AgentSqlBridgeLimits.bridgeTimeoutMsMax + 1,
      );
      check(r.validationError()).equals(
        'bridgeTimeoutMs must be <= '
        '${AgentSqlBridgeLimits.bridgeTimeoutMsMax}',
      );
    });

    test('accepts bridgeTimeoutMs at hub cap', () {
      const r = AgentSqlExecuteRequest(
        agentId: 'a',
        sql: 'SELECT 1',
        bridgeTimeoutMs: AgentSqlBridgeLimits.bridgeTimeoutMsMax,
      );
      check(r.validationError()).isNull();
    });

    test('rejects pageSize above hub cap', () {
      const r = AgentSqlExecuteRequest(
        agentId: 'a',
        sql: 'SELECT 1',
        pagination: AgentSqlPagePagination(
          page: 1,
          pageSize: AgentSqlBridgeLimits.pageSizeMax + 1,
        ),
      );
      check(r.validationError()).equals(
        'pagination.pageSize must be <= ${AgentSqlBridgeLimits.pageSizeMax}',
      );
    });

    test('accepts pageSize at hub cap', () {
      const r = AgentSqlExecuteRequest(
        agentId: 'a',
        sql: 'SELECT 1',
        pagination: AgentSqlPagePagination(
          page: 1,
          pageSize: AgentSqlBridgeLimits.pageSizeMax,
        ),
      );
      check(r.validationError()).isNull();
    });

    test('rejects namedParams JSON larger than bridge UTF-8 cap', () {
      final tooLarge = _namedParamsAtUtf8JsonByteLength(
        AgentSqlBridgeLimits.namedParamsJsonMaxUtf8Bytes + 1,
      );
      final r = AgentSqlExecuteRequest(
        agentId: 'a',
        sql: 'SELECT 1',
        namedParams: tooLarge,
      );
      check(r.validationError()).equals(
        'namedParams JSON must be at most '
        '${AgentSqlBridgeLimits.namedParamsJsonMaxUtf8Bytes} '
        'UTF-8 bytes (Agent SQL bridge limit)',
      );
    });

    test('accepts namedParams JSON at exact bridge UTF-8 cap', () {
      final atLimit = _namedParamsAtUtf8JsonByteLength(
        AgentSqlBridgeLimits.namedParamsJsonMaxUtf8Bytes,
      );
      final r = AgentSqlExecuteRequest(
        agentId: 'a',
        sql: 'SELECT 1',
        namedParams: atLimit,
      );
      check(r.validationError()).isNull();
    });

    test('counts multibyte UTF-8 when measuring namedParams JSON size', () {
      final asciiParams = <String, Object?>{'value': 'a' * 100};
      final emojiParams = <String, Object?>{'value': '😀' * 100};
      final asciiBytes = utf8.encode(jsonEncode(asciiParams)).length;
      final emojiBytes = utf8.encode(jsonEncode(emojiParams)).length;

      check(emojiBytes).isGreaterThan(asciiBytes);

      final overLimit = <String, Object?>{
        'value':
            '😀' *
            ((AgentSqlBridgeLimits.namedParamsJsonMaxUtf8Bytes ~/ 4) + 1),
      };
      check(
        AgentSqlBridgeLimits.namedParamsUtf8JsonSizeError(overLimit),
      ).isNotNull();
    });
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

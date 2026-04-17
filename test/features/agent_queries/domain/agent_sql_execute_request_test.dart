import 'package:checks/checks.dart';
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

    test('rejects namedParams larger than bridge cap', () {
      final tooMany = <String, Object?>{
        for (var i = 0;
            i < AgentSqlExecuteRequest.bridgeMaxNamedParameterCount + 1;
            i++)
          'p$i': i,
      };
      final r = AgentSqlExecuteRequest(
        agentId: 'a',
        sql: 'SELECT 1',
        namedParams: tooMany,
      );
      check(r.validationError()).equals(
        'namedParams must contain at most '
        '${AgentSqlExecuteRequest.bridgeMaxNamedParameterCount} '
        'entries (Agent SQL bridge limit)',
      );
    });
  });
}

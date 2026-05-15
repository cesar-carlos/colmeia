import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_options.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AgentSqlExecuteOptions.validationError', () {
    test('returns null when all fields are null', () {
      const o = AgentSqlExecuteOptions();
      check(o.validationError()).isNull();
    });

    test('rejects maxRows < 1', () {
      const o = AgentSqlExecuteOptions(maxRows: 0);
      check(o.validationError()).equals('maxRows must be >= 1');
    });

    test('rejects sqlTimeoutMs < 1', () {
      const o = AgentSqlExecuteOptions(sqlTimeoutMs: 0);
      check(o.validationError()).equals('sqlTimeoutMs must be >= 1');
    });
  });

  group('AgentSqlExecuteOptions.toRpcOptions', () {
    test('returns null when every field is null', () {
      const o = AgentSqlExecuteOptions();
      check(o.toRpcOptions()).isNull();
    });

    test('maps managed execution mode', () {
      const o = AgentSqlExecuteOptions(
        executionMode: AgentSqlExecutionMode.managed,
      );
      final got = o.toRpcOptions();
      check(got).isNotNull();
      check(got!.length).equals(1);
      check(got['execution_mode']).equals('managed');
    });

    test('maps preserve execution mode', () {
      const o = AgentSqlExecuteOptions(
        executionMode: AgentSqlExecutionMode.preserve,
      );
      final got = o.toRpcOptions();
      check(got).isNotNull();
      check(got!.length).equals(1);
      check(got['execution_mode']).equals('preserve');
    });

    test('maps max_rows and timeout_ms', () {
      const o = AgentSqlExecuteOptions(
        maxRows: 500,
        sqlTimeoutMs: 3000,
      );
      final got = o.toRpcOptions();
      check(got).isNotNull();
      check(got!.length).equals(2);
      check(got['max_rows']).equals(500);
      check(got['timeout_ms']).equals(3000);
    });

    test('maps prefer_db_streaming when provided', () {
      const o = AgentSqlExecuteOptions(preferDbStreaming: true);
      final got = o.toRpcOptions();
      check(got).isNotNull();
      check(got!.length).equals(1);
      check(got['prefer_db_streaming']).equals(true);
    });

    test('combines all option fields', () {
      const o = AgentSqlExecuteOptions(
        maxRows: 100,
        sqlTimeoutMs: 2000,
        executionMode: AgentSqlExecutionMode.managed,
        preferDbStreaming: true,
      );
      final got = o.toRpcOptions();
      check(got).isNotNull();
      check(got!.length).equals(4);
      check(got['max_rows']).equals(100);
      check(got['timeout_ms']).equals(2000);
      check(got['execution_mode']).equals('managed');
      check(got['prefer_db_streaming']).equals(true);
    });
  });
}

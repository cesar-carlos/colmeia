import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/domain/agent_sql_rpc_failure_ui_key.dart';
import 'package:colmeia/features/agent_queries/presentation/agent_query_failure_diagnostic.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('agentQueryFailureDiagnosticBody includes wire message and context', () {
    const failure = RpcFailure(
      message: 'SQL invalid',
      userMessage: 'SQL invalid on agent',
      rpcCode: -32012,
      retryable: false,
      reason: 'validation_failed',
      correlationId: 'corr-1',
      context: <String, Object?>{
        AgentSqlRpcFailureUiKey.field:
            AgentSqlRpcFailureUiKey.sqlValidationFailed,
      },
    );
    final body = agentQueryFailureDiagnosticBody(failure);
    check(body).contains('failureType: RpcFailure');
    check(body).contains('message: SQL invalid');
    check(body).contains('userMessage: SQL invalid on agent');
    check(body).contains('rpcCode: -32012');
    check(body).contains('agentSqlRpcFailureUiKey: sqlValidationFailed');
  });

  test('agentQueryFailureDiagnosticSummary keeps rpc identifiers short', () {
    const failure = RpcFailure(
      message: 'SQL invalid',
      userMessage: 'SQL invalid on agent',
      rpcCode: -32012,
      retryable: false,
      reason: 'validation_failed',
      correlationId: 'corr-1',
    );
    final summary = agentQueryFailureDiagnosticSummary(failure);
    check(summary).contains('failureType: RpcFailure');
    check(summary).contains('correlationId: corr-1');
    check(!summary.contains('context:')).isTrue();
  });

  test('overviewAppFailureDiagnosticBody prefixes localized friendly line', () {
    const failure = NetworkFailure(message: 'timeout');
    final body = overviewAppFailureDiagnosticBody(
      failure,
      localizedUserMessage: 'O agente demorou.',
    );
    check(body).startsWith('userFacingMessage: O agente demorou.');
    check(body).contains('message: timeout');
  });
}

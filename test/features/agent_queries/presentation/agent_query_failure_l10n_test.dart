import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/data/repositories/agent_queries_failure_codes.dart';
import 'package:colmeia/features/agent_queries/domain/agent_sql_rpc_failure_ui_key.dart';
import 'package:colmeia/features/agent_queries/presentation/localization/agent_query_failure_l10n.dart';
import 'package:colmeia/l10n/app_localizations_en.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final en = AppLocalizationsEn();

  test('RpcFailure rateLimited uses wait copy when retryAfter is set', () {
    const failure = RpcFailure(
      message: 'Rate limited',
      userMessage: 'Rate limited',
      rpcCode: -32013,
      retryable: true,
      retryAfter: Duration(seconds: 12),
      context: <String, Object?>{
        AgentSqlRpcFailureUiKey.field: AgentSqlRpcFailureUiKey.rateLimited,
      },
    );
    check(
      agentQueryFailureUserMessage(failure, en),
    ).equals(en.agentSqlErrorRateLimitedWithWait(12));
  });

  test('NetworkFailure with RATE_LIMITED transport code uses rate limit copy', () {
    const failure = NetworkFailure(
      message: 'too many',
      userMessage: 'too many',
      retryAfter: Duration(seconds: 3),
      context: <String, Object?>{
        AgentQueriesFailureContext.transportCodeField: 'RATE_LIMITED',
        AgentSqlRpcFailureUiKey.field: AgentSqlRpcFailureUiKey.rateLimited,
      },
    );
    check(
      agentQueryFailureUserMessage(failure, en),
    ).equals(en.agentSqlErrorRateLimitedWithWait(3));
  });

  test('SessionFailure uses authentication l10n', () {
    const failure = SessionFailure(message: 'expired');
    check(
      agentQueryFailureUserMessage(failure, en),
    ).equals(en.agentSqlErrorAuthenticationFailed);
  });

  test('AuthorizationFailure uses permission l10n', () {
    const failure = AuthorizationFailure(message: 'denied');
    check(
      agentQueryFailureUserMessage(failure, en),
    ).equals(en.agentSqlErrorPermissionDenied);
  });

  test('NetworkFailure with transport ui key uses matching l10n', () {
    const failure = NetworkFailure(
      message: 'timeout',
      context: <String, Object?>{
        AgentSqlRpcFailureUiKey.field:
            AgentSqlRpcFailureUiKey.transportTimeout,
      },
    );
    check(
      agentQueryFailureUserMessage(failure, en),
    ).equals(en.agentSqlErrorTransportTimeout);
  });

  test('cancelled failure returns null from OrNull helper', () {
    const failure = OperationCancelledFailure();
    check(agentQueryFailureUserMessageOrNull(failure, en)).isNull();
  });

  test('isAgentQueryRateLimitedFailure detects ui key and rpc code', () {
    check(
      isAgentQueryRateLimitedFailure(
        const RpcFailure(
          message: 'm',
          userMessage: 'u',
          rpcCode: -32013,
          retryable: false,
        ),
      ),
    ).isTrue();
    check(
      isAgentQueryRateLimitedFailure(
        const ValidationFailure(message: 'x'),
      ),
    ).isFalse();
  });
}

import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/domain/agent_sql_rpc_failure_ui_key.dart';
import 'package:colmeia/features/agent_queries/presentation/localization/agent_sql_rpc_failure_l10n.dart';
import 'package:colmeia/l10n/app_localizations_en.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l10n = AppLocalizationsEn();

  test('all catalogued agent SQL error strings are non-empty in English', () {
    check(l10n.agentSqlErrorAuthenticationFailed).isNotEmpty();
    check(l10n.agentSqlErrorPermissionDenied).isNotEmpty();
    check(l10n.agentSqlErrorTransportTimeout).isNotEmpty();
    check(l10n.agentSqlErrorNetworkError).isNotEmpty();
    check(l10n.agentSqlErrorRateLimited).isNotEmpty();
    check(l10n.agentSqlErrorValidationFailed).isNotEmpty();
    check(l10n.agentSqlErrorExecutionFailed).isNotEmpty();
    check(l10n.agentSqlErrorTransactionFailed).isNotEmpty();
    check(l10n.agentSqlErrorConnectionPoolExhausted).isNotEmpty();
    check(l10n.agentSqlErrorResultTooLarge).isNotEmpty();
    check(l10n.agentSqlErrorDatabaseConnectionFailed).isNotEmpty();
    check(l10n.agentSqlErrorQueryTimeout).isNotEmpty();
    check(l10n.agentSqlErrorInvalidDatabaseConfig).isNotEmpty();
    check(l10n.agentSqlErrorExecutionNotFound).isNotEmpty();
    check(l10n.agentSqlErrorExecutionCancelled).isNotEmpty();
    check(l10n.agentSqlErrorGeneric).isNotEmpty();
  });

  test(
    'agentSqlRpcFailureUserMessage maps uiKey to English catalog string',
    () {
      const failure = RpcFailure(
        message: 'm',
        userMessage: 'u',
        rpcCode: null,
        retryable: false,
        context: <String, Object?>{
          AgentSqlRpcFailureUiKey.field: AgentSqlRpcFailureUiKey.generic,
        },
      );
      check(
        agentSqlRpcFailureUserMessage(failure, l10n),
      ).equals(l10n.agentSqlErrorGeneric);
    },
  );

  test(
    'agentSqlRpcFailureUserMessage prefers bridge text when policy requests it',
    () {
      const bridgeText = 'Custom policy message from hub';
      const failure = RpcFailure(
        message: 'm',
        userMessage: bridgeText,
        rpcCode: -32602,
        retryable: false,
        context: <String, Object?>{
          AgentSqlRpcFailureUiKey.field:
              AgentSqlRpcFailureUiKey.sqlValidationFailed,
          AgentSqlRpcFailureUiKey.preferBridgeUserMessageField: true,
        },
      );
      check(agentSqlRpcFailureUserMessage(failure, l10n)).equals(bridgeText);
    },
  );
}

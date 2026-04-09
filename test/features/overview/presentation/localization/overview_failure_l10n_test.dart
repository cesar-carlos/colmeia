import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/domain/agent_sql_rpc_failure_ui_key.dart';
import 'package:colmeia/features/overview/domain/overview_failure_ui_key.dart';
import 'package:colmeia/features/overview/presentation/localization/overview_failure_l10n.dart';
import 'package:colmeia/l10n/app_localizations_en.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l10n = AppLocalizationsEn();

  test('maps overview no-approved-agents context to English string', () {
    const failure = ValidationFailure(
      message: 'technical',
      context: <String, Object?>{
        OverviewFailureUiKey.field: OverviewFailureUiKey.noApprovedAgents,
      },
    );

    check(overviewFailureUserMessage(failure, l10n)).equals(
      l10n.overviewNoApprovedAgentsUserMessage,
    );
  });

  test('maps overview load-failed context to English string', () {
    const failure = UnknownFailure(
      message: 'technical',
      userMessage: 'ignored when key present',
      context: <String, Object?>{
        OverviewFailureUiKey.field: OverviewFailureUiKey.loadFailed,
      },
    );

    check(overviewFailureUserMessage(failure, l10n)).equals(
      l10n.overviewLoadFailedUserMessage,
    );
  });

  test('maps overview missing client token context to English string', () {
    const failure = ValidationFailure(
      message: 'technical',
      context: <String, Object?>{
        OverviewFailureUiKey.field:
            OverviewFailureUiKey.missingLocalClientToken,
      },
    );

    check(overviewFailureUserMessage(failure, l10n)).equals(
      l10n.overviewSaveClientTokenForAgentUserMessage,
    );
  });

  test('maps SQL catalog keys to English strings', () {
    const failure = RpcFailure(
      message: 'm',
      userMessage: 'fallback pt',
      rpcCode: -32101,
      retryable: false,
      context: <String, Object?>{
        AgentSqlRpcFailureUiKey.field:
            AgentSqlRpcFailureUiKey.sqlValidationFailed,
      },
    );

    check(overviewFailureUserMessage(failure, l10n)).equals(
      l10n.agentSqlErrorValidationFailed,
    );
  });

  test('maps authentication transport failures to localized strings', () {
    const failure = RpcFailure(
      message: 'Authentication failed',
      userMessage: 'fallback',
      rpcCode: -32001,
      retryable: false,
      context: <String, Object?>{
        AgentSqlRpcFailureUiKey.field:
            AgentSqlRpcFailureUiKey.authenticationFailed,
      },
    );

    check(overviewFailureUserMessage(failure, l10n)).equals(
      l10n.agentSqlErrorAuthenticationFailed,
    );
  });

  test('maps rate limited transport failures to localized strings', () {
    const failure = RpcFailure(
      message: 'Rate limited',
      userMessage: 'fallback',
      rpcCode: -32013,
      retryable: false,
      context: <String, Object?>{
        AgentSqlRpcFailureUiKey.field: AgentSqlRpcFailureUiKey.rateLimited,
      },
    );

    check(overviewFailureUserMessage(failure, l10n)).equals(
      l10n.agentSqlErrorRateLimited,
    );
  });

  test('uses localized permission denied when bridge flag is absent', () {
    const failure = RpcFailure(
      message: 'Not authorized',
      userMessage: 'English RpcFailure fallback (ignored when l10n applies)',
      rpcCode: -32002,
      retryable: false,
      context: <String, Object?>{
        AgentSqlRpcFailureUiKey.field: AgentSqlRpcFailureUiKey.permissionDenied,
      },
    );

    check(overviewFailureUserMessage(failure, l10n)).equals(
      l10n.agentSqlErrorPermissionDenied,
    );
  });

  test('keeps bridge user message for permission denied when flagged', () {
    const bridge = 'Custom permission text from API';
    const failure = RpcFailure(
      message: 'Not authorized',
      userMessage: bridge,
      rpcCode: -32002,
      retryable: false,
      context: <String, Object?>{
        AgentSqlRpcFailureUiKey.field: AgentSqlRpcFailureUiKey.permissionDenied,
        AgentSqlRpcFailureUiKey.preferBridgeUserMessageField: true,
      },
    );

    check(overviewFailureUserMessage(failure, l10n)).equals(bridge);
  });

  test('falls back to displayMessage for unknown failures', () {
    const failure = UnknownFailure(
      message: 'technical',
      userMessage: 'User visible',
    );

    check(overviewFailureUserMessage(failure, l10n)).equals('User visible');
  });
}

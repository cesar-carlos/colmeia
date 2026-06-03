import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/data/agent_sql_rpc_user_message_resolver.dart';
import 'package:colmeia/features/agent_queries/data/models/agent_sql_bridge_response.dart';
import 'package:colmeia/features/agent_queries/domain/agent_sql_rpc_failure_ui_key.dart';
import 'package:colmeia/l10n/app_localizations_en.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final en = AppLocalizationsEn();

  test(
    'English fallbacks match app_en.arb agentSqlError* for catalog codes',
    () {
      final expectedByCode = <int, String>{
        -32001: en.agentSqlErrorAuthenticationFailed,
        -32008: en.agentSqlErrorTransportTimeout,
        -32012: en.agentSqlErrorNetworkError,
        -32013: en.agentSqlErrorRateLimited,
        -32602: en.agentSqlErrorValidationFailed,
        -32101: en.agentSqlErrorValidationFailed,
        -32102: en.agentSqlErrorExecutionFailed,
        -32103: en.agentSqlErrorTransactionFailed,
        -32104: en.agentSqlErrorConnectionPoolExhausted,
        -32105: en.agentSqlErrorResultTooLarge,
        -32106: en.agentSqlErrorDatabaseConnectionFailed,
        -32107: en.agentSqlErrorQueryTimeout,
        -32108: en.agentSqlErrorInvalidDatabaseConfig,
        -32109: en.agentSqlErrorExecutionNotFound,
        -32110: en.agentSqlErrorExecutionCancelled,
      };

      for (final entry in expectedByCode.entries) {
        final resolution = resolveAgentSqlRpcUserMessage(
          AgentSqlRpcErrorDetails(
            userMessage: '',
            message: 'rpc',
            code: entry.key,
          ),
        );
        check(resolution.userMessage).equals(entry.value);
        check(resolution.uiKey).isNotNull();
      }
    },
  );

  test('token_revoked maps to authentication copy', () {
    final resolution = resolveAgentSqlRpcUserMessage(
      const AgentSqlRpcErrorDetails(
        userMessage: '',
        message: 'Token revoked',
        code: -32002,
        reason: 'token_revoked',
      ),
    );
    check(resolution.userMessage).equals(en.agentSqlErrorAuthenticationFailed);
  });

  test('generic fallback matches app_en agentSqlErrorGeneric', () {
    final resolution = resolveAgentSqlRpcUserMessage(
      const AgentSqlRpcErrorDetails(userMessage: '', message: 'm'),
    );
    check(resolution.userMessage).equals(en.agentSqlErrorGeneric);
  });

  test(
    '-32101 uses bridge user_message when non-empty and prefers bridge in UI',
    () {
      const bridge =
          'A consulta nao pode ser executada porque contem um erro de sintaxe.';
      final resolution = resolveAgentSqlRpcUserMessage(
        const AgentSqlRpcErrorDetails(
          userMessage: bridge,
          message: 'SQL validation failed',
          code: -32101,
        ),
      );
      check(resolution.userMessage).equals(bridge);
      check(resolution.preferBridgeUserMessage).isTrue();
    },
  );

  test(
    '-32101 with category auth maps to sql validation, not permission denied',
    () {
      const bridge = 'Comando SQL nao suportado para autorizacao.';
      final resolution = resolveAgentSqlRpcUserMessage(
        const AgentSqlRpcErrorDetails(
          userMessage: bridge,
          message: 'SQL validation failed',
          code: -32101,
          category: 'auth',
          reason: 'validation',
        ),
      );
      check(resolution.userMessage).equals(bridge);
      check(
        resolution.uiKey,
      ).equals(AgentSqlRpcFailureUiKey.sqlValidationFailed);
      check(resolution.preferBridgeUserMessage).isTrue();
    },
  );

  test('rate_window_exceeded maps to rateLimited without -32013', () {
    final resolution = resolveAgentSqlRpcUserMessage(
      const AgentSqlRpcErrorDetails(
        userMessage: '',
        message: 'Rate window exceeded',
        reason: 'rate_window_exceeded',
      ),
    );
    check(resolution.uiKey).equals(AgentSqlRpcFailureUiKey.rateLimited);
    check(resolution.userMessage).equals(en.agentSqlErrorRateLimited);
  });

  test(
    'concurrent_handlers_exceeded maps to rateLimited without -32013',
    () {
      final resolution = resolveAgentSqlRpcUserMessage(
        const AgentSqlRpcErrorDetails(
          userMessage: '',
          message: 'Too many concurrent handlers',
          reason: 'concurrent_handlers_exceeded',
        ),
      );
      check(resolution.uiKey).equals(AgentSqlRpcFailureUiKey.rateLimited);
      check(resolution.userMessage).equals(en.agentSqlErrorRateLimited);
    },
  );

  test(
    'client_token_get_policy_rate_limited with -32013 maps to rateLimited',
    () {
      final resolution = resolveAgentSqlRpcUserMessage(
        const AgentSqlRpcErrorDetails(
          userMessage: '',
          message: 'Rate limited',
          code: -32013,
          reason: 'client_token_get_policy_rate_limited',
        ),
      );
      check(resolution.uiKey).equals(AgentSqlRpcFailureUiKey.rateLimited);
      check(resolution.userMessage).equals(en.agentSqlErrorRateLimited);
    },
  );

  test(
    '-32002 unauthorized with odbc_reason invalid_policy maps to sql '
    'validation (hub policy rejection), not permission denied',
    () {
      const bridge =
          'Comando SQL nao suportado para autorizacao. Revise a consulta '
          'enviada.';
      final resolution = resolveAgentSqlRpcUserMessage(
        const AgentSqlRpcErrorDetails(
          userMessage: bridge,
          message: 'Not authorized',
          code: -32002,
          reason: 'unauthorized',
          category: 'auth',
          errorData: <String, dynamic>{
            'reason': 'unauthorized',
            'category': 'auth',
            'odbc_reason': 'invalid_policy',
            'technical_message':
                'Authorization denied: unsupported SQL classification',
          },
        ),
      );
      check(resolution.userMessage).equals(bridge);
      check(
        resolution.uiKey,
      ).equals(AgentSqlRpcFailureUiKey.sqlValidationFailed);
      check(resolution.preferBridgeUserMessage).isTrue();
    },
  );
}

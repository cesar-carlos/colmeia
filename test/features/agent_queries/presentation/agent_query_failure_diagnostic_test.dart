import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/domain/agent_sql_rpc_failure_ui_key.dart';
import 'package:colmeia/features/agent_queries/presentation/agent_query_failure_diagnostic.dart';
import 'package:colmeia/l10n/app_localizations_en.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final en = AppLocalizationsEn();

  test(
    'technical details distinguish transportTimeout from queryTimeout',
    () {
      const transport = NetworkFailure(
        message: 'relay timeout',
        context: <String, Object?>{
          AgentSqlRpcFailureUiKey.field:
              AgentSqlRpcFailureUiKey.transportTimeout,
        },
      );
      const query = RpcFailure(
        message: 'sql timeout',
        userMessage: 'Query timed out',
        rpcCode: -32000,
        retryable: true,
        context: <String, Object?>{
          AgentSqlRpcFailureUiKey.field: AgentSqlRpcFailureUiKey.queryTimeout,
        },
      );

      final transportBody = agentQueryFailureTechnicalDetailsBody(
        transport,
        l10n: en,
      );
      final queryBody = agentQueryFailureTechnicalDetailsBody(
        query,
        l10n: en,
      );

      check(transportBody).contains(en.agentSqlFailureTitleTransportTimeout);
      check(transportBody).contains(AgentSqlRpcFailureUiKey.transportTimeout);
      check(queryBody).contains(en.agentSqlFailureTitleQueryTimeout);
      check(queryBody).contains(AgentSqlRpcFailureUiKey.queryTimeout);
      check(transportBody.contains(en.agentSqlFailureTitleQueryTimeout)).isFalse();
      check(queryBody.contains(en.agentSqlFailureTitleTransportTimeout)).isFalse();
    },
  );
}

import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/domain/agent_sql_rpc_failure_ui_key.dart';
import 'package:colmeia/features/agent_queries/presentation/agent_query_failure_presentation.dart';
import 'package:colmeia/l10n/app_localizations_en.dart';
import 'package:colmeia/shared/widgets/app_inline_error_panel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final en = AppLocalizationsEn();

  test('rate limit uses informational category and title', () {
    const failure = NetworkFailure(
      message: 'limited',
      retryAfter: Duration(seconds: 5),
      context: <String, Object?>{
        AgentSqlRpcFailureUiKey.field: AgentSqlRpcFailureUiKey.rateLimited,
      },
    );
    final presentation = AgentQueryFailurePresentation.from(failure, en);
    check(presentation.category).equals(AgentQueryFailureCategory.rateLimit);
    check(presentation.panelTone).equals(AppInlinePanelTone.informational);
    check(presentation.title).equals(en.agentSqlFailureTitleRateLimited);
    check(presentation.message).equals(en.agentSqlErrorRateLimitedWithWait(5));
    check(presentation.showRetry).isTrue();
  });

  test('cancelled failure suppresses panel', () {
    const failure = OperationCancelledFailure();
    final presentation = AgentQueryFailurePresentation.from(failure, en);
    check(presentation.suppressPanel).isTrue();
  });
}

import 'package:colmeia/features/agent_queries/presentation/localization/agent_query_failure_l10n.dart';
import 'package:colmeia/features/overview/application/overview_agent_query_failure_technical_summary.dart';
import 'package:colmeia/features/overview/domain/entities/overview_agent_query_failure_detail.dart';
import 'package:colmeia/l10n/app_localizations.dart';

extension OverviewAgentQueryFailureDetailL10n
    on OverviewAgentQueryFailureDetail {
  String userMessageFor(AppLocalizations l10n) =>
      agentQueryFailureUserMessage(failure, l10n);

  String? get technicalSummary =>
      overviewAgentQueryFailureTechnicalSummary(failure);
}

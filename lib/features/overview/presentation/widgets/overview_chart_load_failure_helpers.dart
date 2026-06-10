import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/presentation/agent_query_failure_support_context.dart';
import 'package:colmeia/features/agent_queries/presentation/localization/agent_query_failure_l10n.dart';
import 'package:colmeia/features/agent_queries/presentation/widgets/agent_query_chart_failure_placeholder_content.dart';
import 'package:colmeia/features/overview/domain/entities/overview.dart';
import 'package:colmeia/features/overview/domain/entities/overview_agent_query_failure_detail.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

bool overviewHasPartialFailuresForSource(
  Overview overview,
  OverviewAgentQueryFailureSource source,
) {
  return overview.partialQueryFailureDetails.any((d) => d.source == source);
}

String overviewChartLoadFailureMessage({
  required AppLocalizations l10n,
  required bool loadFailed,
  required String genericFallback,
  AppFailure? loadFailure,
  String? legacyMessage,
}) {
  if (!loadFailed) {
    return genericFallback;
  }
  return chartAgentQueryLoadFailureMessage(
    l10n: l10n,
    loadFailure: loadFailure,
    legacyMessage: legacyMessage,
    genericFallback: genericFallback,
  );
}

Widget overviewChartEmptyPlaceholder({
  required String emptyMessage,
  required TextStyle? textStyle,
  required double verticalPadding,
  VoidCallback? onViewAgentFailureDetails,
  AppFailure? loadFailure,
  AgentQueryFailureSupportContext? supportContext,
}) {
  return AgentQueryChartFailurePlaceholderContent(
    emptyMessage: emptyMessage,
    textStyle: textStyle,
    verticalPadding: verticalPadding,
    onViewAgentFailureDetails: onViewAgentFailureDetails,
    loadFailure: loadFailure,
    supportContext: supportContext,
  );
}

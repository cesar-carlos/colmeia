import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/presentation/agent_query_failure_diagnostic.dart';
import 'package:colmeia/features/agent_queries/presentation/agent_query_failure_support_context.dart';
import 'package:colmeia/features/agent_queries/presentation/widgets/agent_query_failure_technical_details.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:flutter/material.dart';

/// Chart/map empty state: friendly message, optional agent link, support details.
class AgentQueryChartFailurePlaceholderContent extends StatelessWidget {
  const AgentQueryChartFailurePlaceholderContent({
    required this.emptyMessage,
    required this.textStyle,
    required this.verticalPadding,
    super.key,
    this.loadFailure,
    this.supportContext,
    this.onViewAgentFailureDetails,
  });

  final String emptyMessage;
  final TextStyle? textStyle;
  final double verticalPadding;
  final AppFailure? loadFailure;
  final AgentQueryFailureSupportContext? supportContext;
  final VoidCallback? onViewAgentFailureDetails;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final failure = loadFailure;
    final technicalBody = failure == null
        ? null
        : agentQueryFailureTechnicalDetailsBody(
            failure,
            l10n: AppLocalizations.of(context),
          ).trim();

    return Padding(
      padding: EdgeInsets.symmetric(vertical: verticalPadding),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final content = Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                emptyMessage,
                textAlign: TextAlign.center,
                style: textStyle,
              ),
              if (onViewAgentFailureDetails != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: onViewAgentFailureDetails,
                    child: Text(
                      AppLocalizations.of(
                        context,
                      ).agentSqlFailureActionViewAffectedAgents,
                    ),
                  ),
                ),
              if (technicalBody != null &&
                  technicalBody.isNotEmpty) ...<Widget>[
                if (onViewAgentFailureDetails != null)
                  SizedBox(height: tokens.gapSm),
                AgentQueryFailureTechnicalDetails(
                  body: technicalBody,
                  failure: failure,
                  supportContext: supportContext,
                  compact: true,
                ),
              ],
            ],
          );

          if (!constraints.hasBoundedHeight) {
            return content;
          }

          return SingleChildScrollView(
            child: content,
          );
        },
      ),
    );
  }
}

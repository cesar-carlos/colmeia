import 'dart:async';
import 'dart:math' as math;

import 'package:colmeia/core/observability/agent_query_failure_support_metrics.dart';
import 'package:colmeia/features/agent_queries/presentation/agent_query_failure_clipboard.dart';
import 'package:colmeia/features/agent_queries/presentation/agent_query_failure_support_context.dart';
import 'package:colmeia/features/overview/domain/entities/overview_agent_query_failure_detail.dart';
import 'package:colmeia/features/overview/domain/overview_failure_referenced_agent_id.dart';
import 'package:colmeia/features/overview/presentation/overview_agent_query_failure_detail_l10n.dart';
import 'package:colmeia/features/overview/presentation/overview_partial_failure_details_plain_text.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:colmeia/shared/widgets/bottom_sheet_compact_drag_handle.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart' show ShareParams, SharePlus;

const Duration _kCopyConfirmationSnackBarDuration = Duration(seconds: 2);

abstract final class _OverviewAlertDetailSheetLayout {
  static const double maxWidth = 560;
  static const double initialChildSize = 0.55;
  static const double maxChildSize = 0.94;
}

String _sourceLabel(
  AppLocalizations l10n,
  OverviewAgentQueryFailureSource source,
) {
  return switch (source) {
    OverviewAgentQueryFailureSource.paymentResumo =>
      l10n.overviewHomeAlertFailureSourcePaymentResumo,
    OverviewAgentQueryFailureSource.lucratividadePeriod =>
      l10n.overviewHomeAlertFailureSourceLucratividadePeriod,
    OverviewAgentQueryFailureSource.userResumo =>
      l10n.overviewHomeAlertFailureSourceUserResumo,
    OverviewAgentQueryFailureSource.monthlyTrend =>
      l10n.overviewHomeAlertFailureSourceMonthlyTrend,
    OverviewAgentQueryFailureSource.weekdayTrend =>
      l10n.overviewHomeAlertFailureSourceWeekdayTrend,
    OverviewAgentQueryFailureSource.weekdayUserTrend =>
      l10n.overviewHomeAlertFailureSourceWeekdayUserTrend,
    OverviewAgentQueryFailureSource.dailyTrend =>
      l10n.overviewHomeAlertFailureSourceDailyTrend,
  };
}

String formatOverviewPartialFailuresDiagnosticBody(
  AppLocalizations l10n,
  List<OverviewAgentQueryFailureDetail> details,
) {
  return formatOverviewPartialFailureDetailsPlainText(
    details: details,
    l10n: l10n,
    emptyMessage: l10n.overviewHomeAlertDetailsNoEntries,
    sourceLabel: (s) => _sourceLabel(l10n, s),
    userLineLabel: l10n.overviewHomeAlertDetailsUserLine,
    technicalLineLabel: l10n.overviewHomeAlertDetailsTechnicalLine,
  );
}

Future<void> showOverviewAlertPlainDetailSheet({
  required BuildContext context,
  required String title,
  required String body,
}) async {
  final trimmed = body.trim();
  if (trimmed.isEmpty) {
    return;
  }
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: false,
    builder: (ctx) => _OverviewAlertDetailSheetScaffold(
      title: title,
      bodyText: trimmed,
    ),
  );
}

Future<void> showOverviewPartialFailureDetailsSheet({
  required BuildContext context,
  required AppLocalizations l10n,
  required List<OverviewAgentQueryFailureDetail> details,
}) async {
  if (details.isEmpty) {
    return;
  }
  final body = formatOverviewPartialFailuresDiagnosticBody(
    l10n,
    details,
  ).trim();
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: false,
    builder: (ctx) => _OverviewAlertDetailSheetScaffold(
      title: l10n.dashboardAffectedAgentsSheetTitlePartialFailure,
      bodyText: body,
      structuredFailureDetails: details,
    ),
  );
}

class _OverviewAlertDetailSheetScaffold extends StatelessWidget {
  const _OverviewAlertDetailSheetScaffold({
    required this.title,
    required this.bodyText,
    this.structuredFailureDetails,
  });

  final String title;
  final String bodyText;

  /// When non-empty, shows one scrollable block per agent instead of a
  /// single [SelectableText] blob (clipboard text remains [bodyText]).
  final List<OverviewAgentQueryFailureDetail>? structuredFailureDetails;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final typography = theme.extension<AppTypographyTokens>()!;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final structured = structuredFailureDetails;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: _OverviewAlertDetailSheetLayout.initialChildSize,
        minChildSize: draggableSheetMinChildFractionForChrome(
          viewportHeight: MediaQuery.sizeOf(context).height,
          minChromePixels: 168,
          minClamp: 0.38,
        ),
        maxChildSize: _OverviewAlertDetailSheetLayout.maxChildSize,
        builder: (context, scrollController) {
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: math.min(
                  _OverviewAlertDetailSheetLayout.maxWidth,
                  MediaQuery.sizeOf(context).width,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const BottomSheetCompactDragHandle(),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      tokens.contentSpacing,
                      0,
                      tokens.contentSpacing,
                      tokens.gapSm,
                    ),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            title,
                            style: typography.sectionHeaderH2.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip:
                              l10n.overviewHomeAlertDetailsCopySemanticsLabel,
                          constraints: const BoxConstraints(
                            minWidth: 48,
                            minHeight: 48,
                          ),
                          onPressed: () async {
                            final l10n = AppLocalizations.of(context);
                            final locale = Localizations.localeOf(
                              context,
                            ).toString();
                            final clipboardText = formatAgentQueryFailureClipboard(
                              diagnosticBody: bodyText,
                              supportContext:
                                  AgentQueryFailureSupportContext.environment(
                                    localeName: locale,
                                    extra: <String, String>{
                                      'surface': 'overview_alert_detail_sheet',
                                      ...AgentQueryFailureSupportMetrics.collectOptional(),
                                    },
                                  ),
                            );
                            await Clipboard.setData(
                              ClipboardData(text: clipboardText),
                            );
                            if (!context.mounted) {
                              return;
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                behavior: SnackBarBehavior.floating,
                                duration: _kCopyConfirmationSnackBarDuration,
                                content: Text(
                                  l10n.agentSqlFailureTechnicalDetailsCopied,
                                ),
                                action: SnackBarAction(
                                  label:
                                      l10n.agentSqlFailureTechnicalDetailsShare,
                                  onPressed: () => unawaited(
                                    SharePlus.instance.share(
                                      ShareParams(text: clipboardText),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.copy_rounded),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded),
                          tooltip: MaterialLocalizations.of(
                            context,
                          ).closeButtonTooltip,
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: structured != null && structured.isNotEmpty
                        ? ListView.separated(
                            controller: scrollController,
                            padding: EdgeInsets.fromLTRB(
                              tokens.contentSpacing,
                              tokens.gapSm,
                              tokens.contentSpacing,
                              tokens.contentSpacing,
                            ),
                            itemCount: structured.length,
                            separatorBuilder: (_, _) => Divider(
                              height: tokens.gapMd * 2,
                              thickness: 1,
                            ),
                            itemBuilder: (context, index) {
                              final d = structured[index];
                              final tech = d.technicalSummary?.trim();
                              final referencedBridgeId =
                                  overviewFailureReferencedAgentId(
                                    detailAgentId: d.agentId,
                                    failure: d.failure,
                                  );
                              return Semantics(
                                container: true,
                                label: l10n
                                    .overviewHomeAlertDetailsAgentSemanticSummary(
                                      d.displayName,
                                      d.agentId,
                                      _sourceLabel(l10n, d.source),
                                      d.userMessageFor(l10n),
                                    ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      '${d.displayName} (${d.agentId})',
                                      style: typography.body.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                    SizedBox(height: tokens.gapSm),
                                    Text(
                                      _sourceLabel(l10n, d.source),
                                      style: typography.caption.copyWith(
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    SizedBox(height: tokens.gapSm),
                                    SelectableText(
                                      '${l10n.overviewHomeAlertDetailsUserLine}: ${d.userMessageFor(l10n)}',
                                      style: typography.body.copyWith(
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                    if (referencedBridgeId != null) ...[
                                      SizedBox(height: tokens.gapSm),
                                      Text(
                                        l10n.overviewHomeAlertDetailsReferencedBridgeIdNote(
                                          referencedBridgeId,
                                          d.agentId,
                                        ),
                                        style: typography.caption.copyWith(
                                          color: theme
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                    if (tech != null && tech.isNotEmpty) ...[
                                      SizedBox(height: tokens.gapSm),
                                      SelectableText(
                                        '${l10n.overviewHomeAlertDetailsTechnicalLine}: $tech',
                                        style: typography.body.copyWith(
                                          color: theme.colorScheme.onSurface,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          )
                        : ListView(
                            controller: scrollController,
                            padding: EdgeInsets.fromLTRB(
                              tokens.contentSpacing,
                              tokens.gapSm,
                              tokens.contentSpacing,
                              tokens.contentSpacing,
                            ),
                            children: <Widget>[
                              SelectableText(
                                bodyText,
                                style: typography.body.copyWith(
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

import 'dart:async';

import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/presentation/agent_query_failure_clipboard.dart';
import 'package:colmeia/features/agent_queries/presentation/agent_query_failure_diagnostic.dart';
import 'package:colmeia/features/agent_queries/presentation/agent_query_failure_support_context.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/actions/app_secondary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart' show ShareParams, SharePlus;

const double _kTechnicalDetailsMaxHeight = 240;
const double _kMinTouchTargetSize = 48;

/// Expandable support-oriented diagnostic text with copy and share.
class AgentQueryFailureTechnicalDetails extends StatefulWidget {
  const AgentQueryFailureTechnicalDetails({
    required this.body,
    super.key,
    this.summaryBody,
    this.failure,
    this.supportContext,
    this.initiallyExpanded = false,
    this.compact = false,
  });

  final String body;
  final String? summaryBody;
  final AppFailure? failure;
  final AgentQueryFailureSupportContext? supportContext;
  final bool initiallyExpanded;
  final bool compact;

  @override
  State<AgentQueryFailureTechnicalDetails> createState() =>
      _AgentQueryFailureTechnicalDetailsState();
}

class _AgentQueryFailureTechnicalDetailsState
    extends State<AgentQueryFailureTechnicalDetails> {
  late bool _expanded = widget.initiallyExpanded;
  final ScrollController _detailsScrollController = ScrollController();

  @override
  void dispose() {
    _detailsScrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant AgentQueryFailureTechnicalDetails oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.body != widget.body) {
      _expanded = widget.initiallyExpanded;
    }
  }

  String get _fullDiagnostic => widget.body.trim();

  String get _summaryDiagnostic {
    final explicit = widget.summaryBody?.trim();
    if (explicit != null && explicit.isNotEmpty) {
      return explicit;
    }
    final failure = widget.failure;
    if (failure != null) {
      return agentQueryFailureDiagnosticSummary(failure);
    }
    return _fullDiagnostic;
  }

  AgentQueryFailureSupportContext _resolvedSupportContext(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    return AgentQueryFailureSupportContext.environment(
      localeName: locale,
    ).merge(widget.supportContext);
  }

  String _clipboardText(BuildContext context, {required bool summaryOnly}) {
    final diagnostic = summaryOnly ? _summaryDiagnostic : _fullDiagnostic;
    return formatAgentQueryFailureClipboard(
      diagnosticBody: diagnostic,
      supportContext: _resolvedSupportContext(context),
      failure: widget.failure,
    );
  }

  Future<void> _copy(
    BuildContext context, {
    required bool summaryOnly,
  }) async {
    final l10n = AppLocalizations.of(context);
    final text = _clipboardText(context, summaryOnly: summaryOnly);
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(l10n.agentSqlFailureTechnicalDetailsCopied),
        action: SnackBarAction(
          label: l10n.agentSqlFailureTechnicalDetailsShare,
          onPressed: () => unawaited(_share(context, text: text)),
        ),
      ),
    );
  }

  Future<void> _share(BuildContext context, {String? text}) async {
    final payload = text ?? _clipboardText(context, summaryOnly: false);
    await SharePlus.instance.share(ShareParams(text: payload));
  }

  @override
  Widget build(BuildContext context) {
    final trimmed = _fullDiagnostic;
    if (trimmed.isEmpty) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final colors = theme.colorScheme;
    final contentPadding = widget.compact
        ? EdgeInsets.zero
        : EdgeInsets.symmetric(horizontal: tokens.gapXs);

    return Semantics(
      container: true,
      expanded: _expanded,
      child: Padding(
        padding: contentPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => setState(() => _expanded = !_expanded),
                borderRadius:
                    BorderRadius.circular(tokens.inlineAlertCornerRadius),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: _kMinTouchTargetSize),
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: tokens.gapXs),
                    child: Row(
                      children: <Widget>[
                        Icon(
                          _expanded
                              ? Icons.expand_less_rounded
                              : Icons.expand_more_rounded,
                          color: colors.primary,
                        ),
                        SizedBox(width: tokens.gapSm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                _expanded
                                    ? l10n
                                        .agentSqlFailureActionHideTechnicalDetails
                                    : l10n
                                        .agentSqlFailureActionShowTechnicalDetails,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: colors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (!_expanded) ...<Widget>[
                                SizedBox(height: tokens.gapXs),
                                Text(
                                  l10n.agentSqlFailureTechnicalDetailsSubtitle,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (_expanded) ...<Widget>[
              SizedBox(height: tokens.gapSm),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  borderRadius:
                      BorderRadius.circular(tokens.inlineAlertCornerRadius),
                  border: Border.all(color: colors.outlineVariant),
                ),
                child: Padding(
                  padding: EdgeInsets.all(tokens.gapSm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text(
                        l10n.agentSqlFailureTechnicalDetailsHeading,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: tokens.gapSm),
                      Wrap(
                        spacing: tokens.gapSm,
                        runSpacing: tokens.gapSm,
                        children: <Widget>[
                          AppSecondaryButton(
                            label: l10n.agentSqlFailureTechnicalDetailsCopySummary,
                            onPressed: () => unawaited(
                              _copy(context, summaryOnly: true),
                            ),
                          ),
                          AppSecondaryButton(
                            label: l10n.agentSqlFailureTechnicalDetailsCopyFull,
                            onPressed: () => unawaited(
                              _copy(context, summaryOnly: false),
                            ),
                          ),
                          AppSecondaryButton(
                            label: l10n.agentSqlFailureTechnicalDetailsShare,
                            onPressed: () => unawaited(_share(context)),
                          ),
                        ],
                      ),
                      SizedBox(height: tokens.gapSm),
                      ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxHeight: _kTechnicalDetailsMaxHeight,
                        ),
                        child: Scrollbar(
                          controller: _detailsScrollController,
                          thumbVisibility: true,
                          child: SingleChildScrollView(
                            primary: false,
                            controller: _detailsScrollController,
                            child: SelectableText(
                              trimmed,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontFamily: 'monospace',
                                height: 1.35,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

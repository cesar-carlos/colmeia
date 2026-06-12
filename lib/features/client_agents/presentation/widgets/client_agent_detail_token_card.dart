import 'dart:async';

import 'package:colmeia/features/client_agents/presentation/controllers/client_agent_detail_controller.dart';
import 'package:colmeia/features/client_agents/presentation/models/client_agents_presentation_message.dart';
import 'package:colmeia/features/client_agents/presentation/widgets/client_agent_detail_feedback_text.dart';
import 'package:colmeia/features/client_agents/presentation/widgets/client_agent_detail_visual_tokens.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/actions/app_primary_button.dart';
import 'package:colmeia/shared/widgets/actions/app_secondary_button.dart';
import 'package:colmeia/shared/widgets/app_section_card_with_heading.dart';
import 'package:colmeia/shared/widgets/forms/app_text_field.dart';
import 'package:flutter/material.dart';

class ClientAgentDetailTokenCard extends StatefulWidget {
  const ClientAgentDetailTokenCard({
    required this.agentId,
    required this.controller,
    required this.l10n,
    required this.tokens,
    super.key,
    this.inputFocusNode,
    this.onDirtyChanged,
    this.discardRevision = 0,
  });

  final String agentId;
  final ClientAgentDetailController controller;
  final AppLocalizations l10n;
  final AppThemeTokens tokens;
  final FocusNode? inputFocusNode;
  final ValueChanged<bool>? onDirtyChanged;
  final int discardRevision;

  @override
  State<ClientAgentDetailTokenCard> createState() =>
      _ClientAgentDetailTokenCardState();
}

class _ClientAgentDetailTokenCardState
    extends State<ClientAgentDetailTokenCard> {
  late final TextEditingController _tokenController;
  int _lastSyncedRevision = -1;
  bool _obscureToken = true;
  String _lastAppliedTokenText = '';
  bool _forceApplyNextRevision = false;
  bool _suppressTokenDirtyNotify = false;
  ClientAgentsPresentationMessage? _ephemeralFeedback;
  ClientAgentsPresentationMessage? _ephemeralError;

  @override
  void initState() {
    super.initState();
    _tokenController = TextEditingController();
    _tokenController.addListener(_notifyTokenDirty);
    widget.controller.addListener(_syncTokenFieldFromController);
    _syncTokenFieldFromController();
  }

  @override
  void didUpdateWidget(covariant ClientAgentDetailTokenCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.discardRevision != oldWidget.discardRevision) {
      _forceApplyNextRevision = true;
      _syncTokenFieldFromController();
    }
  }

  void _notifyTokenDirty() {
    if (_suppressTokenDirtyNotify) {
      return;
    }
    final onDirtyChanged = widget.onDirtyChanged;
    if (onDirtyChanged == null) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      onDirtyChanged(_tokenController.text != _lastAppliedTokenText);
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncTokenFieldFromController);
    _tokenController
      ..removeListener(_notifyTokenDirty)
      ..dispose();
    super.dispose();
  }

  void _syncTokenFieldFromController() {
    final c = widget.controller;
    if (c.isSavingClientToken &&
        (_ephemeralFeedback != null || _ephemeralError != null)) {
      setState(() {
        _ephemeralFeedback = null;
        _ephemeralError = null;
      });
    }
    if (c.clientTokenFeedback != null || c.clientTokenError != null) {
      setState(() {
        _ephemeralFeedback = c.clientTokenFeedback;
        _ephemeralError = c.clientTokenError;
      });
      if (c.clientTokenRevision == _lastSyncedRevision) {
        _forceApplyNextRevision = false;
      }
      c.clearClientTokenFeedback();
    }
    if (_lastSyncedRevision == c.clientTokenRevision) {
      return;
    }
    final text = c.persistedClientTokenForField;
    final hasUnsavedLocalEdits = _tokenController.text != _lastAppliedTokenText;
    if (!_forceApplyNextRevision &&
        hasUnsavedLocalEdits &&
        _tokenController.text != text) {
      return;
    }
    _lastSyncedRevision = c.clientTokenRevision;
    if (_tokenController.text != text) {
      _suppressTokenDirtyNotify = true;
      try {
        _tokenController.value = TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        );
      } finally {
        _suppressTokenDirtyNotify = false;
      }
    }
    _lastAppliedTokenText = text;
    _forceApplyNextRevision = false;
    _notifyTokenDirty();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final feedback = localizeClientAgentDetailPresentationMessage(
      _ephemeralFeedback,
      widget.l10n,
    );
    final feedbackError = localizeClientAgentDetailPresentationMessage(
      _ephemeralError,
      widget.l10n,
    );
    final isMutating = c.isSavingClientToken;

    return AppSectionCardWithHeading(
      title: widget.l10n.clientAgentDetailSectionServerToken,
      subtitle: widget.l10n.clientAgentDetailSectionServerTokenSubtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ClientAgentDetailTokenStatusRow(
            status: c.clientTokenStatus,
            isLoading: c.isLoadingClientToken,
            l10n: widget.l10n,
            tokens: widget.tokens,
          ),
          SizedBox(height: widget.tokens.gapMd),
          AppTextField(
            controller: _tokenController,
            focusNode: widget.inputFocusNode,
            label: widget.l10n.clientAgentsClientTokenLabel,
            hintText: widget.l10n.clientAgentsClientTokenHint,
            obscureText: _obscureToken,
            textInputAction: TextInputAction.done,
            suffix: IconButton(
              tooltip: _obscureToken
                  ? widget.l10n.clientAgentsClientTokenShow
                  : widget.l10n.clientAgentsClientTokenHide,
              onPressed: () {
                setState(() {
                  _obscureToken = !_obscureToken;
                });
              },
              icon: Icon(
                _obscureToken
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded,
              ),
            ),
          ),
          SizedBox(height: widget.tokens.gapMd),
          Wrap(
            spacing: widget.tokens.gapSm,
            runSpacing: widget.tokens.gapSm,
            children: <Widget>[
              AppPrimaryButton(
                label: c.isOnRetryCooldown
                    ? widget.l10n.clientAgentDetailRetryAfterCountdown(
                        c.retryAfterGate.remaining?.inSeconds ?? 0,
                      )
                    : widget.l10n.clientAgentDetailServerTokenSave,
                icon: const Icon(Icons.cloud_upload_rounded),
                isLoading: isMutating,
                onPressed: isMutating || c.isOnRetryCooldown
                    ? null
                    : () {
                        _forceApplyNextRevision = true;
                        unawaited(
                          c.saveClientAgentToken(
                            agentId: widget.agentId,
                            rawToken: _tokenController.text,
                          ),
                        );
                      },
              ),
              AppSecondaryButton(
                label: widget.l10n.clientAgentDetailServerTokenRemove,
                icon: const Icon(Icons.delete_outline_rounded),
                onPressed: isMutating || c.isOnRetryCooldown
                    ? null
                    : () {
                        _forceApplyNextRevision = true;
                        unawaited(
                          c.removeClientAgentToken(agentId: widget.agentId),
                        );
                      },
              ),
            ],
          ),
          if (feedback != null) ...<Widget>[
            SizedBox(height: widget.tokens.gapSm),
            ClientAgentDetailFeedbackText(
              message: feedback,
              tone: ClientAgentDetailFeedbackTone.info,
            ),
          ],
          if (feedbackError != null) ...<Widget>[
            SizedBox(height: widget.tokens.gapSm),
            ClientAgentDetailFeedbackText(
              message: feedbackError,
              tone: ClientAgentDetailFeedbackTone.error,
            ),
          ],
        ],
      ),
    );
  }
}

class ClientAgentDetailTokenStatusRow extends StatelessWidget {
  const ClientAgentDetailTokenStatusRow({
    required this.status,
    required this.isLoading,
    required this.l10n,
    required this.tokens,
    super.key,
  });

  final ClientAgentTokenStatus status;
  final bool isLoading;
  final AppLocalizations l10n;
  final AppThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final (IconData icon, Color color, String label) = switch (status) {
      ClientAgentTokenStatus.configured => (
        Icons.verified_rounded,
        colors.primary,
        l10n.clientAgentDetailServerTokenStatusConfigured,
      ),
      ClientAgentTokenStatus.missing => (
        Icons.info_outline_rounded,
        colors.onSurfaceVariant,
        l10n.clientAgentDetailServerTokenStatusMissing,
      ),
      ClientAgentTokenStatus.unknown => (
        Icons.help_outline_rounded,
        colors.onSurfaceVariant,
        l10n.clientAgentDetailServerTokenStatusUnknown,
      ),
    };

    return Row(
      children: <Widget>[
        if (isLoading)
          SizedBox.square(
            dimension: kClientAgentDetailStatusSpinnerSize,
            child: CircularProgressIndicator(
              strokeWidth: kClientAgentDetailSpinnerStrokeWidth,
              color: color,
            ),
          )
        else
          Icon(icon, size: kClientAgentDetailStatusIconSize, color: color),
        SizedBox(width: tokens.gapSm),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

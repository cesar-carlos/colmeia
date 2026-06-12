import 'package:colmeia/features/client_agents/domain/entities/client_agent.dart';
import 'package:colmeia/features/client_agents/presentation/controllers/client_agent_detail_controller.dart';
import 'package:colmeia/features/client_agents/presentation/widgets/client_agent_detail_metadata_cards.dart';
import 'package:colmeia/features/client_agents/presentation/widgets/client_agent_detail_policy_card.dart';
import 'package:colmeia/features/client_agents/presentation/widgets/client_agent_detail_token_card.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/actions/app_secondary_button.dart';
import 'package:colmeia/shared/widgets/app_section_card_with_heading.dart';
import 'package:colmeia/shared/widgets/app_skeleton.dart';
import 'package:flutter/material.dart';

class ClientAgentDetailTabSkeleton extends StatelessWidget {
  const ClientAgentDetailTabSkeleton({required this.tokens, super.key});

  final AppThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    return AppSkeleton(
      enabled: true,
      child: AppSectionCardWithHeading(
        title: ' ',
        child: SizedBox(height: tokens.contentSpacing * 4),
      ),
    );
  }
}

class ClientAgentDetailInfoTab extends StatelessWidget {
  const ClientAgentDetailInfoTab({
    required this.agent,
    required this.l10n,
    required this.tokens,
    super.key,
  });

  final ClientAgent agent;
  final AppLocalizations l10n;
  final AppThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ClientAgentDetailMetadataCard(agent: agent, l10n: l10n),
        SizedBox(height: tokens.gapMd),
        ClientAgentDetailRecordCard(agent: agent, l10n: l10n),
      ],
    );
  }
}

class ClientAgentDetailConnectionTab extends StatelessWidget {
  const ClientAgentDetailConnectionTab({
    required this.agentId,
    required this.controller,
    required this.l10n,
    required this.tokens,
    required this.tokenCardAnchorKey,
    required this.inputFocusNode,
    required this.onRequestNewToken,
    super.key,
    this.onTokenDirtyChanged,
    this.tokenDiscardRevision = 0,
  });

  final String agentId;
  final ClientAgentDetailController controller;
  final AppLocalizations l10n;
  final AppThemeTokens tokens;
  final GlobalKey tokenCardAnchorKey;
  final FocusNode inputFocusNode;
  final VoidCallback onRequestNewToken;
  final ValueChanged<bool>? onTokenDirtyChanged;
  final int tokenDiscardRevision;

  @override
  Widget build(BuildContext context) {
    final status = controller.clientTokenStatus;
    final showTokenSkeleton =
        controller.isLoadingClientToken &&
        status == ClientAgentTokenStatus.unknown;
    final showMissingTokenBanner = status == ClientAgentTokenStatus.missing;
    final policyRevoked = controller.clientTokenPolicy?.revoked ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (showMissingTokenBanner || policyRevoked)
          Padding(
            padding: EdgeInsets.only(bottom: tokens.gapMd),
            child: ClientAgentDetailConnectionTokenEmptyState(
              l10n: l10n,
              tokens: tokens,
              revoked: policyRevoked,
              onConfigureToken: onRequestNewToken,
            ),
          ),
        if (showTokenSkeleton)
          AppSkeleton(
            enabled: true,
            child: AppSectionCardWithHeading(
              title: ' ',
              child: SizedBox(height: tokens.contentSpacing * 3),
            ),
          )
        else
          KeyedSubtree(
            key: tokenCardAnchorKey,
            child: ClientAgentDetailTokenCard(
              agentId: agentId,
              controller: controller,
              l10n: l10n,
              tokens: tokens,
              inputFocusNode: inputFocusNode,
              onDirtyChanged: onTokenDirtyChanged,
              discardRevision: tokenDiscardRevision,
            ),
          ),
        if (status == ClientAgentTokenStatus.configured) ...<Widget>[
          SizedBox(height: tokens.gapMd),
          ClientAgentDetailPolicyCard(
            agentId: agentId,
            controller: controller,
            l10n: l10n,
            tokens: tokens,
            onRequestNewToken: onRequestNewToken,
          ),
        ],
      ],
    );
  }
}

class ClientAgentDetailConnectionTokenEmptyState extends StatelessWidget {
  const ClientAgentDetailConnectionTokenEmptyState({
    required this.l10n,
    required this.tokens,
    required this.revoked,
    required this.onConfigureToken,
    super.key,
  });

  final AppLocalizations l10n;
  final AppThemeTokens tokens;
  final bool revoked;
  final VoidCallback onConfigureToken;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final title = revoked
        ? l10n.clientAgentDetailConnectionTokenRevokedTitle
        : l10n.clientAgentDetailConnectionTokenMissingTitle;
    final message = revoked
        ? l10n.clientAgentDetailConnectionTokenRevokedMessage
        : l10n.clientAgentDetailConnectionTokenMissingMessage;

    return AppSectionCardWithHeading(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(
                revoked ? Icons.block_rounded : Icons.vpn_key_off_rounded,
                color: revoked ? colors.error : colors.onSurfaceVariant,
              ),
              SizedBox(width: tokens.gapSm),
              Expanded(
                child: Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: tokens.gapMd),
          AppSecondaryButton(
            label: l10n.clientAgentDetailConnectionTokenConfigureAction,
            icon: const Icon(Icons.edit_rounded),
            onPressed: onConfigureToken,
          ),
        ],
      ),
    );
  }
}

import 'dart:async';

import 'package:colmeia/features/agent_meta/domain/entities/client_token_policy.dart';
import 'package:colmeia/features/client_agents/presentation/controllers/client_agent_detail_controller.dart';
import 'package:colmeia/features/client_agents/presentation/widgets/client_agent_detail_feedback_text.dart';
import 'package:colmeia/features/client_agents/presentation/widgets/client_agent_detail_visual_tokens.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/actions/app_secondary_button.dart';
import 'package:colmeia/shared/widgets/app_section_card_with_heading.dart';
import 'package:colmeia/shared/widgets/app_tag_chip.dart';
import 'package:flutter/material.dart';

class ClientAgentDetailPolicyCard extends StatefulWidget {
  const ClientAgentDetailPolicyCard({
    required this.agentId,
    required this.controller,
    required this.l10n,
    required this.tokens,
    super.key,
    this.onRequestNewToken,
  });

  final String agentId;
  final ClientAgentDetailController controller;
  final AppLocalizations l10n;
  final AppThemeTokens tokens;
  final VoidCallback? onRequestNewToken;

  @override
  State<ClientAgentDetailPolicyCard> createState() =>
      _ClientAgentDetailPolicyCardState();
}

class _ClientAgentDetailPolicyCardState
    extends State<ClientAgentDetailPolicyCard> {
  bool _hasRequested = false;
  int _lastSeenTokenRevision = -1;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_maybeKickoff);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeKickoff();
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_maybeKickoff);
    super.dispose();
  }

  void _maybeKickoff() {
    if (!mounted) {
      return;
    }
    final c = widget.controller;
    if (_lastSeenTokenRevision != c.clientTokenRevision) {
      _lastSeenTokenRevision = c.clientTokenRevision;
      _hasRequested = false;
    }
    if (_hasRequested) {
      return;
    }
    if (c.clientTokenStatus != ClientAgentTokenStatus.configured) {
      return;
    }
    if (c.isLoadingClientTokenPolicy) {
      return;
    }
    if (c.clientTokenPolicyError != null) {
      return;
    }
    if (c.clientTokenPolicy != null || c.clientTokenPolicyUnsupported) {
      return;
    }
    _hasRequested = true;
    unawaited(c.loadClientTokenPolicy(agentId: widget.agentId));
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final Widget body;
    if (c.isLoadingClientTokenPolicy) {
      body = SizedBox(
        height: kClientAgentDetailPolicyLoadingHeight,
        child: Center(
          child: SizedBox.square(
            dimension: kClientAgentDetailPolicyLoadingSpinnerSize,
            child: CircularProgressIndicator(
              strokeWidth: kClientAgentDetailSpinnerStrokeWidth,
              color: colors.primary,
            ),
          ),
        ),
      );
    } else if (c.clientTokenPolicyError != null) {
      body = Text(
        localizeClientAgentDetailPresentationMessage(
              c.clientTokenPolicyError,
              widget.l10n,
            ) ??
            '',
        style: theme.textTheme.bodySmall?.copyWith(color: colors.error),
      );
    } else if (c.clientTokenPolicyUnsupported) {
      body = Text(
        widget.l10n.clientAgentDetailPolicyUnsupported,
        style: theme.textTheme.bodySmall?.copyWith(
          color: colors.onSurfaceVariant,
        ),
      );
    } else {
      final policy = c.clientTokenPolicy;
      if (policy == null) {
        body = Text(
          widget.l10n.clientAgentDetailPolicyEmpty,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        );
      } else {
        body = ClientAgentDetailPolicyBody(
          policy: policy,
          l10n: widget.l10n,
          tokens: widget.tokens,
          controller: c,
          agentId: widget.agentId,
          onRequestNewToken: widget.onRequestNewToken,
        );
      }
    }

    return AppSectionCardWithHeading(
      title: widget.l10n.clientAgentDetailSectionPolicy,
      subtitle: widget.l10n.clientAgentDetailSectionPolicySubtitle,
      child: body,
    );
  }
}

class ClientAgentDetailPolicyBody extends StatelessWidget {
  const ClientAgentDetailPolicyBody({
    required this.policy,
    required this.l10n,
    required this.tokens,
    super.key,
    this.controller,
    this.agentId,
    this.onRequestNewToken,
  });

  final ClientTokenPolicy policy;
  final AppLocalizations l10n;
  final AppThemeTokens tokens;
  final ClientAgentDetailController? controller;
  final String? agentId;
  final VoidCallback? onRequestNewToken;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final lines = <Widget>[];

    if (policy.revoked) {
      lines.add(
        ClientAgentDetailPolicyLine(
          icon: Icons.block_rounded,
          color: colors.error,
          text: l10n.clientAgentDetailPolicyRevoked,
        ),
      );
      final c = controller;
      final agent = agentId;
      if (c != null && agent != null) {
        lines.add(
          ClientAgentDetailRevokedTokenRecoveryActions(
            l10n: l10n,
            tokens: tokens,
            controller: c,
            agentId: agent,
            onRequestNewToken: onRequestNewToken,
          ),
        );
      }
    }

    if (policy.hasFullAccess) {
      lines.add(
        ClientAgentDetailPolicyLine(
          icon: Icons.verified_user_rounded,
          color: colors.primary,
          text: l10n.clientAgentDetailPolicyFullAccess,
        ),
      );
    } else {
      if (policy.allTables) {
        lines.add(
          ClientAgentDetailPolicyLine(
            icon: Icons.table_chart_rounded,
            color: colors.onSurface,
            text: l10n.clientAgentDetailPolicyAllTables,
          ),
        );
      } else if (policy.tableRules.isNotEmpty) {
        lines.add(
          ClientAgentDetailPolicyChips(
            label: l10n.clientAgentDetailPolicyTablesLabel,
            entries: policy.tableRules,
          ),
        );
      }
      if (policy.allViews) {
        lines.add(
          ClientAgentDetailPolicyLine(
            icon: Icons.view_list_rounded,
            color: colors.onSurface,
            text: l10n.clientAgentDetailPolicyAllViews,
          ),
        );
      } else if (policy.viewRules.isNotEmpty) {
        lines.add(
          ClientAgentDetailPolicyChips(
            label: l10n.clientAgentDetailPolicyViewsLabel,
            entries: policy.viewRules,
          ),
        );
      }
      if (policy.allPermissions) {
        lines.add(
          ClientAgentDetailPolicyLine(
            icon: Icons.admin_panel_settings_rounded,
            color: colors.onSurface,
            text: l10n.clientAgentDetailPolicyAllPermissions,
          ),
        );
      } else if (policy.permissionRules.isNotEmpty) {
        lines.add(
          ClientAgentDetailPolicyChips(
            label: l10n.clientAgentDetailPolicyPermissionsLabel,
            entries: policy.permissionRules,
          ),
        );
      }
    }

    if (lines.isEmpty) {
      return Text(
        l10n.clientAgentDetailPolicyEmpty,
        style: theme.textTheme.bodySmall?.copyWith(
          color: colors.onSurfaceVariant,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (var i = 0; i < lines.length; i++) ...<Widget>[
          if (i > 0) SizedBox(height: tokens.gapSm),
          lines[i],
        ],
      ],
    );
  }
}

class ClientAgentDetailRevokedTokenRecoveryActions extends StatelessWidget {
  const ClientAgentDetailRevokedTokenRecoveryActions({
    required this.l10n,
    required this.tokens,
    required this.controller,
    required this.agentId,
    super.key,
    this.onRequestNewToken,
  });

  final AppLocalizations l10n;
  final AppThemeTokens tokens;
  final ClientAgentDetailController controller;
  final String agentId;
  final VoidCallback? onRequestNewToken;

  @override
  Widget build(BuildContext context) {
    final isMutating = controller.isSavingClientToken;
    final isCooldown = controller.isOnRetryCooldown;
    final removeDisabled = isMutating || isCooldown;
    final removeLabel = isCooldown
        ? l10n.clientAgentDetailRetryAfterCountdown(
            controller.retryAfterGate.remaining?.inSeconds ?? 0,
          )
        : l10n.clientAgentDetailServerTokenRemove;
    return Padding(
      padding: EdgeInsets.only(top: tokens.gapSm),
      child: Wrap(
        spacing: tokens.gapSm,
        runSpacing: tokens.gapSm,
        children: <Widget>[
          AppSecondaryButton(
            label: removeLabel,
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: removeDisabled
                ? null
                : () => unawaited(
                    controller.removeClientAgentToken(agentId: agentId),
                  ),
          ),
          if (onRequestNewToken != null)
            AppSecondaryButton(
              label: l10n.clientAgentDetailPolicyRevokedSaveNewToken,
              icon: const Icon(Icons.edit_rounded),
              onPressed: isMutating ? null : onRequestNewToken,
            ),
        ],
      ),
    );
  }
}

class ClientAgentDetailPolicyLine extends StatelessWidget {
  const ClientAgentDetailPolicyLine({
    required this.icon,
    required this.color,
    required this.text,
    super.key,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    return Row(
      children: <Widget>[
        Icon(icon, size: kClientAgentDetailPolicyLineIconSize, color: color),
        SizedBox(width: tokens.gapSm),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

class ClientAgentDetailPolicyChips extends StatelessWidget {
  const ClientAgentDetailPolicyChips({
    required this.label,
    required this.entries,
    super.key,
  });

  final String label;
  final List<String> entries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final colors = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        SizedBox(height: tokens.gapXs),
        Wrap(
          spacing: tokens.gapXs,
          runSpacing: tokens.gapXs,
          children: <Widget>[
            for (final entry in entries) AppTagChip(label: entry),
          ],
        ),
      ],
    );
  }
}

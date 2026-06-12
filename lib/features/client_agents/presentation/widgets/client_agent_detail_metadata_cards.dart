import 'dart:async';

import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_catalog_status.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_connection_status.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent.dart';
import 'package:colmeia/features/client_agents/presentation/widgets/client_agent_detail_visual_tokens.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card_with_heading.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ClientAgentDetailMetadataCard extends StatelessWidget {
  const ClientAgentDetailMetadataCard({
    required this.agent,
    required this.l10n,
    super.key,
  });

  final ClientAgent agent;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final statusLabel = _catalogStatusLabel(l10n, agent.catalogStatus);
    final connectionLabel = _connectionLabel(l10n, agent.connectionStatus);
    final documentTypeLabel = _trimmedOrNull(agent.documentType);
    return AppSectionCardWithHeading(
      title: l10n.clientAgentDetailSectionMetadata,
      subtitle: l10n.clientAgentDetailSectionMetadataSubtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ClientAgentDetailRow(
            label: l10n.clientAgentFieldId,
            value: agent.agentId,
            clipboardText: agent.agentId,
          ),
          if (documentTypeLabel != null)
            ClientAgentDetailRow(
              label: l10n.clientAgentFieldDocumentType,
              value: documentTypeLabel,
              clipboardText: documentTypeLabel,
            ),
          ClientAgentDetailRow(
            label: l10n.clientAgentFieldStatus,
            value: statusLabel,
            clipboardText: statusLabel,
          ),
          ClientAgentDetailRow(
            label: l10n.clientAgentFieldConnection,
            value: connectionLabel,
            clipboardText: connectionLabel,
          ),
        ],
      ),
    );
  }

  String _catalogStatusLabel(AppLocalizations l10n, AgentCatalogStatus status) {
    return switch (status) {
      AgentCatalogStatus.inactive => l10n.agentCatalogInactive,
      AgentCatalogStatus.active => l10n.agentCatalogActive,
    };
  }

  String _connectionLabel(
    AppLocalizations l10n,
    AgentConnectionStatus status,
  ) {
    return switch (status) {
      AgentConnectionStatus.online => l10n.agentConnectionOnline,
      AgentConnectionStatus.offline => l10n.agentConnectionOffline,
      AgentConnectionStatus.unknown => l10n.agentConnectionUnknown,
    };
  }
}

class ClientAgentDetailRecordCard extends StatelessWidget {
  const ClientAgentDetailRecordCard({
    required this.agent,
    required this.l10n,
    super.key,
  });

  final ClientAgent agent;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final na = l10n.clientAgentValueNotAvailable;
    final createdLabel = AppBrFormatters.shortDate(agent.createdAt);
    final updatedLabel = agent.updatedAt.isAfter(agent.createdAt)
        ? AppBrFormatters.shortDateTime(agent.updatedAt)
        : na;
    return AppSectionCardWithHeading(
      title: l10n.clientAgentDetailSectionRecord,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (agent.profileUpdatedAt != null)
            ClientAgentDetailRow(
              label: l10n.clientAgentFieldProfileUpdatedAt,
              value: AppBrFormatters.shortDateTime(agent.profileUpdatedAt!),
              clipboardText: AppBrFormatters.shortDateTime(
                agent.profileUpdatedAt!,
              ),
            ),
          ClientAgentDetailRow(
            label: l10n.clientAgentFieldCreatedAt,
            value: createdLabel,
            clipboardText: createdLabel,
          ),
          ClientAgentDetailRow(
            label: l10n.clientAgentFieldUpdatedAt,
            value: updatedLabel,
            clipboardText: updatedLabel == na ? null : updatedLabel,
          ),
        ],
      ),
    );
  }
}

String? _trimmedOrNull(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}

Future<void> _copyClientAgentDetailFieldValue(
  BuildContext context,
  String text,
) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (!context.mounted) {
    return;
  }
  final messenger = ScaffoldMessenger.maybeOf(context);
  final l10n = AppLocalizations.of(context);
  if (messenger == null) {
    return;
  }
  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      duration: kClientAgentDetailCopySnackDuration,
      content: Text(l10n.clientAgentDetailCopiedSnackbar),
    ),
  );
}

class ClientAgentDetailRow extends StatelessWidget {
  const ClientAgentDetailRow({
    required this.label,
    required this.value,
    super.key,
    this.clipboardText,
  });

  final String label;
  final String value;
  final String? clipboardText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final typography = theme.appTypography;
    final colors = theme.appColors;
    final tokens = theme.extension<AppThemeTokens>()!;
    final l10n = AppLocalizations.of(context);
    final trimmedCopy = clipboardText?.trim();
    final copyPayload = trimmedCopy != null && trimmedCopy.isNotEmpty
        ? trimmedCopy
        : null;
    return Padding(
      padding: EdgeInsets.only(bottom: tokens.gapSm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: typography.caption.copyWith(color: colors.onSurfaceVariant),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(child: Text(value, style: typography.body)),
              if (copyPayload != null)
                IconButton(
                  icon: const Icon(
                    Icons.copy_rounded,
                    size: kClientAgentDetailCopyIconSize,
                  ),
                  tooltip: l10n.clientAgentDetailCopyFieldTooltip(label),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: kClientAgentDetailCopyTouchTargetSize,
                    minHeight: kClientAgentDetailCopyTouchTargetSize,
                  ),
                  onPressed: () => unawaited(
                    _copyClientAgentDetailFieldValue(context, copyPayload),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

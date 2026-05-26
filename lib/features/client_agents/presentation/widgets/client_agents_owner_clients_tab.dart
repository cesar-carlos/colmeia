import 'dart:async';

import 'package:colmeia/features/client_agents/domain/entities/client_agent.dart';
import 'package:colmeia/features/client_agents/domain/entities/owner_approved_client.dart';
import 'package:colmeia/features/client_agents/presentation/widgets/client_agents_shared_widgets.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/actions/app_secondary_button.dart';
import 'package:colmeia/shared/widgets/app_inline_error_panel.dart';
import 'package:colmeia/shared/widgets/app_section_card.dart';
import 'package:colmeia/shared/widgets/forms/app_dropdown_field.dart';
import 'package:flutter/material.dart';

class ClientAgentsOwnerClientsTab extends StatelessWidget {
  const ClientAgentsOwnerClientsTab({
    required this.managedAgents,
    required this.managedAgentsErrorMessage,
    required this.selectedAgentId,
    required this.approvedClients,
    required this.errorMessage,
    required this.isMutating,
    required this.onRetry,
    required this.onSelectAgent,
    required this.onRevokeClientAccess,
    super.key,
  });

  final List<ClientAgent> managedAgents;
  final String? managedAgentsErrorMessage;
  final String? selectedAgentId;
  final List<OwnerApprovedClient> approvedClients;
  final String? errorMessage;
  final bool isMutating;
  final VoidCallback onRetry;
  final ValueChanged<String?> onSelectAgent;
  final Future<void> Function(OwnerApprovedClient client) onRevokeClientAccess;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    if (managedAgentsErrorMessage case final String message) {
      return AppInlineErrorPanel(
        title: l10n.clientAgentsOwnerClientsLoadErrorTitle,
        message: message,
        onRetry: onRetry,
        retryLabel: l10n.appInlineErrorRetry,
      );
    }
    if (managedAgents.isEmpty) {
      return Text(l10n.clientAgentsOwnerClientsEmptyAgents);
    }

    ClientAgent? selectedAgent;
    for (final agent in managedAgents) {
      if (agent.agentId == selectedAgentId) {
        selectedAgent = agent;
        break;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AppDropdownField<String>(
                label: l10n.clientAgentsOwnerClientsAgentSelectorLabel,
                hintText: l10n.clientAgentsOwnerClientsAgentSelectorHint,
                value: selectedAgentId,
                enabled: !isMutating,
                options: managedAgents
                    .map(
                      (agent) => AppDropdownOption<String>(
                        value: agent.agentId,
                        label: agent.name,
                      ),
                    )
                    .toList(growable: false),
                onChanged: onSelectAgent,
              ),
              if (selectedAgent != null) ...<Widget>[
                SizedBox(height: tokens.gapSm),
                Text(
                  selectedAgent.tradeName?.trim().isNotEmpty ?? false
                      ? selectedAgent.tradeName!
                      : l10n.clientAgentsNoTradeName,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
        SizedBox(height: tokens.gapMd),
        if (errorMessage case final String message)
          AppInlineErrorPanel(
            title: l10n.clientAgentsOwnerClientsLoadErrorTitle,
            message: message,
            onRetry: onRetry,
            retryLabel: l10n.appInlineErrorRetry,
          )
        else if (approvedClients.isEmpty)
          Text(l10n.clientAgentsOwnerClientsEmpty)
        else
          ...approvedClients.map((client) {
            final subtitleParts = <String>[
              if (client.clientEmail case final String email
                  when email.trim().isNotEmpty)
                email,
              if (client.accountStatus case final String status
                  when status.trim().isNotEmpty)
                status,
            ];
            return ClientAgentsAgentTile(
              title: client.clientName,
              subtitle: subtitleParts.isEmpty
                  ? l10n.clientAgentsOwnerClientsApprovedSubtitle
                  : subtitleParts.join(' - '),
              trailing: AppSecondaryButton(
                label: l10n.clientAgentsOwnerRevokeAction,
                onPressed: isMutating
                    ? null
                    : () => unawaited(onRevokeClientAccess(client)),
              ),
            );
          }),
      ],
    );
  }
}

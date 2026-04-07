import 'package:colmeia/app/router/app_navigation.dart';
import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_connection_status.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent.dart';
import 'package:colmeia/features/client_agents/presentation/widgets/client_agents_shared_widgets.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/widgets/actions/app_secondary_button.dart';
import 'package:colmeia/shared/widgets/app_inline_error_panel.dart';
import 'package:flutter/material.dart';

class ClientAgentsApprovedAgentsTab extends StatelessWidget {
  const ClientAgentsApprovedAgentsTab({
    required this.agents,
    required this.errorMessage,
    required this.onRemoveAccess,
    required this.onRetry,
    required this.isMutating,
    required this.requestAccessTabLabel,
    super.key,
    this.hasActiveFilters = false,
  });

  final List<ClientAgent> agents;
  final String? errorMessage;
  final ValueChanged<String> onRemoveAccess;
  final VoidCallback onRetry;
  final bool isMutating;
  final bool hasActiveFilters;
  final String requestAccessTabLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (errorMessage case final String message) {
      return AppInlineErrorPanel(
        title: l10n.clientAgentsLoadApprovedErrorTitle,
        message: message,
        onRetry: onRetry,
      );
    }

    if (agents.isEmpty) {
      return Text(
        hasActiveFilters
            ? l10n.clientAgentsEmptyFilteredApproved
            : l10n.clientAgentsEmptyApproved(requestAccessTabLabel),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: agents
          .map(
            (agent) => ClientAgentsAgentTile(
              title: agent.name,
              subtitle:
                  '${agent.tradeName ?? l10n.clientAgentsNoTradeName} - '
                  '${_catalogStatusLabel(l10n, agent)} - '
                  '${_connectionLabel(l10n, agent)}',
              onTap: () {
                context.goTo(
                  AppRoute.agentsDetail,
                  pathParameters: <String, String>{
                    'agentId': agent.agentId,
                  },
                );
              },
              trailing: AppSecondaryButton(
                label: l10n.clientAgentsRemoveAccess,
                onPressed: isMutating
                    ? null
                    : () => onRemoveAccess(agent.agentId),
              ),
            ),
          )
          .toList(growable: false),
    );
  }

  String _catalogStatusLabel(AppLocalizations l10n, ClientAgent agent) {
    return switch (agent.catalogStatus.name) {
      'inactive' => l10n.agentCatalogInactive,
      _ => l10n.agentCatalogActive,
    };
  }

  String _connectionLabel(AppLocalizations l10n, ClientAgent agent) {
    return switch (agent.connectionStatus) {
      AgentConnectionStatus.online => l10n.agentConnectionOnline,
      AgentConnectionStatus.offline => l10n.agentConnectionOffline,
      AgentConnectionStatus.unknown => l10n.agentConnectionUnknown,
    };
  }
}

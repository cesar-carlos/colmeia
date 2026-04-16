import 'dart:async';

import 'package:colmeia/app/router/app_navigation.dart';
import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_connection_status.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent.dart';
import 'package:colmeia/features/client_agents/presentation/widgets/client_agents_shared_widgets.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/actions/app_flat_button.dart';
import 'package:colmeia/shared/widgets/actions/app_primary_button.dart';
import 'package:colmeia/shared/widgets/actions/app_secondary_button.dart';
import 'package:colmeia/shared/widgets/app_inline_error_panel.dart';
import 'package:flutter/material.dart';

class ClientAgentsApprovedAgentsTab extends StatefulWidget {
  const ClientAgentsApprovedAgentsTab({
    required this.agents,
    required this.errorMessage,
    required this.onQueueRemoveAccess,
    required this.onRetry,
    required this.isMutating,
    required this.requestAccessTabLabel,
    super.key,
    this.hasActiveFilters = false,
  });

  final List<ClientAgent> agents;
  final String? errorMessage;
  final Future<void> Function(Set<String> agentIds) onQueueRemoveAccess;
  final VoidCallback onRetry;
  final bool isMutating;
  final bool hasActiveFilters;
  final String requestAccessTabLabel;

  @override
  State<ClientAgentsApprovedAgentsTab> createState() =>
      _ClientAgentsApprovedAgentsTabState();
}

class _ClientAgentsApprovedAgentsTabState
    extends State<ClientAgentsApprovedAgentsTab> {
  bool _selecting = false;
  final Set<String> _selected = <String>{};

  @override
  void didUpdateWidget(ClientAgentsApprovedAgentsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.agents != widget.agents) {
      _selected.removeWhere(
        (id) => !widget.agents.any((a) => a.agentId == id),
      );
    }
  }

  void _exitSelection() {
    setState(() {
      _selecting = false;
      _selected.clear();
    });
  }

  Future<void> _confirmBulkRemove() async {
    final l10n = AppLocalizations.of(context);
    final count = _selected.length;
    if (count == 0) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.clientAgentsBulkRemoveConfirmTitle),
          content: Text(l10n.clientAgentsBulkRemoveConfirmMessage(count)),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.clientAgentsBulkRemoveConfirmBack),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.clientAgentsBulkRemoveConfirmAction),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) {
      return;
    }
    await widget.onQueueRemoveAccess(Set<String>.from(_selected));
    if (mounted) {
      _exitSelection();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    if (widget.errorMessage case final String message) {
      return AppInlineErrorPanel(
        title: l10n.clientAgentsLoadApprovedErrorTitle,
        message: message,
        onRetry: widget.onRetry,
        retryLabel: l10n.appInlineErrorRetry,
      );
    }

    if (widget.agents.isEmpty) {
      return Text(
        widget.hasActiveFilters
            ? l10n.clientAgentsEmptyFilteredApproved
            : l10n.clientAgentsEmptyApproved(widget.requestAccessTabLabel),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Wrap(
          spacing: tokens.gapSm,
          runSpacing: tokens.gapSm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            if (!_selecting)
              AppFlatButton(
                label: l10n.clientAgentsApprovedBulkSelect,
                fillWidth: false,
                onPressed: widget.isMutating
                    ? null
                    : () => setState(() => _selecting = true),
              )
            else ...<Widget>[
              AppSecondaryButton(
                label: l10n.clientAgentsApprovedBulkCancel,
                onPressed: widget.isMutating ? null : _exitSelection,
              ),
              AppFlatButton(
                label: l10n.clientAgentsApprovedBulkSelectAll,
                fillWidth: false,
                onPressed: widget.isMutating
                    ? null
                    : () => setState(() {
                          _selected
                            ..clear()
                            ..addAll(
                              widget.agents.map((a) => a.agentId),
                            );
                        }),
              ),
              AppFlatButton(
                label: l10n.clientAgentsApprovedBulkClearSelection,
                fillWidth: false,
                onPressed: widget.isMutating || _selected.isEmpty
                    ? null
                    : () => setState(_selected.clear),
              ),
              if (_selected.isNotEmpty)
                AppPrimaryButton(
                  label: l10n.clientAgentsApprovedBulkRemove(_selected.length),
                  onPressed: widget.isMutating
                      ? null
                      : () => unawaited(_confirmBulkRemove()),
                ),
            ],
          ],
        ),
        SizedBox(height: tokens.gapMd),
        ...widget.agents.map(
          (agent) {
            final selected = _selected.contains(agent.agentId);
            return ClientAgentsAgentTile(
              leading: _selecting
                  ? Checkbox(
                      value: selected,
                      onChanged: widget.isMutating
                          ? null
                          : (value) {
                              setState(() {
                                if (value ?? false) {
                                  _selected.add(agent.agentId);
                                } else {
                                  _selected.remove(agent.agentId);
                                }
                              });
                            },
                    )
                  : null,
              title: agent.name,
              subtitle:
                  '${agent.tradeName ?? l10n.clientAgentsNoTradeName} - '
                  '${_catalogStatusLabel(l10n, agent)} - '
                  '${_connectionLabel(l10n, agent)}',
              onTap: _selecting
                  ? () {
                      if (widget.isMutating) {
                        return;
                      }
                      setState(() {
                        if (selected) {
                          _selected.remove(agent.agentId);
                        } else {
                          _selected.add(agent.agentId);
                        }
                      });
                    }
                  : () {
                      context.goTo(
                        AppRoute.agentsDetail,
                        pathParameters: <String, String>{
                          'agentId': agent.agentId,
                        },
                      );
                    },
              trailing: _selecting
                  ? null
                  : AppSecondaryButton(
                      label: l10n.clientAgentsRemoveAccess,
                      onPressed: widget.isMutating
                          ? null
                          : () => unawaited(
                                widget.onQueueRemoveAccess(
                                  <String>{agent.agentId},
                                ),
                              ),
                    ),
            );
          },
        ),
      ],
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

import 'dart:async';
import 'dart:math' as math;

import 'package:colmeia/app/router/app_navigation.dart';
import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent.dart';
import 'package:colmeia/features/client_agents/presentation/widgets/client_agents_approved_agents_table.dart';
import 'package:colmeia/features/client_agents/presentation/widgets/client_agents_bulk_selection_bar.dart';
import 'package:colmeia/features/client_agents/presentation/widgets/client_agents_data_grid_widgets.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/actions/app_flat_button.dart';
import 'package:colmeia/shared/widgets/app_inline_error_panel.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ClientAgentsApprovedAgentsTab extends StatefulWidget {
  const ClientAgentsApprovedAgentsTab({
    required this.agents,
    required this.totalCount,
    required this.errorMessage,
    required this.onQueueRemoveAccess,
    required this.onRetry,
    required this.isMutating,
    required this.requestAccessTabLabel,
    super.key,
    this.hasActiveFilters = false,
    this.isLoading = false,
    this.pendingRemoveAgentIds = const <String>{},
    this.isResultTruncated = false,
    this.loadedCount,
  });

  final List<ClientAgent> agents;
  final int totalCount;
  final String? errorMessage;
  final Future<void> Function(Set<String> agentIds) onQueueRemoveAccess;
  final VoidCallback onRetry;
  final bool isMutating;
  final bool hasActiveFilters;
  final bool isLoading;
  final String requestAccessTabLabel;
  final Set<String> pendingRemoveAgentIds;
  final bool isResultTruncated;
  final int? loadedCount;

  @override
  State<ClientAgentsApprovedAgentsTab> createState() =>
      _ClientAgentsApprovedAgentsTabState();
}

class _ClientAgentsApprovedAgentsTabState
    extends State<ClientAgentsApprovedAgentsTab> {
  bool _selecting = false;
  final Set<String> _selected = <String>{};
  int _currentPage = 1;
  int _pageSize = kClientAgentsApprovedTablePageSizeOptions.first;

  @override
  void didUpdateWidget(ClientAgentsApprovedAgentsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.agents != widget.agents) {
      _selected.removeWhere(
        (id) => !widget.agents.any((a) => a.agentId == id),
      );
      final totalPages = widget.totalCount == 0
          ? 0
          : (widget.totalCount / _pageSize).ceil();
      if (totalPages > 0 && _currentPage > totalPages) {
        _currentPage = totalPages;
      }
    }
  }

  void _exitSelection() {
    setState(() {
      _selecting = false;
      _selected.clear();
    });
  }

  List<ClientAgent> get _pageAgents {
    if (widget.agents.isEmpty) {
      return const <ClientAgent>[];
    }
    final start = (_currentPage - 1) * _pageSize;
    if (start >= widget.agents.length) {
      return const <ClientAgent>[];
    }
    final end = math.min(start + _pageSize, widget.agents.length);
    return widget.agents.sublist(start, end);
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
    final theme = Theme.of(context);
    final rowNumber = NumberFormat.decimalPattern(l10n.localeName);

    if (widget.errorMessage case final String message) {
      return AppInlineErrorPanel(
        title: l10n.clientAgentsLoadApprovedErrorTitle,
        message: message,
        onRetry: widget.onRetry,
        retryLabel: l10n.appInlineErrorRetry,
      );
    }

    if (widget.isLoading && widget.agents.isEmpty) {
      return const ClientAgentsTableLoadingSkeleton();
    }

    if (widget.agents.isEmpty) {
      return Text(
        widget.hasActiveFilters
            ? l10n.clientAgentsEmptyFilteredApproved
            : l10n.clientAgentsEmptyApproved(widget.requestAccessTabLabel),
      );
    }

    return Stack(
      children: <Widget>[
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (widget.isResultTruncated) ...<Widget>[
              Text(
                l10n.clientAgentsApprovedListTruncated(
                  rowNumber.format(widget.loadedCount ?? widget.agents.length),
                  rowNumber.format(widget.totalCount),
                ),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
              SizedBox(height: tokens.gapMd),
            ],
            if (!_selecting)
              AppFlatButton(
                label: l10n.clientAgentsApprovedBulkSelect,
                fillWidth: false,
                onPressed: widget.isMutating
                    ? null
                    : () => setState(() => _selecting = true),
              ),
            SizedBox(height: tokens.gapMd),
            ClientAgentsApprovedAgentsTable(
              l10n: l10n,
              agents: _pageAgents,
              totalCount: widget.agents.length,
              currentPage: _currentPage,
              pageSize: _pageSize,
              onPageSelected: (page) => setState(() => _currentPage = page),
              onPageSizeChanged: (size) => setState(() {
                _pageSize = size;
                _currentPage = 1;
              }),
              selecting: _selecting,
              selectedAgentIds: _selected,
              pendingRemoveAgentIds: widget.pendingRemoveAgentIds,
              isMutating: widget.isMutating,
              onAgentTap: (agent) {
                context.goTo(
                  AppRoute.agentsDetail,
                  pathParameters: <String, String>{'agentId': agent.agentId},
                );
              },
              onAgentSelectionChanged: (agent, {required selected}) {
                setState(() {
                  if (selected) {
                    _selected.add(agent.agentId);
                  } else {
                    _selected.remove(agent.agentId);
                  }
                });
              },
              onRemoveAccess: (agent) {
                unawaited(
                  widget.onQueueRemoveAccess(<String>{agent.agentId}),
                );
              },
            ),
            if (_selecting) SizedBox(height: tokens.sectionSpacing * 2),
          ],
        ),
        if (_selecting)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ClientAgentsBulkSelectionBar(
              l10n: l10n,
              selectedCount: _selected.length,
              isMutating: widget.isMutating,
              onCancel: _exitSelection,
              onSelectAll: () => setState(() {
                _selected
                  ..clear()
                  ..addAll(_pageAgents.map((a) => a.agentId));
              }),
              onClearSelection: () => setState(_selected.clear),
              onRemoveSelected: () => unawaited(_confirmBulkRemove()),
            ),
          ),
      ],
    );
  }
}

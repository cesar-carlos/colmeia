import 'dart:async';
import 'dart:math' as math;

import 'package:colmeia/features/client_agents/domain/entities/agent_access_request_status.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent_access_request.dart';
import 'package:colmeia/features/client_agents/domain/entities/pending_agent_action.dart';
import 'package:colmeia/features/client_agents/presentation/widgets/client_agents_approved_agents_table.dart';
import 'package:colmeia/features/client_agents/presentation/widgets/client_agents_requests_table.dart';
import 'package:colmeia/features/client_agents/presentation/widgets/client_agents_shared_widgets.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_inline_error_panel.dart';
import 'package:flutter/material.dart';

class ClientAgentsRequestsTab extends StatefulWidget {
  const ClientAgentsRequestsTab({
    required this.requests,
    required this.pendingActions,
    required this.errorMessage,
    required this.pendingErrorMessage,
    required this.onRetry,
    required this.isMutating,
    super.key,
    this.hasActiveFilters = false,
    this.onRetryAccessRequest,
    this.onDiscardQueuedRequestAccess,
  });

  final List<ClientAgentAccessRequest> requests;
  final List<PendingAgentAction> pendingActions;
  final String? errorMessage;
  final String? pendingErrorMessage;
  final VoidCallback onRetry;
  final bool isMutating;
  final bool hasActiveFilters;
  final Future<void> Function(ClientAgentAccessRequest request)?
  onRetryAccessRequest;
  final Future<void> Function(PendingAgentAction action)?
  onDiscardQueuedRequestAccess;

  @override
  State<ClientAgentsRequestsTab> createState() =>
      _ClientAgentsRequestsTabState();
}

class _ClientAgentsRequestsTabState extends State<ClientAgentsRequestsTab> {
  int _currentPage = 1;
  int _pageSize = kClientAgentsApprovedTablePageSizeOptions.first;

  @override
  void didUpdateWidget(ClientAgentsRequestsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.requests != widget.requests ||
        oldWidget.pendingActions != widget.pendingActions) {
      final totalPages = _allRows.isEmpty
          ? 0
          : (_allRows.length / _pageSize).ceil();
      if (totalPages > 0 && _currentPage > totalPages) {
        _currentPage = totalPages;
      }
    }
  }

  List<ClientAgentsRequestTableRowData> get _allRows {
    final l10n = AppLocalizations.of(context);
    return <ClientAgentsRequestTableRowData>[
      ...widget.pendingActions.map(_pendingActionRow),
      ...widget.requests.map((request) => _accessRequestRow(l10n, request)),
    ];
  }

  List<ClientAgentsRequestTableRowData> get _pageRows {
    final rows = _allRows;
    if (rows.isEmpty) {
      return const <ClientAgentsRequestTableRowData>[];
    }
    final start = (_currentPage - 1) * _pageSize;
    if (start >= rows.length) {
      return const <ClientAgentsRequestTableRowData>[];
    }
    final end = math.min(start + _pageSize, rows.length);
    return rows.sublist(start, end);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final children = <Widget>[
      if (widget.errorMessage case final String message) ...<Widget>[
        AppInlineErrorPanel(
          title: l10n.clientAgentsLoadRequestsErrorTitle,
          message: message,
          onRetry: widget.onRetry,
          retryLabel: l10n.appInlineErrorRetry,
        ),
      ],
      if (widget.pendingErrorMessage case final String message) ...<Widget>[
        AppInlineErrorPanel(
          title: l10n.clientAgentsLoadPendingErrorTitle,
          message: message,
          onRetry: widget.onRetry,
          retryLabel: l10n.appInlineErrorRetry,
        ),
      ],
    ];

    if (widget.requests.isEmpty && widget.pendingActions.isEmpty) {
      if (children.isNotEmpty) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        );
      }
      return Text(
        widget.hasActiveFilters
            ? l10n.clientAgentsEmptyFilteredRequests
            : l10n.clientAgentsNoRequestsYet,
      );
    }

    if (children.isNotEmpty) {
      children.add(SizedBox(height: tokens.gapMd));
    }
    children.add(
      ClientAgentsRequestsTable(
        l10n: l10n,
        rows: _pageRows,
        totalCount: _allRows.length,
        currentPage: _currentPage,
        pageSize: _pageSize,
        isMutating: widget.isMutating,
        onPageSelected: (page) => setState(() => _currentPage = page),
        onPageSizeChanged: (size) => setState(() {
          _pageSize = size;
          _currentPage = 1;
        }),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }

  ClientAgentsRequestTableRowData _pendingActionRow(PendingAgentAction action) {
    final l10n = AppLocalizations.of(context);
    final errorSuffix = action.errorMessage == null
        ? ''
        : ' (${action.errorMessage})';
    final canDiscard =
        _canDiscardLocalQueuedRequest(action) &&
        widget.onDiscardQueuedRequestAccess != null;

    return ClientAgentsRequestTableRowData(
      name: l10n.clientAgentsPendingSendTitle(action.agentId),
      description: '${_pendingActionDescription(l10n, action)}$errorSuffix',
      statusLabel: _pendingActionChipLabel(l10n, action),
      statusKind: _pendingActionChipKind(action),
      date: action.createdAt,
      showDiscard: canDiscard,
      onDiscard: canDiscard
          ? () => unawaited(widget.onDiscardQueuedRequestAccess!(action))
          : null,
    );
  }

  ClientAgentsRequestTableRowData _accessRequestRow(
    AppLocalizations l10n,
    ClientAgentAccessRequest request,
  ) {
    final canRetry =
        _canRetryRequest(request) && widget.onRetryAccessRequest != null;

    return ClientAgentsRequestTableRowData(
      name: request.agentName,
      description: _requestStatusDescription(l10n, request.status),
      statusLabel: _requestStatusLabel(l10n, request.status),
      statusKind: _requestStatusChipKind(request.status),
      date: request.requestedAt ?? request.reviewedAt,
      showRetry: canRetry,
      onRetry: canRetry
          ? () => unawaited(widget.onRetryAccessRequest!(request))
          : null,
    );
  }

  String _requestStatusLabel(
    AppLocalizations l10n,
    AgentAccessRequestStatus status,
  ) {
    return switch (status) {
      AgentAccessRequestStatus.pending => l10n.clientAgentsRequestStatusPending,
      AgentAccessRequestStatus.approved =>
        l10n.clientAgentsRequestStatusApproved,
      AgentAccessRequestStatus.rejected =>
        l10n.clientAgentsRequestStatusRejected,
      AgentAccessRequestStatus.expired => l10n.clientAgentsRequestStatusExpired,
      AgentAccessRequestStatus.unknown => l10n.clientAgentsRequestStatusUnknown,
    };
  }

  String _requestStatusDescription(
    AppLocalizations l10n,
    AgentAccessRequestStatus status,
  ) {
    return switch (status) {
      AgentAccessRequestStatus.pending => l10n.clientAgentsRequestDescPending,
      AgentAccessRequestStatus.approved => l10n.clientAgentsRequestDescApproved,
      AgentAccessRequestStatus.rejected => l10n.clientAgentsRequestDescRejected,
      AgentAccessRequestStatus.expired => l10n.clientAgentsRequestDescExpired,
      AgentAccessRequestStatus.unknown => l10n.clientAgentsRequestDescUnknown,
    };
  }

  String _pendingActionDescription(
    AppLocalizations l10n,
    PendingAgentAction action,
  ) {
    return switch (action.state) {
      PendingAgentActionState.queued => l10n.clientAgentsPendingDescQueued,
      PendingAgentActionState.syncing => l10n.clientAgentsPendingDescSyncing,
      PendingAgentActionState.failed => l10n.clientAgentsPendingDescFailed,
      PendingAgentActionState.synced => l10n.clientAgentsPendingDescSynced,
    };
  }

  String _pendingActionChipLabel(
    AppLocalizations l10n,
    PendingAgentAction action,
  ) {
    final prefix = switch (action.type) {
      PendingAgentActionType.requestAccess =>
        l10n.clientAgentsPendingChipRequest,
      PendingAgentActionType.removeAccess => l10n.clientAgentsPendingChipRemove,
    };
    final suffix = switch (action.state) {
      PendingAgentActionState.queued => l10n.clientAgentsPendingChipQueued,
      PendingAgentActionState.syncing => l10n.clientAgentsPendingChipSyncing,
      PendingAgentActionState.failed => l10n.clientAgentsPendingChipFailed,
      PendingAgentActionState.synced => l10n.clientAgentsPendingChipSynced,
    };
    return '$prefix: $suffix';
  }

  ClientAgentsStatusChipKind _pendingActionChipKind(PendingAgentAction action) {
    return switch (action.state) {
      PendingAgentActionState.queued => ClientAgentsStatusChipKind.info,
      PendingAgentActionState.syncing => ClientAgentsStatusChipKind.success,
      PendingAgentActionState.failed => ClientAgentsStatusChipKind.error,
      PendingAgentActionState.synced => ClientAgentsStatusChipKind.neutral,
    };
  }

  ClientAgentsStatusChipKind _requestStatusChipKind(
    AgentAccessRequestStatus status,
  ) {
    return switch (status) {
      AgentAccessRequestStatus.pending => ClientAgentsStatusChipKind.info,
      AgentAccessRequestStatus.approved => ClientAgentsStatusChipKind.success,
      AgentAccessRequestStatus.rejected => ClientAgentsStatusChipKind.error,
      AgentAccessRequestStatus.expired => ClientAgentsStatusChipKind.neutral,
      AgentAccessRequestStatus.unknown => ClientAgentsStatusChipKind.neutral,
    };
  }

  bool _canRetryRequest(ClientAgentAccessRequest request) {
    final hasRequestId = request.requestId?.trim().isNotEmpty ?? false;
    return hasRequestId &&
        (request.status == AgentAccessRequestStatus.rejected ||
            request.status == AgentAccessRequestStatus.expired);
  }

  bool _canDiscardLocalQueuedRequest(PendingAgentAction action) {
    return action.type == PendingAgentActionType.requestAccess &&
        (action.state == PendingAgentActionState.queued ||
            action.state == PendingAgentActionState.failed);
  }
}

import 'dart:async';

import 'package:colmeia/features/client_agents/domain/entities/agent_access_request_status.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent_access_request.dart';
import 'package:colmeia/features/client_agents/domain/entities/pending_agent_action.dart';
import 'package:colmeia/features/client_agents/presentation/widgets/client_agents_shared_widgets.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/widgets/actions/app_secondary_button.dart';
import 'package:colmeia/shared/widgets/app_inline_error_panel.dart';
import 'package:flutter/material.dart';

class ClientAgentsRequestsTab extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final children = <Widget>[
      if (errorMessage case final String message) ...<Widget>[
        AppInlineErrorPanel(
          title: l10n.clientAgentsLoadRequestsErrorTitle,
          message: message,
          onRetry: onRetry,
          retryLabel: l10n.appInlineErrorRetry,
        ),
      ],
      if (pendingErrorMessage case final String message) ...<Widget>[
        AppInlineErrorPanel(
          title: l10n.clientAgentsLoadPendingErrorTitle,
          message: message,
          onRetry: onRetry,
          retryLabel: l10n.appInlineErrorRetry,
        ),
      ],
    ];

    if (requests.isEmpty && pendingActions.isEmpty) {
      if (children.isNotEmpty) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        );
      }
      return Text(
        hasActiveFilters
            ? l10n.clientAgentsEmptyFilteredRequests
            : l10n.clientAgentsNoRequestsYet,
      );
    }

    children
      ..addAll(
        pendingActions.map(
          (action) {
            final errorSuffix = action.errorMessage == null
                ? ''
                : ' (${action.errorMessage})';
            return ClientAgentsAgentTile(
              title: l10n.clientAgentsPendingSendTitle(action.agentId),
              subtitle:
                  '${_pendingActionDescription(l10n, action)}$errorSuffix',
              trailing: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  ClientAgentsStatusChip(
                    label: _pendingActionChipLabel(l10n, action),
                    kind: _pendingActionChipKind(action),
                  ),
                  if (_canDiscardLocalQueuedRequest(action) &&
                      onDiscardQueuedRequestAccess != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: AppSecondaryButton(
                        label: l10n.clientAgentsDiscardQueuedRequestAction,
                        onPressed: isMutating
                            ? null
                            : () => unawaited(
                                onDiscardQueuedRequestAccess!(action),
                              ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      )
      ..addAll(
        requests.map(
          (request) => ClientAgentsAgentTile(
            title: request.agentName,
            subtitle: _requestStatusDescription(l10n, request.status),
            trailing: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ClientAgentsStatusChip(
                  label: _requestStatusLabel(l10n, request.status),
                  kind: _requestStatusChipKind(request.status),
                ),
                if (_canRetryRequest(request) && onRetryAccessRequest != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: FilledButton.tonalIcon(
                      onPressed: isMutating
                          ? null
                          : () => unawaited(onRetryAccessRequest!(request)),
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(l10n.clientAgentsRetryRequestAction),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
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
    return request.requestId?.trim().isNotEmpty == true &&
        (request.status == AgentAccessRequestStatus.rejected ||
            request.status == AgentAccessRequestStatus.expired);
  }

  bool _canDiscardLocalQueuedRequest(PendingAgentAction action) {
    return action.type == PendingAgentActionType.requestAccess &&
        (action.state == PendingAgentActionState.queued ||
            action.state == PendingAgentActionState.failed);
  }
}

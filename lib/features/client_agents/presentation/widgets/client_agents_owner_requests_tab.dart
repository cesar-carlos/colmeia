import 'dart:async';

import 'package:colmeia/features/client_agents/domain/entities/agent_access_request_status.dart';
import 'package:colmeia/features/client_agents/domain/entities/owner_client_access_request.dart';
import 'package:colmeia/features/client_agents/presentation/widgets/client_agents_shared_widgets.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/actions/app_primary_button.dart';
import 'package:colmeia/shared/widgets/actions/app_secondary_button.dart';
import 'package:colmeia/shared/widgets/app_inline_error_panel.dart';
import 'package:flutter/material.dart';

class ClientAgentsOwnerRequestsTab extends StatelessWidget {
  const ClientAgentsOwnerRequestsTab({
    required this.requests,
    required this.errorMessage,
    required this.onRetry,
    required this.onApprove,
    required this.onReject,
    required this.isMutating,
    super.key,
  });

  final List<OwnerClientAccessRequest> requests;
  final String? errorMessage;
  final VoidCallback onRetry;
  final Future<void> Function(OwnerClientAccessRequest request) onApprove;
  final Future<void> Function(OwnerClientAccessRequest request) onReject;
  final bool isMutating;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    if (errorMessage case final String message) {
      return AppInlineErrorPanel(
        title: l10n.clientAgentsOwnerRequestsLoadErrorTitle,
        message: message,
        onRetry: onRetry,
        retryLabel: l10n.appInlineErrorRetry,
      );
    }

    if (requests.isEmpty) {
      return Text(l10n.clientAgentsOwnerRequestsEmpty);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: requests
          .map((request) {
            return ClientAgentsAgentTile(
              title: request.clientName,
              subtitle: _subtitle(l10n, request),
              trailing: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  ClientAgentsStatusChip(
                    label: _statusLabel(l10n, request.status),
                    kind: _statusKind(request.status),
                  ),
                  if (request.status ==
                      AgentAccessRequestStatus.pending) ...<Widget>[
                    SizedBox(height: tokens.gapSm),
                    Wrap(
                      spacing: tokens.gapSm,
                      runSpacing: tokens.gapSm,
                      children: <Widget>[
                        AppPrimaryButton(
                          label: l10n.clientAgentsOwnerApproveAction,
                          onPressed: isMutating
                              ? null
                              : () => unawaited(onApprove(request)),
                        ),
                        AppSecondaryButton(
                          label: l10n.clientAgentsOwnerRejectAction,
                          onPressed: isMutating
                              ? null
                              : () => unawaited(onReject(request)),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          })
          .toList(growable: false),
    );
  }

  String _subtitle(
    AppLocalizations l10n,
    OwnerClientAccessRequest request,
  ) {
    final parts = <String>[
      request.agentName,
      if (request.clientEmail case final String email
          when email.trim().isNotEmpty)
        email,
      _statusDescription(l10n, request.status),
    ];
    return parts.join(' - ');
  }

  String _statusLabel(AppLocalizations l10n, AgentAccessRequestStatus status) {
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

  String _statusDescription(
    AppLocalizations l10n,
    AgentAccessRequestStatus status,
  ) {
    return switch (status) {
      AgentAccessRequestStatus.pending =>
        l10n.clientAgentsOwnerRequestsStatusPending,
      AgentAccessRequestStatus.approved =>
        l10n.clientAgentsOwnerRequestsStatusApproved,
      AgentAccessRequestStatus.rejected =>
        l10n.clientAgentsOwnerRequestsStatusRejected,
      AgentAccessRequestStatus.expired =>
        l10n.clientAgentsOwnerRequestsStatusExpired,
      AgentAccessRequestStatus.unknown =>
        l10n.clientAgentsOwnerRequestsStatusUnknown,
    };
  }

  ClientAgentsStatusChipKind _statusKind(AgentAccessRequestStatus status) {
    return switch (status) {
      AgentAccessRequestStatus.pending => ClientAgentsStatusChipKind.info,
      AgentAccessRequestStatus.approved => ClientAgentsStatusChipKind.success,
      AgentAccessRequestStatus.rejected => ClientAgentsStatusChipKind.error,
      AgentAccessRequestStatus.expired => ClientAgentsStatusChipKind.neutral,
      AgentAccessRequestStatus.unknown => ClientAgentsStatusChipKind.neutral,
    };
  }
}

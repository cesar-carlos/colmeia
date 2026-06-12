import 'package:colmeia/features/client_agents/presentation/models/client_agents_presentation_message.dart';
import 'package:colmeia/features/client_agents/presentation/widgets/client_agents_shared_widgets.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/actions/app_primary_button.dart';
import 'package:colmeia/shared/widgets/actions/app_secondary_button.dart';
import 'package:colmeia/shared/widgets/app_inline_error_panel.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_page_intro.dart';
import 'package:flutter/material.dart';

class ClientAgentsPageHeader extends StatelessWidget {
  const ClientAgentsPageHeader({
    required this.l10n,
    required this.tokens,
    required this.pendingCount,
    required this.isLoading,
    required this.isRefreshing,
    required this.isSyncing,
    required this.isMutating,
    required this.isSyncOnCooldown,
    required this.syncRetryAfterSeconds,
    required this.onRefresh,
    required this.onSyncPending,
    super.key,
  });

  final AppLocalizations l10n;
  final AppThemeTokens tokens;
  final int pendingCount;
  final bool isLoading;
  final bool isRefreshing;
  final bool isSyncing;
  final bool isMutating;
  final bool isSyncOnCooldown;
  final int syncRetryAfterSeconds;
  final VoidCallback onRefresh;
  final VoidCallback onSyncPending;

  @override
  Widget build(BuildContext context) {
    final hasPending = pendingCount > 0;
    return AppShellPageIntro(
      eyebrow: l10n.clientAgentsDataSourcesEyebrow,
      title: l10n.clientAgentsPageTitle,
      subtitle: l10n.clientAgentsPageSubtitle,
      footer: Wrap(
        spacing: tokens.gapSm,
        runSpacing: tokens.gapSm,
        children: <Widget>[
          if (hasPending)
            Chip(
              label: Text(l10n.clientAgentsPendingActionsCount(pendingCount)),
            ),
          AppSecondaryButton(
            label: l10n.clientAgentsRefresh,
            icon: const Icon(Icons.refresh_rounded),
            onPressed: isLoading ? null : onRefresh,
            isLoading: isRefreshing,
          ),
          if (hasPending)
            AppPrimaryButton(
              label: isSyncOnCooldown
                  ? l10n.clientAgentsSyncRetryAfterCountdown(
                      syncRetryAfterSeconds,
                    )
                  : l10n.clientAgentsSubmitRequests,
              icon: const Icon(Icons.sync_rounded),
              onPressed: isSyncing || isMutating || isSyncOnCooldown
                  ? null
                  : onSyncPending,
              isLoading: isSyncing,
            ),
        ],
      ),
    );
  }
}

class ClientAgentsPageBanners extends StatelessWidget {
  const ClientAgentsPageBanners({
    required this.l10n,
    required this.tokens,
    required this.actionErrorMessage,
    required this.ownerActionErrorMessage,
    required this.actionNoticeMessage,
    required this.actionNoticeKind,
    required this.ownerActionNoticeMessage,
    required this.ownerActionNoticeKind,
    super.key,
  });

  final AppLocalizations l10n;
  final AppThemeTokens tokens;
  final String? actionErrorMessage;
  final String? ownerActionErrorMessage;
  final String? actionNoticeMessage;
  final ClientAgentsActionFeedbackKind? actionNoticeKind;
  final String? ownerActionNoticeMessage;
  final ClientAgentsActionFeedbackKind? ownerActionNoticeKind;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];

    if (actionErrorMessage case final String message) {
      children
        ..add(SizedBox(height: tokens.sectionSpacing))
        ..add(
          AppInlineErrorPanel(
            title: l10n.clientAgentsActionFailedTitle,
            message: message,
          ),
        );
    }
    if (ownerActionErrorMessage case final String message) {
      children
        ..add(SizedBox(height: tokens.gapMd))
        ..add(
          AppInlineErrorPanel(
            title: l10n.clientAgentsOwnerActionFailedTitle,
            message: message,
          ),
        );
    }
    if (actionNoticeMessage case final String message) {
      children
        ..add(SizedBox(height: tokens.gapMd))
        ..add(
          ClientAgentsActionFeedbackBanner(
            message: message,
            kind: actionNoticeKind,
          ),
        );
    }
    if (ownerActionNoticeMessage case final String message) {
      children
        ..add(SizedBox(height: tokens.gapMd))
        ..add(
          ClientAgentsActionFeedbackBanner(
            message: message,
            kind: ownerActionNoticeKind,
          ),
        );
    }

    if (children.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}

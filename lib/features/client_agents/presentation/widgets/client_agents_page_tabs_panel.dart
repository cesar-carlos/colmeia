import 'dart:async';

import 'package:colmeia/core/layout/app_responsive_spacing.dart';
import 'package:colmeia/features/client_agents/application/client_agents_page_session_service.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent_access_request.dart';
import 'package:colmeia/features/client_agents/presentation/controllers/client_agents_controller.dart';
import 'package:colmeia/features/client_agents/presentation/controllers/client_agents_owner_controller.dart';
import 'package:colmeia/features/client_agents/presentation/models/client_agent_access_request_row_input.dart';
import 'package:colmeia/features/client_agents/presentation/models/client_agents_presentation_message.dart';
import 'package:colmeia/features/client_agents/presentation/widgets/client_agents_approved_agents_tab.dart';
import 'package:colmeia/features/client_agents/presentation/widgets/client_agents_owner_clients_tab.dart';
import 'package:colmeia/features/client_agents/presentation/widgets/client_agents_owner_requests_tab.dart';
import 'package:colmeia/features/client_agents/presentation/widgets/client_agents_page_filters.dart';
import 'package:colmeia/features/client_agents/presentation/widgets/client_agents_page_header_widgets.dart';
import 'package:colmeia/features/client_agents/presentation/widgets/client_agents_request_access_tab.dart';
import 'package:colmeia/features/client_agents/presentation/widgets/client_agents_requests_tab.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card_with_heading.dart';
import 'package:colmeia/shared/widgets/app_skeleton.dart';
import 'package:colmeia/shared/widgets/navigation/app_tab_view.dart';
import 'package:flutter/material.dart';

class ClientAgentsPageTabsPanel extends StatelessWidget {
  const ClientAgentsPageTabsPanel({
    required this.tokens,
    required this.l10n,
    required this.controller,
    required this.ownerController,
    required this.canManageOwnerAccess,
    required this.pageSession,
    required this.requestAccessDraftResetRevision,
    required this.localizeMessage,
    required this.localizeNoticeMessage,
    required this.onTabChanged,
    required this.onRequestAccessDraftSlotsChanged,
    required this.onSubmitRequestAccessRows,
    required this.onNavigateToRequestAccess,
    required this.onClearRequestsFilters,
    required this.filterButton,
    required this.filterSummary,
    super.key,
  });

  static const int approvedAgentsTabIndex = 0;
  static const int requestAccessTabIndex = 1;
  static const int requestsTabIndex = 2;
  static const int ownerClientsTabIndex = 4;

  final AppThemeTokens tokens;
  final AppLocalizations l10n;
  final ClientAgentsController controller;
  final ClientAgentsOwnerController ownerController;
  final bool canManageOwnerAccess;
  final ClientAgentsPageSessionState pageSession;
  final int requestAccessDraftResetRevision;
  final String? Function(ClientAgentsPresentationMessage?, AppLocalizations)
  localizeMessage;
  final String? Function(ClientAgentsPresentationNotice?, AppLocalizations)
  localizeNoticeMessage;
  final ValueChanged<int> onTabChanged;
  final ValueChanged<List<String>> onRequestAccessDraftSlotsChanged;
  final Future<bool> Function(
    ClientAgentsController controller,
    List<ClientAgentAccessRequestRowInput> rows,
  )
  onSubmitRequestAccessRows;
  final VoidCallback onNavigateToRequestAccess;
  final VoidCallback onClearRequestsFilters;
  final Widget? filterButton;
  final Widget? filterSummary;

  @override
  Widget build(BuildContext context) {
    final selectedTabIndex = pageSession.selectedTabIndex.clamp(
      0,
      canManageOwnerAccess ? ownerClientsTabIndex : requestsTabIndex,
    );
    return RefreshIndicator(
      onRefresh: () async {
        await controller.refreshAll();
        if (canManageOwnerAccess) {
          await ownerController.refreshAll();
        }
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: context.pageScrollPadding(tokens),
        children: <Widget>[
          ClientAgentsPageHeader(
            l10n: l10n,
            tokens: tokens,
            pendingCount: controller.pendingActions.length,
            isLoading: controller.isLoading || ownerController.isLoading,
            isRefreshing:
                controller.isRefreshing || ownerController.isRefreshing,
            isSyncing: controller.isSyncing,
            isMutating: controller.isMutating,
            isSyncOnCooldown: controller.isSyncOnCooldown,
            syncRetryAfterSeconds: controller.syncRetryAfter?.inSeconds ?? 0,
            onRefresh: () {
              unawaited(controller.refreshAll());
              if (canManageOwnerAccess) {
                unawaited(ownerController.refreshAll());
              }
            },
            onSyncPending: () => unawaited(controller.syncPending()),
          ),
          ClientAgentsPageBanners(
            l10n: l10n,
            tokens: tokens,
            actionErrorMessage: localizeMessage(controller.actionError, l10n),
            ownerActionErrorMessage: localizeMessage(
              ownerController.actionError,
              l10n,
            ),
            actionNoticeMessage: localizeNoticeMessage(
              controller.actionNotice,
              l10n,
            ),
            actionNoticeKind: controller.actionNotice?.kind,
            ownerActionNoticeMessage: localizeNoticeMessage(
              ownerController.actionNotice,
              l10n,
            ),
            ownerActionNoticeKind: ownerController.actionNotice?.kind,
          ),
          SizedBox(height: tokens.sectionSpacing),
          AppSectionCardWithHeading(
            title: l10n.clientAgentsMaintenanceTitle,
            subtitle: canManageOwnerAccess
                ? l10n.clientAgentsMaintenanceSubtitleOwner
                : l10n.clientAgentsMaintenanceSubtitle,
            headingTrailing: filterButton,
            headingBottom: filterSummary,
            child: AppSkeleton(
              enabled:
                  controller.isLoadingInitial ||
                  (canManageOwnerAccess && ownerController.isLoadingInitial),
              child: AppTabView(
                initialIndex: selectedTabIndex,
                onChanged: onTabChanged,
                items: _buildTabItems(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<AppTabViewItem> _buildTabItems() {
    final rawRequests =
        controller.accessRequests?.items ?? const <ClientAgentAccessRequest>[];
    final approvedSnapshot = controller.approvedAgents;
    final requestsForRequestsTab = approvedSnapshot == null
        ? rawRequests
        : excludeApprovedRequestsWithoutActiveAgent(
            rawRequests,
            approvedSnapshot.items.map((a) => a.agentId).toSet(),
          );
    final approvedAgents =
        controller.approvedAgents?.items ?? const <ClientAgent>[];
    final filteredRequests = filterClientAgentsRequestsList(
      requestsForRequestsTab,
      pageSession.requestsFilters,
    );
    final filteredPendingActions = filterClientAgentsPendingActionsList(
      controller.pendingActions,
      pageSession.requestsFilters,
    );
    final filteredApprovedAgents = filterClientAgentsApprovedList(
      approvedAgents,
      pageSession.approvedAgentFilters,
    );

    return <AppTabViewItem>[
      AppTabViewItem(
        label: l10n.clientAgentsTabMyAgents,
        child: ClientAgentsApprovedAgentsTab(
          agents: filteredApprovedAgents,
          totalCount: approvedSnapshot?.total ?? filteredApprovedAgents.length,
          errorMessage: localizeMessage(controller.approvedAgentsError, l10n),
          onQueueRemoveAccess: (agentIds) async {
            await controller.removeAccess(agentIds: agentIds);
          },
          onRetry: () => unawaited(controller.refreshAll()),
          isMutating: controller.isMutating,
          isLoading: controller.isLoadingInitial,
          pendingRemoveAgentIds: controller.pendingRemoveAgentIds,
          isResultTruncated: controller.approvedAgentsResultTruncated,
          loadedCount: approvedSnapshot?.items.length,
          hasActiveFilters:
              clientAgentsApprovedActiveFilterCount(
                l10n,
                pageSession.approvedAgentFilters,
              ) >
              0,
          requestAccessTabLabel: l10n.clientAgentsTabRequestAccess,
        ),
      ),
      AppTabViewItem(
        label: l10n.clientAgentsTabRequestAccess,
        child: ClientAgentsRequestAccessTab(
          draftSeedAgentIdSlots: pageSession.requestAccessDraftAgentIdSlots,
          draftResetRevision: requestAccessDraftResetRevision,
          onDraftSlotsChanged: onRequestAccessDraftSlotsChanged,
          loadClientToken: controller.readLocalClientToken,
          persistClientTokenDraftLine:
              controller.persistLocalClientTokenDraftLine,
          onSubmitRows: (rows) => onSubmitRequestAccessRows(controller, rows),
          onClearMessages: () {
            controller
              ..clearActionError()
              ..clearActionFeedback();
          },
          isMutating:
              controller.isMutating || controller.isRequestAccessOnCooldown,
          retryAfterSeconds: controller.isRequestAccessOnCooldown
              ? (controller.requestAccessRetryAfter?.inSeconds ?? 0)
              : null,
        ),
      ),
      AppTabViewItem(
        label: l10n.clientAgentsTabRequests,
        child: ClientAgentsRequestsTab(
          requests: filteredRequests,
          pendingActions: filteredPendingActions,
          errorMessage: localizeMessage(controller.accessRequestsError, l10n),
          pendingErrorMessage: localizeMessage(
            controller.pendingActionsError,
            l10n,
          ),
          onRetry: () => unawaited(controller.refreshAll()),
          isMutating: controller.isMutating,
          isLoading: controller.isLoadingInitial,
          onRetryAccessRequest: (request) =>
              controller.retryAccessRequest(request: request),
          onDiscardQueuedRequestAccess: (action) =>
              controller.discardQueuedRequestAccess(action: action),
          hasActiveFilters:
              clientAgentsRequestsActiveFilterCount(
                l10n,
                pageSession.requestsFilters,
              ) >
              0,
          onClearFilters: onClearRequestsFilters,
          onNavigateToRequestAccess: onNavigateToRequestAccess,
        ),
      ),
      if (canManageOwnerAccess)
        AppTabViewItem(
          label: l10n.clientAgentsTabOwnerRequests,
          child: ClientAgentsOwnerRequestsTab(
            requests: ownerController.ownerRequests,
            errorMessage: localizeMessage(
              ownerController.ownerRequestsError,
              l10n,
            ),
            onRetry: () => unawaited(ownerController.refreshAll()),
            onApprove: (request) => ownerController.approveRequest(
              requestId: request.requestId,
              agentId: request.agentId,
            ),
            onReject: (request) => ownerController.rejectRequest(
              requestId: request.requestId,
              agentId: request.agentId,
            ),
            isMutating: ownerController.isMutating,
          ),
        ),
      if (canManageOwnerAccess)
        AppTabViewItem(
          label: l10n.clientAgentsTabOwnerClients,
          child: ClientAgentsOwnerClientsTab(
            managedAgents: ownerController.managedAgents,
            managedAgentsErrorMessage: localizeMessage(
              ownerController.managedAgentsError,
              l10n,
            ),
            selectedAgentId: ownerController.selectedManagedAgentId,
            approvedClients: ownerController.approvedClients,
            errorMessage: localizeMessage(
              ownerController.approvedClientsError,
              l10n,
            ),
            isMutating: ownerController.isMutating,
            onRetry: () => unawaited(ownerController.refreshAll()),
            onSelectAgent: (agentId) =>
                unawaited(ownerController.selectManagedAgent(agentId)),
            onRevokeClientAccess: (client) =>
                ownerController.revokeClientAccess(
                  agentId: ownerController.selectedManagedAgentId ?? '',
                  clientId: client.clientId,
                ),
          ),
        ),
    ];
  }
}

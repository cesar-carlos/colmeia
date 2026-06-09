import 'dart:async';

import 'package:colmeia/app/router/app_shell_route_observer.dart';
import 'package:colmeia/core/layout/app_responsive_spacing.dart';
import 'package:colmeia/features/client_agents/application/client_agents_page_session_service.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent_access_request.dart';
import 'package:colmeia/features/client_agents/presentation/controllers/client_agents_controller.dart';
import 'package:colmeia/features/client_agents/presentation/controllers/client_agents_owner_controller.dart';
import 'package:colmeia/features/client_agents/presentation/localization/client_agents_presentation_message_l10n.dart';
import 'package:colmeia/features/client_agents/presentation/models/client_agent_access_request_row_input.dart';
import 'package:colmeia/features/client_agents/presentation/models/client_agents_presentation_message.dart';
import 'package:colmeia/features/client_agents/presentation/utils/client_agents_page_route_lifecycle_bridge.dart';
import 'package:colmeia/features/client_agents/presentation/widgets/client_agents_approved_agents_tab.dart';
import 'package:colmeia/features/client_agents/presentation/widgets/client_agents_owner_clients_tab.dart';
import 'package:colmeia/features/client_agents/presentation/widgets/client_agents_owner_requests_tab.dart';
import 'package:colmeia/features/client_agents/presentation/widgets/client_agents_page_filters.dart';
import 'package:colmeia/features/client_agents/presentation/widgets/client_agents_request_access_tab.dart';
import 'package:colmeia/features/client_agents/presentation/widgets/client_agents_requests_tab.dart';
import 'package:colmeia/features/client_agents/presentation/widgets/client_agents_shared_widgets.dart';
import 'package:colmeia/features/user_context/domain/entities/user_permission.dart';
import 'package:colmeia/features/user_context/presentation/controllers/current_user_context_controller.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/actions/app_primary_button.dart';
import 'package:colmeia/shared/widgets/actions/app_secondary_button.dart';
import 'package:colmeia/shared/widgets/app_inline_error_panel.dart';
import 'package:colmeia/shared/widgets/app_section_card_with_heading.dart';
import 'package:colmeia/shared/widgets/app_skeleton.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_page_intro.dart';
import 'package:colmeia/shared/widgets/navigation/app_tab_view.dart';
import 'package:colmeia/shared/widgets/reports/app_report_filters_panel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ClientAgentsPage extends StatefulWidget {
  const ClientAgentsPage({
    required this.controller,
    required this.ownerController,
    required this.pageSessionService,
    super.key,
  });

  final ClientAgentsController controller;
  final ClientAgentsOwnerController ownerController;
  final ClientAgentsPageSessionService pageSessionService;

  @override
  State<ClientAgentsPage> createState() => _ClientAgentsPageState();
}

class _ClientAgentsPageState extends State<ClientAgentsPage> with RouteAware {
  static const int _approvedAgentsTabIndex = 0;
  static const int _requestsTabIndex = 2;
  static const int _ownerClientsTabIndex = 4;
  static const int _maxTabIndex = _ownerClientsTabIndex;
  static const Duration _draftPersistenceDebounce = Duration(milliseconds: 350);
  late final ClientAgentsController _controller;
  late final ClientAgentsOwnerController _ownerController;
  late final ClientAgentsPageSessionService _pageSessionService;
  late final ClientAgentsPageRouteLifecycleBridge _routeLifecycleBridge;
  late ClientAgentsPageSessionState _pageSession;
  Timer? _draftPersistenceTimer;
  bool _shellRouteObserverSubscribed = false;
  bool _ownerInitialLoadScheduled = false;
  int _requestAccessDraftResetRevision = 0;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller;
    _ownerController = widget.ownerController;
    _pageSessionService = widget.pageSessionService;
    _routeLifecycleBridge = ClientAgentsPageRouteLifecycleBridge(
      setScreenVisible: ({required isVisible}) {
        _controller.setScreenVisible(isVisible: isVisible);
      },
    );
    _pageSession = _pageSessionService.restore(
      fallbackTabIndex: _approvedAgentsTabIndex,
      maxTabIndex: _maxTabIndex,
    );
  }

  bool _initialLoadScheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_shellRouteObserverSubscribed) {
      final route = ModalRoute.of(context);
      if (route is PageRoute<void>) {
        appShellRouteObserver.subscribe(this, route);
        _shellRouteObserverSubscribed = true;
      }
    }
    if (!_initialLoadScheduled) {
      _initialLoadScheduled = true;
      unawaited(_controller.initialize());
    }
    _ensureOwnerInitialized(
      canManageOwnerAccess: context
          .read<CurrentUserContextController>()
          .hasPermission(UserPermission.manageAgents),
      schedulePostFrame: false,
    );
  }

  /// Owner data is loaded exactly once when the user is known to have the
  /// `manageAgents` permission.
  ///
  /// Called from two places intentionally:
  /// - `didChangeDependencies`, for the common case where the permission is
  ///   already known at first frame; runs synchronously.
  /// - the `Consumer2.builder`, for the case where the permission only
  ///   becomes true after a later `CurrentUserContextController` rebuild;
  ///   must defer to a post-frame callback because `build` cannot call
  ///   `unawaited(...)` on a future that itself might `notifyListeners`.
  ///
  /// The `_ownerInitialLoadScheduled` flag guarantees idempotency across
  /// both call sites and across rebuilds.
  void _ensureOwnerInitialized({
    required bool canManageOwnerAccess,
    required bool schedulePostFrame,
  }) {
    if (_ownerInitialLoadScheduled || !canManageOwnerAccess) {
      return;
    }
    _ownerInitialLoadScheduled = true;
    if (!schedulePostFrame) {
      unawaited(_ownerController.initialize());
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(_ownerController.initialize());
    });
  }

  @override
  void didPush() {
    // PR-M part 3: visibility on first push so the REST poller (when
    // wired) can decide if it should start polling on a degraded
    // socket.
    _routeLifecycleBridge.didPush();
  }

  @override
  void didPopNext() {
    _routeLifecycleBridge.didPopNext();
    unawaited(_controller.refreshAll());
  }

  @override
  void didPushNext() {
    // PR-M part 3: pushed onto a child route (e.g. agent detail).
    // Stop the REST poller — the badge stays in the in-memory
    // snapshot and is reconciled when we come back via didPopNext.
    _routeLifecycleBridge.didPushNext();
  }

  @override
  void didPop() {
    _routeLifecycleBridge.didPop();
  }

  @override
  void dispose() {
    if (_shellRouteObserverSubscribed) {
      appShellRouteObserver.unsubscribe(this);
    }
    _draftPersistenceTimer?.cancel();
    unawaited(
      _persistRequestAccessDraftSlots(
        _pageSession.requestAccessDraftAgentIdSlots,
      ),
    );
    _controller.dispose();
    _ownerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final canManageOwnerAccess = context
        .select<CurrentUserContextController, bool>(
          (controller) => controller.hasPermission(UserPermission.manageAgents),
        );
    _ensureOwnerInitialized(
      canManageOwnerAccess: canManageOwnerAccess,
      schedulePostFrame: true,
    );
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ClientAgentsController>.value(
          value: _controller,
        ),
        ChangeNotifierProvider<ClientAgentsOwnerController>.value(
          value: _ownerController,
        ),
      ],
      child: Consumer2<ClientAgentsController, ClientAgentsOwnerController>(
        builder: (context, controller, ownerController, _) {
          final l10n = AppLocalizations.of(context);
          return _buildBody(
            context: context,
            tokens: tokens,
            l10n: l10n,
            controller: controller,
            ownerController: ownerController,
            canManageOwnerAccess: canManageOwnerAccess,
          );
        },
      ),
    );
  }

  Widget _buildBody({
    required BuildContext context,
    required AppThemeTokens tokens,
    required AppLocalizations l10n,
    required ClientAgentsController controller,
    required ClientAgentsOwnerController ownerController,
    required bool canManageOwnerAccess,
  }) {
    final selectedTabIndex = _pageSession.selectedTabIndex.clamp(
      0,
      canManageOwnerAccess ? _ownerClientsTabIndex : _requestsTabIndex,
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
          _PageHeader(
            l10n: l10n,
            tokens: tokens,
            pendingCount: controller.pendingActions.length,
            isLoading: controller.isLoading || ownerController.isLoading,
            isRefreshing:
                controller.isRefreshing || ownerController.isRefreshing,
            isSyncing: controller.isSyncing,
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
          _PageBanners(
            l10n: l10n,
            tokens: tokens,
            actionErrorMessage: _localizeMessage(controller.actionError, l10n),
            ownerActionErrorMessage: _localizeMessage(
              ownerController.actionError,
              l10n,
            ),
            actionNoticeMessage: _localizeNoticeMessage(
              controller.actionNotice,
              l10n,
            ),
            actionNoticeKind: controller.actionNotice?.kind,
            ownerActionNoticeMessage: _localizeNoticeMessage(
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
            headingTrailing: _buildFilterButton(
              l10n: l10n,
              controller: controller,
              selectedTabIndex: selectedTabIndex,
            ),
            headingBottom: _buildFilterSummary(
              l10n: l10n,
              selectedTabIndex: selectedTabIndex,
              tokens: tokens,
            ),
            child: AppSkeleton(
              enabled:
                  controller.isLoadingInitial ||
                  (canManageOwnerAccess && ownerController.isLoadingInitial),
              child: AppTabView(
                initialIndex: selectedTabIndex,
                onChanged: _onTabChanged,
                items: _buildTabItems(
                  l10n: l10n,
                  controller: controller,
                  ownerController: ownerController,
                  canManageOwnerAccess: canManageOwnerAccess,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onTabChanged(int index) {
    if (_pageSession.selectedTabIndex == index) {
      return;
    }
    setState(() {
      _pageSession = _pageSession.copyWith(selectedTabIndex: index);
    });
    unawaited(_pageSessionService.persistSelectedTabIndex(index));
  }

  List<AppTabViewItem> _buildTabItems({
    required AppLocalizations l10n,
    required ClientAgentsController controller,
    required ClientAgentsOwnerController ownerController,
    required bool canManageOwnerAccess,
  }) {
    final rawRequests =
        controller.accessRequests?.items ??
        const <ClientAgentAccessRequest>[];
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
      _pageSession.requestsFilters,
    );
    final filteredPendingActions = filterClientAgentsPendingActionsList(
      controller.pendingActions,
      _pageSession.requestsFilters,
    );
    final filteredApprovedAgents = filterClientAgentsApprovedList(
      approvedAgents,
      _pageSession.approvedAgentFilters,
    );

    return <AppTabViewItem>[
      AppTabViewItem(
        label: l10n.clientAgentsTabMyAgents,
        child: ClientAgentsApprovedAgentsTab(
          agents: filteredApprovedAgents,
          errorMessage: _localizeMessage(controller.approvedAgentsError, l10n),
          onQueueRemoveAccess: (agentIds) async {
            await controller.removeAccess(agentIds: agentIds);
          },
          onRetry: () => unawaited(controller.refreshAll()),
          isMutating: controller.isMutating,
          hasActiveFilters:
              clientAgentsApprovedActiveFilterCount(
                l10n,
                _pageSession.approvedAgentFilters,
              ) >
              0,
          requestAccessTabLabel: l10n.clientAgentsTabRequestAccess,
        ),
      ),
      AppTabViewItem(
        label: l10n.clientAgentsTabRequestAccess,
        child: ClientAgentsRequestAccessTab(
          draftSeedAgentIdSlots: _pageSession.requestAccessDraftAgentIdSlots,
          draftResetRevision: _requestAccessDraftResetRevision,
          onDraftSlotsChanged: _onRequestAccessDraftSlotsChanged,
          loadClientToken: controller.readLocalClientToken,
          persistClientTokenDraftLine:
              controller.persistLocalClientTokenDraftLine,
          onSubmitRows: (rows) => _onSubmitRequestAccessRows(controller, rows),
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
          errorMessage: _localizeMessage(controller.accessRequestsError, l10n),
          pendingErrorMessage: _localizeMessage(
            controller.pendingActionsError,
            l10n,
          ),
          onRetry: () => unawaited(controller.refreshAll()),
          isMutating: controller.isMutating,
          onRetryAccessRequest: (request) =>
              controller.retryAccessRequest(request: request),
          onDiscardQueuedRequestAccess: (action) =>
              controller.discardQueuedRequestAccess(action: action),
          hasActiveFilters:
              clientAgentsRequestsActiveFilterCount(
                l10n,
                _pageSession.requestsFilters,
              ) >
              0,
        ),
      ),
      if (canManageOwnerAccess)
        AppTabViewItem(
          label: l10n.clientAgentsTabOwnerRequests,
          child: ClientAgentsOwnerRequestsTab(
            requests: ownerController.ownerRequests,
            errorMessage: _localizeMessage(
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
            managedAgentsErrorMessage: _localizeMessage(
              ownerController.managedAgentsError,
              l10n,
            ),
            selectedAgentId: ownerController.selectedManagedAgentId,
            approvedClients: ownerController.approvedClients,
            errorMessage: _localizeMessage(
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

  void _onRequestAccessDraftSlotsChanged(List<String> slots) {
    if (!mounted) {
      return;
    }
    setState(() {
      _pageSession = _pageSession.copyWith(
        requestAccessDraftAgentIdSlots: slots,
      );
    });
    _scheduleDraftPersistence();
  }

  Future<bool> _onSubmitRequestAccessRows(
    ClientAgentsController controller,
    List<ClientAgentAccessRequestRowInput> rows,
  ) async {
    final accepted = await controller.submitAccessRequestWithLocalTokens(rows);
    if (!mounted) {
      return accepted;
    }
    if (accepted) {
      setState(() {
        _pageSession = _pageSession.copyWith(
          requestAccessDraftAgentIdSlots: const <String>[''],
        );
        _requestAccessDraftResetRevision++;
      });
      _draftPersistenceTimer?.cancel();
      await _persistRequestAccessDraftSlots(const <String>['']);
    }
    return accepted;
  }

  Widget? _buildFilterButton({
    required AppLocalizations l10n,
    required ClientAgentsController controller,
    required int selectedTabIndex,
  }) {
    if (selectedTabIndex == _approvedAgentsTabIndex) {
      return ClientAgentsFilterButton(
        activeCount: clientAgentsApprovedActiveFilterCount(
          l10n,
          _pageSession.approvedAgentFilters,
        ),
        l10n: l10n,
        onPressed: controller.isLoading
            ? null
            : () => unawaited(_showApprovedAgentFilters()),
      );
    }
    if (selectedTabIndex == _requestsTabIndex) {
      return ClientAgentsFilterButton(
        activeCount: clientAgentsRequestsActiveFilterCount(
          l10n,
          _pageSession.requestsFilters,
        ),
        l10n: l10n,
        onPressed: controller.isLoading
            ? null
            : () => unawaited(_showRequestsFilters()),
      );
    }
    return null;
  }

  Widget? _buildFilterSummary({
    required AppLocalizations l10n,
    required int selectedTabIndex,
    required AppThemeTokens tokens,
  }) {
    if (selectedTabIndex == _approvedAgentsTabIndex &&
        clientAgentsApprovedActiveFilterCount(
              l10n,
              _pageSession.approvedAgentFilters,
            ) >
            0) {
      return Wrap(
        spacing: tokens.gapSm,
        runSpacing: tokens.gapSm,
        children: _buildSummaryChips(
          buildClientAgentsApprovedFilterSummaryLabels(
            l10n: l10n,
            approvedAgentFilters: _pageSession.approvedAgentFilters,
          ),
        ),
      );
    }
    if (selectedTabIndex == _requestsTabIndex &&
        clientAgentsRequestsActiveFilterCount(
              l10n,
              _pageSession.requestsFilters,
            ) >
            0) {
      return Wrap(
        spacing: tokens.gapSm,
        runSpacing: tokens.gapSm,
        children: _buildSummaryChips(
          buildClientAgentsRequestsFilterSummaryLabels(
            l10n: l10n,
            requestsFilters: _pageSession.requestsFilters,
          ),
        ),
      );
    }
    return null;
  }

  List<Widget> _buildSummaryChips(List<String> labels) {
    return labels
        .map((label) => Chip(label: Text(label)))
        .toList(growable: false);
  }

  Future<void> _showApprovedAgentFilters() async {
    if (!mounted) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        final tokens = Theme.of(context).extension<AppThemeTokens>()!;
        final sheetL10n = AppLocalizations.of(context);
        final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(
            tokens.contentSpacing,
            tokens.gapMd,
            tokens.contentSpacing,
            tokens.contentSpacing + bottomInset,
          ),
          child: SingleChildScrollView(
            child: AppReportFiltersPanel(
              title: sheetL10n.clientAgentsFilterSheetTitle,
              filters: buildClientAgentsApprovedFilterDescriptors(sheetL10n),
              initialValues: _pageSession.approvedAgentFilters,
              onApply: (values) {
                setState(() {
                  _pageSession = _pageSession.copyWith(
                    approvedAgentFilters: values,
                  );
                });
                unawaited(_pageSessionService.persistApprovedFilters(values));
                Navigator.of(context).pop();
              },
              onClear: () {
                setState(() {
                  _pageSession = _pageSession.copyWith(
                    approvedAgentFilters: <String, Object?>{},
                  );
                });
                unawaited(
                  _pageSessionService.persistApprovedFilters(
                    const <String, Object?>{},
                  ),
                );
                Navigator.of(context).pop();
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _showRequestsFilters() async {
    if (!mounted) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        final tokens = Theme.of(context).extension<AppThemeTokens>()!;
        final sheetL10n = AppLocalizations.of(context);
        final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(
            tokens.contentSpacing,
            tokens.gapMd,
            tokens.contentSpacing,
            tokens.contentSpacing + bottomInset,
          ),
          child: SingleChildScrollView(
            child: AppReportFiltersPanel(
              title: sheetL10n.clientAgentsRequestsFilterSheetTitle,
              filters: buildClientAgentsRequestsFilterDescriptors(sheetL10n),
              initialValues: _pageSession.requestsFilters,
              onApply: (values) {
                setState(() {
                  _pageSession = _pageSession.copyWith(
                    requestsFilters: values,
                  );
                });
                unawaited(_pageSessionService.persistRequestsFilters(values));
                Navigator.of(context).pop();
              },
              onClear: () {
                setState(() {
                  _pageSession = _pageSession.copyWith(
                    requestsFilters: <String, Object?>{},
                  );
                });
                unawaited(
                  _pageSessionService.persistRequestsFilters(
                    const <String, Object?>{},
                  ),
                );
                Navigator.of(context).pop();
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _persistRequestAccessDraftSlots(List<String> slots) {
    return _pageSessionService.persistRequestAccessDraftAgentIdSlots(slots);
  }

  void _scheduleDraftPersistence() {
    _draftPersistenceTimer?.cancel();
    _draftPersistenceTimer = Timer(_draftPersistenceDebounce, () {
      unawaited(
        _persistRequestAccessDraftSlots(
          _pageSession.requestAccessDraftAgentIdSlots,
        ),
      );
    });
  }

  String? _localizeMessage(
    ClientAgentsPresentationMessage? message,
    AppLocalizations l10n,
  ) {
    if (message == null) {
      return null;
    }
    return localizeClientAgentsPresentationMessage(message, l10n);
  }

  String? _localizeNoticeMessage(
    ClientAgentsPresentationNotice? notice,
    AppLocalizations l10n,
  ) {
    final message = notice?.message;
    if (message == null) {
      return null;
    }
    return localizeClientAgentsPresentationMessage(message, l10n);
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.l10n,
    required this.tokens,
    required this.pendingCount,
    required this.isLoading,
    required this.isRefreshing,
    required this.isSyncing,
    required this.isSyncOnCooldown,
    required this.syncRetryAfterSeconds,
    required this.onRefresh,
    required this.onSyncPending,
  });

  final AppLocalizations l10n;
  final AppThemeTokens tokens;
  final int pendingCount;
  final bool isLoading;
  final bool isRefreshing;
  final bool isSyncing;
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
            Chip(label: Text(l10n.clientAgentsPendingActionsCount(pendingCount))),
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
              onPressed: isSyncing || isSyncOnCooldown ? null : onSyncPending,
              isLoading: isSyncing,
            ),
        ],
      ),
    );
  }
}

class _PageBanners extends StatelessWidget {
  const _PageBanners({
    required this.l10n,
    required this.tokens,
    required this.actionErrorMessage,
    required this.ownerActionErrorMessage,
    required this.actionNoticeMessage,
    required this.actionNoticeKind,
    required this.ownerActionNoticeMessage,
    required this.ownerActionNoticeKind,
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

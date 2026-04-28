import 'dart:async';

import 'package:colmeia/app/router/app_shell_route_observer.dart';
import 'package:colmeia/core/di/injector.dart';
import 'package:colmeia/core/layout/app_responsive_spacing.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent_access_request.dart';
import 'package:colmeia/features/client_agents/presentation/controllers/client_agents_controller.dart';
import 'package:colmeia/features/client_agents/presentation/controllers/client_agents_owner_controller.dart';
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
import 'package:colmeia/shared/presentation/localization/sync_app_localizations_mixin.dart';
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
import 'package:shared_preferences/shared_preferences.dart';

class ClientAgentsPage extends StatefulWidget {
  const ClientAgentsPage({super.key});

  @override
  State<ClientAgentsPage> createState() => _ClientAgentsPageState();
}

class _ClientAgentsPageState extends State<ClientAgentsPage>
    with SyncAppLocalizationsMixin<ClientAgentsPage>, RouteAware {
  static const int _approvedAgentsTabIndex = 0;
  static const int _requestsTabIndex = 2;
  static const int _ownerClientsTabIndex = 4;
  static const int _maxTabIndex = _ownerClientsTabIndex;
  static const Duration _draftPersistenceDebounce = Duration(milliseconds: 350);
  late final ClientAgentsController _controller;
  late final ClientAgentsOwnerController _ownerController;
  late final SharedPreferences _prefs;
  late ClientAgentsPageSessionState _pageSession;
  Timer? _draftPersistenceTimer;
  bool _shellRouteObserverSubscribed = false;
  bool _ownerInitialLoadScheduled = false;

  @override
  void initState() {
    super.initState();
    _prefs = getIt<SharedPreferences>();
    _controller = getIt<ClientAgentsController>();
    _ownerController = getIt<ClientAgentsOwnerController>();
    _pageSession = ClientAgentsPageSessionState.restore(
      prefs: _prefs,
      fallbackTabIndex: _approvedAgentsTabIndex,
      maxTabIndex: _maxTabIndex,
    );
  }

  bool _initialLoadScheduled = false;

  @override
  void bindAppLocalizations(AppLocalizations l10n) {
    _controller.activeLocalizations = l10n;
    _ownerController.activeLocalizations = l10n;
  }

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
    if (!_ownerInitialLoadScheduled &&
        context.read<CurrentUserContextController>().hasPermission(
          UserPermission.manageAgents,
        )) {
      _ownerInitialLoadScheduled = true;
      unawaited(_ownerController.initialize());
    }
  }

  @override
  void didPush() {
    // PR-M part 3: visibility on first push so the REST poller (when
    // wired) can decide if it should start polling on a degraded
    // socket.
    _controller.onScreenVisible();
  }

  @override
  void didPopNext() {
    _controller.onScreenVisible();
    unawaited(_controller.refreshAll());
  }

  @override
  void didPushNext() {
    // PR-M part 3: pushed onto a child route (e.g. agent detail).
    // Stop the REST poller — the badge stays in the in-memory
    // snapshot and is reconciled when we come back via didPopNext.
    _controller.onScreenHidden();
  }

  @override
  void didPop() {
    _controller.onScreenHidden();
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
          final pendingCount = controller.pendingActions.length;
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
          final selectedTabIndex = _pageSession.selectedTabIndex.clamp(
            0,
            canManageOwnerAccess ? _ownerClientsTabIndex : _requestsTabIndex,
          );

          final items = <AppTabViewItem>[
            AppTabViewItem(
              label: l10n.clientAgentsTabMyAgents,
              child: ClientAgentsApprovedAgentsTab(
                agents: filteredApprovedAgents,
                errorMessage: controller.approvedAgentsErrorMessage,
                onQueueRemoveAccess: (agentIds) async {
                  await controller.removeAccess(agentIds: agentIds);
                },
                onRetry: () => unawaited(controller.refreshAll()),
                isMutating: controller.isSyncing,
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
                initialAgentIdSlots:
                    _pageSession.requestAccessDraftAgentIdSlots,
                onDraftSlotsChanged: (slots) {
                  if (!mounted) {
                    return;
                  }
                  setState(() {
                    _pageSession = _pageSession.copyWith(
                      requestAccessDraftAgentIdSlots: slots,
                    );
                  });
                  _scheduleDraftPersistence();
                },
                loadClientToken: controller.readLocalClientToken,
                persistClientTokenDraftLine:
                    controller.persistLocalClientTokenDraftLine,
                onSubmitRows: (rows) async {
                  final accepted = await controller
                      .submitAccessRequestWithLocalTokens(rows);
                  if (!mounted) {
                    return accepted;
                  }
                  if (accepted) {
                    _pageSession = _pageSession.copyWith(
                      requestAccessDraftAgentIdSlots: const <String>[''],
                    );
                    _draftPersistenceTimer?.cancel();
                    await _persistRequestAccessDraftSlots(const <String>['']);
                  }
                  return accepted;
                },
                onClearMessages: () {
                  controller
                    ..clearActionError()
                    ..clearActionFeedback();
                },
                isMutating:
                    controller.isSyncing ||
                    controller.isRequestAccessOnCooldown,
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
                errorMessage: controller.accessRequestsErrorMessage,
                pendingErrorMessage: controller.pendingActionsErrorMessage,
                onRetry: () => unawaited(controller.refreshAll()),
                isMutating: controller.isSyncing,
                onRetryAccessRequest: (request) =>
                    controller.retryAccessRequest(
                      request: request,
                    ),
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
                  errorMessage: ownerController.ownerRequestsErrorMessage,
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
                  selectedAgentId: ownerController.selectedManagedAgentId,
                  approvedClients: ownerController.approvedClients,
                  errorMessage: ownerController.approvedClientsErrorMessage,
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
                AppShellPageIntro(
                  eyebrow: l10n.clientAgentsDataSourcesEyebrow,
                  title: l10n.clientAgentsPageTitle,
                  subtitle: l10n.clientAgentsPageSubtitle,
                  footer: Wrap(
                    spacing: tokens.gapSm,
                    runSpacing: tokens.gapSm,
                    children: <Widget>[
                      if (pendingCount > 0)
                        Chip(
                          label: Text(
                            l10n.clientAgentsPendingActionsCount(pendingCount),
                          ),
                        ),
                      AppSecondaryButton(
                        label: l10n.clientAgentsRefresh,
                        icon: const Icon(Icons.refresh_rounded),
                        onPressed:
                            controller.isLoading || ownerController.isLoading
                            ? null
                            : () {
                                unawaited(controller.refreshAll());
                                if (canManageOwnerAccess) {
                                  unawaited(ownerController.refreshAll());
                                }
                              },
                        isLoading:
                            controller.isRefreshing ||
                            ownerController.isRefreshing,
                      ),
                      if (pendingCount > 0)
                        AppPrimaryButton(
                          label: controller.isSyncOnCooldown
                              ? l10n.clientAgentsSyncRetryAfterCountdown(
                                  controller.syncRetryAfter?.inSeconds ?? 0,
                                )
                              : l10n.clientAgentsSubmitRequests,
                          icon: const Icon(Icons.sync_rounded),
                          onPressed:
                              controller.isSyncing ||
                                  controller.isSyncOnCooldown
                              ? null
                              : () => unawaited(controller.syncPending()),
                          isLoading: controller.isSyncing,
                        ),
                    ],
                  ),
                ),
                if (controller.actionErrorMessage
                    case final String message) ...<Widget>[
                  SizedBox(height: tokens.sectionSpacing),
                  AppInlineErrorPanel(
                    title: l10n.clientAgentsActionFailedTitle,
                    message: message,
                  ),
                ],
                if (ownerController.actionErrorMessage
                    case final String message) ...<Widget>[
                  SizedBox(height: tokens.gapMd),
                  AppInlineErrorPanel(
                    title: l10n.clientAgentsOwnerActionFailedTitle,
                    message: message,
                  ),
                ],
                if (controller.actionFeedbackMessage
                    case final String message) ...<Widget>[
                  SizedBox(height: tokens.gapMd),
                  ClientAgentsActionFeedbackBanner(
                    message: message,
                    kind: controller.actionFeedbackKind,
                  ),
                ],
                if (ownerController.actionFeedbackMessage
                    case final String message) ...<Widget>[
                  SizedBox(height: tokens.gapMd),
                  ClientAgentsActionFeedbackBanner(
                    message: message,
                    kind: ClientAgentsActionFeedbackKind.success,
                  ),
                ],
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
                        (canManageOwnerAccess &&
                            ownerController.isLoadingInitial),
                    child: AppTabView(
                      initialIndex: selectedTabIndex,
                      onChanged: (index) {
                        if (_pageSession.selectedTabIndex == index) {
                          return;
                        }
                        setState(() {
                          _pageSession = _pageSession.copyWith(
                            selectedTabIndex: index,
                          );
                        });
                        unawaited(
                          persistClientAgentsSelectedTabIndex(_prefs, index),
                        );
                      },
                      items: items,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
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
        children: buildClientAgentsApprovedFilterSummaryChips(
          l10n: l10n,
          approvedAgentFilters: _pageSession.approvedAgentFilters,
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
        children: buildClientAgentsRequestsFilterSummaryChips(
          l10n: l10n,
          requestsFilters: _pageSession.requestsFilters,
        ),
      );
    }
    return null;
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
                unawaited(
                  persistClientAgentsApprovedFilters(_prefs, values),
                );
                Navigator.of(context).pop();
              },
              onClear: () {
                setState(() {
                  _pageSession = _pageSession.copyWith(
                    approvedAgentFilters: <String, Object?>{},
                  );
                });
                unawaited(
                  persistClientAgentsApprovedFilters(
                    _prefs,
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
                unawaited(
                  persistClientAgentsRequestsFilters(_prefs, values),
                );
                Navigator.of(context).pop();
              },
              onClear: () {
                setState(() {
                  _pageSession = _pageSession.copyWith(
                    requestsFilters: <String, Object?>{},
                  );
                });
                unawaited(
                  persistClientAgentsRequestsFilters(
                    _prefs,
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
    return persistClientAgentsRequestAccessDraftAgentIdSlots(_prefs, slots);
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
}

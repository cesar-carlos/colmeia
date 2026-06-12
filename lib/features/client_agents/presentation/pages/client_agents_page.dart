import 'dart:async';

import 'package:colmeia/app/router/app_shell_route_observer.dart';
import 'package:colmeia/features/client_agents/application/client_agents_page_session_service.dart';
import 'package:colmeia/features/client_agents/presentation/controllers/client_agents_controller.dart';
import 'package:colmeia/features/client_agents/presentation/controllers/client_agents_owner_controller.dart';
import 'package:colmeia/features/client_agents/presentation/localization/client_agents_presentation_message_l10n.dart';
import 'package:colmeia/features/client_agents/presentation/models/client_agent_access_request_row_input.dart';
import 'package:colmeia/features/client_agents/presentation/models/client_agents_presentation_message.dart';
import 'package:colmeia/features/client_agents/presentation/utils/client_agents_page_route_lifecycle_bridge.dart';
import 'package:colmeia/features/client_agents/presentation/widgets/client_agents_page_filters.dart';
import 'package:colmeia/features/client_agents/presentation/widgets/client_agents_page_tabs_panel.dart';
import 'package:colmeia/features/client_agents/presentation/widgets/client_agents_shared_widgets.dart';
import 'package:colmeia/features/user_context/domain/entities/user_permission.dart';
import 'package:colmeia/features/user_context/presentation/controllers/current_user_context_controller.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
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
      fallbackTabIndex: ClientAgentsPageTabsPanel.approvedAgentsTabIndex,
      maxTabIndex: ClientAgentsPageTabsPanel.ownerClientsTabIndex,
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
    _routeLifecycleBridge.didPush();
  }

  @override
  void didPopNext() {
    _routeLifecycleBridge.didPopNext();
  }

  @override
  void didPushNext() {
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
          final selectedTabIndex = _pageSession.selectedTabIndex.clamp(
            0,
            canManageOwnerAccess
                ? ClientAgentsPageTabsPanel.ownerClientsTabIndex
                : ClientAgentsPageTabsPanel.requestsTabIndex,
          );
          return ClientAgentsPageTabsPanel(
            tokens: tokens,
            l10n: l10n,
            controller: controller,
            ownerController: ownerController,
            canManageOwnerAccess: canManageOwnerAccess,
            pageSession: _pageSession,
            requestAccessDraftResetRevision: _requestAccessDraftResetRevision,
            localizeMessage: _localizeMessage,
            localizeNoticeMessage: _localizeNoticeMessage,
            onTabChanged: _onTabChanged,
            onRequestAccessDraftSlotsChanged: _onRequestAccessDraftSlotsChanged,
            onSubmitRequestAccessRows: _onSubmitRequestAccessRows,
            onNavigateToRequestAccess: () => _onTabChanged(
              ClientAgentsPageTabsPanel.requestAccessTabIndex,
            ),
            onClearRequestsFilters: () {
              setState(() {
                _pageSession = _pageSession.copyWith(
                  requestsFilters: const <String, Object?>{},
                );
              });
              unawaited(
                _pageSessionService.persistRequestsFilters(
                  const <String, Object?>{},
                ),
              );
            },
            filterButton: _buildFilterButton(
              l10n: l10n,
              controller: controller,
              selectedTabIndex: selectedTabIndex,
            ),
            filterSummary: _buildFilterSummary(
              l10n: l10n,
              selectedTabIndex: selectedTabIndex,
              tokens: tokens,
            ),
          );
        },
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
    if (selectedTabIndex == ClientAgentsPageTabsPanel.approvedAgentsTabIndex) {
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
    if (selectedTabIndex == ClientAgentsPageTabsPanel.requestsTabIndex) {
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
    if (selectedTabIndex == ClientAgentsPageTabsPanel.approvedAgentsTabIndex &&
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
    if (selectedTabIndex == ClientAgentsPageTabsPanel.requestsTabIndex &&
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

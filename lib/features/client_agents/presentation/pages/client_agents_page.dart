import 'dart:async';

import 'package:colmeia/core/di/injector.dart';
import 'package:colmeia/core/layout/app_responsive_spacing.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent_access_request.dart';
import 'package:colmeia/features/client_agents/presentation/controllers/client_agents_controller.dart';
import 'package:colmeia/features/client_agents/presentation/widgets/client_agents_approved_agents_tab.dart';
import 'package:colmeia/features/client_agents/presentation/widgets/client_agents_page_filters.dart';
import 'package:colmeia/features/client_agents/presentation/widgets/client_agents_request_access_tab.dart';
import 'package:colmeia/features/client_agents/presentation/widgets/client_agents_requests_tab.dart';
import 'package:colmeia/features/client_agents/presentation/widgets/client_agents_shared_widgets.dart';
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
    with SyncAppLocalizationsMixin<ClientAgentsPage> {
  static const int _approvedAgentsTabIndex = 0;
  static const int _requestsTabIndex = 2;
  late final ClientAgentsController _controller;
  late final SharedPreferences _prefs;
  int _selectedTabIndex = _approvedAgentsTabIndex;
  late Map<String, Object?> _approvedAgentFilters;
  late Map<String, Object?> _requestsFilters;

  @override
  void initState() {
    super.initState();
    _prefs = getIt<SharedPreferences>();
    _controller = getIt<ClientAgentsController>();
    _approvedAgentFilters = restoreClientAgentsApprovedFilters(_prefs);
    _requestsFilters = restoreClientAgentsRequestsFilters(_prefs);
  }

  bool _initialLoadScheduled = false;

  @override
  void bindAppLocalizations(AppLocalizations l10n) {
    _controller.activeLocalizations = l10n;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialLoadScheduled) {
      _initialLoadScheduled = true;
      unawaited(_controller.initialize());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    return ChangeNotifierProvider<ClientAgentsController>.value(
      value: _controller,
      child: Consumer<ClientAgentsController>(
        builder: (context, controller, _) {
          final l10n = AppLocalizations.of(context);
          final pendingCount = controller.pendingActions.length;
          final requests =
              controller.accessRequests?.items ??
              const <ClientAgentAccessRequest>[];
          final approvedAgents =
              controller.approvedAgents?.items ?? const <ClientAgent>[];
          final filteredRequests = filterClientAgentsRequestsList(
            requests,
            _requestsFilters,
          );
          final filteredPendingActions = filterClientAgentsPendingActionsList(
            controller.pendingActions,
            _requestsFilters,
          );
          final filteredApprovedAgents = filterClientAgentsApprovedList(
            approvedAgents,
            _approvedAgentFilters,
          );
          return ListView(
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
                      onPressed: controller.isLoading
                          ? null
                          : () => unawaited(controller.refreshAll()),
                    ),
                    if (pendingCount > 0)
                      AppPrimaryButton(
                        label: l10n.clientAgentsSubmitRequests,
                        icon: const Icon(Icons.sync_rounded),
                        onPressed: controller.isSyncing
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
              if (controller.actionFeedbackMessage
                  case final String message) ...<Widget>[
                SizedBox(height: tokens.gapMd),
                ClientAgentsActionFeedbackBanner(
                  message: message,
                  kind: controller.actionFeedbackKind,
                ),
              ],
              SizedBox(height: tokens.sectionSpacing),
              AppSectionCardWithHeading(
                title: l10n.clientAgentsMaintenanceTitle,
                subtitle: l10n.clientAgentsMaintenanceSubtitle,
                headingTrailing: _selectedTabIndex == _approvedAgentsTabIndex
                    ? ClientAgentsFilterButton(
                        activeCount: clientAgentsApprovedActiveFilterCount(
                          l10n,
                          _approvedAgentFilters,
                        ),
                        l10n: l10n,
                        onPressed: controller.isLoading
                            ? null
                            : () => unawaited(_showApprovedAgentFilters()),
                      )
                    : (_selectedTabIndex == _requestsTabIndex
                          ? ClientAgentsFilterButton(
                              activeCount:
                                  clientAgentsRequestsActiveFilterCount(
                                    l10n,
                                    _requestsFilters,
                                  ),
                              l10n: l10n,
                              onPressed: controller.isLoading
                                  ? null
                                  : () => unawaited(_showRequestsFilters()),
                            )
                          : null),
                headingBottom:
                    _selectedTabIndex == _approvedAgentsTabIndex &&
                        clientAgentsApprovedActiveFilterCount(
                              l10n,
                              _approvedAgentFilters,
                            ) >
                            0
                    ? Wrap(
                        spacing: tokens.gapSm,
                        runSpacing: tokens.gapSm,
                        children: buildClientAgentsApprovedFilterSummaryChips(
                          l10n: l10n,
                          approvedAgentFilters: _approvedAgentFilters,
                        ),
                      )
                    : (_selectedTabIndex == _requestsTabIndex &&
                              clientAgentsRequestsActiveFilterCount(
                                    l10n,
                                    _requestsFilters,
                                  ) >
                                  0
                          ? Wrap(
                              spacing: tokens.gapSm,
                              runSpacing: tokens.gapSm,
                              children:
                                  buildClientAgentsRequestsFilterSummaryChips(
                                    l10n: l10n,
                                    requestsFilters: _requestsFilters,
                                  ),
                            )
                          : null),
                child: AppSkeleton(
                  enabled: controller.isLoading,
                  child: AppTabView(
                    onChanged: (index) {
                      if (_selectedTabIndex == index) {
                        return;
                      }
                      setState(() => _selectedTabIndex = index);
                    },
                    items: <AppTabViewItem>[
                      AppTabViewItem(
                        label: l10n.clientAgentsTabMyAgents,
                        child: ClientAgentsApprovedAgentsTab(
                          agents: filteredApprovedAgents,
                          errorMessage: controller.approvedAgentsErrorMessage,
                          onRemoveAccess: (agent) => unawaited(
                            controller.removeAccess(agentIds: <String>{agent}),
                          ),
                          onRetry: () => unawaited(controller.refreshAll()),
                          isMutating: controller.isSyncing,
                          hasActiveFilters:
                              clientAgentsApprovedActiveFilterCount(
                                l10n,
                                _approvedAgentFilters,
                              ) >
                              0,
                          requestAccessTabLabel:
                              l10n.clientAgentsTabRequestAccess,
                        ),
                      ),
                      AppTabViewItem(
                        label: l10n.clientAgentsTabRequestAccess,
                        child: ClientAgentsRequestAccessTab(
                          onRequestAccess: (agentIds) => unawaited(
                            controller.requestAccess(agentIds: agentIds),
                          ),
                          onClearMessages: () {
                            controller
                              ..clearActionError()
                              ..clearActionFeedback();
                          },
                          isMutating: controller.isSyncing,
                        ),
                      ),
                      AppTabViewItem(
                        label: l10n.clientAgentsTabRequests,
                        child: ClientAgentsRequestsTab(
                          requests: filteredRequests,
                          pendingActions: filteredPendingActions,
                          errorMessage: controller.accessRequestsErrorMessage,
                          pendingErrorMessage:
                              controller.pendingActionsErrorMessage,
                          onRetry: () => unawaited(controller.refreshAll()),
                          hasActiveFilters:
                              clientAgentsRequestsActiveFilterCount(
                                l10n,
                                _requestsFilters,
                              ) >
                              0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
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
        return Padding(
          padding: EdgeInsets.fromLTRB(
            tokens.contentSpacing,
            tokens.gapMd,
            tokens.contentSpacing,
            tokens.contentSpacing,
          ),
          child: SingleChildScrollView(
            child: AppReportFiltersPanel(
              title: sheetL10n.clientAgentsFilterSheetTitle,
              filters: buildClientAgentsApprovedFilterDescriptors(sheetL10n),
              initialValues: _approvedAgentFilters,
              onApply: (values) {
                setState(() => _approvedAgentFilters = values);
                unawaited(
                  persistClientAgentsApprovedFilters(
                    _prefs,
                    _approvedAgentFilters,
                  ),
                );
                Navigator.of(context).pop();
              },
              onClear: () {
                setState(() => _approvedAgentFilters = <String, Object?>{});
                unawaited(
                  persistClientAgentsApprovedFilters(
                    _prefs,
                    _approvedAgentFilters,
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
        return Padding(
          padding: EdgeInsets.fromLTRB(
            tokens.contentSpacing,
            tokens.gapMd,
            tokens.contentSpacing,
            tokens.contentSpacing,
          ),
          child: SingleChildScrollView(
            child: AppReportFiltersPanel(
              title: sheetL10n.clientAgentsRequestsFilterSheetTitle,
              filters: buildClientAgentsRequestsFilterDescriptors(sheetL10n),
              initialValues: _requestsFilters,
              onApply: (values) {
                setState(() => _requestsFilters = values);
                unawaited(
                  persistClientAgentsRequestsFilters(_prefs, _requestsFilters),
                );
                Navigator.of(context).pop();
              },
              onClear: () {
                setState(() => _requestsFilters = <String, Object?>{});
                unawaited(
                  persistClientAgentsRequestsFilters(_prefs, _requestsFilters),
                );
                Navigator.of(context).pop();
              },
            ),
          ),
        );
      },
    );
  }
}

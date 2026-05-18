import 'dart:async';

import 'package:colmeia/app/router/app_chart_fullscreen_routes.dart';
import 'package:colmeia/app/router/app_navigation.dart';
import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/core/layout/app_responsive_spacing.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map_use_case.dart';
import 'package:colmeia/features/sales/domain/entities/sales_auto_refresh_preference.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_filter.dart';
import 'package:colmeia/features/sales/presentation/controllers/sales_live_map_controller.dart';
import 'package:colmeia/features/sales/presentation/state/sales_live_map_presentation_state.dart';
import 'package:colmeia/features/sales/presentation/utils/sales_auto_refresh_state_mixin.dart';
import 'package:colmeia/features/sales/presentation/view_models/sales_live_map_view_model.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_auto_refresh_actions_row.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_card_filter_trigger.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_live_map_filters_sheet.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_live_map_kpi_grid.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/utils/app_branch_display_name.dart';
import 'package:colmeia/shared/widgets/app_inline_error_panel.dart';
import 'package:colmeia/shared/widgets/app_section_card.dart';
import 'package:colmeia/shared/widgets/app_skeleton.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_chart.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_models.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_page_intro.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class SalesLiveMapPage extends StatelessWidget {
  const SalesLiveMapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<AuthController, String?>(
      selector: (_, auth) => auth.session?.userId,
      builder: (context, sessionUserId, _) {
        return _SalesLiveMapSession(
          key: ValueKey<String?>(
            sessionUserId == null ? null : 'sales-live-map-$sessionUserId',
          ),
          sessionUserId: sessionUserId,
        );
      },
    );
  }
}

class _SalesLiveMapSession extends StatefulWidget {
  const _SalesLiveMapSession({
    required this.sessionUserId,
    super.key,
  });

  final String? sessionUserId;

  @override
  State<_SalesLiveMapSession> createState() => _SalesLiveMapSessionState();
}

class _SalesLiveMapSessionState extends State<_SalesLiveMapSession>
    with SalesAutoRefreshStateMixin<_SalesLiveMapSession> {
  late final SalesLiveMapController _controller;
  int _pendingReloadForceCount = 0;
  int _lastCloseFullscreenRequestId = 0;
  DateTime? _lastRecordedSuccessfulRefreshAt;

  @override
  void initState() {
    super.initState();
    _controller = context.read<SalesLiveMapController>()
      ..addListener(_handleControllerChanged);
    _lastCloseFullscreenRequestId = _controller.state.closeFullscreenRequestId;
    restoreSalesAutoRefreshPreference(_controller.restoreAutoRefreshPreference());
    _scheduleInitialize();
  }

  @override
  void didUpdateWidget(covariant _SalesLiveMapSession oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sessionUserId != widget.sessionUserId) {
      _scheduleInitialize();
    }
  }

  void _scheduleInitialize() {
    unawaited(
      Future<void>.microtask(() async {
        if (!mounted) {
          return;
        }
        await _controller.bindUser(widget.sessionUserId);
      }),
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerChanged);
    super.dispose();
  }

  @override
  bool get rebuildOnSalesAutoRefreshStateChange => false;

  @override
  bool get canScheduleSalesAutoRefresh =>
      _controller.state.canScheduleAutoRefresh && !_controller.state.isLoading;

  Future<void> _reload({bool force = false}) async {
    if (force) {
      _pendingReloadForceCount += 1;
    }
    await reloadWithSalesAutoRefresh(force: force);
  }

  @override
  Future<void> performSalesAutoRefreshReload() async {
    final force = _pendingReloadForceCount > 0;
    _pendingReloadForceCount = 0;
    await _controller.reload(force: force);
  }

  @override
  DateTime? resolveSalesAutoRefreshCompletedAt() {
    final result = _controller.state.result;
    if (result == null || result.loadFailed || result.cancelled) {
      return null;
    }
    return result.refreshedAt;
  }

  @override
  void didUpdateSalesAutoRefreshUiState(SalesAutoRefreshUiState state) {
    unawaited(
      _controller.persistAutoRefreshPreference(
        SalesAutoRefreshPreference(
          interval: state.interval,
          lastSuccessfulRefreshAt: state.lastUpdatedAt,
          nextDueAt: state.nextDueAt,
          remainingDelay: state.remainingDelay,
          failureStreak: state.failureStreak,
        ),
      ),
    );
  }

  void _handleControllerChanged() {
    if (!mounted) {
      return;
    }
    final state = _controller.state;
    if (!state.isLoading && !state.canScheduleAutoRefresh) {
      disableSalesAutoRefresh();
    } else {
      refreshSalesAutoRefreshScheduling();
    }
    final successfulRefreshAt = _resolveSuccessfulRefreshAt(state);
    if (successfulRefreshAt != null &&
        successfulRefreshAt != _lastRecordedSuccessfulRefreshAt) {
      _lastRecordedSuccessfulRefreshAt = successfulRefreshAt;
      recordSalesAutoRefreshSuccessfulReload(successfulRefreshAt);
    }
    if (state.closeFullscreenRequestId != _lastCloseFullscreenRequestId) {
      _lastCloseFullscreenRequestId = state.closeFullscreenRequestId;
      _maybePopChartFullscreenAfterDataChanged();
    }
  }

  DateTime? _resolveSuccessfulRefreshAt(SalesLiveMapPresentationState state) {
    final result = state.result;
    if (result == null || result.loadFailed || result.cancelled) {
      return null;
    }
    return result.refreshedAt;
  }

  Future<void> _openFiltersSheet() async {
    final state = _controller.state;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: false,
      builder: (context) => SalesLiveMapFiltersSheet(
        l10n: AppLocalizations.of(context),
        availableAgents: state.availableAgents,
        availableBranches:
            state.result?.branchOptions ?? const <SalesLiveMapBranchOption>[],
        initialFilter: state.filter,
        onApply: (filter) => unawaited(_controller.applyFilter(filter)),
      ),
    );
  }

  void _openLiveMapFullscreen(
    SalesLiveMapPresentationState state,
    SalesLiveMapViewModel viewModel,
  ) {
    final l10n = AppLocalizations.of(context);
    final pointsSnapshot = List<AppBrazilStoreSalesPoint>.of(
      state.result?.points ?? const <AppBrazilStoreSalesPoint>[],
      growable: false,
    );
    final filterBranchIdsSnapshot = Set<String>.from(
      state.filterBranchStorageKeys,
    );
    final initialMetricSnapshot = state.filter.metric;
    final styleSnapshot = state.mapStyle;

    unawaited(
      context.pushChartFullscreen<void>(
        extra: AppChartFullscreenRouteExtra(
          title: l10n.salesLiveMapChartTitle,
          subtitle: viewModel.mapSubtitle,
          chartSemanticsLabel: l10n.salesLiveMapChartTitle,
          chartBuilder: (_) {
            return LayoutBuilder(
              builder: (context, _) {
                final tokens = Theme.of(
                  context,
                ).extension<AppThemeTokens>()!;
                return AppSectionCard(
                  padding: EdgeInsets.fromLTRB(
                    tokens.contentSpacing,
                    tokens.contentSpacing,
                    tokens.contentSpacing,
                    0,
                  ),
                  child: LayoutBuilder(
                    builder: (context, cardConstraints) {
                      Widget chart = AppBrazilStoreSalesMapChart(
                        points: pointsSnapshot,
                        initialMetric: initialMetricSnapshot,
                        filterBranchIds: filterBranchIdsSnapshot,
                        fixedBranchIds: filterBranchIdsSnapshot,
                        style: styleSnapshot,
                        onMetricChanged: _controller.updateMetric,
                        showDesktopBranchSidebar: true,
                        presentationMode:
                            AppBrazilStoreSalesMapPresentationMode
                                .cleanFullscreen,
                      );
                      final maxH = cardConstraints.maxHeight;
                      if (maxH.isFinite && maxH < double.infinity) {
                        chart = SizedBox(height: maxH, child: chart);
                      }
                      return chart;
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _maybePopChartFullscreenAfterDataChanged() {
    final router = GoRouter.maybeOf(context);
    if (router == null) {
      return;
    }
    final matched = router.state.matchedLocation;
    if (AppRoute.fromLocation(matched) != AppRoute.chartFullscreen) {
      return;
    }
    if (!router.canPop()) {
      return;
    }
    router.pop();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;

    return SingleChildScrollView(
      padding: context.pageScrollPadding(
        tokens,
        horizontalAdjustment:
            AppPageSpacingPresets.dashboardHorizontalAdjustment,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const _SalesLiveMapIntroSection(),
          SizedBox(height: tokens.sectionSpacing),
          _SalesLiveMapFilterSection(onOpenFilters: _openFiltersSheet),
          SizedBox(height: tokens.gapMd),
          _SalesLiveMapAutoRefreshSection(
            onIntervalChanged: setSalesAutoRefreshInterval,
            onRefreshNow: () => unawaited(_reload()),
            stateListenable: salesAutoRefreshStateListenable,
          ),
          SizedBox(height: tokens.sectionSpacing),
          _SalesLiveMapBodySection(
            onRetryReload: () => unawaited(_reload()),
            onOpenFullscreen: _openLiveMapFullscreen,
          ),
        ],
      ),
    );
  }
}

class _SalesLiveMapIntroSection extends StatelessWidget {
  const _SalesLiveMapIntroSection();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppShellPageIntro(
      sectionLabel: l10n.salesHubTitle,
      onSectionLabelTap: () => context.goTo(AppRoute.sales),
      title: l10n.salesLiveMapTitle,
      subtitle: l10n.salesLiveMapSubtitle,
    );
  }
}

class _SalesLiveMapFilterSection extends StatelessWidget {
  const _SalesLiveMapFilterSection({required this.onOpenFilters});

  final Future<void> Function() onOpenFilters;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;

    return Selector<SalesLiveMapController, SalesLiveMapPresentationState>(
      selector: (_, controller) => controller.state,
      builder: (context, state, _) {
        final controller = context.read<SalesLiveMapController>();
        final viewModel = SalesLiveMapViewModel.fromState(state, l10n);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SalesCardFilterTrigger(
              onTap: () => unawaited(onOpenFilters()),
              buttonSemanticsLabel: l10n.reportFiltersButton,
              summaryItems: <SalesCardFilterSummaryItem>[
                SalesCardFilterSummaryItem(
                  label: l10n.salesLiveMapAgentsLabel,
                  value: viewModel.agentsSummary,
                ),
                SalesCardFilterSummaryItem(
                  label: l10n.salesLiveMapPeriodLabel,
                  value: viewModel.periodSummary,
                ),
                SalesCardFilterSummaryItem(
                  label: l10n.salesLiveMapDetailLabel,
                  value: viewModel.detailSummary,
                ),
                SalesCardFilterSummaryItem(
                  label: viewModel.usesMapLabel
                      ? l10n.salesLiveMapMapLabel
                      : l10n.salesLiveMapVisualLabel,
                  value: viewModel.visualSummary,
                ),
              ],
              enabled: !state.isLoading,
            ),
            if (state.hasSelectedBranchFilter ||
                state.hasNonBranchNonDefaultFilter) ...<Widget>[
              SizedBox(height: tokens.gapSm),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: tokens.gapSm,
                  runSpacing: tokens.gapXs,
                  children: <Widget>[
                    if (state.hasSelectedBranchFilter)
                      OutlinedButton.icon(
                        onPressed: state.isLoading
                            ? null
                            : () => unawaited(
                                controller.clearSelectedBranches(),
                              ),
                        icon: const Icon(Icons.storefront_outlined),
                        label: Text(
                          l10n.salesLiveMapClearBranchSelectionAction,
                        ),
                      ),
                    if (state.hasNonBranchNonDefaultFilter)
                      OutlinedButton.icon(
                        onPressed: state.isLoading
                            ? null
                            : () => unawaited(controller.clearSavedFilters()),
                        icon: const Icon(Icons.filter_alt_off_rounded),
                        label: Text(l10n.salesLiveMapClearSavedFiltersAction),
                      ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _SalesLiveMapAutoRefreshSection extends StatelessWidget {
  const _SalesLiveMapAutoRefreshSection({
    required this.onIntervalChanged,
    required this.onRefreshNow,
    required this.stateListenable,
  });

  final ValueChanged<SalesAutoRefreshInterval?> onIntervalChanged;
  final VoidCallback onRefreshNow;
  final ValueListenable<SalesAutoRefreshUiState> stateListenable;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ValueListenableBuilder<SalesAutoRefreshUiState>(
      valueListenable: stateListenable,
      builder: (context, refreshState, _) {
        return Selector<SalesLiveMapController, SalesLiveMapPresentationState>(
          selector: (_, controller) => controller.state,
          builder: (context, state, _) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                SalesAutoRefreshActionsRow(
                  value: refreshState.interval,
                  onChanged: onIntervalChanged,
                  onRefreshNow: state.canReload ? onRefreshNow : () {},
                  enabled: state.canScheduleAutoRefresh,
                  lastUpdatedAt: refreshState.lastUpdatedAt,
                  nextDueAt: refreshState.nextDueAt,
                  isBackingOff: refreshState.isBackingOff,
                  l10n: l10n,
                ),
                if (state.isLoading && state.result != null) ...<Widget>[
                  SizedBox(
                    height: Theme.of(context)
                        .extension<AppThemeTokens>()!
                        .gapSm,
                  ),
                  const LinearProgressIndicator(minHeight: 2),
                ],
              ],
            );
          },
        );
      },
    );
  }
}

class _SalesLiveMapBodySection extends StatelessWidget {
  const _SalesLiveMapBodySection({
    required this.onRetryReload,
    required this.onOpenFullscreen,
  });

  final VoidCallback onRetryReload;
  final void Function(
    SalesLiveMapPresentationState state,
    SalesLiveMapViewModel viewModel,
  )
  onOpenFullscreen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;

    return Selector<SalesLiveMapController, SalesLiveMapPresentationState>(
      selector: (_, controller) => controller.state,
      builder: (context, state, _) {
        final controller = context.read<SalesLiveMapController>();
        final result = state.result;
        final viewModel = SalesLiveMapViewModel.fromState(state, l10n);

        if (result == null && state.isLoading) {
          return _SalesLiveMapInitialSkeleton();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (result != null)
              AppSkeleton(
                enabled: result.salesDataPending,
                child: SalesLiveMapKpiGrid(result: result),
              ),
            if (result != null &&
                !result.salesDataPending &&
                result.hasPartialIssue) ...<Widget>[
              SizedBox(height: tokens.gapMd),
              _SalesLiveMapAttentionPanel(result: result),
            ],
            if (result?.loadFailed ?? false) ...<Widget>[
              SizedBox(height: tokens.gapMd),
              AppInlineErrorPanel(
                title: l10n.salesLiveMapLoadErrorTitle,
                message: viewModel.loadErrorMessage,
                onRetry: state.canReload ? onRetryReload : null,
              ),
            ],
            if (state.shouldShowEmptyNotice && result != null) ...<Widget>[
              SizedBox(height: tokens.gapMd),
              _SalesLiveMapEmptyNotice(
                result: result,
                hasSelectedBranches: state.hasSelectedBranchFilter,
                onClearSelectedBranches: () => unawaited(
                  controller.clearSelectedBranches(),
                ),
                l10n: l10n,
              ),
            ],
            SizedBox(height: tokens.sectionSpacing),
            AppBrazilStoreSalesMapChart(
              title: l10n.salesLiveMapChartTitle,
              subtitle: viewModel.mapSubtitle,
              points: result?.points ?? const <AppBrazilStoreSalesPoint>[],
              initialMetric: state.filter.metric,
              filterBranchIds: state.filterBranchStorageKeys,
              fixedBranchIds: state.filterBranchStorageKeys,
              style: state.mapStyle,
              presentationMode:
                  AppBrazilStoreSalesMapPresentationMode.inlineOperational,
              onMetricChanged: controller.updateMetric,
              onOpenFullscreen: () => onOpenFullscreen(state, viewModel),
            ),
          ],
        );
      },
    );
  }
}

class _SalesLiveMapInitialSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    return AppSkeleton(
      enabled: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const SalesLiveMapKpiGrid(
            result: SalesLiveMapLoadResult(
              points: <AppBrazilStoreSalesPoint>[],
              branchOptions: <SalesLiveMapBranchOption>[],
              totalRevenue: 128000,
              totalSalesCount: 420,
              totalBranchCount: 12,
              mappedBranchCount: 12,
              mappedMunicipalityCount: 8,
              queriedAgentCount: 3,
              plannedAgentCount: 3,
              failedAgentCount: 0,
              missingClientTokenAgentCount: 0,
              skippedOfflineAgentCount: 0,
              rowCapReachedAgentCount: 0,
              refreshedAt: null,
            ),
          ),
          SizedBox(height: tokens.sectionSpacing),
          AppBrazilStoreSalesMapChart(
            title: AppLocalizations.of(context).salesLiveMapChartTitle,
            points: const <AppBrazilStoreSalesPoint>[],
            style: const AppBrazilStoreSalesMapStyle(
              showStoreDetail: false,
              showRegionFilter: false,
            ),
            presentationMode:
                AppBrazilStoreSalesMapPresentationMode.inlineOperational,
          ),
        ],
      ),
    );
  }
}

class _SalesLiveMapAttentionPanel extends StatelessWidget {
  const _SalesLiveMapAttentionPanel({required this.result});

  final SalesLiveMapLoadResult result;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final messages = <String>[
      l10n.salesLiveMapAgentQuerySummary(
        result.plannedAgentCount,
        result.queriedAgentCount,
        result.salesAgentCount,
        result.noSalesAgentOptions.length,
      ),
      if (result.failedAgentCount > 0)
        l10n.salesLiveMapPartialFailedAgents(result.failedAgentCount),
      if (result.missingClientTokenAgentCount > 0)
        l10n.salesLiveMapPartialMissingTokenAgents(
          result.missingClientTokenAgentCount,
        ),
      if (result.skippedOfflineAgentCount > 0)
        l10n.salesLiveMapPartialOfflineAgents(
          result.skippedOfflineAgentCount,
        ),
      if (result.rowCapReachedAgentCount > 0)
        l10n.salesLiveMapPartialRowCapReached(
          result.rowCapReachedAgentCount,
        ),
      if (result.mappedBranchCount < result.totalBranchCount)
        l10n.salesLiveMapPartialMissingCoordinates(
          result.totalBranchCount - result.mappedBranchCount,
        ),
      if (result.noSalesAgentOptions.isNotEmpty)
        l10n.salesLiveMapPartialNoSalesAgents(
          result.noSalesAgentOptions.length,
        ),
      if (result.noSalesBranchCount > 0)
        l10n.salesLiveMapPartialZeroedBranches(result.noSalesBranchCount),
      if (result.salesUnavailableBranchCount > 0)
        l10n.salesLiveMapPartialUnavailableSalesBranches(
          result.salesUnavailableBranchCount,
        ),
    ];

    return AppInlineErrorPanel(
      tone: AppInlinePanelTone.informational,
      title: l10n.salesLiveMapPartialTitle,
      message: messages.join(' '),
      actions:
          result.unmappedBranchOptions.isEmpty &&
              result.noSalesAgentOptions.isEmpty
          ? null
          : _SalesLiveMapAttentionDetails(
              noSalesAgents: result.noSalesAgentOptions,
              unmappedBranches: result.unmappedBranchOptions,
            ),
    );
  }
}

class _SalesLiveMapAttentionDetails extends StatelessWidget {
  const _SalesLiveMapAttentionDetails({
    required this.noSalesAgents,
    required this.unmappedBranches,
  });

  final List<SalesLiveMapAgentOption> noSalesAgents;
  final List<SalesLiveMapBranchOption> unmappedBranches;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (noSalesAgents.isNotEmpty)
          _SalesLiveMapNoSalesAgentsList(agents: noSalesAgents),
        if (noSalesAgents.isNotEmpty && unmappedBranches.isNotEmpty)
          SizedBox(height: tokens.gapSm),
        if (unmappedBranches.isNotEmpty)
          _SalesLiveMapUnmappedBranchesList(branches: unmappedBranches),
      ],
    );
  }
}

class _SalesLiveMapNoSalesAgentsList extends StatelessWidget {
  const _SalesLiveMapNoSalesAgentsList({required this.agents});

  final List<SalesLiveMapAgentOption> agents;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(bottom: tokens.gapXs),
          child: Text(
            l10n.salesLiveMapNoSalesAgentsTitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        for (final agent in agents)
          Padding(
            padding: EdgeInsets.only(bottom: tokens.gapXs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  Icons.receipt_long_outlined,
                  size: 18,
                  color: colorScheme.primary,
                ),
                SizedBox(width: tokens.gapSm),
                Expanded(
                  child: Text(
                    appBranchDisplayName(agent.name),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _SalesLiveMapUnmappedBranchesList extends StatelessWidget {
  const _SalesLiveMapUnmappedBranchesList({required this.branches});

  static const int _maxVisibleBranches = 6;

  final List<SalesLiveMapBranchOption> branches;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final colorScheme = Theme.of(context).colorScheme;
    final visibleBranches = branches
        .take(_maxVisibleBranches)
        .toList(growable: false);
    final hiddenBranchCount = branches.length - visibleBranches.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final branch in visibleBranches)
          Padding(
            padding: EdgeInsets.only(bottom: tokens.gapXs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  Icons.location_off_outlined,
                  size: 18,
                  color: colorScheme.primary,
                ),
                SizedBox(width: tokens.gapSm),
                Expanded(
                  child: Text(
                    _unmappedBranchLabel(branch),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (hiddenBranchCount > 0)
          Padding(
            padding: EdgeInsets.only(left: 18 + tokens.gapSm),
            child: Text(
              '+ $hiddenBranchCount',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  String _unmappedBranchLabel(SalesLiveMapBranchOption branch) {
    final location = '${branch.city} / ${branch.uf}';
    return '${branch.name} - $location - ${appBranchDisplayName(branch.agentName)}';
  }
}

class _SalesLiveMapEmptyNotice extends StatelessWidget {
  const _SalesLiveMapEmptyNotice({
    required this.result,
    required this.hasSelectedBranches,
    required this.onClearSelectedBranches,
    required this.l10n,
  });

  final SalesLiveMapLoadResult result;
  final bool hasSelectedBranches;
  final VoidCallback onClearSelectedBranches;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final selectedWithoutRows =
        hasSelectedBranches &&
        result.totalBranchCount == 0 &&
        result.totalSalesCount == 0;
    return AppInlineErrorPanel(
      tone: AppInlinePanelTone.informational,
      title: selectedWithoutRows
          ? l10n.salesLiveMapEmptySelectionTitle
          : l10n.salesLiveMapEmptyNoSalesTitle,
      message: selectedWithoutRows
          ? l10n.salesLiveMapEmptySelectionMessage
          : l10n.salesLiveMapEmptyNoSalesMessage,
      actions: selectedWithoutRows
          ? Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                onPressed: onClearSelectedBranches,
                icon: const Icon(Icons.filter_alt_off_rounded),
                label: Text(l10n.salesLiveMapClearBranchSelectionAction),
              ),
            )
          : null,
    );
  }
}

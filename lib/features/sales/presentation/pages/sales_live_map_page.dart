import 'dart:async';

import 'package:colmeia/app/refresh/app_auto_refresh_support.dart';
import 'package:colmeia/app/router/app_chart_fullscreen_routes.dart';
import 'package:colmeia/app/router/app_navigation.dart';
import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/core/layout/app_responsive_spacing.dart';
import 'package:colmeia/core/refresh/auto_refresh_option.dart';
import 'package:colmeia/core/refresh/auto_refresh_state_mixin.dart';
import 'package:colmeia/core/refresh/auto_refresh_state_persistence.dart';
import 'package:colmeia/core/refresh/auto_refresh_ui_state.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map_use_case.dart';
import 'package:colmeia/features/sales/application/sales_live_map_reload_reason.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_filter.dart';
import 'package:colmeia/features/sales/presentation/auto_refresh/sales_auto_refresh_support.dart';
import 'package:colmeia/features/sales/presentation/controllers/sales_live_map_controller.dart';
import 'package:colmeia/features/sales/presentation/state/sales_live_map_presentation_state.dart';
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
import 'package:colmeia/shared/widgets/charts/app_chart_fullscreen_scaffold.dart';
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
    with AutoRefreshStateMixin<_SalesLiveMapSession> {
  late final SalesLiveMapController _controller;
  int _pendingReloadForceCount = 0;
  SalesLiveMapReloadReason? _pendingReloadReason;
  int _lastCloseFullscreenRequestId = 0;
  AutoRefreshReloadResult _lastAutoRefreshReloadResult =
      const AutoRefreshReloadResult.cancelled();
  DateTime? _lastRecordedSuccessfulRefreshAt;
  bool _wasControllerLoading = false;
  DateTime? _controllerReloadQueuedTickThreshold;
  bool _liveMapFullscreenOpen = false;
  _SalesLiveMapSchedulingSlice? _lastSchedulingSlice;

  @override
  void initState() {
    super.initState();
    _controller = context.read<SalesLiveMapController>()
      ..addListener(_handleControllerChanged);
    _lastCloseFullscreenRequestId = _controller.state.closeFullscreenRequestId;
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
  bool get rebuildOnAutoRefreshStateChange => false;

  @override
  bool get supportsAutoRefresh =>
      salesAutoRefreshIsAvailableForViewport(context);

  @override
  RouteObserver<ModalRoute<void>>? get autoRefreshRouteObserver =>
      AppAutoRefreshSupport.routeObserver;

  @override
  bool get canAutoRefreshWhileRouteHidden => _liveMapFullscreenOpen;

  @override
  AutoRefreshStatePersistence get autoRefreshStatePersistence =>
      _controller.autoRefreshPersistence;

  @override
  void logAutoRefreshInfo(String message, Map<String, Object?> context) {
    AppAutoRefreshSupport.logInfo(message, <String, Object?>{
      'cardId': SalesAutoRefreshCardIds.liveMap,
      ...context,
    });
  }

  @override
  void logAutoRefreshWarning(String message, Map<String, Object?> context) {
    AppAutoRefreshSupport.logWarning(message, <String, Object?>{
      'cardId': SalesAutoRefreshCardIds.liveMap,
      ...context,
    });
  }

  @override
  bool get canScheduleAutoRefresh =>
      _controller.state.canScheduleAutoRefresh && !_controller.state.isLoading;

  @override
  AutoRefreshPauseReason? resolveAutoRefreshPauseReason() {
    final state = _controller.state;
    if (state.isLoading) {
      return AutoRefreshPauseReason.pageLoading;
    }
    final availableAgents = state.availableAgents;
    if (availableAgents.isEmpty) {
      return AutoRefreshPauseReason.noEligibleSelection;
    }
    final tokenBackedAgentIds = availableAgents
        .where((agent) => !agent.missingLocalClientToken)
        .map((agent) => agent.agentId)
        .toSet();
    if (tokenBackedAgentIds.isEmpty) {
      return AutoRefreshPauseReason.missingLocalToken;
    }
    final selectedAgentIds = state.filter.selectedAgentIds;
    if (selectedAgentIds == null) {
      return null;
    }
    if (selectedAgentIds.any(tokenBackedAgentIds.contains)) {
      return null;
    }
    final selectedSet = selectedAgentIds.toSet();
    final selectedAgents = availableAgents
        .where((agent) => selectedSet.contains(agent.agentId))
        .toList(growable: false);
    if (selectedAgents.isNotEmpty &&
        selectedAgents.every((agent) => agent.missingLocalClientToken)) {
      return AutoRefreshPauseReason.missingLocalToken;
    }
    return AutoRefreshPauseReason.noEligibleSelection;
  }

  Future<void> _reload({bool force = false}) async {
    if (force) {
      _pendingReloadForceCount += 1;
    }
    _pendingReloadReason = SalesLiveMapReloadReason.manual;
    await reloadWithAutoRefresh(force: force);
  }

  @override
  Future<void> performAutoRefreshReload() async {
    final force = _pendingReloadForceCount > 0;
    final reason = _pendingReloadReason ?? SalesLiveMapReloadReason.autoRefresh;
    _pendingReloadForceCount = 0;
    _pendingReloadReason = null;
    final outcome = await _controller.reload(force: force, reason: reason);
    final result = outcome.result;
    if (outcome.isCancelled || outcome.isSuperseded) {
      _lastAutoRefreshReloadResult = const AutoRefreshReloadResult.cancelled();
      return;
    }
    if (result == null ||
        result.loadFailed ||
        result.cancelled ||
        result.salesDataPending ||
        result.refreshedAt == null) {
      _lastAutoRefreshReloadResult = const AutoRefreshReloadResult.failure();
      return;
    }
    _lastAutoRefreshReloadResult = AutoRefreshReloadResult.success(
      result.refreshedAt,
    );
  }

  @override
  AutoRefreshReloadResult resolveAutoRefreshReloadResult() =>
      _lastAutoRefreshReloadResult;

  void _handleControllerChanged() {
    if (!mounted) {
      return;
    }
    final state = _controller.state;
    final wasControllerLoading = _wasControllerLoading;
    if (state.isLoading &&
        !wasControllerLoading &&
        !autoRefreshReloadInProgress) {
      _controllerReloadQueuedTickThreshold =
          _resolveQueuedTickThresholdForControllerReload();
    }
    if (state.isLoading) {
      _lastRecordedSuccessfulRefreshAt = null;
    }
    if (!state.isLoading && !state.canScheduleAutoRefresh) {
      _controllerReloadQueuedTickThreshold = null;
    }
    final schedulingSlice = _SalesLiveMapSchedulingSlice.fromState(state);
    if (_lastSchedulingSlice != schedulingSlice) {
      _lastSchedulingSlice = schedulingSlice;
      refreshAutoRefreshScheduling();
    }
    final successfulRefreshAt = _resolveSuccessfulRefreshAt(state);
    if (successfulRefreshAt != null &&
        !autoRefreshReloadInProgress &&
        successfulRefreshAt != _lastRecordedSuccessfulRefreshAt) {
      final shouldQueueElapsedTick =
          _didControllerReloadCrossQueuedTickThreshold();
      _lastRecordedSuccessfulRefreshAt = successfulRefreshAt;
      _controllerReloadQueuedTickThreshold = null;
      recordAutoRefreshSuccessfulReload(
        successfulRefreshAt,
        scheduleNextCycle: !shouldQueueElapsedTick,
      );
    } else if (!state.isLoading && wasControllerLoading) {
      _controllerReloadQueuedTickThreshold = null;
    }
    _wasControllerLoading = state.isLoading;
    if (state.closeFullscreenRequestId != _lastCloseFullscreenRequestId) {
      _lastCloseFullscreenRequestId = state.closeFullscreenRequestId;
      _maybePopChartFullscreenAfterDataChanged();
    }
  }

  DateTime? _resolveQueuedTickThresholdForControllerReload() {
    final option = autoRefreshOption;
    final nextDueAt = autoRefreshNextDueAt;
    if (option == null || nextDueAt == null) {
      return null;
    }
    final startTime = currentAutoRefreshTime;
    if (startTime.isBefore(nextDueAt)) {
      return nextDueAt;
    }
    return nextDueAt.add(option.duration);
  }

  bool _didControllerReloadCrossQueuedTickThreshold() {
    final threshold = _controllerReloadQueuedTickThreshold;
    if (threshold == null) {
      return false;
    }
    return !currentAutoRefreshTime.isBefore(threshold);
  }

  DateTime? _resolveSuccessfulRefreshAt(SalesLiveMapPresentationState state) {
    final result = state.result;
    if (result == null ||
        result.loadFailed ||
        result.cancelled ||
        result.salesDataPending ||
        state.isLoading) {
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

  void _openLiveMapFullscreen() {
    if (_liveMapFullscreenOpen) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    _setLiveMapFullscreenOpen(true);

    unawaited(
      context
          .pushChartFullscreen<void>(
            extra: AppChartFullscreenRouteExtra(
              chartSemanticsLabel: l10n.salesLiveMapChartTitle,
              headerBuilder: (_) =>
                  _SalesLiveMapFullscreenHeader(controller: _controller),
              chartBuilder: (_) =>
                  _SalesLiveMapFullscreenChart(controller: _controller),
            ),
          )
          .whenComplete(() {
            if (!mounted) {
              return;
            }
            _setLiveMapFullscreenOpen(false);
          }),
    );
  }

  void _setLiveMapFullscreenOpen(bool isOpen) {
    if (_liveMapFullscreenOpen == isOpen) {
      return;
    }
    _liveMapFullscreenOpen = isOpen;
    if (!mounted) {
      return;
    }
    refreshAutoRefreshScheduling();
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
            onOptionChanged: setAutoRefreshOption,
            onRefreshNow: () => unawaited(_reload()),
            stateListenable: autoRefreshStateListenable,
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
    required this.onOptionChanged,
    required this.onRefreshNow,
    required this.stateListenable,
  });

  final ValueChanged<AutoRefreshOption?> onOptionChanged;
  final VoidCallback onRefreshNow;
  final ValueListenable<AutoRefreshUiState> stateListenable;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final autoRefreshSupported = salesAutoRefreshIsAvailableForViewport(
      context,
    );

    return ValueListenableBuilder<AutoRefreshUiState>(
      valueListenable: stateListenable,
      builder: (context, refreshState, _) {
        return Selector<SalesLiveMapController, _SalesLiveMapAutoRefreshSlice>(
          selector: (_, controller) =>
              _SalesLiveMapAutoRefreshSlice.fromState(controller.state),
          builder: (context, slice, _) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                SalesAutoRefreshActionsRow(
                  value: refreshState.option,
                  onChanged: onOptionChanged,
                  onRefreshNow: slice.canReload ? onRefreshNow : () {},
                  enabled: slice.canScheduleAutoRefresh,
                  refreshNowEnabled: slice.canReload,
                  lastUpdatedAt: refreshState.lastUpdatedAt,
                  nextDueAt: autoRefreshSupported
                      ? refreshState.nextDueAt
                      : null,
                  isBackingOff: refreshState.isBackingOff,
                  isPaused: refreshState.isPaused,
                  pauseReason: refreshState.pauseReason,
                  l10n: l10n,
                ),
                if (slice.showReloadProgress) ...<Widget>[
                  SizedBox(
                    height: Theme.of(
                      context,
                    ).extension<AppThemeTokens>()!.gapSm,
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
  final VoidCallback onOpenFullscreen;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;

    return Selector<SalesLiveMapController, _SalesLiveMapBodyStatusSlice>(
      selector: (_, controller) =>
          _SalesLiveMapBodyStatusSlice.fromState(controller.state),
      builder: (context, slice, _) {
        if (slice.showInitialSkeleton) {
          return _SalesLiveMapInitialSkeleton();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _SalesLiveMapBodyStatusContent(
              slice: slice,
              onRetryReload: onRetryReload,
            ),
            SizedBox(height: tokens.sectionSpacing),
            _SalesLiveMapInlineChartSection(
              onOpenFullscreen: onOpenFullscreen,
            ),
          ],
        );
      },
    );
  }
}

class _SalesLiveMapFullscreenHeader extends StatelessWidget {
  const _SalesLiveMapFullscreenHeader({required this.controller});

  final SalesLiveMapController controller;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SalesLiveMapController>.value(
      value: controller,
      child:
          Selector<SalesLiveMapController, _SalesLiveMapFullscreenHeaderSlice>(
            selector: (_, controller) =>
                _SalesLiveMapFullscreenHeaderSlice.fromState(controller.state),
            builder: (context, slice, _) {
              final l10n = AppLocalizations.of(context);
              final viewModel = SalesLiveMapViewModel.fromState(
                slice.state,
                l10n,
              );
              return AppChartFullscreenHeader(
                title: l10n.salesLiveMapChartTitle,
                subtitle: viewModel.mapSubtitle,
                filterSummary: viewModel.fullscreenFilterSummary,
              );
            },
          ),
    );
  }
}

class _SalesLiveMapFullscreenChart extends StatelessWidget {
  const _SalesLiveMapFullscreenChart({required this.controller});

  final SalesLiveMapController controller;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SalesLiveMapController>.value(
      value: controller,
      child: Selector<SalesLiveMapController, _SalesLiveMapMapSlice>(
        selector: (_, controller) =>
            _SalesLiveMapMapSlice.fromState(controller.state),
        builder: (context, slice, _) {
          return LayoutBuilder(
            builder: (context, _) {
              final tokens = Theme.of(context).extension<AppThemeTokens>()!;
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
                      points: slice.points,
                      initialMetric: slice.metric,
                      filterBranchIds: slice.filterBranchIds,
                      fixedBranchIds: slice.filterBranchIds,
                      style: slice.mapStyle,
                      onMetricChanged: controller.updateMetric,
                      showDesktopBranchSidebar: true,
                      presentationMode: AppBrazilStoreSalesMapPresentationMode
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
    );
  }
}

class _SalesLiveMapBodyStatusContent extends StatelessWidget {
  const _SalesLiveMapBodyStatusContent({
    required this.slice,
    required this.onRetryReload,
  });

  final _SalesLiveMapBodyStatusSlice slice;
  final VoidCallback onRetryReload;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final controller = context.read<SalesLiveMapController>();
    final state = slice.state;
    final result = state.result;
    final viewModel = SalesLiveMapViewModel.fromState(state, l10n);

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
            result.hasPartialIssue)
          Padding(
            padding: EdgeInsets.only(top: tokens.gapMd),
            child: _SalesLiveMapAttentionPanel(result: result),
          ),
        if (result?.loadFailed ?? false)
          Padding(
            padding: EdgeInsets.only(top: tokens.gapMd),
            child: AppInlineErrorPanel(
              title: l10n.salesLiveMapLoadErrorTitle,
              message: viewModel.loadErrorMessage,
              onRetry: state.canReload ? onRetryReload : null,
            ),
          ),
        if (state.shouldShowEmptyNotice && result != null)
          Padding(
            padding: EdgeInsets.only(top: tokens.gapMd),
            child: _SalesLiveMapEmptyNotice(
              result: result,
              hasSelectedBranches: state.hasSelectedBranchFilter,
              onClearSelectedBranches: () => unawaited(
                controller.clearSelectedBranches(),
              ),
              l10n: l10n,
            ),
          ),
      ],
    );
  }
}

class _SalesLiveMapInlineChartSection extends StatelessWidget {
  const _SalesLiveMapInlineChartSection({required this.onOpenFullscreen});

  final VoidCallback onOpenFullscreen;

  @override
  Widget build(BuildContext context) {
    return Selector<SalesLiveMapController, _SalesLiveMapMapSlice>(
      selector: (_, controller) =>
          _SalesLiveMapMapSlice.fromState(controller.state),
      builder: (context, slice, _) {
        final l10n = AppLocalizations.of(context);
        final controller = context.read<SalesLiveMapController>();
        final viewModel = SalesLiveMapViewModel.fromState(slice.state, l10n);
        return AppBrazilStoreSalesMapChart(
          title: l10n.salesLiveMapChartTitle,
          subtitle: viewModel.mapSubtitle,
          points: slice.points,
          initialMetric: slice.metric,
          filterBranchIds: slice.filterBranchIds,
          fixedBranchIds: slice.filterBranchIds,
          style: slice.mapStyle,
          presentationMode:
              AppBrazilStoreSalesMapPresentationMode.inlineOperational,
          onMetricChanged: controller.updateMetric,
          onOpenFullscreen: onOpenFullscreen,
        );
      },
    );
  }
}

@immutable
class _SalesLiveMapSchedulingSlice {
  const _SalesLiveMapSchedulingSlice({
    required this.isLoading,
    required this.canScheduleAutoRefresh,
  });

  factory _SalesLiveMapSchedulingSlice.fromState(
    SalesLiveMapPresentationState state,
  ) {
    return _SalesLiveMapSchedulingSlice(
      isLoading: state.isLoading,
      canScheduleAutoRefresh: state.canScheduleAutoRefresh,
    );
  }

  final bool isLoading;
  final bool canScheduleAutoRefresh;

  @override
  bool operator ==(Object other) {
    return other is _SalesLiveMapSchedulingSlice &&
        other.isLoading == isLoading &&
        other.canScheduleAutoRefresh == canScheduleAutoRefresh;
  }

  @override
  int get hashCode => Object.hash(isLoading, canScheduleAutoRefresh);
}

@immutable
class _SalesLiveMapAutoRefreshSlice {
  const _SalesLiveMapAutoRefreshSlice({
    required this.canReload,
    required this.canScheduleAutoRefresh,
    required this.showReloadProgress,
  });

  factory _SalesLiveMapAutoRefreshSlice.fromState(
    SalesLiveMapPresentationState state,
  ) {
    return _SalesLiveMapAutoRefreshSlice(
      canReload: state.canReload,
      canScheduleAutoRefresh: state.canScheduleAutoRefresh,
      showReloadProgress: state.isLoading && state.result != null,
    );
  }

  final bool canReload;
  final bool canScheduleAutoRefresh;
  final bool showReloadProgress;

  @override
  bool operator ==(Object other) {
    return other is _SalesLiveMapAutoRefreshSlice &&
        other.canReload == canReload &&
        other.canScheduleAutoRefresh == canScheduleAutoRefresh &&
        other.showReloadProgress == showReloadProgress;
  }

  @override
  int get hashCode => Object.hash(
    canReload,
    canScheduleAutoRefresh,
    showReloadProgress,
  );
}

@immutable
class _SalesLiveMapBodyStatusSlice {
  const _SalesLiveMapBodyStatusSlice({
    required this.state,
    required this.showInitialSkeleton,
  });

  factory _SalesLiveMapBodyStatusSlice.fromState(
    SalesLiveMapPresentationState state,
  ) {
    return _SalesLiveMapBodyStatusSlice(
      state: state,
      showInitialSkeleton: state.result == null && state.isLoading,
    );
  }

  final SalesLiveMapPresentationState state;
  final bool showInitialSkeleton;

  @override
  bool operator ==(Object other) {
    return other is _SalesLiveMapBodyStatusSlice &&
        identical(other.state.result, state.result) &&
        other.state.isLoading == state.isLoading &&
        other.state.sessionExpired == state.sessionExpired &&
        other.state.canReload == state.canReload &&
        other.state.hasSelectedBranchFilter == state.hasSelectedBranchFilter &&
        other.showInitialSkeleton == showInitialSkeleton;
  }

  @override
  int get hashCode => Object.hash(
    identityHashCode(state.result),
    state.isLoading,
    state.sessionExpired,
    state.canReload,
    state.hasSelectedBranchFilter,
    showInitialSkeleton,
  );
}

@immutable
class _SalesLiveMapFullscreenHeaderSlice {
  const _SalesLiveMapFullscreenHeaderSlice({required this.state});

  factory _SalesLiveMapFullscreenHeaderSlice.fromState(
    SalesLiveMapPresentationState state,
  ) {
    return _SalesLiveMapFullscreenHeaderSlice(state: state);
  }

  final SalesLiveMapPresentationState state;

  @override
  bool operator ==(Object other) {
    return other is _SalesLiveMapFullscreenHeaderSlice &&
        identical(other.state.result, state.result) &&
        other.state.filter == state.filter &&
        other.state.isLoading == state.isLoading;
  }

  @override
  int get hashCode => Object.hash(
    identityHashCode(state.result),
    state.filter,
    state.isLoading,
  );
}

@immutable
class _SalesLiveMapMapSlice {
  const _SalesLiveMapMapSlice({
    required this.state,
    required this.points,
    required this.mapPayloadDigest,
    required this.metric,
    required this.filterBranchIds,
    required this.mapStyle,
  });

  factory _SalesLiveMapMapSlice.fromState(SalesLiveMapPresentationState state) {
    final filterBranchIds = Set<String>.unmodifiable(
      state.filterBranchStorageKeys,
    );
    return _SalesLiveMapMapSlice(
      state: state,
      points: state.result?.points ?? const <AppBrazilStoreSalesPoint>[],
      mapPayloadDigest: state.mapPayloadDigest,
      metric: state.filter.metric,
      filterBranchIds: filterBranchIds,
      mapStyle: state.mapStyle,
    );
  }

  final SalesLiveMapPresentationState state;
  final List<AppBrazilStoreSalesPoint> points;
  final int mapPayloadDigest;
  final AppBrazilStoreSalesMapMetric metric;
  final Set<String> filterBranchIds;
  final AppBrazilStoreSalesMapStyle mapStyle;

  @override
  bool operator ==(Object other) {
    return other is _SalesLiveMapMapSlice &&
        other.mapPayloadDigest == mapPayloadDigest &&
        other.metric == metric &&
        setEquals(other.filterBranchIds, filterBranchIds) &&
        other.mapStyle == mapStyle;
  }

  @override
  int get hashCode => Object.hash(
    mapPayloadDigest,
    metric,
    Object.hashAll(filterBranchIds.toList(growable: false)..sort()),
    mapStyle,
  );
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

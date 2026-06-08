import 'dart:async';

import 'package:colmeia/app/refresh/app_auto_refresh_support.dart';
import 'package:colmeia/app/router/app_chart_fullscreen_routes.dart';
import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/app/router/chart_share_icon_button.dart';
import 'package:colmeia/core/layout/app_breakpoints.dart';
import 'package:colmeia/core/layout/app_responsive_spacing.dart';
import 'package:colmeia/core/refresh/auto_refresh_state_mixin.dart';
import 'package:colmeia/core/refresh/auto_refresh_state_persistence.dart';
import 'package:colmeia/core/refresh/auto_refresh_ui_state.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_filter.dart';
import 'package:colmeia/features/sales/presentation/auto_refresh/sales_auto_refresh_support.dart';
import 'package:colmeia/features/sales/presentation/auto_refresh/sales_live_map_auto_refresh_observer.dart';
import 'package:colmeia/features/sales/presentation/controllers/sales_live_map_controller.dart';
import 'package:colmeia/features/sales/presentation/coordinators/sales_live_map_session_coordinator.dart';
import 'package:colmeia/features/sales/presentation/view_models/sales_live_map_view_model.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_live_map_auto_refresh_section.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_live_map_body_section.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_live_map_chart_panel.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_live_map_filter_section.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_live_map_filters_sheet.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_live_map_fullscreen_chart.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_live_map_intro_section.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_live_map_retry_cooldown_snackbar.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
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
  late final SalesLiveMapAutoRefreshObserver _autoRefreshObserver;
  final SalesLiveMapSessionCoordinator _coordinator =
      SalesLiveMapSessionCoordinator();
  bool _lockPageScrollForInlineMap = false;
  int _inlineChartRemountKey = 0;

  @override
  void initState() {
    super.initState();
    _controller = context.read<SalesLiveMapController>();
    _autoRefreshObserver = SalesLiveMapAutoRefreshObserver(
      coordinator: _coordinator,
      readAutoRefreshOption: () => autoRefreshOption,
      readAutoRefreshNextDueAt: () => autoRefreshNextDueAt,
      readCurrentAutoRefreshTime: () => currentAutoRefreshTime,
      readAutoRefreshReloadInProgress: () => autoRefreshReloadInProgress,
      refreshAutoRefreshScheduling: refreshAutoRefreshScheduling,
      recordAutoRefreshSuccessfulReload: recordAutoRefreshSuccessfulReload,
      onCloseFullscreenRequested: _maybePopChartFullscreenAfterDataChanged,
    );
    _controller.addListener(_handleControllerChanged);
    _coordinator.lastCloseFullscreenRequestId =
        _controller.state.closeFullscreenRequestId;
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
  bool get canAutoRefreshWhileRouteHidden => _coordinator.liveMapFullscreenOpen;

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
  AutoRefreshPauseReason? resolveAutoRefreshPauseReason() =>
      SalesLiveMapViewModel.resolveAutoRefreshPauseReason(
        _controller.state,
        isOnRetryCooldown: _controller.isOnRetryCooldown,
      );

  Future<void> _reload({bool force = false}) async {
    _coordinator.markManualReload(force: force);
    try {
      await reloadWithAutoRefresh(force: force);
    } finally {
      _coordinator.clearPendingReloadIfNotConsumed();
    }
  }

  @override
  Future<void> performAutoRefreshReload() async {
    final pending = _coordinator.consumePendingReload();
    final outcome = await _controller.reload(
      force: pending.force,
      reason: pending.reason,
    );
    if (outcome.isBlockedByCooldown) {
      _coordinator.lastAutoRefreshReloadResult =
          const AutoRefreshReloadResult.cancelled();
      return;
    }
    final result = outcome.result;
    if (outcome.isCancelled || outcome.isSuperseded) {
      _coordinator.lastAutoRefreshReloadResult =
          const AutoRefreshReloadResult.cancelled();
      return;
    }
    if (result == null ||
        result.loadFailed ||
        result.cancelled ||
        result.salesDataPending ||
        result.refreshedAt == null) {
      _coordinator.lastAutoRefreshReloadResult =
          const AutoRefreshReloadResult.failure();
      return;
    }
    _coordinator.lastAutoRefreshReloadResult = AutoRefreshReloadResult.success(
      result.refreshedAt,
    );
  }

  @override
  AutoRefreshReloadResult resolveAutoRefreshReloadResult() =>
      _coordinator.lastAutoRefreshReloadResult;

  void _handleControllerChanged() {
    if (!mounted) {
      return;
    }
    _autoRefreshObserver.onControllerChanged(_controller.state);
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
        isApplyEnabled: !_controller.isOnRetryCooldown,
        onApply: (filter) => unawaited(_applyFilterFromSheet(filter)),
      ),
    );
  }

  Future<void> _applyFilterFromSheet(SalesLiveMapFilter filter) async {
    final outcome = await _controller.applyFilter(filter);
    if (!mounted) {
      return;
    }
    if (outcome == SalesLiveMapFilterMutationOutcome.blockedByCooldown) {
      showSalesLiveMapRetryCooldownSnackbar(
        context,
        _controller.retryAfterGate,
      );
    }
  }

  void _openLiveMapFullscreen() {
    if (_coordinator.liveMapFullscreenOpen) {
      return;
    }
    final router = GoRouter.maybeOf(context);
    if (router != null &&
        AppRoute.fromLocation(router.state.matchedLocation) ==
            AppRoute.chartFullscreen) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    final fullscreenShareKey = GlobalKey();
    final shareTitle = l10n.salesLiveMapChartTitle;
    _setLiveMapFullscreenOpen(true);

    Future<void>? pushFuture;
    try {
      pushFuture = context.pushChartFullscreen<void>(
        extra: AppChartFullscreenRouteExtra(
          chartSemanticsLabel: shareTitle,
          headerBuilder: (_) =>
              SalesLiveMapFullscreenHeader(controller: _controller),
          headerTrailing: buildChartFullscreenShareTrailing(
            context: context,
            shareKey: fullscreenShareKey,
            subject: shareTitle,
          ),
          chartBuilder: (_) => RepaintBoundary(
            key: fullscreenShareKey,
            child: SalesLiveMapFullscreenChart(controller: _controller),
          ),
        ),
      );
    } on Object {
      if (mounted) {
        _setLiveMapFullscreenOpen(false);
      }
      rethrow;
    }

    unawaited(
      pushFuture.whenComplete(() {
        if (!mounted) {
          return;
        }
        _setLiveMapFullscreenOpen(false);
      }),
    );
  }

  void _setLiveMapFullscreenOpen(bool isOpen) {
    if (_coordinator.liveMapFullscreenOpen == isOpen) {
      return;
    }
    final wasOpen = _coordinator.liveMapFullscreenOpen;
    _coordinator.liveMapFullscreenOpen = isOpen;
    if (!mounted) {
      return;
    }
    if (wasOpen && !isOpen) {
      _inlineChartRemountKey += 1;
    }
    setState(() {});
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
    final tokens = context.appTokens;

    final lockPageScroll =
        _lockPageScrollForInlineMap && AppBreakpoints.isMobile(context);

    return NotificationListener<SalesLiveMapParentScrollLockNotification>(
      onNotification: (notification) {
        if (_lockPageScrollForInlineMap == notification.lockParentScroll) {
          return true;
        }
        setState(() {
          _lockPageScrollForInlineMap = notification.lockParentScroll;
        });
        return true;
      },
      child: SingleChildScrollView(
        physics: lockPageScroll
            ? const NeverScrollableScrollPhysics()
            : const AlwaysScrollableScrollPhysics(),
        padding: context.pageScrollPadding(
          tokens,
          horizontalAdjustment:
              AppPageSpacingPresets.dashboardHorizontalAdjustment,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const SalesLiveMapIntroSection(),
            SizedBox(height: tokens.sectionSpacing),
            SalesLiveMapFilterSection(onOpenFilters: _openFiltersSheet),
            SizedBox(height: tokens.gapMd),
            SalesLiveMapAutoRefreshSection(
              onOptionChanged: setAutoRefreshOption,
              onRefreshNow: () => unawaited(_reload()),
              stateListenable: autoRefreshStateListenable,
            ),
            SizedBox(height: tokens.sectionSpacing),
            SalesLiveMapBodySection(
              onRetryReload: () => unawaited(_reload()),
              onOpenFullscreen: _openLiveMapFullscreen,
              hideInlineChart: _coordinator.liveMapFullscreenOpen,
              inlineChartRemountKey: _inlineChartRemountKey,
            ),
          ],
        ),
      ),
    );
  }
}

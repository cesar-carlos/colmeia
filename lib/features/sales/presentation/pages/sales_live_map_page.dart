import 'dart:async';

import 'package:colmeia/app/router/app_chart_fullscreen_routes.dart';
import 'package:colmeia/app/router/app_navigation.dart';
import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/core/di/injector.dart';
import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/core/layout/app_responsive_spacing.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/overview/domain/entities/overview_filter.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map_use_case.dart';
import 'package:colmeia/features/sales/data/sales_preferences.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_filter.dart';
import 'package:colmeia/features/sales/domain/load_available_agents_for_sales.dart';
import 'package:colmeia/features/sales/presentation/utils/sales_auto_refresh_state_mixin.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_auto_refresh_actions_row.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_card_filter_trigger.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_live_map_filters_sheet.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_live_map_kpi_grid.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_inline_error_panel.dart';
import 'package:colmeia/shared/widgets/app_section_card.dart';
import 'package:colmeia/shared/widgets/app_skeleton.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_chart.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_models.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_page_intro.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SalesLiveMapPage extends StatefulWidget {
  const SalesLiveMapPage({super.key});

  @override
  State<SalesLiveMapPage> createState() => _SalesLiveMapPageState();
}

class _SalesLiveMapPageState extends State<SalesLiveMapPage>
    with SalesAutoRefreshStateMixin<SalesLiveMapPage> {
  static const int _autoMunicipalityDetailPointThreshold = 200;

  late final SalesPreferences _prefs;
  late final LoadAvailableAgentsForSales _loadAgentsUseCase;
  late final LoadSalesLiveMapUseCase _loadLiveMap;

  List<OverviewAgentOption> _availableAgents = const <OverviewAgentOption>[];
  late SalesLiveMapFilter _filter;
  SalesLiveMapLoadResult? _result;
  bool _loading = true;
  int _loadGeneration = 0;
  SalesLiveMapLoadCancelToken? _activeLoadCancelToken;

  @override
  void initState() {
    super.initState();
    _prefs = getIt<SalesPreferences>();
    _loadAgentsUseCase = getIt<LoadAvailableAgentsForSales>();
    _loadLiveMap = getIt<LoadSalesLiveMapUseCase>();
    _filter = _prefs.restoreSalesLiveMapFilter();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_loadAgents());
    });
  }

  Future<void> _loadAgents() async {
    final stopwatch = _startTraceStopwatch();
    final auth = context.read<AuthController>();
    final userId = auth.session?.userId;
    if (userId == null) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _result = _sessionExpiredResult();
      });
      return;
    }

    final agents = await _loadAgentsUseCase(userId);
    _logTrace(
      'Sales live map agents loaded',
      <String, Object?>{
        'elapsedMs': stopwatch?.elapsedMilliseconds,
        'agentCount': agents.length,
        'missingTokenCount': agents
            .where((agent) => agent.missingLocalClientToken)
            .length,
      },
    );
    if (!mounted) {
      return;
    }

    final normalizedFilter = _filter.copyWith(
      selectedAgentIds: _normalizeSelectedAgentIds(
        agents: agents,
        selectedAgentIds: _filter.selectedAgentIds,
      ),
    );
    setState(() {
      _availableAgents = agents;
      _filter = normalizedFilter;
    });
    unawaited(_prefs.persistSalesLiveMapFilter(normalizedFilter));
    unawaited(_reload());
  }

  Set<String>? _normalizeSelectedAgentIds({
    required List<OverviewAgentOption> agents,
    required Set<String>? selectedAgentIds,
  }) {
    final tokenBacked = agents
        .where((agent) => !agent.missingLocalClientToken)
        .map((agent) => agent.agentId)
        .toSet();
    if (selectedAgentIds == null) {
      if (tokenBacked.isEmpty || tokenBacked.length == agents.length) {
        return null;
      }
      return Set<String>.unmodifiable(tokenBacked);
    }

    final reconciled = selectedAgentIds.where(tokenBacked.contains).toSet();
    if (reconciled.isEmpty) {
      return tokenBacked.isEmpty ? null : Set<String>.unmodifiable(tokenBacked);
    }
    if (reconciled.length == tokenBacked.length) {
      return tokenBacked.length == agents.length
          ? null
          : Set<String>.unmodifiable(reconciled);
    }
    return Set<String>.unmodifiable(reconciled);
  }

  Future<void> _reload({bool force = false}) {
    if (force) {
      _activeLoadCancelToken?.cancel();
    }
    return reloadWithSalesAutoRefresh(force: force);
  }

  @override
  bool get canScheduleSalesAutoRefresh => _hasRunnableAgent;

  bool get _hasRunnableAgent {
    final tokenBacked = _availableAgents
        .where((agent) => !agent.missingLocalClientToken)
        .map((agent) => agent.agentId)
        .toSet();
    if (tokenBacked.isEmpty) {
      return false;
    }
    final selected = _filter.selectedAgentIds;
    if (selected == null) {
      return true;
    }
    return selected.any(tokenBacked.contains);
  }

  @override
  Future<void> performSalesAutoRefreshReload() async {
    final auth = context.read<AuthController>();
    final userId = auth.session?.userId;
    final generation = ++_loadGeneration;
    final cancelToken = SalesLiveMapLoadCancelToken();
    final hadResultBeforeReload = _result != null;
    _activeLoadCancelToken = cancelToken;

    setState(() {
      _loading = true;
    });

    if (userId == null) {
      if (!mounted || generation != _loadGeneration) {
        return;
      }
      if (identical(_activeLoadCancelToken, cancelToken)) {
        _activeLoadCancelToken = null;
      }
      setState(() {
        _loading = false;
        _result = _sessionExpiredResult();
      });
      return;
    }

    var emittedAnyResult = false;
    await for (final result in _loadLiveMap.loadProgressive(
      userId: userId,
      filter: _filter,
      cancelToken: cancelToken,
    )) {
      if (!mounted || generation != _loadGeneration) {
        return;
      }
      emittedAnyResult = true;
      if (result.cancelled) {
        if (identical(_activeLoadCancelToken, cancelToken)) {
          _activeLoadCancelToken = null;
        }
        setState(() {
          _loading = false;
        });
        return;
      }
      if (hadResultBeforeReload && result.salesDataPending) {
        continue;
      }

      setState(() {
        _result = result;
        _loading = result.salesDataPending;
      });
      if (!result.salesDataPending && result.loadFailed) {
        disableSalesAutoRefresh();
      }
    }

    if (!mounted || generation != _loadGeneration) {
      return;
    }
    if (identical(_activeLoadCancelToken, cancelToken)) {
      _activeLoadCancelToken = null;
    }
    if (!emittedAnyResult) {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _activeLoadCancelToken?.cancel();
    super.dispose();
  }

  void _openLiveMapFullscreen() {
    final pageL10n = AppLocalizations.of(context);
    final resultSnapshot = _result;
    final pointsSnapshot = List<AppBrazilStoreSalesPoint>.of(
      resultSnapshot?.points ?? const <AppBrazilStoreSalesPoint>[],
      growable: false,
    );
    final subtitleSnapshot = _mapSubtitle(resultSnapshot);
    final initialMetricSnapshot = _filter.metric;
    final detailSnapshot = _effectiveDetailLevel(resultSnapshot);
    final markerVisualSnapshot = _filter.markerVisual;
    final styleSnapshot = _mapStyle(
      detailLevel: detailSnapshot,
      markerVisual: markerVisualSnapshot,
    );
    final filterSummarySnapshot = _liveMapFullscreenFilterSummary(pageL10n);

    unawaited(
      context.pushChartFullscreen<void>(
        extra: AppChartFullscreenRouteExtra(
          title: pageL10n.salesLiveMapChartTitle,
          subtitle: subtitleSnapshot,
          filterSummary: filterSummarySnapshot,
          chartSemanticsLabel: pageL10n.salesLiveMapChartTitle,
          chartBuilder: (_) {
            return LayoutBuilder(
              builder: (context, _) {
                final tokens = Theme.of(
                  context,
                ).extension<AppThemeTokens>()!;
                return AppSectionCard(
                  padding: EdgeInsets.all(tokens.contentSpacing),
                  child: LayoutBuilder(
                    builder: (context, cardConstraints) {
                      Widget chart = AppBrazilStoreSalesMapChart(
                        points: pointsSnapshot,
                        initialMetric: initialMetricSnapshot,
                        style: styleSnapshot,
                        onMetricChanged: _onMapMetricChanged,
                        onBranchFilter: _filterByMapBranch,
                      );
                      final maxH = cardConstraints.maxHeight;
                      if (maxH.isFinite && maxH < double.infinity) {
                        chart = SizedBox(
                          height: maxH,
                          child: chart,
                        );
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

  String _liveMapFullscreenFilterSummary(AppLocalizations l10n) {
    final parts = <String>[
      '${l10n.salesLiveMapAgentsLabel}: ${_filiaisSummary(_result)}',
      '${l10n.salesLiveMapPeriodLabel}: ${_periodSummary()}',
      '${l10n.salesLiveMapDetailLabel}: ${_detailLabel(_filter.detailLevel)}',
    ];
    if (_filter.detailLevel != SalesLiveMapMapDetail.states) {
      parts.add(
        '${l10n.salesLiveMapVisualLabel}: ${_visualLabel(_filter.markerVisual)}',
      );
    } else {
      parts.add(
        '${l10n.salesLiveMapMapLabel}: ${_visualLabel(SalesLiveMapMarkerVisual.bubble)}',
      );
    }
    return '${parts.join(' · ')} · ${l10n.chartFullscreenDataSnapshotHint}';
  }

  Future<void> _openFiltersSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: false,
      builder: (context) => SalesLiveMapFiltersSheet(
        l10n: AppLocalizations.of(context),
        availableAgents: _availableAgents,
        availableBranches:
            _result?.branchOptions ?? const <SalesLiveMapBranchOption>[],
        initialFilter: _filter,
        onApply: _onFilterChanged,
      ),
    );
  }

  void _onFilterChanged(SalesLiveMapFilter filter) {
    final normalizedFilter = _normalizeFilterForSelectedBranches(filter);
    setState(() {
      _filter = normalizedFilter;
    });
    unawaited(_prefs.persistSalesLiveMapFilter(normalizedFilter));
    if (!canScheduleSalesAutoRefresh) {
      disableSalesAutoRefresh();
    }
    unawaited(_reload(force: true));
  }

  void _clearSelectedBranches() {
    final next = _filter.copyWith(
      selectedAgentIds: null,
      selectedBranchIds: null,
    );
    setState(() {
      _filter = next;
    });
    unawaited(_prefs.persistSalesLiveMapFilter(next));
    unawaited(_reload(force: true));
  }

  void _clearSavedFilters() {
    const next = SalesLiveMapFilter();
    setState(() {
      _filter = next;
    });
    unawaited(_prefs.persistSalesLiveMapFilter(next));
    if (!canScheduleSalesAutoRefresh) {
      disableSalesAutoRefresh();
    }
    unawaited(_reload(force: true));
  }

  void _filterByMapBranch(AppBrazilStoreSalesPointTapEvent event) {
    final next = _normalizeFilterForSelectedBranches(
      _filter.copyWith(
        selectedBranchIds: <String>{event.point.id},
        detailLevel: SalesLiveMapMapDetail.branches,
      ),
    );
    setState(() {
      _filter = next;
    });
    unawaited(_prefs.persistSalesLiveMapFilter(next));
    unawaited(_reload(force: true));
  }

  SalesLiveMapFilter _normalizeFilterForSelectedBranches(
    SalesLiveMapFilter filter,
  ) {
    final selectedBranchIds = filter.selectedBranchIds;
    if (selectedBranchIds == null || selectedBranchIds.isEmpty) {
      return filter.copyWith(selectedAgentIds: null);
    }

    final branches =
        _result?.branchOptions ?? const <SalesLiveMapBranchOption>[];
    final selectedAgents = branches
        .where((branch) => selectedBranchIds.contains(branch.id))
        .map((branch) => branch.agentId)
        .toSet();
    if (selectedAgents.isEmpty) {
      return filter;
    }

    return filter.copyWith(
      selectedAgentIds: Set<String>.unmodifiable(selectedAgents),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final result = _result;

    return SingleChildScrollView(
      padding: context.pageScrollPadding(
        tokens,
        horizontalAdjustment:
            AppPageSpacingPresets.dashboardHorizontalAdjustment,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppShellPageIntro(
            sectionLabel: l10n.salesHubTitle,
            onSectionLabelTap: () => context.goTo(AppRoute.sales),
            title: l10n.salesLiveMapTitle,
            subtitle: l10n.salesLiveMapSubtitle,
          ),
          SizedBox(height: tokens.sectionSpacing),
          SalesCardFilterTrigger(
            onTap: () => unawaited(_openFiltersSheet()),
            buttonSemanticsLabel: l10n.reportFiltersButton,
            summaryItems: <SalesCardFilterSummaryItem>[
              SalesCardFilterSummaryItem(
                label: l10n.salesLiveMapAgentsLabel,
                value: _filiaisSummary(result),
              ),
              SalesCardFilterSummaryItem(
                label: l10n.salesLiveMapPeriodLabel,
                value: _periodSummary(),
              ),
              SalesCardFilterSummaryItem(
                label: l10n.salesLiveMapDetailLabel,
                value: _detailLabel(_filter.detailLevel),
              ),
              if (_filter.detailLevel != SalesLiveMapMapDetail.states)
                SalesCardFilterSummaryItem(
                  label: l10n.salesLiveMapVisualLabel,
                  value: _visualLabel(_filter.markerVisual),
                ),
              if (_filter.detailLevel == SalesLiveMapMapDetail.states)
                SalesCardFilterSummaryItem(
                  label: l10n.salesLiveMapMapLabel,
                  value: _visualLabel(SalesLiveMapMarkerVisual.bubble),
                ),
            ],
            enabled: !_loading,
          ),
          if (_hasNonDefaultFilter) ...<Widget>[
            SizedBox(height: tokens.gapSm),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: _loading ? null : _clearSavedFilters,
                icon: const Icon(Icons.filter_alt_off_rounded),
                label: Text(l10n.salesLiveMapClearSavedFiltersAction),
              ),
            ),
          ],
          SizedBox(height: tokens.gapMd),
          SalesAutoRefreshActionsRow(
            value: salesAutoRefreshInterval,
            onChanged: setSalesAutoRefreshInterval,
            onRefreshNow: () => unawaited(_reload()),
            enabled: canScheduleSalesAutoRefresh,
            lastUpdatedAt: salesAutoRefreshLastUpdatedAt,
            l10n: l10n,
          ),
          if (_loading && result != null) ...<Widget>[
            SizedBox(height: tokens.gapSm),
            const LinearProgressIndicator(minHeight: 2),
          ],
          SizedBox(height: tokens.sectionSpacing),
          if (result == null && _loading)
            _SalesLiveMapInitialSkeleton()
          else ...<Widget>[
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
                message: _loadErrorMessage(result, l10n),
                onRetry: () => unawaited(_reload()),
              ),
            ],
            if (_shouldShowEmptyNotice(result)) ...<Widget>[
              SizedBox(height: tokens.gapMd),
              _SalesLiveMapEmptyNotice(
                result: result!,
                hasSelectedBranches:
                    _filter.selectedBranchIds?.isNotEmpty ?? false,
                onClearSelectedBranches: _clearSelectedBranches,
                l10n: l10n,
              ),
            ],
            SizedBox(height: tokens.gapMd),
            _SalesLiveMapTechnicalDiagnosticsPanel(
              filter: _filter,
              result: result,
              periodLabel: _periodSummary(),
              detailLabel: _detailLabel(_filter.detailLevel),
              visualLabel: _filter.detailLevel == SalesLiveMapMapDetail.states
                  ? _visualLabel(SalesLiveMapMarkerVisual.bubble)
                  : _visualLabel(_filter.markerVisual),
              metricLabel: _metricLabel(_filter.metric),
            ),
            SizedBox(height: tokens.sectionSpacing),
            AppBrazilStoreSalesMapChart(
              title: l10n.salesLiveMapChartTitle,
              subtitle: _mapSubtitle(result),
              points: result?.points ?? const <AppBrazilStoreSalesPoint>[],
              initialMetric: _filter.metric,
              style: _mapStyle(
                detailLevel: _effectiveDetailLevel(result),
                markerVisual: _filter.markerVisual,
              ),
              onMetricChanged: _onMapMetricChanged,
              onBranchFilter: _filterByMapBranch,
              onOpenFullscreen: _openLiveMapFullscreen,
            ),
          ],
        ],
      ),
    );
  }

  String _filiaisSummary(SalesLiveMapLoadResult? result) {
    final l10n = AppLocalizations.of(context);
    final branchOptions =
        result?.branchOptions ?? const <SalesLiveMapBranchOption>[];
    if (branchOptions.isEmpty) {
      if (result != null && !_loading) {
        return l10n.salesLiveMapAgentsNoneSummary;
      }
      if (_availableAgents.isEmpty) {
        return l10n.salesLiveMapAgentsLoadingSummary;
      }
      return l10n.salesLiveMapAgentsLoadingSummary;
    }
    final selected = _filter.selectedBranchIds;
    if (selected == null) {
      return l10n.salesLiveMapAgentsAllWithTokenSummary(branchOptions.length);
    }
    return l10n.salesLiveMapAgentsSelectedSummary(selected.length);
  }

  bool _shouldShowEmptyNotice(SalesLiveMapLoadResult? result) {
    if (result == null ||
        result.salesDataPending ||
        result.loadFailed ||
        result.hasPartialIssue) {
      return false;
    }
    return result.totalSalesCount == 0 || result.totalBranchCount == 0;
  }

  bool get _hasNonDefaultFilter {
    const defaults = SalesLiveMapFilter();
    return _filter.selectedAgentIds != defaults.selectedAgentIds ||
        _filter.selectedBranchIds != defaults.selectedBranchIds ||
        _filter.periodMode != defaults.periodMode ||
        _filter.customDateRange != defaults.customDateRange ||
        _filter.detailLevel != defaults.detailLevel ||
        _filter.markerVisual != defaults.markerVisual ||
        _filter.metric != defaults.metric;
  }

  SalesLiveMapLoadResult _sessionExpiredResult() {
    return SalesLiveMapLoadResult(
      points: const <AppBrazilStoreSalesPoint>[],
      branchOptions: const <SalesLiveMapBranchOption>[],
      totalRevenue: 0,
      totalSalesCount: 0,
      totalBranchCount: 0,
      mappedBranchCount: 0,
      mappedMunicipalityCount: 0,
      queriedAgentCount: 0,
      plannedAgentCount: 0,
      failedAgentCount: 0,
      missingClientTokenAgentCount: 0,
      skippedOfflineAgentCount: 0,
      rowCapReachedAgentCount: 0,
      loadFailed: true,
      loadFailureMessage: AppLocalizations.of(
        context,
      ).salesLiveMapSessionExpiredMessage,
      refreshedAt: DateTime.now(),
    );
  }

  Stopwatch? _startTraceStopwatch() {
    if (!_shouldTracePerformance) {
      return null;
    }
    return Stopwatch()..start();
  }

  void _logTrace(String message, Map<String, Object?> context) {
    if (!_shouldTracePerformance) {
      return;
    }
    AppLogger.info(
      message,
      context: <String, Object?>{
        'operation': 'SalesLiveMapPage',
        ...context,
      },
    );
  }

  bool get _shouldTracePerformance => kDebugMode || kProfileMode;

  String _loadErrorMessage(
    SalesLiveMapLoadResult? result,
    AppLocalizations l10n,
  ) {
    return switch (result?.loadFailureReason) {
      SalesLiveMapLoadFailureReason.missingClientTokenSetup =>
        l10n.salesLiveMapMissingClientTokenSetupMessage,
      null =>
        result?.loadFailureMessage ?? l10n.salesLiveMapLoadErrorRetryMessage,
    };
  }

  void _onMapMetricChanged(AppBrazilStoreSalesMapMetric metric) {
    if (_filter.metric == metric) {
      return;
    }
    final next = _filter.copyWith(metric: metric);
    setState(() {
      _filter = next;
    });
    unawaited(_prefs.persistSalesLiveMapFilter(next));
  }

  String _periodSummary() {
    final l10n = AppLocalizations.of(context);
    final range = _filter.resolveDateRange();
    final rangeLabel =
        '${AppBrFormatters.shortDate(range.startInclusive)} a ${AppBrFormatters.shortDate(range.endInclusive)}';
    return switch (_filter.periodMode) {
      SalesLiveMapPeriodMode.today => l10n.salesLiveMapPeriodToday,
      SalesLiveMapPeriodMode.lastSevenDays =>
        l10n.salesLiveMapPeriodLastSevenDays,
      SalesLiveMapPeriodMode.currentMonth =>
        l10n.salesLiveMapPeriodCurrentMonth,
      SalesLiveMapPeriodMode.customRange => rangeLabel,
    };
  }

  String _mapSubtitle(SalesLiveMapLoadResult? result) {
    final l10n = AppLocalizations.of(context);
    final range = _filter.resolveDateRange();
    final period =
        '${AppBrFormatters.shortDate(range.startInclusive)} a ${AppBrFormatters.shortDate(range.endInclusive)}';
    if (result == null || result.salesDataPending) {
      return l10n.salesLiveMapChartSubtitlePending(period);
    }
    final baseSubtitle = l10n.salesLiveMapChartSubtitleLoaded(
      period,
      result.mappedBranchCount,
      result.totalBranchCount,
    );
    if (_effectiveDetailLevel(result) == SalesLiveMapMapDetail.municipalities &&
        _filter.detailLevel == SalesLiveMapMapDetail.branches) {
      return '$baseSubtitle ${l10n.salesLiveMapDetailAutoMunicipalities(_autoMunicipalityDetailPointThreshold)}';
    }
    return baseSubtitle;
  }

  SalesLiveMapMapDetail _effectiveDetailLevel(SalesLiveMapLoadResult? result) {
    if (_filter.detailLevel == SalesLiveMapMapDetail.branches &&
        (result?.mappedBranchCount ?? 0) >
            _autoMunicipalityDetailPointThreshold) {
      return SalesLiveMapMapDetail.municipalities;
    }
    return _filter.detailLevel;
  }

  AppBrazilStoreSalesMapStyle _mapStyle({
    required SalesLiveMapMapDetail detailLevel,
    required SalesLiveMapMarkerVisual markerVisual,
  }) {
    final resolvedVisual = detailLevel == SalesLiveMapMapDetail.states
        ? SalesLiveMapMarkerVisual.bubble
        : markerVisual;
    final appMarkerVisual = switch (resolvedVisual) {
      SalesLiveMapMarkerVisual.dot => AppBrazilStoreSalesMarkerVisual.dot,
      SalesLiveMapMarkerVisual.bubble => AppBrazilStoreSalesMarkerVisual.bubble,
      SalesLiveMapMarkerVisual.storeIcon =>
        AppBrazilStoreSalesMarkerVisual.storeIcon,
    };
    final aggregation = switch (detailLevel) {
      SalesLiveMapMapDetail.branches =>
        AppBrazilStoreSalesMarkerAggregation.stores,
      SalesLiveMapMapDetail.municipalities =>
        AppBrazilStoreSalesMarkerAggregation.municipalities,
      SalesLiveMapMapDetail.states =>
        AppBrazilStoreSalesMarkerAggregation.states,
    };
    final (minSize, maxSize) = switch (resolvedVisual) {
      SalesLiveMapMarkerVisual.dot => (10.0, 24.0),
      SalesLiveMapMarkerVisual.bubble =>
        detailLevel == SalesLiveMapMapDetail.states
            ? (30.0, 76.0)
            : (34.0, 82.0),
      SalesLiveMapMarkerVisual.storeIcon => (24.0, 34.0),
    };

    return AppBrazilStoreSalesMapStyle(
      height: 560,
      markerVisual: appMarkerVisual,
      markerAggregation: aggregation,
      markerMinSize: minSize,
      markerMaxSize: maxSize,
      maxClusterTooltipStores:
          detailLevel == SalesLiveMapMapDetail.municipalities ? 8 : 5,
      showStoreDetail: detailLevel != SalesLiveMapMapDetail.states,
      enableProximityCluster: detailLevel == SalesLiveMapMapDetail.branches,
      stateLabelMode: AppBrazilStoreSalesStateLabelMode.responsive,
    );
  }

  String _detailLabel(SalesLiveMapMapDetail detailLevel) {
    final l10n = AppLocalizations.of(context);
    return switch (detailLevel) {
      SalesLiveMapMapDetail.branches => l10n.salesLiveMapDetailBranches,
      SalesLiveMapMapDetail.municipalities =>
        l10n.salesLiveMapDetailMunicipalities,
      SalesLiveMapMapDetail.states => l10n.salesLiveMapDetailStates,
    };
  }

  String _visualLabel(SalesLiveMapMarkerVisual visual) {
    final l10n = AppLocalizations.of(context);
    return switch (visual) {
      SalesLiveMapMarkerVisual.dot => l10n.salesLiveMapVisualDot,
      SalesLiveMapMarkerVisual.bubble => l10n.salesLiveMapVisualBubble,
      SalesLiveMapMarkerVisual.storeIcon => l10n.salesLiveMapVisualStoreIcon,
    };
  }

  String _metricLabel(AppBrazilStoreSalesMapMetric metric) {
    final l10n = AppLocalizations.of(context);
    return switch (metric) {
      AppBrazilStoreSalesMapMetric.revenue => l10n.salesLiveMapKpiRevenue,
      AppBrazilStoreSalesMapMetric.salesCount => l10n.salesLiveMapKpiSales,
    };
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
            ),
          ),
        ],
      ),
    );
  }
}

class _SalesLiveMapTechnicalDiagnosticsPanel extends StatelessWidget {
  const _SalesLiveMapTechnicalDiagnosticsPanel({
    required this.filter,
    required this.result,
    required this.periodLabel,
    required this.detailLabel,
    required this.visualLabel,
    required this.metricLabel,
  });

  final SalesLiveMapFilter filter;
  final SalesLiveMapLoadResult? result;
  final String periodLabel;
  final String detailLabel;
  final String visualLabel;
  final String metricLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final colorScheme = Theme.of(context).colorScheme;
    final diagnostics = result?.locationDiagnostics;

    return AppSectionCard(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.contentSpacing,
        vertical: tokens.gapSm,
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: EdgeInsets.only(bottom: tokens.gapSm),
          leading: Icon(
            Icons.manage_search_rounded,
            color: colorScheme.primary,
          ),
          title: Text(l10n.salesLiveMapTechnicalDiagnosticsTitle),
          children: <Widget>[
            _SalesLiveMapDiagnosticsSection(
              title: l10n.salesLiveMapTechnicalDiagnosticsFilters,
              rows: <_SalesLiveMapDiagnosticsRowData>[
                _SalesLiveMapDiagnosticsRowData(
                  label: 'selectedAgentIds',
                  value: _selectedSetLabel(filter.selectedAgentIds),
                ),
                _SalesLiveMapDiagnosticsRowData(
                  label: 'selectedBranchIds',
                  value: _selectedSetLabel(filter.selectedBranchIds),
                ),
                _SalesLiveMapDiagnosticsRowData(
                  label: 'period',
                  value: '${filter.periodMode.name} ($periodLabel)',
                ),
                _SalesLiveMapDiagnosticsRowData(
                  label: 'detailLevel',
                  value: '${filter.detailLevel.name} ($detailLabel)',
                ),
                _SalesLiveMapDiagnosticsRowData(
                  label: 'markerVisual',
                  value: '${filter.markerVisual.name} ($visualLabel)',
                ),
                _SalesLiveMapDiagnosticsRowData(
                  label: 'metric',
                  value: '${filter.metric.name} ($metricLabel)',
                ),
              ],
            ),
            SizedBox(height: tokens.gapMd),
            _SalesLiveMapDiagnosticsSection(
              title: l10n.salesLiveMapTechnicalDiagnosticsQuery,
              rows: <_SalesLiveMapDiagnosticsRowData>[
                _SalesLiveMapDiagnosticsRowData(
                  label: 'plannedAgentCount',
                  value: _countLabel(result?.plannedAgentCount),
                ),
                _SalesLiveMapDiagnosticsRowData(
                  label: 'queriedAgentCount',
                  value: _countLabel(result?.queriedAgentCount),
                ),
                _SalesLiveMapDiagnosticsRowData(
                  label: 'salesAgentCount',
                  value: _countLabel(result?.salesAgentCount),
                ),
                _SalesLiveMapDiagnosticsRowData(
                  label: 'catalogBranchCount',
                  value: _countLabel(result?.catalogBranchCount),
                ),
                _SalesLiveMapDiagnosticsRowData(
                  label: 'salesBranchCount',
                  value: _countLabel(result?.salesBranchCount),
                ),
                _SalesLiveMapDiagnosticsRowData(
                  label: 'salesPendingBranchCount',
                  value: _countLabel(result?.salesPendingBranchCount),
                ),
                _SalesLiveMapDiagnosticsRowData(
                  label: 'zeroedBranchCount',
                  value: _countLabel(result?.zeroedBranchCount),
                ),
                _SalesLiveMapDiagnosticsRowData(
                  label: 'noSalesBranchCount',
                  value: _countLabel(result?.noSalesBranchCount),
                ),
                _SalesLiveMapDiagnosticsRowData(
                  label: 'salesUnavailableBranchCount',
                  value: _countLabel(result?.salesUnavailableBranchCount),
                ),
                _SalesLiveMapDiagnosticsRowData(
                  label: 'noSalesAgentCount',
                  value: _countLabel(result?.noSalesAgentOptions.length),
                ),
                _SalesLiveMapDiagnosticsRowData(
                  label: 'failedCatalogAgentCount',
                  value: _countLabel(result?.failedCatalogAgentCount),
                ),
                _SalesLiveMapDiagnosticsRowData(
                  label: 'failedSalesAgentCount',
                  value: _countLabel(result?.failedSalesAgentCount),
                ),
                _SalesLiveMapDiagnosticsRowData(
                  label: 'failedAgentCount',
                  value: _countLabel(result?.failedAgentCount),
                ),
                _SalesLiveMapDiagnosticsRowData(
                  label: 'missingClientTokenAgentCount',
                  value: _countLabel(result?.missingClientTokenAgentCount),
                ),
                _SalesLiveMapDiagnosticsRowData(
                  label: 'skippedOfflineAgentCount',
                  value: _countLabel(result?.skippedOfflineAgentCount),
                ),
                _SalesLiveMapDiagnosticsRowData(
                  label: 'rowCapReachedAgentCount',
                  value: _countLabel(result?.rowCapReachedAgentCount),
                ),
                _SalesLiveMapDiagnosticsRowData(
                  label: 'branches',
                  value:
                      '${_countLabel(result?.mappedBranchCount)}/${_countLabel(result?.totalBranchCount)}',
                ),
                _SalesLiveMapDiagnosticsRowData(
                  label: 'mappedMunicipalityCount',
                  value: _countLabel(result?.mappedMunicipalityCount),
                ),
                _SalesLiveMapDiagnosticsRowData(
                  label: 'geo.providedGeoPoint',
                  value: _countLabel(
                    diagnostics?.resolvedByProvidedGeoPointCount,
                  ),
                ),
                _SalesLiveMapDiagnosticsRowData(
                  label: 'geo.ibgeMunicipalityCode',
                  value: _countLabel(
                    diagnostics?.resolvedByIbgeMunicipalityCodeCount,
                  ),
                ),
                _SalesLiveMapDiagnosticsRowData(
                  label: 'geo.cep',
                  value: _countLabel(diagnostics?.resolvedByCepCount),
                ),
                _SalesLiveMapDiagnosticsRowData(
                  label: 'geo.cityUf',
                  value: _countLabel(diagnostics?.resolvedByCityUfCount),
                ),
                _SalesLiveMapDiagnosticsRowData(
                  label: 'geo.capitalUf',
                  value: _countLabel(diagnostics?.resolvedByCapitalUfCount),
                ),
                _SalesLiveMapDiagnosticsRowData(
                  label: 'geo.stateUf',
                  value: _countLabel(diagnostics?.resolvedByStateUfCount),
                ),
                _SalesLiveMapDiagnosticsRowData(
                  label: 'geo.unknown',
                  value: _countLabel(diagnostics?.unknownResolutionCount),
                ),
                _SalesLiveMapDiagnosticsRowData(
                  label: 'geo.unresolvedBranch',
                  value: _countLabel(diagnostics?.unresolvedBranchCount),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _selectedSetLabel(Set<String>? values) {
    if (values == null) {
      return 'all';
    }
    if (values.isEmpty) {
      return '[]';
    }
    final sorted = values.toList(growable: false)..sort();
    return sorted.join(', ');
  }

  String _countLabel(int? value) {
    return value?.toString() ?? '-';
  }
}

class _SalesLiveMapDiagnosticsSection extends StatelessWidget {
  const _SalesLiveMapDiagnosticsSection({
    required this.title,
    required this.rows,
  });

  final String title;
  final List<_SalesLiveMapDiagnosticsRowData> rows;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final colorScheme = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(bottom: tokens.gapXs),
            child: Text(
              title,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Wrap(
            spacing: tokens.gapSm,
            runSpacing: tokens.gapSm,
            children: <Widget>[
              for (final row in rows) _SalesLiveMapDiagnosticsChip(row: row),
            ],
          ),
        ],
      ),
    );
  }
}

class _SalesLiveMapDiagnosticsChip extends StatelessWidget {
  const _SalesLiveMapDiagnosticsChip({required this.row});

  final _SalesLiveMapDiagnosticsRowData row;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: tokens.gapSm,
          vertical: tokens.gapXs,
        ),
        child: Text.rich(
          TextSpan(
            children: <InlineSpan>[
              TextSpan(
                text: '${row.label}: ',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              TextSpan(text: row.value),
            ],
          ),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _SalesLiveMapDiagnosticsRowData {
  const _SalesLiveMapDiagnosticsRowData({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;
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
                    agent.name,
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
    return '${branch.name} - $location - ${branch.agentName}';
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

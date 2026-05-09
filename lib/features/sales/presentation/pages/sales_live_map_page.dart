import 'dart:async';

import 'package:colmeia/app/router/app_navigation.dart';
import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/core/di/injector.dart';
import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/core/layout/app_responsive_spacing.dart';
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
import 'package:colmeia/shared/widgets/app_skeleton.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_chart.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_models.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_page_intro.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SalesLiveMapPage extends StatefulWidget {
  const SalesLiveMapPage({super.key});

  @override
  State<SalesLiveMapPage> createState() => _SalesLiveMapPageState();
}

class _SalesLiveMapPageState extends State<SalesLiveMapPage>
    with SalesAutoRefreshStateMixin<SalesLiveMapPage> {
  late final SalesPreferences _prefs;
  late final LoadAvailableAgentsForSales _loadAgentsUseCase;
  late final LoadSalesLiveMapUseCase _loadLiveMap;

  List<OverviewAgentOption> _availableAgents = const <OverviewAgentOption>[];
  late SalesLiveMapFilter _filter;
  SalesLiveMapLoadResult? _result;
  bool _loading = false;
  int _loadGeneration = 0;

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
    final auth = context.read<AuthController>();
    final userId = auth.session?.userId;
    if (userId == null) {
      return;
    }

    final agents = await _loadAgentsUseCase(userId);
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

  Future<void> _reload() => reloadWithSalesAutoRefresh();

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

    setState(() {
      _loading = true;
    });

    if (userId == null) {
      if (!mounted || generation != _loadGeneration) {
        return;
      }
      setState(() {
        _loading = false;
        _result = SalesLiveMapLoadResult(
          points: const <AppBrazilStoreSalesPoint>[],
          totalRevenue: 0,
          totalSalesCount: 0,
          totalBranchCount: 0,
          mappedBranchCount: 0,
          queriedAgentCount: 0,
          plannedAgentCount: 0,
          failedAgentCount: 0,
          missingClientTokenAgentCount: 0,
          skippedOfflineAgentCount: 0,
          loadFailed: true,
          loadFailureMessage: AppLocalizations.of(
            context,
          ).salesLiveMapSessionExpiredMessage,
          refreshedAt: DateTime.now(),
        );
      });
      return;
    }

    final result = await _loadLiveMap(
      userId: userId,
      filter: _filter,
    );
    if (!mounted || generation != _loadGeneration) {
      return;
    }

    setState(() {
      _result = result;
      _loading = false;
    });
    if (result.loadFailed) {
      disableSalesAutoRefresh();
    }
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
        initialFilter: _filter,
        onApply: _onFilterChanged,
      ),
    );
  }

  void _onFilterChanged(SalesLiveMapFilter filter) {
    setState(() {
      _filter = filter;
    });
    unawaited(_prefs.persistSalesLiveMapFilter(filter));
    if (!canScheduleSalesAutoRefresh) {
      disableSalesAutoRefresh();
    }
    unawaited(_reload());
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
                value: _filiaisSummary(),
              ),
              SalesCardFilterSummaryItem(
                label: l10n.salesLiveMapPeriodLabel,
                value: _periodSummary(),
              ),
              SalesCardFilterSummaryItem(
                label: l10n.salesLiveMapMapLabel,
                value: _mapPresetLabel(_filter.mapPreset),
              ),
            ],
            enabled: !_loading,
          ),
          SizedBox(height: tokens.gapMd),
          SalesAutoRefreshActionsRow(
            value: salesAutoRefreshInterval,
            onChanged: setSalesAutoRefreshInterval,
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
            if (result != null) SalesLiveMapKpiGrid(result: result),
            if (result != null && result.hasPartialIssue) ...<Widget>[
              SizedBox(height: tokens.gapMd),
              _SalesLiveMapAttentionPanel(result: result),
            ],
            if (result?.loadFailed ?? false) ...<Widget>[
              SizedBox(height: tokens.gapMd),
              AppInlineErrorPanel(
                title: l10n.salesLiveMapLoadErrorTitle,
                message:
                    result?.loadFailureMessage ??
                    l10n.salesLiveMapLoadErrorRetryMessage,
                onRetry: () => unawaited(_reload()),
              ),
            ],
            SizedBox(height: tokens.sectionSpacing),
            AppBrazilStoreSalesMapChart(
              title: l10n.salesLiveMapChartTitle,
              subtitle: _mapSubtitle(result),
              points: result?.points ?? const <AppBrazilStoreSalesPoint>[],
              style: _mapStyle(_filter.mapPreset),
            ),
          ],
        ],
      ),
    );
  }

  String _filiaisSummary() {
    final l10n = AppLocalizations.of(context);
    if (_availableAgents.isEmpty) {
      return l10n.salesLiveMapAgentsLoadingSummary;
    }
    final selected = _filter.selectedAgentIds;
    final tokenBackedCount = _availableAgents
        .where((agent) => !agent.missingLocalClientToken)
        .length;
    if (selected == null) {
      return l10n.salesLiveMapAgentsAllWithTokenSummary(tokenBackedCount);
    }
    return l10n.salesLiveMapAgentsSelectedSummary(selected.length);
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
    if (result == null) {
      return l10n.salesLiveMapChartSubtitlePending(period);
    }
    return l10n.salesLiveMapChartSubtitleLoaded(
      period,
      result.mappedBranchCount,
      result.totalBranchCount,
    );
  }

  AppBrazilStoreSalesMapStyle _mapStyle(SalesLiveMapMapPreset preset) {
    final appPreset = switch (preset) {
      SalesLiveMapMapPreset.standard => AppBrazilStoreSalesMapPreset.standard,
      SalesLiveMapMapPreset.bubble => AppBrazilStoreSalesMapPreset.bubble,
      SalesLiveMapMapPreset.municipalities =>
        AppBrazilStoreSalesMapPreset.municipalityBubbles,
      SalesLiveMapMapPreset.stateBubbles =>
        AppBrazilStoreSalesMapPreset.stateBubbles,
      SalesLiveMapMapPreset.storeIcon => AppBrazilStoreSalesMapPreset.storeIcon,
    };
    return appPreset.style(
      height: 560,
      enableProximityCluster: preset != SalesLiveMapMapPreset.stateBubbles,
    );
  }

  String _mapPresetLabel(SalesLiveMapMapPreset preset) {
    final l10n = AppLocalizations.of(context);
    return switch (preset) {
      SalesLiveMapMapPreset.standard => l10n.salesLiveMapMapPresetPoints,
      SalesLiveMapMapPreset.bubble => l10n.salesLiveMapMapPresetBubbles,
      SalesLiveMapMapPreset.municipalities =>
        l10n.salesLiveMapMapPresetMunicipalities,
      SalesLiveMapMapPreset.stateBubbles =>
        l10n.salesLiveMapMapPresetStateBubbles,
      SalesLiveMapMapPreset.storeIcon => l10n.salesLiveMapMapPresetStoreIcon,
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
              totalRevenue: 128000,
              totalSalesCount: 420,
              totalBranchCount: 12,
              mappedBranchCount: 12,
              queriedAgentCount: 3,
              plannedAgentCount: 3,
              failedAgentCount: 0,
              missingClientTokenAgentCount: 0,
              skippedOfflineAgentCount: 0,
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

class _SalesLiveMapAttentionPanel extends StatelessWidget {
  const _SalesLiveMapAttentionPanel({required this.result});

  final SalesLiveMapLoadResult result;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final messages = <String>[
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
      if (result.mappedBranchCount < result.totalBranchCount)
        l10n.salesLiveMapPartialMissingCoordinates(
          result.totalBranchCount - result.mappedBranchCount,
        ),
    ];

    return AppInlineErrorPanel(
      tone: AppInlinePanelTone.informational,
      title: l10n.salesLiveMapPartialTitle,
      message: messages.join(' '),
    );
  }
}

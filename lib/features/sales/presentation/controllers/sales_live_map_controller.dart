import 'dart:async';

import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/overview/domain/entities/overview_filter.dart';
import 'package:colmeia/features/sales/application/load_sales_available_agents_use_case.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map_use_case.dart';
import 'package:colmeia/features/sales/application/sales_session_service.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_filter.dart';
import 'package:colmeia/features/sales/presentation/state/sales_live_map_presentation_state.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_data.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_models.dart';
import 'package:flutter/foundation.dart';

class SalesLiveMapController extends ChangeNotifier {
  SalesLiveMapController({
    required SalesSessionService sessionService,
    required LoadSalesAvailableAgentsUseCase loadSalesAvailableAgentsUseCase,
    required LoadSalesLiveMapUseCase loadSalesLiveMapUseCase,
  }) : _sessionService = sessionService,
       _loadAgentsUseCase = loadSalesAvailableAgentsUseCase,
       _loadLiveMap = loadSalesLiveMapUseCase;

  final SalesSessionService _sessionService;
  final LoadSalesAvailableAgentsUseCase _loadAgentsUseCase;
  final LoadSalesLiveMapUseCase _loadLiveMap;

  SalesLiveMapPresentationState _state =
      const SalesLiveMapPresentationState();
  String? _boundUserId;
  int _loadGeneration = 0;
  SalesLiveMapLoadCancelToken? _activeLoadCancelToken;
  bool _disposed = false;

  SalesLiveMapPresentationState get state => _state;

  Future<void> bindUser(String? userId) async {
    if (_boundUserId == userId) {
      return;
    }
    _boundUserId = userId;
    _activeLoadCancelToken?.cancel();

    final restoredFilter = _normalizeRestoredFilter(
      _sessionService.restoreSalesLiveMapFilter(),
    );
    _state = _state.copyWith(
      filter: restoredFilter,
      availableAgents: const <OverviewAgentOption>[],
      result: userId == null ? _sessionExpiredResult() : null,
      isLoading: userId != null,
      sessionExpired: userId == null,
    );
    _notifyListenersIfAlive();

    if (restoredFilter.selectedBranchIds != null) {
      unawaited(_sessionService.persistSalesLiveMapFilter(restoredFilter));
    }
    if (userId == null) {
      return;
    }
    await _loadAgents(userId);
  }

  Future<void> reload({bool force = false}) async {
    if (force) {
      _activeLoadCancelToken?.cancel();
    }
    await _performReload();
  }

  Future<void> applyFilter(SalesLiveMapFilter filter) async {
    final normalizedFilter = _normalizeFilterForSelectedBranches(filter);
    final previousData = _state.filter.dataFilter;
    final nextData = normalizedFilter.dataFilter;

    _state = _state.copyWith(
      filter: normalizedFilter,
      sessionExpired: false,
    );
    _notifyListenersIfAlive();
    unawaited(_sessionService.persistSalesLiveMapFilter(normalizedFilter));

    if (previousData != nextData) {
      _requestCloseFullscreenAfterDataChanged();
      await reload(force: true);
    }
  }

  Future<void> clearSelectedBranches() async {
    final next = _state.filter.copyWith(
      selectedAgentIds: null,
      selectedBranchIds: null,
    );
    _state = _state.copyWith(filter: next, sessionExpired: false);
    _notifyListenersIfAlive();
    unawaited(_sessionService.persistSalesLiveMapFilter(next));
    _requestCloseFullscreenAfterDataChanged();
    await reload(force: true);
  }

  Future<void> clearSavedFilters() async {
    const next = SalesLiveMapFilter();
    _state = _state.copyWith(filter: next, sessionExpired: false);
    _notifyListenersIfAlive();
    unawaited(_sessionService.persistSalesLiveMapFilter(next));
    _requestCloseFullscreenAfterDataChanged();
    await reload(force: true);
  }

  void updateMetric(AppBrazilStoreSalesMapMetric metric) {
    if (_state.filter.metric == metric) {
      return;
    }
    final next = _state.filter.copyWith(metric: metric);
    _state = _state.copyWith(filter: next);
    _notifyListenersIfAlive();
    unawaited(_sessionService.persistSalesLiveMapFilter(next));
  }

  String filiaisSummary(AppLocalizations l10n) {
    final branchOptions =
        _state.result?.branchOptions ?? const <SalesLiveMapBranchOption>[];
    if (branchOptions.isEmpty) {
      if (_state.result != null && !_state.isLoading) {
        return l10n.salesLiveMapAgentsNoneSummary;
      }
      return l10n.salesLiveMapAgentsLoadingSummary;
    }
    final selected = _state.filter.selectedBranchIds;
    if (selected == null) {
      return l10n.salesLiveMapAgentsAllWithTokenSummary(branchOptions.length);
    }
    return l10n.salesLiveMapAgentsSelectedSummary(selected.length);
  }

  String periodSummary(AppLocalizations l10n) {
    final range = _state.filter.resolveDateRange();
    final rangeLabel =
        '${AppBrFormatters.shortDate(range.startInclusive)} a ${AppBrFormatters.shortDate(range.endInclusive)}';
    return switch (_state.filter.periodMode) {
      SalesLiveMapPeriodMode.today => l10n.salesLiveMapPeriodToday,
      SalesLiveMapPeriodMode.lastSevenDays =>
        l10n.salesLiveMapPeriodLastSevenDays,
      SalesLiveMapPeriodMode.currentMonth =>
        l10n.salesLiveMapPeriodCurrentMonth,
      SalesLiveMapPeriodMode.customRange => rangeLabel,
    };
  }

  String detailLabel(AppLocalizations l10n, SalesLiveMapMapDetail detailLevel) {
    return switch (detailLevel) {
      SalesLiveMapMapDetail.branches => l10n.salesLiveMapDetailBranches,
      SalesLiveMapMapDetail.municipalities =>
        l10n.salesLiveMapDetailMunicipalities,
      SalesLiveMapMapDetail.states => l10n.salesLiveMapDetailStates,
    };
  }

  String visualLabel(
    AppLocalizations l10n,
    SalesLiveMapMarkerVisual visual,
  ) {
    return switch (visual) {
      SalesLiveMapMarkerVisual.dot => l10n.salesLiveMapVisualDot,
      SalesLiveMapMarkerVisual.bubble => l10n.salesLiveMapVisualBubble,
      SalesLiveMapMarkerVisual.storeIcon => l10n.salesLiveMapVisualStoreIcon,
    };
  }

  String mapSubtitle(AppLocalizations l10n) {
    final range = _state.filter.resolveDateRange();
    final period =
        '${AppBrFormatters.shortDate(range.startInclusive)} a ${AppBrFormatters.shortDate(range.endInclusive)}';
    final result = _state.result;
    if (result == null || result.salesDataPending) {
      return l10n.salesLiveMapChartSubtitlePending(period);
    }
    final baseSubtitle = l10n.salesLiveMapChartSubtitleLoaded(
      period,
      result.mappedBranchCount,
      result.totalBranchCount,
    );
    if (_state.effectiveDetailLevel == SalesLiveMapMapDetail.municipalities &&
        _state.filter.detailLevel == SalesLiveMapMapDetail.branches) {
      return '$baseSubtitle ${l10n.salesLiveMapDetailAutoMunicipalities(kSalesLiveMapAutoMunicipalityDetailPointThreshold)}';
    }
    return baseSubtitle;
  }

  String loadErrorMessage(AppLocalizations l10n) {
    if (_state.sessionExpired) {
      return l10n.salesLiveMapSessionExpiredMessage;
    }
    final result = _state.result;
    return switch (result?.loadFailureReason) {
      SalesLiveMapLoadFailureReason.missingClientTokenSetup =>
        l10n.salesLiveMapMissingClientTokenSetupMessage,
      null => result?.loadFailureMessage ?? l10n.salesLiveMapLoadErrorRetryMessage,
    };
  }

  String liveMapFullscreenFilterSummary(AppLocalizations l10n) {
    final parts = <String>[
      '${l10n.salesLiveMapAgentsLabel}: ${filiaisSummary(l10n)}',
      '${l10n.salesLiveMapPeriodLabel}: ${periodSummary(l10n)}',
      '${l10n.salesLiveMapDetailLabel}: ${detailLabel(l10n, _state.filter.detailLevel)}',
    ];
    if (_state.filter.detailLevel != SalesLiveMapMapDetail.states) {
      parts.add(
        '${l10n.salesLiveMapVisualLabel}: ${visualLabel(l10n, _state.filter.markerVisual)}',
      );
    } else {
      parts.add(
        '${l10n.salesLiveMapMapLabel}: ${visualLabel(l10n, SalesLiveMapMarkerVisual.bubble)}',
      );
    }
    return '${parts.join(' | ')} | ${l10n.chartFullscreenDataSnapshotHint}';
  }

  @override
  void dispose() {
    _disposed = true;
    _activeLoadCancelToken?.cancel();
    super.dispose();
  }

  SalesLiveMapFilter _normalizeRestoredFilter(SalesLiveMapFilter filter) {
    if (filter.selectedBranchIds == null) {
      return filter;
    }
    return filter.copyWith(selectedAgentIds: null, selectedBranchIds: null);
  }

  Future<void> _loadAgents(String userId) async {
    final stopwatch = _startTraceStopwatch();
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

    final normalizedFilter = _state.filter.copyWith(
      selectedAgentIds: _normalizeSelectedAgentIds(
        agents: agents,
        selectedAgentIds: _state.filter.selectedAgentIds,
      ),
    );
    _state = _state.copyWith(
      availableAgents: agents,
      filter: normalizedFilter,
      sessionExpired: false,
    );
    _notifyListenersIfAlive();
    unawaited(_sessionService.persistSalesLiveMapFilter(normalizedFilter));
    await reload();
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

  Future<void> _performReload() async {
    final userId = _boundUserId;
    final generation = ++_loadGeneration;
    final cancelToken = SalesLiveMapLoadCancelToken();
    final hadResultBeforeReload = _state.result != null;
    _activeLoadCancelToken = cancelToken;

    _state = _state.copyWith(isLoading: true, sessionExpired: userId == null);
    _notifyListenersIfAlive();

    if (userId == null) {
      if (generation != _loadGeneration) {
        return;
      }
      if (identical(_activeLoadCancelToken, cancelToken)) {
        _activeLoadCancelToken = null;
      }
      _state = _state.copyWith(
        isLoading: false,
        result: _sessionExpiredResult(),
        sessionExpired: true,
      );
      _notifyListenersIfAlive();
      return;
    }

    var emittedAnyResult = false;
    await for (final result in _loadLiveMap.loadProgressive(
      userId: userId,
      filter: _state.filter,
      cancelToken: cancelToken,
    )) {
      if (generation != _loadGeneration) {
        return;
      }
      emittedAnyResult = true;
      if (result.cancelled) {
        if (identical(_activeLoadCancelToken, cancelToken)) {
          _activeLoadCancelToken = null;
        }
        _state = _state.copyWith(isLoading: false);
        _notifyListenersIfAlive();
        return;
      }
      if (hadResultBeforeReload && result.salesDataPending) {
        continue;
      }

      final previousResult = _state.result;
      if (previousResult != null) {
        final mapPayloadUnchanged =
            AppBrazilStoreSalesMapData.pointsContentDigest(
              previousResult.points,
            ) ==
            AppBrazilStoreSalesMapData.pointsContentDigest(result.points);
        if (mapPayloadUnchanged &&
            previousResult.salesDataPending == result.salesDataPending &&
            previousResult.loadFailed == result.loadFailed &&
            previousResult.refreshedAt == result.refreshedAt) {
          if (_state.isLoading != result.salesDataPending) {
            _state = _state.copyWith(isLoading: result.salesDataPending);
            _notifyListenersIfAlive();
          }
          continue;
        }
      }

      _state = _state.copyWith(
        result: result,
        isLoading: result.salesDataPending,
        sessionExpired: false,
      );
      _notifyListenersIfAlive();
    }

    if (generation != _loadGeneration) {
      return;
    }
    if (identical(_activeLoadCancelToken, cancelToken)) {
      _activeLoadCancelToken = null;
    }
    if (!emittedAnyResult) {
      _state = _state.copyWith(isLoading: false);
      _notifyListenersIfAlive();
    }
  }

  SalesLiveMapFilter _normalizeFilterForSelectedBranches(
    SalesLiveMapFilter filter,
  ) {
    final selectedBranchIds = filter.selectedBranchIds;
    if (selectedBranchIds == null || selectedBranchIds.isEmpty) {
      return filter.copyWith(selectedAgentIds: null);
    }

    final branches =
        _state.result?.branchOptions ?? const <SalesLiveMapBranchOption>[];
    final selectedAgents = branches
        .where((branch) => selectedBranchIds.contains(branch.branchRef))
        .map((branch) => branch.agentId)
        .toSet();
    if (selectedAgents.isEmpty) {
      return filter;
    }

    return filter.copyWith(
      selectedAgentIds: Set<String>.unmodifiable(selectedAgents),
    );
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
      refreshedAt: DateTime.now(),
    );
  }

  void _requestCloseFullscreenAfterDataChanged() {
    _state = _state.copyWith(
      closeFullscreenRequestId: _state.closeFullscreenRequestId + 1,
    );
    _notifyListenersIfAlive();
  }

  void _notifyListenersIfAlive() {
    if (_disposed) {
      return;
    }
    notifyListeners();
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
        'operation': 'SalesLiveMapController',
        ...context,
      },
    );
  }

  bool get _shouldTracePerformance => kDebugMode || kProfileMode;
}

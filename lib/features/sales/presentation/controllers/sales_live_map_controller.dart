import 'dart:async';

import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/core/refresh/auto_refresh_state_persistence.dart';
import 'package:colmeia/features/overview/domain/entities/overview_filter.dart';
import 'package:colmeia/features/sales/application/load_sales_available_agents_use_case.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map_use_case.dart';
import 'package:colmeia/features/sales/application/sales_live_map_reload_reason.dart';
import 'package:colmeia/features/sales/application/sales_session_service.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_data_filter.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_filter.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_metric.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_point.dart';
import 'package:colmeia/features/sales/presentation/auto_refresh/sales_auto_refresh_support.dart';
import 'package:colmeia/features/sales/presentation/mappers/sales_live_map_chart_mapper.dart';
import 'package:colmeia/features/sales/presentation/state/sales_live_map_presentation_state.dart';
import 'package:flutter/foundation.dart';

enum SalesLiveMapReloadOutcomeKind { completed, cancelled, superseded }

@immutable
class SalesLiveMapReloadOutcome {
  const SalesLiveMapReloadOutcome._(this.kind, this.result);

  const SalesLiveMapReloadOutcome.completed([SalesLiveMapLoadResult? result])
    : this._(SalesLiveMapReloadOutcomeKind.completed, result);

  const SalesLiveMapReloadOutcome.cancelled([SalesLiveMapLoadResult? result])
    : this._(SalesLiveMapReloadOutcomeKind.cancelled, result);

  const SalesLiveMapReloadOutcome.superseded([SalesLiveMapLoadResult? result])
    : this._(SalesLiveMapReloadOutcomeKind.superseded, result);

  final SalesLiveMapReloadOutcomeKind kind;
  final SalesLiveMapLoadResult? result;

  bool get isCompleted => kind == SalesLiveMapReloadOutcomeKind.completed;

  bool get isCancelled => kind == SalesLiveMapReloadOutcomeKind.cancelled;

  bool get isSuperseded => kind == SalesLiveMapReloadOutcomeKind.superseded;
}

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

  SalesLiveMapPresentationState _state = const SalesLiveMapPresentationState();
  String? _boundUserId;
  int _loadGeneration = 0;
  SalesLiveMapLoadCancelToken? _activeLoadCancelToken;
  bool _disposed = false;

  SalesLiveMapPresentationState get state => _state;

  AutoRefreshStatePersistence get autoRefreshPersistence =>
      SalesCardAutoRefreshPersistence(
        sessionService: _sessionService,
        cardId: SalesAutoRefreshCardIds.liveMap,
        optionSet: SalesAutoRefreshOptions.optionSet,
      );

  Future<void> bindUser(String? userId) async {
    if (_boundUserId == userId) {
      return;
    }
    _boundUserId = userId;
    _activeLoadCancelToken?.cancel();

    final restoredFilter = _normalizeRestoredFilter(
      _sessionService.restoreSalesLiveMapFilter(),
    );
    final sessionExpiredResult = userId == null
        ? _sessionExpiredResult()
        : null;
    _setState(
      _state.copyWith(
        filter: restoredFilter,
        availableAgents: const <OverviewAgentOption>[],
        result: sessionExpiredResult,
        visualResult: sessionExpiredResult,
        mapPayloadDigest: _mapPayloadDigestFor(sessionExpiredResult),
        isLoading: userId != null,
        sessionExpired: userId == null,
      ),
    );

    if (restoredFilter.selectedBranchIds != null) {
      unawaited(_sessionService.persistSalesLiveMapFilter(restoredFilter));
    }
    if (userId == null) {
      return;
    }
    await _loadAgents(userId);
  }

  Future<SalesLiveMapReloadOutcome> reload({
    bool force = false,
    SalesLiveMapReloadReason reason = SalesLiveMapReloadReason.manual,
  }) async {
    if (force) {
      _activeLoadCancelToken?.cancel();
    }
    return _performReload(reason: reason);
  }

  Future<void> applyFilter(SalesLiveMapFilter filter) async {
    final normalizedFilter = _normalizeFilterForSelectedBranches(filter);
    if (_state.filter == normalizedFilter && !_state.sessionExpired) {
      return;
    }
    final previousData = _state.filter.dataFilter;
    final nextData = normalizedFilter.dataFilter;

    _setState(
      _state.copyWith(
        filter: normalizedFilter,
        sessionExpired: false,
      ),
    );
    unawaited(_sessionService.persistSalesLiveMapFilter(normalizedFilter));

    if (previousData != nextData) {
      _requestCloseFullscreenAfterDataChanged();
      await reload(force: true, reason: SalesLiveMapReloadReason.filterChange);
    }
  }

  Future<void> clearSelectedBranches() async {
    final next = _state.filter.copyWith(
      selectedAgentIds: null,
      selectedBranchIds: null,
    );
    if (_state.filter == next && !_state.sessionExpired) {
      return;
    }
    _setState(_state.copyWith(filter: next, sessionExpired: false));
    unawaited(_sessionService.persistSalesLiveMapFilter(next));
    _requestCloseFullscreenAfterDataChanged();
    await reload(force: true, reason: SalesLiveMapReloadReason.filterChange);
  }

  Future<void> clearSavedFilters() async {
    const next = SalesLiveMapFilter();
    if (_state.filter == next && !_state.sessionExpired) {
      return;
    }
    _setState(_state.copyWith(filter: next, sessionExpired: false));
    unawaited(_sessionService.persistSalesLiveMapFilter(next));
    _requestCloseFullscreenAfterDataChanged();
    await reload(force: true, reason: SalesLiveMapReloadReason.filterChange);
  }

  void updateMetric(SalesLiveMapMetric metric) {
    if (_state.filter.metric == metric) {
      return;
    }
    final next = _state.filter.copyWith(metric: metric);
    _setState(_state.copyWith(filter: next));
    unawaited(_sessionService.persistSalesLiveMapFilter(next));
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
    _setState(
      _state.copyWith(
        availableAgents: agents,
        filter: normalizedFilter,
        sessionExpired: false,
      ),
    );
    unawaited(_sessionService.persistSalesLiveMapFilter(normalizedFilter));
    await reload(reason: SalesLiveMapReloadReason.initial);
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

  Future<SalesLiveMapReloadOutcome> _performReload({
    required SalesLiveMapReloadReason reason,
  }) async {
    final userId = _boundUserId;
    final generation = ++_loadGeneration;
    final cancelToken = SalesLiveMapLoadCancelToken();
    final preserveVisualSnapshot =
        reason != SalesLiveMapReloadReason.filterChange;
    final preservedVisualResult = preserveVisualSnapshot
        ? _state.visualResult
        : null;
    _activeLoadCancelToken = cancelToken;

    _setState(
      _state.copyWith(
        isLoading: true,
        sessionExpired: userId == null,
        visualResult: preservedVisualResult,
        mapPayloadDigest: _mapPayloadDigestFor(preservedVisualResult),
      ),
    );

    if (userId == null) {
      if (generation != _loadGeneration) {
        return SalesLiveMapReloadOutcome.superseded(_state.result);
      }
      if (identical(_activeLoadCancelToken, cancelToken)) {
        _activeLoadCancelToken = null;
      }
      final sessionExpiredResult = _sessionExpiredResult();
      _setState(
        _state.copyWith(
          isLoading: false,
          result: sessionExpiredResult,
          visualResult: sessionExpiredResult,
          mapPayloadDigest: _mapPayloadDigestFor(sessionExpiredResult),
          sessionExpired: true,
        ),
      );
      return SalesLiveMapReloadOutcome.completed(_state.result);
    }

    var emittedAnyResult = false;
    await for (final result in _loadLiveMap.loadProgressive(
      userId: userId,
      filter: _state.filter,
      reason: reason,
      cancelToken: cancelToken,
    )) {
      if (generation != _loadGeneration) {
        return SalesLiveMapReloadOutcome.superseded(_state.result);
      }
      emittedAnyResult = true;
      if (result.cancelled) {
        if (identical(_activeLoadCancelToken, cancelToken)) {
          _activeLoadCancelToken = null;
        }
        _setState(_state.copyWith(isLoading: false));
        return SalesLiveMapReloadOutcome.cancelled(result);
      }
      if (preservedVisualResult != null && result.salesDataPending) {
        continue;
      }

      final previousResult = _state.result;
      final nextVisualResult = _resolveNextVisualResult(
        incomingResult: result,
        previousVisualResult: _state.visualResult,
      );
      final nextMapPayloadDigest = _mapPayloadDigestFor(nextVisualResult);
      if (previousResult != null) {
        final mapPayloadUnchanged =
            _state.mapPayloadDigest == nextMapPayloadDigest;
        if (mapPayloadUnchanged &&
            identical(_state.visualResult, nextVisualResult) &&
            previousResult.salesDataPending == result.salesDataPending &&
            previousResult.loadFailed == result.loadFailed &&
            previousResult.refreshedAt == result.refreshedAt) {
          if (_state.isLoading != result.salesDataPending) {
            _setState(
              _state.copyWith(isLoading: result.salesDataPending),
            );
          }
          continue;
        }
      }

      _setState(
        _state.copyWith(
          result: result,
          visualResult: nextVisualResult,
          mapPayloadDigest: nextMapPayloadDigest,
          isLoading: result.salesDataPending,
          sessionExpired: false,
        ),
      );
    }

    if (generation != _loadGeneration) {
      return SalesLiveMapReloadOutcome.superseded(_state.result);
    }
    if (identical(_activeLoadCancelToken, cancelToken)) {
      _activeLoadCancelToken = null;
    }
    if (!emittedAnyResult) {
      _setState(_state.copyWith(isLoading: false));
    }
    return SalesLiveMapReloadOutcome.completed(_state.result);
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
      points: const <SalesLiveMapPoint>[],
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
    _setState(
      _state.copyWith(
        closeFullscreenRequestId: _state.closeFullscreenRequestId + 1,
      ),
    );
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

  void _setState(SalesLiveMapPresentationState nextState) {
    if (_state == nextState) {
      return;
    }
    _state = nextState;
    _notifyListenersIfAlive();
  }

  SalesLiveMapLoadResult? _resolveNextVisualResult({
    required SalesLiveMapLoadResult incomingResult,
    required SalesLiveMapLoadResult? previousVisualResult,
  }) {
    if (_shouldUseResultAsVisualSnapshot(incomingResult)) {
      return incomingResult;
    }
    return previousVisualResult;
  }

  bool _shouldUseResultAsVisualSnapshot(SalesLiveMapLoadResult result) {
    if (!result.salesDataPending) {
      return true;
    }
    return result.points.isNotEmpty || result.branchOptions.isNotEmpty;
  }

  int _mapPayloadDigestFor(SalesLiveMapLoadResult? visualResult) {
    if (visualResult == null) {
      return 0;
    }
    return SalesLiveMapChartMapper.pointsContentDigest(visualResult.points);
  }
}

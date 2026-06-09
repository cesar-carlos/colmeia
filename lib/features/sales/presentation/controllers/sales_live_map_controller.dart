import 'dart:async';

import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/retry_after_gate.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/core/refresh/auto_refresh_state_persistence.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/presentation/agent_query_retry_after.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_result_builder.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_visual_snapshot_policy.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map_use_case.dart';
import 'package:colmeia/features/sales/application/sales_live_map_reload_reason.dart';
import 'package:colmeia/features/sales/application/sales_session_service.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_data_filter.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_filter.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_metric.dart';
import 'package:colmeia/features/sales/domain/load_available_agents_for_sales.dart';
import 'package:colmeia/features/sales/presentation/auto_refresh/sales_auto_refresh_support.dart';
import 'package:colmeia/features/sales/presentation/controllers/sales_live_map_filter_normalizer.dart';
import 'package:colmeia/features/sales/presentation/controllers/sales_live_map_progressive_stream_handler.dart';
import 'package:colmeia/features/sales/presentation/controllers/sales_live_map_reload_outcome.dart';
import 'package:colmeia/features/sales/presentation/sales_live_map_available_agents_assembler.dart';
import 'package:colmeia/features/sales/presentation/state/sales_live_map_presentation_state.dart';
import 'package:colmeia/shared/filters/dashboard_filter.dart';
import 'package:flutter/foundation.dart';

export 'sales_live_map_reload_outcome.dart';

enum SalesLiveMapFilterMutationOutcome {
  applied,
  blockedByCooldown,
  unchanged,
}

class SalesLiveMapController extends ChangeNotifier {
  SalesLiveMapController({
    required SalesSessionService sessionService,
    required LoadAvailableAgentsForSales loadSalesAvailableAgentsUseCase,
    required LoadSalesLiveMapUseCase loadSalesLiveMapUseCase,
    RetryAfterGate? retryAfterGate,
    AgentQueriesRelayCancelScopeBinder? relayCancelScopeBinder,
    SalesLiveMapProgressiveStreamHandler? progressiveStreamHandler,
  }) : _sessionService = sessionService,
       _loadAgentsUseCase = loadSalesAvailableAgentsUseCase,
       _loadLiveMap = loadSalesLiveMapUseCase,
       _retryAfterGate = retryAfterGate ?? RetryAfterGate(),
       _ownsRetryAfterGate = retryAfterGate == null,
       _relayCancelScopeBinder = relayCancelScopeBinder,
       _progressiveStreamHandler =
           progressiveStreamHandler ??
           const SalesLiveMapProgressiveStreamHandler() {
    _retryAfterGate.addListener(_notifyListenersIfAlive);
  }

  final SalesSessionService _sessionService;
  final LoadAvailableAgentsForSales _loadAgentsUseCase;
  final LoadSalesLiveMapUseCase _loadLiveMap;
  final RetryAfterGate _retryAfterGate;
  final bool _ownsRetryAfterGate;
  final AgentQueriesRelayCancelScopeBinder? _relayCancelScopeBinder;
  final SalesLiveMapProgressiveStreamHandler _progressiveStreamHandler;

  SalesLiveMapPresentationState _state = const SalesLiveMapPresentationState();
  String? _boundUserId;
  int _loadGeneration = 0;
  SalesLiveMapLoadCancelToken? _activeLoadCancelToken;
  bool _disposed = false;

  SalesLiveMapPresentationState get state => _state;

  RetryAfterGate get retryAfterGate => _retryAfterGate;

  bool get isOnRetryCooldown => !_retryAfterGate.isOpen;

  AutoRefreshStatePersistence get autoRefreshPersistence =>
      SalesCardAutoRefreshPersistence(
        sessionService: _sessionService,
        cardId: SalesAutoRefreshCardIds.liveMap,
        optionSet: SalesLiveMapAutoRefreshOptions.optionSet,
      );

  Future<void> bindUser(String? userId) async {
    if (_boundUserId == userId) {
      return;
    }
    _boundUserId = userId;
    _loadGeneration++;
    _activeLoadCancelToken?.cancel();

    final persistedFilter = _sessionService.restoreSalesLiveMapFilter();
    final restoredFilter = SalesLiveMapFilterNormalizer.normalizeRestoredFilter(
      persistedFilter,
    );
    final droppedStaleBranchSelection =
        persistedFilter.selectedBranchIds != null &&
        restoredFilter.selectedBranchIds == null;
    final sessionExpiredResult = userId == null
        ? _sessionExpiredResult()
        : null;
    _setState(
      _state.copyWith(
        filter: restoredFilter,
        availableAgents: const <DashboardAgentOption>[],
        result: sessionExpiredResult,
        visualResult: sessionExpiredResult,
        mapPayloadDigest: SalesLiveMapVisualSnapshotPolicy.payloadDigestFor(
          sessionExpiredResult,
        ),
        isLoading: userId != null,
        sessionExpired: userId == null,
      ),
    );

    // Persist the normalized filter back so the next session does not have
    // to re-clear the same stale branch selection from disk.
    if (droppedStaleBranchSelection) {
      _persistFilter(restoredFilter);
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
    if (isOnRetryCooldown) {
      return SalesLiveMapReloadOutcome.blockedByCooldown(_state.result);
    }
    return _performReload(reason: reason, bypassCatalogCache: force);
  }

  Future<SalesLiveMapFilterMutationOutcome> applyFilter(
    SalesLiveMapFilter filter,
  ) async {
    if (isOnRetryCooldown) {
      return SalesLiveMapFilterMutationOutcome.blockedByCooldown;
    }
    final normalizedFilter =
        SalesLiveMapFilterNormalizer.normalizeForSelectedBranches(
          filter: filter,
          result: _state.result,
        );
    if (_state.filter == normalizedFilter && !_state.sessionExpired) {
      return SalesLiveMapFilterMutationOutcome.unchanged;
    }
    final previousData = _state.filter.dataFilter;
    final nextData = normalizedFilter.dataFilter;
    final wasSessionExpired = _state.sessionExpired;

    _setState(
      _state.copyWith(
        filter: normalizedFilter,
        sessionExpired: false,
      ),
    );
    _persistFilter(normalizedFilter);

    if (previousData != nextData) {
      _requestCloseFullscreenAfterDataChanged();
      await reload(force: true, reason: SalesLiveMapReloadReason.filterChange);
    } else if (wasSessionExpired) {
      await reload(force: true);
    }
    return SalesLiveMapFilterMutationOutcome.applied;
  }

  Future<SalesLiveMapFilterMutationOutcome> clearSelectedBranches() async {
    if (isOnRetryCooldown) {
      return SalesLiveMapFilterMutationOutcome.blockedByCooldown;
    }
    final next = _state.filter.copyWith(
      selectedAgentIds: null,
      selectedBranchIds: null,
    );
    if (_state.filter == next && !_state.sessionExpired) {
      return SalesLiveMapFilterMutationOutcome.unchanged;
    }
    _setState(_state.copyWith(filter: next, sessionExpired: false));
    _persistFilter(next);
    _requestCloseFullscreenAfterDataChanged();
    await reload(force: true, reason: SalesLiveMapReloadReason.filterChange);
    return SalesLiveMapFilterMutationOutcome.applied;
  }

  Future<SalesLiveMapFilterMutationOutcome> clearSavedFilters() async {
    if (isOnRetryCooldown) {
      return SalesLiveMapFilterMutationOutcome.blockedByCooldown;
    }
    const next = SalesLiveMapFilter();
    if (_state.filter == next && !_state.sessionExpired) {
      return SalesLiveMapFilterMutationOutcome.unchanged;
    }
    _setState(_state.copyWith(filter: next, sessionExpired: false));
    _persistFilter(next);
    _requestCloseFullscreenAfterDataChanged();
    await reload(force: true, reason: SalesLiveMapReloadReason.filterChange);
    return SalesLiveMapFilterMutationOutcome.applied;
  }

  void updateMetric(SalesLiveMapMetric metric) {
    if (_state.filter.metric == metric) {
      return;
    }
    final wasSessionExpired = _state.sessionExpired;
    final next = _state.filter.copyWith(metric: metric);
    _setState(_state.copyWith(filter: next, sessionExpired: false));
    _persistFilter(next);
    if (wasSessionExpired) {
      unawaited(reload(force: true));
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _activeLoadCancelToken?.cancel();
    _retryAfterGate.removeListener(_notifyListenersIfAlive);
    if (_ownsRetryAfterGate) {
      _retryAfterGate.dispose();
    }
    super.dispose();
  }

  Future<void> _loadAgents(String userId) async {
    final stopwatch = _startTraceStopwatch();
    final agents = await _loadAgentsUseCase(userId);
    if (_isStaleBoundUser(userId)) {
      return;
    }
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
      selectedAgentIds: SalesLiveMapFilterNormalizer.normalizeSelectedAgentIds(
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
    _persistFilter(normalizedFilter);
    if (_isStaleBoundUser(userId)) {
      return;
    }
    await reload(reason: SalesLiveMapReloadReason.initial);
  }

  bool _isStaleBoundUser(String userId) {
    return _disposed || _boundUserId != userId;
  }

  /// Fire-and-forget persistence of the live map filter. Persistence
  /// failures are already logged inside `SalesPreferences`; the controller
  /// intentionally does not block the UI on disk IO.
  void _persistFilter(SalesLiveMapFilter filter) {
    unawaited(_sessionService.persistSalesLiveMapFilter(filter));
  }

  Future<SalesLiveMapReloadOutcome> _performReload({
    required SalesLiveMapReloadReason reason,
    bool bypassCatalogCache = false,
  }) async {
    final userId = _boundUserId;
    final generation = ++_loadGeneration;
    _activeLoadCancelToken?.cancel();
    final cancelToken = SalesLiveMapLoadCancelToken();
    _relayCancelScopeBinder?.call(cancelToken.sqlCancelScope);
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
        mapPayloadDigest: SalesLiveMapVisualSnapshotPolicy.payloadDigestFor(
          preservedVisualResult,
        ),
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
          mapPayloadDigest: SalesLiveMapVisualSnapshotPolicy.payloadDigestFor(
            sessionExpiredResult,
          ),
          sessionExpired: true,
        ),
      );
      return SalesLiveMapReloadOutcome.completed(_state.result);
    }

    return _progressiveStreamHandler.handle(
      stream: _loadLiveMap.loadProgressive(
        userId: userId,
        filter: _state.filter,
        reason: reason,
        cancelToken: cancelToken,
        bypassCatalogCache: bypassCatalogCache,
      ),
      session: SalesLiveMapProgressiveStreamSession(
        preservedVisualResult: preservedVisualResult,
        cancelToken: cancelToken,
        isGenerationStale: () => generation != _loadGeneration,
        readState: () => _state,
        applyState: _setState,
        clearActiveCancelTokenIfMatching: () {
          if (identical(_activeLoadCancelToken, cancelToken)) {
            _activeLoadCancelToken = null;
          }
        },
        onLoadResultReceived: _armRetryAfterFromLoadResult,
        rehydrateAvailableAgents: _rehydrateAvailableAgents,
      ),
    );
  }

  SalesLiveMapLoadResult _sessionExpiredResult() {
    return SalesLiveMapResultBuilder.sessionExpired(
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
    if (_disposed || _state == nextState) {
      return;
    }
    _state = nextState;
    _notifyListenersIfAlive();
  }

  List<DashboardAgentOption>? _rehydrateAvailableAgents(
    SalesLiveMapLoadResult result,
  ) {
    return SalesLiveMapAvailableAgentsAssembler.rehydrate(
      previousOptions: _state.availableAgents,
      onlineAgentIds: result.hubPresenceOnlineAgentIdsSnapshot,
      result: result,
    );
  }

  void _armRetryAfterFromLoadResult(SalesLiveMapLoadResult result) {
    final failure = result.loadFailure;
    if (failure != null) {
      _armRetryAfterFromFailure(failure);
    }
    for (final agentFailure in result.agentQueryFailures) {
      if (shouldArmRetryAfterFromPartialAgentQueryFailure(agentFailure)) {
        _armRetryAfterFromFailure(agentFailure);
      }
    }
  }

  void _armRetryAfterFromFailure(AppFailure failure) {
    armAgentQueryRetryAfterGate(_retryAfterGate, failure);
  }

}

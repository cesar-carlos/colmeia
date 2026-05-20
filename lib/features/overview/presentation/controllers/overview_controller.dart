import 'dart:async';

import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/retry_after_gate.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/core/preferences/app_user_preferences_store.dart';
import 'package:colmeia/features/agent_meta/application/agent_rpc_capabilities_registry.dart';
import 'package:colmeia/features/overview/application/usecases/load_overview_online_agent_ids_use_case.dart';
import 'package:colmeia/features/overview/application/usecases/load_overview_use_case.dart';
import 'package:colmeia/features/overview/domain/entities/overview.dart';
import 'package:colmeia/features/overview/domain/entities/overview_agent_query_failure_detail.dart';
import 'package:colmeia/features/overview/domain/entities/overview_filter.dart';
import 'package:colmeia/features/overview/domain/entities/overview_load_labels.dart';
import 'package:colmeia/features/overview/domain/entities/overview_load_policy.dart';
import 'package:colmeia/features/overview/domain/entities/overview_progressive_snapshot.dart';
import 'package:colmeia/features/overview/presentation/overview_available_agents_assembler.dart';
import 'package:colmeia/features/overview/presentation/widgets/overview_agent_names_list_sheet.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

typedef OverviewFailureMessageBuilder = String Function(AppFailure failure);

/// Drives overview loading for the home dashboard.
///
/// Progressive loads ([OverviewLoadingMode.progressive]) emit partial
/// [Overview] snapshots; UI can render KPIs from [overview] while sections
/// are still loading ([completedOverviewSections]).
class OverviewController extends ChangeNotifier {
  OverviewController(
    this._loadOverviewUseCase,
    this._loadOverviewOnlineAgentIdsUseCase, {
    RetryAfterGate? retryAfterGate,
    AgentRpcCapabilitiesRegistry? agentRpcCapabilitiesRegistry,
  }) : _retryAfterGate = retryAfterGate ?? RetryAfterGate(),
       _agentRpcCapabilitiesRegistry = agentRpcCapabilitiesRegistry {
    // Re-publish gate ticks (countdown updates + window expired) through
    // the controller so the home page's retry button reacts without
    // subscribing to the gate directly.
    _retryAfterGate.addListener(_notifyListenersIfAlive);
  }

  final LoadOverviewUseCase _loadOverviewUseCase;
  final LoadOverviewOnlineAgentIdsUseCase _loadOverviewOnlineAgentIdsUseCase;

  /// Cool-down gate fed by `Retry-After` hints surfaced by the bridge
  /// (HTTP header, JSON-RPC `error.data.retry_after_ms`). The overview
  /// fan-outs SQL across multiple agents in a single user-driven
  /// refresh, so a rate-limit hit by **any** agent throttles the whole
  /// "Reload" CTA — that is what the hub quotas are designed to enforce.
  final RetryAfterGate _retryAfterGate;

  /// Optional bulk feature-gating cache. When provided we kick off a
  /// `rpc.discover` for every approved agent right after the overview
  /// settles so other surfaces (queries, detail page) can read
  /// capabilities synchronously without waiting on a per-render
  /// network call. Failures are swallowed by the registry — discovery
  /// is best-effort.
  final AgentRpcCapabilitiesRegistry? _agentRpcCapabilitiesRegistry;

  Overview? _overview;
  bool _isLoadingInitial = false;
  bool _isRefreshing = false;
  String? _errorMessage;
  String? _errorDiagnosticBody;
  String? _requestedOverviewSignature;
  String? _loadedOverviewSignature;
  int _loadGeneration = 0;
  bool _disposed = false;
  Set<OverviewProgressiveSection> _completedOverviewSections =
      const <OverviewProgressiveSection>{};

  OverviewFilter _activeFilter = OverviewFilter.initial();

  /// The filter currently applied to the overview.
  OverviewFilter get activeFilter => _activeFilter;

  /// Agent options derived from the last successful overview load.
  ///
  /// Populated after the first successful load so the filter bar can show
  /// agent names. Empty until data arrives.
  List<OverviewAgentOption> _availableAgents = const <OverviewAgentOption>[];
  List<OverviewAgentOption> get availableAgents => _availableAgents;

  Overview? _normalizedNamesCacheRef;
  List<String> _missingTokenNamesNormalized = const <String>[];
  List<String> _partialFailureNamesNormalized = const <String>[];
  List<String> _skippedDueToHubPresenceNamesNormalized = const <String>[];

  /// Normalized display names for missing-token alerts (trim, sort, dedupe).
  List<String> get missingTokenAgentNamesNormalized {
    _ensureNormalizedAlertNamesCache();
    return _missingTokenNamesNormalized;
  }

  /// Normalized display names for partial query failure alerts.
  List<String> get partialQueryFailureAgentNamesNormalized {
    _ensureNormalizedAlertNamesCache();
    return _partialFailureNamesNormalized;
  }

  /// Normalized display names for the "agentes offline" alert (agents
  /// that have a stored client_token but were skipped because the hub
  /// reported them disconnected at dispatch time).
  List<String> get skippedDueToHubPresenceAgentNamesNormalized {
    _ensureNormalizedAlertNamesCache();
    return _skippedDueToHubPresenceNamesNormalized;
  }

  void _ensureNormalizedAlertNamesCache() {
    final o = _overview;
    if (identical(o, _normalizedNamesCacheRef)) {
      return;
    }
    _normalizedNamesCacheRef = o;
    if (o == null) {
      _missingTokenNamesNormalized = const <String>[];
      _partialFailureNamesNormalized = const <String>[];
      _skippedDueToHubPresenceNamesNormalized = const <String>[];
      return;
    }
    _missingTokenNamesNormalized = normalizeOverviewAgentNames(
      o.agentNamesMissingClientToken,
    );
    _partialFailureNamesNormalized = normalizeOverviewAgentNames(
      <String>[
        ...o.agentNamesExcludedFromQueryFailure,
        ...o.lucratividadePartialFailureAgentNames,
      ],
    );
    _skippedDueToHubPresenceNamesNormalized = normalizeOverviewAgentNames(
      o.agentNamesSkippedDueToHubPresence,
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _retryAfterGate
      ..removeListener(_notifyListenersIfAlive)
      ..dispose();
    super.dispose();
  }

  void _notifyListenersIfAlive() {
    if (_disposed) {
      return;
    }
    notifyListeners();
  }

  bool _isOverviewLoadStale(int generation) =>
      _disposed || generation != _loadGeneration;

  Overview? get overview => _overview;
  bool get isLoading => _isLoadingInitial || _isRefreshing;
  bool get isLoadingInitial => _isLoadingInitial;
  bool get isRefreshing => _isRefreshing;
  bool get hasContent => _overview != null;
  String? get errorMessage => _errorMessage;

  /// Technical lines for the last full overview load failure (no stack trace).
  String? get errorDiagnosticBody => _errorDiagnosticBody;
  Set<OverviewProgressiveSection> get completedOverviewSections =>
      _completedOverviewSections;

  /// Read-only access to the cool-down gate so the home page can render
  /// a "Retry in Ns" countdown.
  RetryAfterGate get retryAfterGate => _retryAfterGate;

  /// Convenience for "is the overview currently throttled by a server
  /// `Retry-After` hint?". Page combines this with `isLoading` to gate
  /// the CTA.
  bool get isOnRetryCooldown => !_retryAfterGate.isOpen;

  /// Applies [filter] and immediately reloads the overview.
  Future<void> applyFilter({
    required String userId,
    required OverviewFilter filter,
    OverviewLoadingMode loadingMode = OverviewLoadingMode.progressive,
    OverviewLoadLabels? rowLabels,
    OverviewFailureMessageBuilder? failureMessageBuilder,
  }) async {
    _activeFilter = filter.normalizedForHomeDashboardReferenceRange();
    _requestedOverviewSignature = null;
    await _loadOverview(
      userId: userId,
      policy: OverviewLoadPolicy.forceRefresh,
      keepContentVisible: _overview != null,
      loadingMode: loadingMode,
      rowLabels: rowLabels ?? OverviewLoadLabels.englishFallback,
      failureMessageBuilder:
          failureMessageBuilder ?? _defaultFailureMessageBuilder,
    );
  }

  /// Schedules [loadOverview] after the current frame when the
  /// user changes. Safe to call from widget build methods.
  void scheduleOverviewLoadIfNeeded({
    required String userId,
    OverviewLoadingMode loadingMode = OverviewLoadingMode.progressive,
    OverviewLoadLabels? rowLabels,
    OverviewFailureMessageBuilder? failureMessageBuilder,
  }) {
    final signature = _signatureFor(userId: userId);
    if (_requestedOverviewSignature == signature) {
      return;
    }
    _requestedOverviewSignature = signature;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (_requestedOverviewSignature != signature) {
        return;
      }
      unawaited(
        loadOverview(
          userId: userId,
          loadingMode: loadingMode,
          rowLabels: rowLabels,
          failureMessageBuilder: failureMessageBuilder,
        ),
      );
    });
  }

  Future<void> loadOverview({
    required String userId,
    OverviewLoadingMode loadingMode = OverviewLoadingMode.progressive,
    OverviewLoadLabels? rowLabels,
    OverviewFailureMessageBuilder? failureMessageBuilder,
  }) async {
    await _loadOverview(
      userId: userId,
      policy: OverviewLoadPolicy.defaultLoad,
      keepContentVisible: false,
      loadingMode: loadingMode,
      rowLabels: rowLabels ?? OverviewLoadLabels.englishFallback,
      failureMessageBuilder:
          failureMessageBuilder ?? _defaultFailureMessageBuilder,
    );
  }

  Future<void> refreshOverview({
    required String userId,
    OverviewLoadingMode loadingMode = OverviewLoadingMode.progressive,
    OverviewLoadLabels? rowLabels,
    OverviewFailureMessageBuilder? failureMessageBuilder,
  }) async {
    if (isOnRetryCooldown) {
      // Server explicitly asked us to back off — respect the window.
      // The page already renders the countdown, so we just no-op here
      // instead of spamming the bridge with a refresh that would burn
      // the same quota.
      return;
    }
    final signature = _signatureFor(userId: userId);
    final keepContentVisible =
        _loadedOverviewSignature == signature && _overview != null;
    await _loadOverview(
      userId: userId,
      policy: OverviewLoadPolicy.forceRefresh,
      keepContentVisible: keepContentVisible,
      loadingMode: loadingMode,
      rowLabels: rowLabels ?? OverviewLoadLabels.englishFallback,
      failureMessageBuilder:
          failureMessageBuilder ?? _defaultFailureMessageBuilder,
    );
  }

  Future<void> retryOverview({
    required String userId,
    OverviewLoadingMode loadingMode = OverviewLoadingMode.progressive,
    OverviewLoadLabels? rowLabels,
    OverviewFailureMessageBuilder? failureMessageBuilder,
  }) async {
    if (isOnRetryCooldown) {
      return;
    }
    final signature = _signatureFor(userId: userId);
    final keepContentVisible =
        _loadedOverviewSignature == signature && _overview != null;
    await _loadOverview(
      userId: userId,
      policy: keepContentVisible
          ? OverviewLoadPolicy.forceRefresh
          : OverviewLoadPolicy.defaultLoad,
      keepContentVisible: keepContentVisible,
      loadingMode: loadingMode,
      rowLabels: rowLabels ?? OverviewLoadLabels.englishFallback,
      failureMessageBuilder:
          failureMessageBuilder ?? _defaultFailureMessageBuilder,
    );
  }

  Future<void> _loadOverview({
    required String userId,
    required OverviewLoadPolicy policy,
    required bool keepContentVisible,
    required OverviewLoadingMode loadingMode,
    required OverviewLoadLabels rowLabels,
    required OverviewFailureMessageBuilder failureMessageBuilder,
  }) async {
    final normalized = _activeFilter.normalizedForHomeDashboardReferenceRange();
    if (normalized != _activeFilter) {
      _activeFilter = normalized;
      _notifyListenersIfAlive();
    }
    final signature = _signatureFor(userId: userId);
    _requestedOverviewSignature = signature;
    final generation = ++_loadGeneration;

    AppLogger.debug(
      'Starting overview load in controller',
      context: <String, Object?>{
        'operation': 'loadOverview',
        'userId': userId,
        'policy': policy.name,
        'keepContentVisible': keepContentVisible,
        'loadingMode': loadingMode.name,
      },
    );

    if (keepContentVisible) {
      _isLoadingInitial = false;
      _isRefreshing = true;
    } else {
      _isRefreshing = false;
      _isLoadingInitial = true;
      _overview = null;
      _loadedOverviewSignature = null;
      _completedOverviewSections = const <OverviewProgressiveSection>{};
    }
    _errorMessage = null;
    _errorDiagnosticBody = null;
    _notifyListenersIfAlive();

    if (loadingMode == OverviewLoadingMode.progressive) {
      await _loadOverviewProgressively(
        userId: userId,
        policy: policy,
        keepContentVisible: keepContentVisible,
        rowLabels: rowLabels,
        failureMessageBuilder: failureMessageBuilder,
        signature: signature,
        generation: generation,
      );
      return;
    }

    final result = await _loadOverviewUseCase(
      userId: userId,
      policy: policy,
      filter: _activeFilter,
      rowLabels: rowLabels,
    );
    if (_isOverviewLoadStale(generation)) {
      return;
    }

    final overview = result.getOrNull();
    if (overview != null) {
      _overview = overview;
      _completedOverviewSections = Set<OverviewProgressiveSection>.of(
        OverviewProgressiveSection.values,
      );
      _loadedOverviewSignature = signature;
      _errorMessage = null;
      _errorDiagnosticBody = null;
      AppLogger.info(
        'Overview loaded in controller',
        context: <String, Object?>{
          'operation': 'loadOverview',
          'userId': userId,
          'paymentMethods': overview.paymentMethods.length,
          'policy': policy.name,
        },
      );
    } else {
      final failure = result.exceptionOrNull();
      if (failure != null) {
        if (!keepContentVisible) {
          _overview = null;
          _loadedOverviewSignature = null;
          _completedOverviewSections = const <OverviewProgressiveSection>{};
        }
        // Arm the cool-down gate when the bridge propagated a
        // `Retry-After` hint (HTTP header, JSON-RPC
        // `error.data.retry_after_ms`, socket overload). Same
        // semantics as the detail page and the request-access tab —
        // the next `Reload` tap is debounced until the window closes.
        final retryAfter = appFailureRetryAfter(failure);
        if (retryAfter != null) {
          _retryAfterGate.arm(retryAfter);
        }
        _errorMessage = failureMessageBuilder(failure);
        _errorDiagnosticBody = overviewAppFailureDiagnosticBody(failure);
        AppLogger.warning(
          'Overview load failed in controller',
          context: <String, Object?>{
            'operation': 'loadOverview',
            'userId': userId,
            'policy': policy.name,
            'keepContentVisible': keepContentVisible,
            'technicalMessage': switch (failure) {
              RpcFailure(:final technicalMessage) => technicalMessage,
              _ => failure.message,
            },
          },
          error: failure.cause ?? failure,
          stackTrace: failure.stackTrace,
        );
      }
    }

    if (keepContentVisible) {
      _isRefreshing = false;
    } else {
      _isLoadingInitial = false;
    }
    _notifyListenersIfAlive();

    if (overview != null &&
        await _updateAvailableAgents(overview, userId, generation)) {
      _notifyListenersIfAlive();
    }
  }

  Future<void> _loadOverviewProgressively({
    required String userId,
    required OverviewLoadPolicy policy,
    required bool keepContentVisible,
    required OverviewLoadLabels rowLabels,
    required OverviewFailureMessageBuilder failureMessageBuilder,
    required String signature,
    required int generation,
  }) async {
    await for (final result in _loadOverviewUseCase.progressively(
      userId: userId,
      policy: policy,
      filter: _activeFilter,
      rowLabels: rowLabels,
    )) {
      if (_isOverviewLoadStale(generation)) {
        return;
      }

      final snapshot = result.getOrNull();
      if (snapshot != null) {
        _overview = snapshot.overview;
        _completedOverviewSections = snapshot.completedSections;
        _errorMessage = null;
        _errorDiagnosticBody = null;
        if (snapshot.completedSections.contains(
          OverviewProgressiveSection.summary,
        )) {
          _isLoadingInitial = false;
        }
        if (snapshot.isFinal) {
          _loadedOverviewSignature = signature;
          AppLogger.info(
            'Overview loaded progressively in controller',
            context: <String, Object?>{
              'operation': 'loadOverview',
              'userId': userId,
              'paymentMethods': snapshot.overview.paymentMethods.length,
              'policy': policy.name,
            },
          );
          _finishProgressiveLoading(keepContentVisible: keepContentVisible);
          if (await _updateAvailableAgents(
            snapshot.overview,
            userId,
            generation,
          )) {
            _notifyListenersIfAlive();
          }
          return;
        }
        _notifyListenersIfAlive();
        continue;
      }

      final failure = result.exceptionOrNull();
      if (failure != null) {
        _handleProgressiveFailure(
          failure,
          userId: userId,
          policy: policy,
          keepContentVisible: keepContentVisible,
          failureMessageBuilder: failureMessageBuilder,
        );
      }
      _finishProgressiveLoading(keepContentVisible: keepContentVisible);
      return;
    }

    _finishProgressiveLoading(keepContentVisible: keepContentVisible);
  }

  void _handleProgressiveFailure(
    AppFailure failure, {
    required String userId,
    required OverviewLoadPolicy policy,
    required bool keepContentVisible,
    required OverviewFailureMessageBuilder failureMessageBuilder,
  }) {
    if (!keepContentVisible) {
      _overview = null;
      _loadedOverviewSignature = null;
      _completedOverviewSections = const <OverviewProgressiveSection>{};
    }
    final retryAfter = appFailureRetryAfter(failure);
    if (retryAfter != null) {
      _retryAfterGate.arm(retryAfter);
    }
    _errorMessage = failureMessageBuilder(failure);
    _errorDiagnosticBody = overviewAppFailureDiagnosticBody(failure);
    AppLogger.warning(
      'Overview load failed in controller',
      context: <String, Object?>{
        'operation': 'loadOverview',
        'userId': userId,
        'policy': policy.name,
        'keepContentVisible': keepContentVisible,
        'technicalMessage': switch (failure) {
          RpcFailure(:final technicalMessage) => technicalMessage,
          _ => failure.message,
        },
      },
      error: failure.cause ?? failure,
      stackTrace: failure.stackTrace,
    );
  }

  void _finishProgressiveLoading({required bool keepContentVisible}) {
    if (keepContentVisible) {
      _isRefreshing = false;
    } else {
      _isLoadingInitial = false;
    }
    _notifyListenersIfAlive();
  }

  static String _defaultFailureMessageBuilder(AppFailure failure) {
    return failure.displayMessage;
  }

  String _signatureFor({required String userId}) {
    final ids = _activeFilter.selectedAgentIds;
    final agentPart = ids == null
        ? '*'
        : (List<String>.from(ids)..sort()).join(',');
    final rr = _activeFilter.referenceRange;
    final refPart = rr == null
        ? ''
        : '|r:${rr.startInclusive.year}-${rr.startInclusive.month}-${rr.startInclusive.day}'
              ':${rr.endInclusive.year}-${rr.endInclusive.month}-${rr.endInclusive.day}';
    return '$userId|$agentPart|${_activeFilter.yearMonth ?? 'default'}$refPart';
  }

  /// Rebuilds [_availableAgents] from the overview (per-agent rankings and
  /// failure metadata). Uses names resolved by the repository.
  Future<bool> _updateAvailableAgents(
    Overview overview,
    String userId,
    int generation,
  ) async {
    final onlineIds =
        overview.hubPresenceOnlineAgentIdsSnapshot ??
        await _loadOverviewOnlineAgentIdsUseCase(userId: userId);

    if (_isOverviewLoadStale(generation)) {
      return false;
    }

    final assembled = OverviewAvailableAgentsAssembler.assemble(
      overview: overview,
      previousOptions: _availableAgents,
      onlineAgentIds: onlineIds,
    );
    if (assembled.isEmpty) {
      return false;
    }
    if (listEquals(_availableAgents, assembled)) {
      return false;
    }
    _availableAgents = assembled;
    _scheduleAgentRpcCapabilityPrefetch();
    return true;
  }

  /// Fire-and-forgets a `rpc.discover` for every agent that we both
  /// have surfaced in [_availableAgents] **and** for which we hold a
  /// client token (so the bridge can actually route the call). The
  /// registry deduplicates per-agent in-flight requests, so calling
  /// this on every successful overview load is cheap (only new ids
  /// do work). The future is intentionally not awaited: the overview
  /// UI must not block on a best-effort capability cache.
  ///
  /// Agents without a local client token are intentionally skipped:
  /// the hub answers `404` to `agents/commands` for those (because
  /// it cannot bind the request to a `(client, agent)` pair without
  /// the token), so the prefetch would just spam the log + Sentry
  /// with non-actionable failures. The legitimate
  /// `requiresClientTokenSetup` UX banner already surfaces that
  /// state separately.
  void _scheduleAgentRpcCapabilityPrefetch() {
    final registry = _agentRpcCapabilitiesRegistry;
    if (registry == null || _availableAgents.isEmpty) {
      return;
    }
    final ids = <String>{
      for (final option in _availableAgents)
        if (option.agentId.trim().isNotEmpty && !option.missingLocalClientToken)
          option.agentId.trim(),
    };
    if (ids.isEmpty) {
      return;
    }
    unawaited(registry.prefetch(ids));
  }
}

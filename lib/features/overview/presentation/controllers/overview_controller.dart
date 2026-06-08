import 'dart:async';

import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/retry_after_gate.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/core/preferences/app_user_preferences_store.dart';
import 'package:colmeia/features/agent_meta/application/agent_rpc_capabilities_registry.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/presentation/agent_query_failure_diagnostic.dart';
import 'package:colmeia/features/agent_queries/presentation/agent_query_retry_after.dart';
import 'package:colmeia/features/overview/application/overview_shell_cache.dart';
import 'package:colmeia/features/overview/application/usecases/load_overview_sections_use_case.dart';
import 'package:colmeia/features/overview/application/usecases/load_overview_use_case.dart';
import 'package:colmeia/features/overview/domain/entities/overview.dart';
import 'package:colmeia/features/overview/domain/entities/overview_load_labels.dart';
import 'package:colmeia/features/overview/domain/entities/overview_load_policy.dart';
import 'package:colmeia/features/overview/domain/entities/overview_progressive_snapshot.dart';
import 'package:colmeia/features/overview/domain/entities/overview_section_request.dart';
import 'package:colmeia/features/overview/domain/overview_load_signature.dart';
import 'package:colmeia/features/overview/presentation/controllers/overview_load_session.dart';
import 'package:colmeia/features/overview/presentation/overview_agent_alert_names_projection.dart';
import 'package:colmeia/features/overview/presentation/overview_available_agents_assembler.dart';
import 'package:colmeia/shared/filters/dashboard_filter.dart';
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
    this._loadOverviewUseCase, {
    LoadOverviewSectionsUseCase? loadSectionsUseCase,
    RetryAfterGate? retryAfterGate,
    AgentRpcCapabilitiesRegistry? agentRpcCapabilitiesRegistry,
    AgentQueriesRelayCancelScopeBinder? relayCancelScopeBinder,
    OverviewShellCache? shellCache,
  })  : _loadSectionsUseCase = loadSectionsUseCase,
        _retryAfterGate = retryAfterGate ?? RetryAfterGate(),
        _ownsRetryAfterGate = retryAfterGate == null,
        _agentRpcCapabilitiesRegistry = agentRpcCapabilitiesRegistry,
        _shellCache = shellCache,
        _session = OverviewLoadSession(
          relayCancelScopeBinder: relayCancelScopeBinder,
        ) {
    // Re-publish gate ticks (countdown updates + window expired) through
    // the controller so the home page's retry button reacts without
    // subscribing to the gate directly.
    _retryAfterGate.addListener(_notifyListenersIfAlive);
  }

  // Lazy sections not loaded by OverviewSectionRequest.home, ordered by
  // likelihood of being opened first so the most useful data warms earliest.
  static const List<OverviewProgressiveSection> _prefetchSections =
      <OverviewProgressiveSection>[
    OverviewProgressiveSection.dailySales,
    OverviewProgressiveSection.weekdaySales,
    OverviewProgressiveSection.weekdayUserSales,
    OverviewProgressiveSection.lucratividadePeriod,
  ];

  final LoadOverviewUseCase _loadOverviewUseCase;
  final LoadOverviewSectionsUseCase? _loadSectionsUseCase;

  /// Cool-down gate fed by `Retry-After` hints surfaced by the bridge
  /// (HTTP header, JSON-RPC `error.data.retry_after_ms`). The overview
  /// fan-outs SQL across multiple agents in a single user-driven
  /// refresh, so a rate-limit hit by **any** agent throttles the whole
  /// "Reload" CTA — that is what the hub quotas are designed to enforce.
  final RetryAfterGate _retryAfterGate;

  /// `true` when this controller created [_retryAfterGate]; injected
  /// singletons from DI must outlive route-scoped providers.
  final bool _ownsRetryAfterGate;

  /// Optional bulk feature-gating cache. When provided we kick off a
  /// `rpc.discover` for every approved agent right after the overview
  /// settles so other surfaces (queries, detail page) can read
  /// capabilities synchronously without waiting on a per-render
  /// network call. Failures are swallowed by the registry — discovery
  /// is best-effort.
  final AgentRpcCapabilitiesRegistry? _agentRpcCapabilitiesRegistry;

  /// Shell-scoped snapshot for instant dashboard re-entry with the same filters.
  final OverviewShellCache? _shellCache;

  /// Encapsulates the per-load mutable state (generation, requested/
  /// loaded signatures, SQL cancel scope) so the controller methods read
  /// like orchestration steps instead of bookkeeping mutations.
  final OverviewLoadSession _session;

  Overview? _overview;
  bool _isLoadingInitial = false;
  bool _isRefreshing = false;
  String? _errorMessage;
  String? _errorDiagnosticBody;
  AppFailure? _loadFailure;
  bool _disposed = false;
  Set<OverviewProgressiveSection> _completedOverviewSections =
      const <OverviewProgressiveSection>{};

  DashboardFilter _activeFilter = DashboardFilter.initial();

  /// The filter currently applied to the overview.
  DashboardFilter get activeFilter => _activeFilter;

  /// Agent options derived from the last successful overview load.
  ///
  /// Populated after the first successful load so the filter bar can show
  /// agent names. Empty until data arrives.
  List<DashboardAgentOption> _availableAgents = const <DashboardAgentOption>[];
  List<DashboardAgentOption> get availableAgents => _availableAgents;

  final OverviewAgentAlertNamesProjection _alertNamesProjection =
      OverviewAgentAlertNamesProjection();

  /// Normalized display names for missing-token alerts (trim, sort, dedupe).
  List<String> get missingTokenAgentNamesNormalized =>
      _alertNamesProjection.missingClientToken;

  /// Normalized display names for partial query failure alerts.
  List<String> get partialQueryFailureAgentNamesNormalized =>
      _alertNamesProjection.partialQueryFailure;

  /// Normalized display names for the "agentes offline" alert (agents
  /// that have a stored client_token but were skipped because the hub
  /// reported them disconnected at dispatch time).
  List<String> get skippedDueToHubPresenceAgentNamesNormalized =>
      _alertNamesProjection.skippedDueToHubPresence;

  @override
  void dispose() {
    _disposed = true;
    _session.dispose();
    _retryAfterGate.removeListener(_notifyListenersIfAlive);
    if (_ownsRetryAfterGate) {
      _retryAfterGate.dispose();
    }
    super.dispose();
  }

  void _notifyListenersIfAlive() {
    if (_disposed) {
      return;
    }
    notifyListeners();
  }

  /// Defers [notifyListeners] until after the current frame so callers
  /// invoked from widget mount/build (e.g. [scheduleOverviewLoadIfNeeded])
  /// do not trigger Provider rebuilds mid-build.
  void _notifyListenersIfAliveAfterFrame() {
    if (_disposed) {
      return;
    }
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _notifyListenersIfAlive();
    });
  }

  void _setOverview(Overview? overview) {
    _overview = overview;
    _alertNamesProjection.update(overview);
  }

  bool _isOverviewLoadStale(int generation) => _session.isStale(generation);

  Overview? get overview => _overview;
  bool get isLoading => _isLoadingInitial || _isRefreshing;
  bool get isLoadingInitial => _isLoadingInitial;
  bool get isRefreshing => _isRefreshing;
  bool get hasContent => _overview != null;
  String? get errorMessage => _errorMessage;

  /// Last full overview load failure for agent-query UX (title, technical body).
  AppFailure? get loadFailure => _loadFailure;

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
    required DashboardFilter filter,
    OverviewLoadingMode loadingMode = OverviewLoadingMode.progressive,
    OverviewLoadLabels? rowLabels,
    OverviewFailureMessageBuilder? failureMessageBuilder,
  }) async {
    if (isOnRetryCooldown) {
      return;
    }
    _shellCache?.invalidate();
    _activeFilter = filter.normalizedForHomeDashboardReferenceRange();
    _session.resetRequested();
    await _loadOverview(
      userId: userId,
      policy: OverviewLoadPolicy.defaultLoad,
      // Clear prior overview so KPI/chart sections show skeleton instead of
      // stale data from the previous filter signature.
      keepContentVisible: false,
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
    if (_session.requestedSignature == signature) {
      return;
    }
    final restoredFromShellCache = _tryRestoreFromShellCache(
      userId: userId,
      signature: signature,
    );
    _session.requestedSignature = signature;
    final resolvedRowLabels = rowLabels ?? OverviewLoadLabels.englishFallback;
    final resolvedFailureMessageBuilder =
        failureMessageBuilder ?? _defaultFailureMessageBuilder;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!_session.isRequestStillCurrent(signature)) {
        return;
      }
      unawaited(
        restoredFromShellCache
            ? _revalidateOverviewInBackground(
                userId: userId,
                loadingMode: loadingMode,
                rowLabels: resolvedRowLabels,
                failureMessageBuilder: resolvedFailureMessageBuilder,
              )
            : loadOverview(
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
    if (isOnRetryCooldown) {
      return;
    }
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
    _shellCache?.invalidate();
    final signature = _signatureFor(userId: userId);
    final keepContentVisible =
        _session.isReloadingSameSignature(signature) && _overview != null;
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
        _session.isReloadingSameSignature(signature) && _overview != null;
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
    final ctx = _beginLoad(
      userId: userId,
      keepContentVisible: keepContentVisible,
      loadingMode: loadingMode,
      policy: policy,
    );

    if (loadingMode == OverviewLoadingMode.progressive) {
      await _loadOverviewProgressively(
        userId: userId,
        policy: policy,
        keepContentVisible: keepContentVisible,
        rowLabels: rowLabels,
        failureMessageBuilder: failureMessageBuilder,
        signature: ctx.signature,
        generation: ctx.generation,
        sqlCancelScope: ctx.sqlCancelScope,
      );
      return;
    }

    final result = await _loadOverviewUseCase(
      userId: userId,
      policy: policy,
      filter: _activeFilter,
      rowLabels: rowLabels,
      cancelScope: ctx.sqlCancelScope,
      sectionRequest: OverviewSectionRequest.home,
    );
    if (_isOverviewLoadStale(ctx.generation)) {
      return;
    }

    final overview = result.getOrNull();
    if (overview != null) {
      _applyOneShotSuccess(
        overview: overview,
        signature: ctx.signature,
        userId: userId,
        policy: policy,
      );
    } else {
      final failure = result.exceptionOrNull();
      if (failure != null) {
        _applyFailure(
          failure,
          userId: userId,
          policy: policy,
          keepContentVisible: keepContentVisible,
          failureMessageBuilder: failureMessageBuilder,
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
        await _updateAvailableAgents(overview, userId, ctx.generation)) {
      _notifyListenersIfAlive();
    }

    if (overview != null && !_isOverviewLoadStale(ctx.generation)) {
      _scheduleSectionPrefetch(
        userId: userId,
        signature: ctx.signature,
        generation: ctx.generation,
        rowLabels: rowLabels,
      );
    }
  }

  /// Normalizes the filter, opens a fresh [OverviewLoadSession] entry,
  /// primes the loading flags and returns the bookkeeping the calling
  /// load path needs (signature + generation + cancel scope).
  ({
    String signature,
    int generation,
    AgentQueriesCancelScope sqlCancelScope,
  }) _beginLoad({
    required String userId,
    required bool keepContentVisible,
    required OverviewLoadingMode loadingMode,
    required OverviewLoadPolicy policy,
  }) {
    final normalized = _activeFilter.normalizedForHomeDashboardReferenceRange();
    if (normalized != _activeFilter) {
      _activeFilter = normalized;
      _notifyListenersIfAlive();
    }
    final signature = _signatureFor(userId: userId);
    final generation = _session.begin(signature);
    final sqlCancelScope = _session.cancelScope!;

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
      _setOverview(null);
      _session.clearLoaded();
      _completedOverviewSections = const <OverviewProgressiveSection>{};
    }
    _errorMessage = null;
    _errorDiagnosticBody = null;
    _loadFailure = null;
    _notifyListenersIfAlive();
    return (
      signature: signature,
      generation: generation,
      sqlCancelScope: sqlCancelScope,
    );
  }

  void _armRetryAfterFromFailures(AppFailure failure) {
    armAgentQueryRetryAfterGate(_retryAfterGate, failure);
  }

  void _armRetryAfterFromPartialFailures(Overview overview) {
    for (final detail in overview.partialQueryFailureDetails) {
      if (shouldArmRetryAfterFromPartialAgentQueryFailure(detail.failure)) {
        _armRetryAfterFromFailures(detail.failure);
      }
    }
  }

  void _applyOneShotSuccess({
    required Overview overview,
    required String signature,
    required String userId,
    required OverviewLoadPolicy policy,
  }) {
    _armRetryAfterFromPartialFailures(overview);
    _setOverview(overview);
    _completedOverviewSections =
        OverviewSectionRequest.home.completedWhenFinal();
    _session.loadedSignature = signature;
    _errorMessage = null;
    _errorDiagnosticBody = null;
    _loadFailure = null;
    _publishShellCache(signature);
    AppLogger.info(
      'Overview loaded in controller',
      context: <String, Object?>{
        'operation': 'loadOverview',
        'userId': userId,
        'paymentMethods': overview.paymentMethods.length,
        'policy': policy.name,
      },
    );
  }

  /// Shared failure path used by both one-shot and progressive loads:
  /// arms the retry-after gate when the bridge sent a hint, captures the
  /// user-facing message + diagnostic body, and logs the technical
  /// failure with the same shape as the legacy in-line block.
  void _applyFailure(
    AppFailure failure, {
    required String userId,
    required OverviewLoadPolicy policy,
    required bool keepContentVisible,
    required OverviewFailureMessageBuilder failureMessageBuilder,
  }) {
    if (!keepContentVisible) {
      _setOverview(null);
      _session.clearLoaded();
      _completedOverviewSections = const <OverviewProgressiveSection>{};
    }
    _armRetryAfterFromFailures(failure);
    final userMessage = failureMessageBuilder(failure);
    _errorMessage = userMessage;
    _loadFailure = failure;
    _errorDiagnosticBody = overviewAppFailureDiagnosticBody(
      failure,
      localizedUserMessage: userMessage,
    );
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

  Future<void> _loadOverviewProgressively({
    required String userId,
    required OverviewLoadPolicy policy,
    required bool keepContentVisible,
    required OverviewLoadLabels rowLabels,
    required OverviewFailureMessageBuilder failureMessageBuilder,
    required String signature,
    required int generation,
    required AgentQueriesCancelScope sqlCancelScope,
  }) async {
    await for (final result in _loadOverviewUseCase.progressively(
      userId: userId,
      policy: policy,
      filter: _activeFilter,
      rowLabels: rowLabels,
      cancelScope: sqlCancelScope,
      sectionRequest: OverviewSectionRequest.home,
    )) {
      if (_isOverviewLoadStale(generation)) {
        return;
      }

      final snapshot = result.getOrNull();
      if (snapshot != null) {
        _setOverview(snapshot.overview);
        _completedOverviewSections = snapshot.completedSections;
        _armRetryAfterFromPartialFailures(snapshot.overview);
        _errorMessage = null;
        _errorDiagnosticBody = null;
        _loadFailure = null;
        if (snapshot.completedSections.contains(
          OverviewProgressiveSection.summary,
        )) {
          _isLoadingInitial = false;
        }
        if (snapshot.isFinal) {
          _session.loadedSignature = signature;
          _publishShellCache(signature);
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
          _scheduleSectionPrefetch(
            userId: userId,
            signature: signature,
            generation: generation,
            rowLabels: rowLabels,
          );
          return;
        }
        _notifyListenersIfAlive();
        continue;
      }

      final failure = result.exceptionOrNull();
      if (failure != null) {
        _applyFailure(
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
    return overviewLoadSignature(userId: userId, filter: _activeFilter);
  }

  bool _tryRestoreFromShellCache({
    required String userId,
    required String signature,
  }) {
    if (hasContent) {
      return false;
    }
    final entry = _shellCache?.read(signature);
    if (entry == null) {
      return false;
    }
    _activeFilter = entry.activeFilter;
    _setOverview(entry.overview);
    _availableAgents = entry.availableAgents;
    _completedOverviewSections = Set<OverviewProgressiveSection>.of(
      entry.completedSections,
    );
    _session.loadedSignature = signature;
    _isLoadingInitial = false;
    _isRefreshing = false;
    _errorMessage = null;
    _errorDiagnosticBody = null;
    _loadFailure = null;
    AppLogger.debug(
      'Overview restored from shell cache',
      context: <String, Object?>{
        'operation': 'restoreOverviewShellCache',
        'userId': userId,
        'signature': signature,
      },
    );
    _notifyListenersIfAliveAfterFrame();
    return true;
  }

  Future<void> _revalidateOverviewInBackground({
    required String userId,
    required OverviewLoadingMode loadingMode,
    required OverviewLoadLabels rowLabels,
    required OverviewFailureMessageBuilder failureMessageBuilder,
  }) async {
    if (isOnRetryCooldown) {
      return;
    }
    final keepContentVisible = _overview != null;
    await _loadOverview(
      userId: userId,
      policy: OverviewLoadPolicy.defaultLoad,
      keepContentVisible: keepContentVisible,
      loadingMode: loadingMode,
      rowLabels: rowLabels,
      failureMessageBuilder: failureMessageBuilder,
    );
  }

  void _publishShellCache(String signature) {
    final cache = _shellCache;
    final overview = _overview;
    if (cache == null || overview == null) {
      return;
    }
    cache.publish(
      signature: signature,
      overview: overview,
      activeFilter: _activeFilter,
      availableAgents: _availableAgents,
      completedSections: _completedOverviewSections,
    );
  }

  /// Fires background prefetch for the 4 section-only chart cards that are
  /// not included in [OverviewSectionRequest.home].  Each section is fetched
  /// serially so the bridge is never flooded, and each step checks the shell
  /// cache before issuing SQL (avoids redundant work after the user opens a
  /// card manually before prefetch reaches it).  Failures are swallowed —
  /// the controller state is never mutated; only the shell cache is warmed.
  void _scheduleSectionPrefetch({
    required String userId,
    required String signature,
    required int generation,
    required OverviewLoadLabels rowLabels,
  }) {
    final useCase = _loadSectionsUseCase;
    final cache = _shellCache;
    if (useCase == null || cache == null) {
      return;
    }
    unawaited(
      _prefetchSectionsInBackground(
        useCase: useCase,
        cache: cache,
        userId: userId,
        signature: signature,
        generation: generation,
        rowLabels: rowLabels,
      ),
    );
  }

  Future<void> _prefetchSectionsInBackground({
    required LoadOverviewSectionsUseCase useCase,
    required OverviewShellCache cache,
    required String userId,
    required String signature,
    required int generation,
    required OverviewLoadLabels rowLabels,
  }) async {
    AppLogger.debug(
      'Overview section prefetch started',
      context: <String, Object?>{
        'operation': 'prefetchOverviewSections',
        'userId': userId,
        'sections': _prefetchSections.map((s) => s.name).toList(),
      },
    );
    for (final section in _prefetchSections) {
      if (_isOverviewLoadStale(generation) || _disposed) {
        return;
      }
      final entry = cache.read(signature);
      if (entry == null) {
        return;
      }
      if (entry.completedSections.contains(section)) {
        continue;
      }

      final request = OverviewSectionRequest.forChartSection(section);
      await for (final result in useCase.progressively(
        userId: userId,
        sectionRequest: request,
        filter: _activeFilter,
        rowLabels: rowLabels,
      )) {
        if (_isOverviewLoadStale(generation) || _disposed) {
          return;
        }
        final snapshot = result.getOrNull();
        if (snapshot != null && snapshot.isFinal && request.isSectionBatchOnly) {
          cache.mergePublish(
            signature: signature,
            detailOverview: snapshot.overview,
            section: section,
            addedSections: request.completedWhenFinal(),
          );
          AppLogger.debug(
            'Overview section prefetch warmed',
            context: <String, Object?>{
              'operation': 'prefetchOverviewSections',
              'section': section.name,
            },
          );
        }
      }
    }
  }

  /// Rebuilds [_availableAgents] from the overview (per-agent rankings and
  /// failure metadata). Uses names resolved by the repository.
  Future<bool> _updateAvailableAgents(
    Overview overview,
    String userId,
    int generation,
  ) async {
    final onlineIds = overview.hubPresenceOnlineAgentIdsSnapshot;
    if (onlineIds == null) {
      AppLogger.debug(
        'Overview agent filter missing hub presence snapshot',
        context: <String, Object?>{
          'operation': 'updateAvailableAgents',
          'userId': userId,
        },
      );
    }

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
    if (_session.loadedSignature != null) {
      _publishShellCache(_session.loadedSignature!);
    }
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
    final cancelScope = _session.cancelScope;
    unawaited(
      registry.prefetch(
        ids,
        shouldAbort: () => cancelScope?.isCancelled ?? false,
      ),
    );
  }
}

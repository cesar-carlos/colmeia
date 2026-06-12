import 'dart:async';

import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/retry_after_gate.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/core/preferences/app_user_preferences_store.dart';
import 'package:colmeia/features/agent_meta/application/agent_rpc_capabilities_registry.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/overview/application/overview_prefetch_session.dart';
import 'package:colmeia/features/overview/application/overview_rpc_capabilities_warm_up_coordinator.dart';
import 'package:colmeia/features/overview/application/overview_section_prefetch_coordinator.dart';
import 'package:colmeia/features/overview/application/overview_shell_cache.dart';
import 'package:colmeia/features/overview/application/usecases/load_overview_sections_use_case.dart';
import 'package:colmeia/features/overview/application/usecases/load_overview_use_case.dart';
import 'package:colmeia/features/overview/domain/entities/overview.dart';
import 'package:colmeia/features/overview/domain/entities/overview_load_labels.dart';
import 'package:colmeia/features/overview/domain/entities/overview_load_policy.dart';
import 'package:colmeia/features/overview/domain/entities/overview_progressive_snapshot.dart';
import 'package:colmeia/features/overview/domain/overview_load_signature.dart';
import 'package:colmeia/features/overview/presentation/controllers/overview_load_orchestration_coordinator.dart';
import 'package:colmeia/features/overview/presentation/controllers/overview_load_session.dart';
import 'package:colmeia/features/overview/presentation/overview_agent_alert_names_projection.dart';
import 'package:colmeia/features/overview/presentation/overview_available_agents_assembler.dart';
import 'package:colmeia/shared/filters/dashboard_filter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

export 'package:colmeia/features/overview/presentation/controllers/overview_load_orchestration_coordinator.dart'
    show OverviewFailureMessageBuilder;

/// Drives overview loading for the home dashboard.
///
/// Progressive loads ([OverviewLoadingMode.progressive]) emit partial
/// [Overview] snapshots; UI can render KPIs from [overview] while sections
/// are still loading ([completedOverviewSections]).
class OverviewController extends ChangeNotifier
    implements OverviewLoadOrchestrationHost {
  OverviewController(
    LoadOverviewUseCase loadOverviewUseCase, {
    LoadOverviewSectionsUseCase? loadSectionsUseCase,
    RetryAfterGate? retryAfterGate,
    AgentRpcCapabilitiesRegistry? agentRpcCapabilitiesRegistry,
    AgentQueriesRelayCancelScopeBinder? relayCancelScopeBinder,
    OverviewShellCache? shellCache,
  }) : _loadSectionsUseCase = loadSectionsUseCase,
       _retryAfterGate = retryAfterGate ?? RetryAfterGate(),
       _ownsRetryAfterGate = retryAfterGate == null,
       _agentRpcCapabilitiesRegistry = agentRpcCapabilitiesRegistry,
       _shellCache = shellCache,
       _session = OverviewLoadSession(
         relayCancelScopeBinder: relayCancelScopeBinder,
       ),
       _loadOverviewUseCase = loadOverviewUseCase {
    _loadOrchestration = OverviewLoadOrchestrationCoordinator(
      host: this,
      loadOverviewUseCase: _loadOverviewUseCase,
    );
    _sectionPrefetchCoordinator = OverviewSectionPrefetchCoordinator(
      prefetchSession: _prefetchSession,
      isOnRetryCooldown: () => isOnRetryCooldown,
      isLoading: () => isLoading,
      notifyListeners: _notifyListenersIfAlive,
      isNarrowViewport: _isNarrowPrefetchViewport,
    );
    // Re-publish gate ticks (countdown updates + window expired) through
    // the controller so the home page's retry button reacts without
    // subscribing to the gate directly.
    _retryAfterGate.addListener(_notifyListenersIfAlive);
  }

  static const double _narrowPrefetchViewportWidth = 600;

  final LoadOverviewUseCase _loadOverviewUseCase;
  final LoadOverviewSectionsUseCase? _loadSectionsUseCase;
  late final OverviewLoadOrchestrationCoordinator _loadOrchestration;

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
  final OverviewPrefetchSession _prefetchSession = OverviewPrefetchSession();
  late final OverviewSectionPrefetchCoordinator _sectionPrefetchCoordinator;
  final OverviewRpcCapabilitiesWarmUpCoordinator
  _rpcCapabilitiesWarmUpCoordinator =
      const OverviewRpcCapabilitiesWarmUpCoordinator();

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
  @override
  DashboardFilter get activeFilter => _activeFilter;

  @override
  set activeFilter(DashboardFilter value) => _activeFilter = value;

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
    _prefetchSession.dispose();
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
    super.notifyListeners();
  }

  @override
  bool get disposed => _disposed;

  @override
  OverviewLoadSession get session => _session;

  @override
  OverviewPrefetchSession get prefetchSession => _prefetchSession;

  @override
  OverviewShellCache? get shellCache => _shellCache;

  @override
  RetryAfterGate get retryAfterGate => _retryAfterGate;

  @override
  void notifyOverviewChanged() => _notifyListenersIfAlive();

  @override
  Future<bool> updateAvailableAgents(
    Overview overview,
    String userId,
    int generation,
  ) => _updateAvailableAgents(overview, userId, generation);

  @override
  void scheduleSectionPrefetch({
    required String userId,
    required String signature,
    required int generation,
    required OverviewLoadLabels rowLabels,
  }) {
    _scheduleSectionPrefetch(
      userId: userId,
      signature: signature,
      generation: generation,
      rowLabels: rowLabels,
    );
  }

  @override
  void publishShellCache(String signature) => _publishShellCache(signature);

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

  @override
  void setOverview(Overview? overview) {
    _overview = overview;
    _alertNamesProjection.update(overview);
  }

  @override
  bool isOverviewLoadStale(int generation) => _session.isStale(generation);

  @override
  Overview? get overview => _overview;
  bool get isLoading => _isLoadingInitial || _isRefreshing;
  @override
  bool get isLoadingInitial => _isLoadingInitial;
  @override
  bool get isRefreshing => _isRefreshing;
  @override
  set isLoadingInitial(bool value) => _isLoadingInitial = value;
  @override
  set isRefreshing(bool value) => _isRefreshing = value;
  bool get hasContent => _overview != null;
  @override
  String? get errorMessage => _errorMessage;
  @override
  set errorMessage(String? value) => _errorMessage = value;

  /// Last full overview load failure for agent-query UX (title, technical body).
  @override
  AppFailure? get loadFailure => _loadFailure;
  @override
  set loadFailure(AppFailure? value) => _loadFailure = value;

  /// Technical lines for the last full overview load failure (no stack trace).
  @override
  String? get errorDiagnosticBody => _errorDiagnosticBody;
  @override
  set errorDiagnosticBody(String? value) => _errorDiagnosticBody = value;
  @override
  Set<OverviewProgressiveSection> get completedOverviewSections =>
      _completedOverviewSections;
  @override
  set completedOverviewSections(Set<OverviewProgressiveSection> value) =>
      _completedOverviewSections = value;

  /// Chart nav cards whose SQL data is already in the home load or shell cache.
  Set<OverviewProgressiveSection> get chartNavReadySections {
    final ready = Set<OverviewProgressiveSection>.from(
      _completedOverviewSections,
    );
    final signature = _session.loadedSignature;
    if (signature != null) {
      final cached = _shellCache?.read(signature);
      if (cached != null) {
        ready.addAll(cached.completedSections);
      }
    }
    return Set<OverviewProgressiveSection>.unmodifiable(ready);
  }

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
  }) => _loadOrchestration.loadOverview(
    userId: userId,
    policy: policy,
    keepContentVisible: keepContentVisible,
    loadingMode: loadingMode,
    rowLabels: rowLabels,
    failureMessageBuilder: failureMessageBuilder,
  );

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
    setOverview(entry.overview);
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
    _sectionPrefetchCoordinator.schedule(
      useCase: useCase,
      cache: cache,
      userId: userId,
      signature: signature,
      loadGeneration: generation,
      activeFilter: _activeFilter,
      rowLabels: rowLabels,
      isLoadStale: isOverviewLoadStale,
      disposed: _disposed,
    );
  }

  bool _isNarrowPrefetchViewport() {
    final view = PlatformDispatcher.instance.implicitView;
    if (view == null) {
      return false;
    }
    final width = view.physicalSize.width / view.devicePixelRatio;
    return width < _narrowPrefetchViewportWidth;
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

    if (isOverviewLoadStale(generation)) {
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

  void _scheduleAgentRpcCapabilityPrefetch() {
    final registry = _agentRpcCapabilitiesRegistry;
    if (registry == null) {
      return;
    }
    _rpcCapabilitiesWarmUpCoordinator.schedule(
      registry: registry,
      availableAgents: _availableAgents,
      cancelScope: _session.cancelScope,
    );
  }
}

import 'dart:async';

import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/errors/retry_after_gate.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/core/socket/consumer_socket_connection.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/client_agents/application/client_agent_token_draft_store.dart';
import 'package:colmeia/features/client_agents/application/services/agent_presence_poller.dart';
import 'package:colmeia/features/client_agents/application/usecases/discard_queued_client_agent_request_access_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/get_client_agent_token_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/load_client_access_requests_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/load_client_access_status_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/load_client_agent_detail_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/load_client_approved_agents_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/observe_agent_presence_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/probe_client_approved_agent_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/queue_client_agent_remove_access_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/queue_client_agent_request_access_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/read_pending_client_agent_actions_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/retry_client_access_request_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/save_client_agent_token_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/sync_pending_client_agent_actions_use_case.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent_access_request.dart';
import 'package:colmeia/features/client_agents/domain/entities/paginated_result.dart';
import 'package:colmeia/features/client_agents/domain/entities/pending_agent_action.dart';
import 'package:colmeia/features/client_agents/presentation/controllers/client_agents_access_mutation_coordinator.dart';
import 'package:colmeia/features/client_agents/presentation/controllers/client_agents_access_request_actions_coordinator.dart';
import 'package:colmeia/features/client_agents/presentation/controllers/client_agents_approval_polling_coordinator.dart';
import 'package:colmeia/features/client_agents/presentation/controllers/client_agents_list_loading_coordinator.dart';
import 'package:colmeia/features/client_agents/presentation/controllers/client_agents_presence_coordinator.dart';
import 'package:colmeia/features/client_agents/presentation/controllers/client_agents_sync_coordinator.dart';
import 'package:colmeia/features/client_agents/presentation/controllers/client_agents_token_draft_coordinator.dart';
import 'package:colmeia/features/client_agents/presentation/controllers/request_access_submission_snapshot.dart';
import 'package:colmeia/features/client_agents/presentation/models/client_agent_access_request_row_input.dart';
import 'package:colmeia/features/client_agents/presentation/models/client_agents_presentation_message.dart';
import 'package:colmeia/shared/ports/agent_query_target_resolution_invalidator.dart';
import 'package:flutter/foundation.dart';
import 'package:result_dart/result_dart.dart' show Unit;

export 'package:colmeia/features/client_agents/presentation/controllers/request_access_submission_snapshot.dart';

class ClientAgentsController extends ChangeNotifier
    implements
        ClientAgentsPresenceHost,
        ClientAgentsApprovalPollingHost,
        ClientAgentsAccessMutationHost,
        ClientAgentsTokenDraftHost,
        ClientAgentsSyncHost,
        ClientAgentsListLoadingHost,
        ClientAgentsAccessRequestActionsHost {
  ClientAgentsController({
    required this._authController,
    required ClientAgentTokenDraftStore clientTokenDraftStore,
    required LoadClientApprovedAgentsUseCase loadApprovedAgentsUseCase,
    required LoadClientAccessRequestsUseCase loadAccessRequestsUseCase,
    required LoadClientAccessStatusUseCase loadClientAccessStatusUseCase,
    required LoadClientAgentDetailUseCase loadClientAgentDetailUseCase,
    required QueueClientAgentRequestAccessUseCase queueRequestAccessUseCase,
    required QueueClientAgentRemoveAccessUseCase queueRemoveAccessUseCase,
    required ProbeClientApprovedAgentUseCase probeClientApprovedAgentUseCase,
    required DiscardQueuedClientAgentRequestAccessUseCase
    discardQueuedClientAgentRequestAccessUseCase,
    required ReadPendingClientAgentActionsUseCase readPendingActionsUseCase,
    required SyncPendingClientAgentActionsUseCase syncPendingActionsUseCase,
    required GetClientAgentTokenUseCase getClientAgentTokenUseCase,
    required SaveClientAgentTokenUseCase saveClientAgentTokenUseCase,
    required RetryClientAccessRequestUseCase retryClientAccessRequestUseCase,
    ObserveAgentPresenceUseCase? observeAgentPresenceUseCase,
    AgentPresencePoller? agentPresencePoller,
    ConsumerSocketConnection? consumerSocketConnection,
    this._targetResolutionInvalidator,
    Duration hintConfirmDelay = const Duration(seconds: 5),
    RetryAfterGate? syncRetryAfterGate,
    RetryAfterGate? requestAccessRetryAfterGate,
  }) : _loadClientAgentDetailUseCase = loadClientAgentDetailUseCase,
       _requestAccessRetryAfterGate =
           requestAccessRetryAfterGate ?? RetryAfterGate(),
       _ownsRequestAccessRetryAfterGate = requestAccessRetryAfterGate == null {
    _presence = ClientAgentsPresenceCoordinator(
      host: this,
      loadClientAgentDetailUseCase: loadClientAgentDetailUseCase,
      hintConfirmDelay: hintConfirmDelay,
      observeAgentPresenceUseCase: observeAgentPresenceUseCase,
      agentPresencePoller: agentPresencePoller,
      consumerSocketConnection: consumerSocketConnection,
    );
    _approvalPolling = ClientAgentsApprovalPollingCoordinator(
      host: this,
      loadAccessRequestsUseCase: loadAccessRequestsUseCase,
      loadClientAgentDetailUseCase: loadClientAgentDetailUseCase,
      loadClientAccessStatusUseCase: loadClientAccessStatusUseCase,
      loadApprovedAgentsUseCase: loadApprovedAgentsUseCase,
    );
    _accessMutation = ClientAgentsAccessMutationCoordinator(
      host: this,
      loadApprovedAgentsUseCase: loadApprovedAgentsUseCase,
      queueRequestAccessUseCase: queueRequestAccessUseCase,
      queueRemoveAccessUseCase: queueRemoveAccessUseCase,
      probeClientApprovedAgentUseCase: probeClientApprovedAgentUseCase,
      discardQueuedClientAgentRequestAccessUseCase:
          discardQueuedClientAgentRequestAccessUseCase,
      readPendingActionsUseCase: readPendingActionsUseCase,
    );
    _tokenDraft = ClientAgentsTokenDraftCoordinator(
      host: this,
      clientTokenDraftStore: clientTokenDraftStore,
      getClientAgentTokenUseCase: getClientAgentTokenUseCase,
      saveClientAgentTokenUseCase: saveClientAgentTokenUseCase,
    );
    _sync = ClientAgentsSyncCoordinator(
      host: this,
      syncPendingActionsUseCase: syncPendingActionsUseCase,
      syncRetryAfterGate: syncRetryAfterGate,
    );
    _listLoading = ClientAgentsListLoadingCoordinator(
      host: this,
      loadApprovedAgentsUseCase: loadApprovedAgentsUseCase,
      loadAccessRequestsUseCase: loadAccessRequestsUseCase,
      readPendingActionsUseCase: readPendingActionsUseCase,
    );
    _accessRequestActions = ClientAgentsAccessRequestActionsCoordinator(
      host: this,
      retryClientAccessRequestUseCase: retryClientAccessRequestUseCase,
      discardQueuedClientAgentRequestAccessUseCase:
          discardQueuedClientAgentRequestAccessUseCase,
    );
    _requestAccessRetryAfterGate.addListener(_notifyListenersIfAlive);
  }

  final AuthController _authController;
  final LoadClientAgentDetailUseCase _loadClientAgentDetailUseCase;
  final AgentQueryTargetResolutionInvalidator? _targetResolutionInvalidator;

  /// Owns the realtime presence concern (socket subscription, hint timers,
  /// visibility-gated REST poller). All its dependencies are optional, so it
  /// is a no-op when the build does not opt into the socket transport.
  late final ClientAgentsPresenceCoordinator _presence;
  late final ClientAgentsApprovalPollingCoordinator _approvalPolling;
  late final ClientAgentsAccessMutationCoordinator _accessMutation;
  late final ClientAgentsTokenDraftCoordinator _tokenDraft;
  late final ClientAgentsSyncCoordinator _sync;
  late final ClientAgentsListLoadingCoordinator _listLoading;
  late final ClientAgentsAccessRequestActionsCoordinator _accessRequestActions;

  /// Same idea for the request-access flow. The hub returns
  /// `Retry-After` for the dedicated `REST_CLIENT_ME_AGENTS_POST_RATE_LIMIT_*`
  /// quota, so a flurry of submissions does not bypass the throttle.
  final RetryAfterGate _requestAccessRetryAfterGate;

  final bool _ownsRequestAccessRetryAfterGate;

  bool _isDisposed = false;
  bool _isLoadingInitial = false;
  bool _isRefreshing = false;
  bool _isSyncingPending = false;
  bool _isMutating = false;
  bool _hasLoadedInitialData = false;
  @override
  bool get hasLoadedInitialData => _hasLoadedInitialData;
  @override
  set hasLoadedInitialData(bool value) => _hasLoadedInitialData = value;
  @override
  set isLoadingInitial(bool value) => _isLoadingInitial = value;
  @override
  set isRefreshing(bool value) => _isRefreshing = value;
  @override
  int get refreshAllToken => _refreshAllToken;
  @override
  set refreshAllToken(int value) => _refreshAllToken = value;
  ClientAgentsPresentationMessage? _actionError;
  ClientAgentsPresentationNotice? _actionNotice;
  ClientAgentsPresentationMessage? _approvedAgentsError;
  ClientAgentsPresentationMessage? _accessRequestsError;
  ClientAgentsPresentationMessage? _pendingActionsError;

  PaginatedResult<ClientAgent>? _approvedAgents;
  PaginatedResult<ClientAgentAccessRequest>? _accessRequests;
  List<PendingAgentAction> _pendingActions = const <PendingAgentAction>[];
  int _refreshAllToken = 0;
  Future<void> _pendingMutationTail = Future.value();

  Future<T> _runPendingMutationSerialized<T>(
    Future<T> Function() action, {
    bool resetBusyFlags = true,
  }) {
    final completer = Completer<T>();
    _pendingMutationTail = _pendingMutationTail.then((_) async {
      try {
        completer.complete(await action());
      } on Object catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      } finally {
        if (resetBusyFlags && !_isDisposed) {
          _isMutating = false;
          _isSyncingPending = false;
          _notifyListenersIfAlive();
        }
      }
    });
    return completer.future;
  }

  bool get isLoading => _isLoadingInitial || _isRefreshing;
  @override
  bool get isLoadingInitial => _isLoadingInitial;
  @override
  bool get isRefreshing => _isRefreshing;
  bool get isSyncing => _isSyncingPending;
  bool get isMutating => _isMutating;
  @override
  bool get isBusy => _isSyncingPending || _isMutating;
  @override
  ClientAgentsPresentationMessage? get actionError => _actionError;
  ClientAgentsPresentationNotice? get actionNotice => _actionNotice;
  ClientAgentsPresentationMessage? get approvedAgentsError =>
      _approvedAgentsError;
  ClientAgentsPresentationMessage? get accessRequestsError =>
      _accessRequestsError;
  ClientAgentsPresentationMessage? get pendingActionsError =>
      _pendingActionsError;
  PaginatedResult<ClientAgent>? get approvedAgents => _approvedAgents;
  bool get approvedAgentsResultTruncated =>
      _approvedAgents?.isResultTruncated ?? false;
  bool get accessRequestsResultTruncated =>
      _accessRequests?.isResultTruncated ?? false;
  PaginatedResult<ClientAgentAccessRequest>? get accessRequests =>
      _accessRequests;
  List<PendingAgentAction> get pendingActions => _pendingActions;

  Set<String> get pendingRemoveAgentIds {
    return _pendingActions
        .where(
          (action) =>
              action.type == PendingAgentActionType.removeAccess &&
              action.state != PendingAgentActionState.synced,
        )
        .map((action) => action.agentId)
        .toSet();
  }

  /// Time left in the `Retry-After` cooldown for the sync action, or
  /// `null` when the action is allowed.
  Duration? get syncRetryAfter => _sync.syncRetryAfter;
  bool get isSyncOnCooldown => _sync.isSyncOnCooldown;

  /// Time left in the `Retry-After` cooldown for the request-access
  /// action, or `null` when the action is allowed.
  Duration? get requestAccessRetryAfter =>
      _requestAccessRetryAfterGate.remaining;
  bool get isRequestAccessOnCooldown => !_requestAccessRetryAfterGate.isOpen;

  Future<void> initialize() async {
    if (_hasLoadedInitialData || isLoading) {
      return;
    }
    await _listLoading.refreshAll(keepContentVisible: false);
    // Subscribe to realtime presence after the initial load so the first
    // hints/catalog events have a populated `_approvedAgents` to upsert
    // into. Subscription is idempotent — re-running `initialize()` is a
    // no-op (early return above), and the presence use case may not be
    // registered when the build does not opt in.
    _presence.subscribe();
  }

  Future<void> refreshAll() async {
    if (isBusy) {
      await _runPendingMutationSerialized(
        () => _listLoading.refreshAll(keepContentVisible: hasContent),
        resetBusyFlags: false,
      );
      return;
    }
    await _listLoading.refreshAll(keepContentVisible: hasContent);
  }

  bool get hasContent => hasListContent();

  /// Reads the token to prefill in the request-access form for [agentId].
  ///
  /// Server is the source of truth for already-approved agents — we hit the
  /// dedicated `GET /client/me/agents/{id}/client-token` endpoint when this
  /// id is in the in-memory approved list and falls back to the local cache
  /// on auth/network failure (so the form keeps working offline). For
  /// agents that are NOT yet approved, the server returns 403 by design and
  /// only the local draft is meaningful.
  Future<String?> readLocalClientToken(String agentId) =>
      _tokenDraft.readLocalClientToken(agentId);

  @override
  Future<void> persistLocalClientTokenDraftLine({
    required String agentIdRaw,
    required String clientTokenRaw,
  }) => _tokenDraft.persistLocalClientTokenDraftLine(
    agentIdRaw: agentIdRaw,
    clientTokenRaw: clientTokenRaw,
  );

  Future<bool> submitAccessRequestWithLocalTokens(
    List<ClientAgentAccessRequestRowInput> rows,
  ) => _tokenDraft.submitAccessRequestWithLocalTokens(rows);

  /// Optional callback fired by [requestAccess] right after the controller
  /// has resolved every id into either "relinked" (server already linked the
  /// client) or "queued" (POST will fire on the next sync). Lets callers
  /// (e.g. `submitAccessRequestWithLocalTokens`) apply side effects keyed by
  /// the resolved ids without re-reading the controller's internal state.
  @override
  Future<bool> requestAccess({
    required Set<String> agentIds,
    Future<void> Function(RequestAccessSubmissionSnapshot snapshot)? onResolved,
  }) async {
    if (agentIds.isEmpty) {
      return false;
    }
    final userId = _authController.session?.userId;
    if (userId == null || userId.isEmpty) {
      _actionError =
          ClientAgentsPresentationMessage.clientAgentsSessionUnavailableRequest();
      _notifyListenersIfAlive();
      return false;
    }

    return _runPendingMutationSerialized(() async {
      if (_isDisposed) {
        return false;
      }
      _isMutating = true;
      _notifyListenersIfAlive();
      return _accessMutation.requestAccess(
        userId: userId,
        agentIds: agentIds,
        onResolved: onResolved,
        onQueueResult: _maybeArmRequestAccessRetryGateFromResult,
      );
    });
  }

  Future<void> removeAccess({
    required Set<String> agentIds,
  }) async {
    if (agentIds.isEmpty) {
      return;
    }
    final userId = _authController.session?.userId;
    if (userId == null || userId.isEmpty) {
      _actionError =
          ClientAgentsPresentationMessage.clientAgentsSessionUnavailableRemove();
      _notifyListenersIfAlive();
      return;
    }

    await _runPendingMutationSerialized(() async {
      if (_isDisposed) {
        return;
      }
      _isMutating = true;
      _notifyListenersIfAlive();
      await _accessMutation.removeAccess(userId: userId, agentIds: agentIds);
    });
  }

  Future<void> retryAccessRequest({
    required ClientAgentAccessRequest request,
  }) async {
    await _runPendingMutationSerialized(
      () => _accessRequestActions.retryAccessRequest(request: request),
    );
  }

  /// Drops a **local** `requestAccess` action that is still `queued` or
  /// `failed` (not yet successfully synced). Does not cancel a request that
  /// already exists on the server with status pending; that would require a
  /// dedicated hub route.
  Future<void> discardQueuedRequestAccess({
    required PendingAgentAction action,
  }) async {
    await _runPendingMutationSerialized(
      () => _accessRequestActions.discardQueuedRequestAccess(action: action),
    );
  }

  Future<void> syncPending({bool autoTriggered = false}) =>
      _sync.syncPending(autoTriggered: autoTriggered);

  @override
  Future<void> refreshAfterMutation({required String userId}) =>
      _refreshAfterMutation(userId: userId);

  Future<void> _refreshAfterMutation({
    required String userId,
  }) async {
    await _listLoading.refreshAfterMutation(userId: userId);
  }

  @override
  ClientAgentsPresentationMessage? consumeResult<T extends Object>({
    required AppResult<T> result,
    required String operation,
    ValueChanged<T>? onSuccess,
  }) {
    return result.fold(
      (value) {
        onSuccess?.call(value);
        return null;
      },
      (failure) {
        AppLogger.warning(
          'Client agents operation failed',
          context: <String, Object?>{
            'operation': operation,
            'technicalMessage': failure.message,
          },
          error: failure.cause ?? failure,
          stackTrace: failure.stackTrace,
        );
        return ClientAgentsPresentationMessage.failure(failure);
      },
    );
  }

  void clearActionError() {
    if (_actionError == null) {
      return;
    }
    _actionError = null;
    _notifyListenersIfAlive();
  }

  @override
  void clearActionFeedback() {
    if (_actionNotice == null) {
      return;
    }
    _clearActionFeedback();
    _notifyListenersIfAlive();
  }

  @override
  void clearSectionErrors() {
    _actionError = null;
    _approvedAgentsError = null;
    _accessRequestsError = null;
    _pendingActionsError = null;
  }

  @override
  bool hasListContent() {
    return _approvedAgents != null ||
        _accessRequests != null ||
        _pendingActions.isNotEmpty;
  }

  @override
  void notifyListChanged() => _notifyListenersIfAlive();

  @override
  void scheduleLocalTokenServerFlushForApprovedAgents({
    required String userId,
  }) {
    _tokenDraft.scheduleLocalTokenServerFlushForApprovedAgents(userId: userId);
  }

  @override
  void scheduleAutoSyncIfNeeded() => _sync.scheduleAutoSyncIfNeeded();

  @override
  void notifyActionsChanged() => _notifyListenersIfAlive();

  void _clearActionFeedback() {
    _actionNotice = null;
  }

  void _setActionFeedback({
    required ClientAgentsPresentationMessage message,
    required ClientAgentsActionFeedbackKind kind,
  }) {
    _actionNotice = ClientAgentsPresentationNotice(
      message: message,
      kind: kind,
    );
  }

  @override
  Future<void> hydrateApprovedAgentsInMemory({
    required String userId,
    required Iterable<String> agentIds,
  }) async {
    final ids = agentIds.toSet();
    if (ids.isEmpty) {
      return;
    }
    final results = await Future.wait(
      ids.map(
        (agentId) => _loadClientAgentDetailUseCase(
          userId: userId,
          agentId: agentId,
        ),
      ),
    );
    if (_isDisposed) {
      return;
    }
    final approved = <ClientAgent>[];
    for (final result in results) {
      final agent = result.getOrNull();
      if (agent != null) {
        approved.add(agent);
      }
    }
    if (approved.isEmpty) {
      return;
    }
    _upsertApprovedAgentsInMemory(approved);
    _notifyListenersIfAlive();
  }

  void _upsertApprovedAgentsInMemory(List<ClientAgent> approvedAgents) {
    final current = _approvedAgents;
    if (current == null) {
      _approvedAgents = PaginatedResult<ClientAgent>(
        items: approvedAgents,
        count: approvedAgents.length,
        total: approvedAgents.length,
        page: 1,
        pageSize: approvedAgents.length,
      );
      return;
    }

    final mergedByAgentId = <String, ClientAgent>{
      for (final agent in current.items) agent.agentId: agent,
    };
    for (final agent in approvedAgents) {
      mergedByAgentId[agent.agentId] = agent;
    }
    final mergedItems = mergedByAgentId.values.toList(growable: false);
    _approvedAgents = PaginatedResult<ClientAgent>(
      items: mergedItems,
      count: mergedItems.length,
      total: mergedItems.length > current.total
          ? mergedItems.length
          : current.total,
      page: current.page,
      pageSize: current.pageSize > mergedItems.length
          ? current.pageSize
          : mergedItems.length,
    );
  }

  void _notifyListenersIfAlive() {
    if (_isDisposed) {
      return;
    }
    notifyListeners();
  }

  // ----- Realtime presence host (delegated to the coordinator) -----

  /// Page-level hook (RouteAware): the `client_agents` screen visibility
  /// changed. Delegates to the presence coordinator, which gates the
  /// optional REST poller. No-op when the socket layer is not wired.
  void setScreenVisible({required bool isVisible}) {
    _presence.setScreenVisible(isVisible: isVisible);
  }

  void onScreenVisible() {
    setScreenVisible(isVisible: true);
  }

  void onScreenHidden() {
    setScreenVisible(isVisible: false);
  }

  @override
  bool get isDisposed => _isDisposed;

  @override
  String? get currentUserId => _authController.session?.userId;

  @override
  PaginatedResult<ClientAgent>? get approvedAgentsSnapshot => _approvedAgents;

  @override
  void replaceApprovedAgents(PaginatedResult<ClientAgent> value) {
    _approvedAgents = value;
  }

  @override
  void upsertApprovedAgentsInMemory(List<ClientAgent> agents) {
    _upsertApprovedAgentsInMemory(agents);
  }

  @override
  void notifyPresenceChanged() {
    _notifyListenersIfAlive();
  }

  // ----- Access mutation host (delegated to the coordinator) -----

  @override
  List<PendingAgentAction> get pendingActionsSnapshot => _pendingActions;

  @override
  void setActionError(ClientAgentsPresentationMessage? error) {
    _actionError = error;
  }

  @override
  void replacePendingActions(List<PendingAgentAction> actions) {
    _pendingActions = actions;
  }

  @override
  void setPendingActionsError(ClientAgentsPresentationMessage? error) {
    _pendingActionsError = error;
  }

  @override
  void notifyMutationChanged() {
    _notifyListenersIfAlive();
    _sync.scheduleAutoSyncIfNeeded();
  }

  // ----- Approval polling host (delegated to the coordinator) -----

  @override
  PaginatedResult<ClientAgentAccessRequest>? get accessRequestsSnapshot =>
      _accessRequests;

  @override
  void replaceAccessRequests(PaginatedResult<ClientAgentAccessRequest> value) {
    _accessRequests = value;
  }

  @override
  void setApprovedAgentsError(ClientAgentsPresentationMessage? error) {
    _approvedAgentsError = error;
  }

  @override
  void setAccessRequestsError(ClientAgentsPresentationMessage? error) {
    _accessRequestsError = error;
  }

  @override
  void setActionFeedback({
    required ClientAgentsPresentationMessage message,
    required ClientAgentsActionFeedbackKind kind,
  }) {
    _setActionFeedback(message: message, kind: kind);
  }

  @override
  void scheduleLocalTokenServerFlush({
    required String userId,
    required Iterable<String> agentIds,
  }) {
    unawaited(
      _tokenDraft.pushLocalTokenToServerAfterApproval(
        userId: userId,
        agentIds: agentIds,
      ),
    );
  }

  @override
  void invalidateTargetResolution({required String userId}) {
    _targetResolutionInvalidator?.invalidate(userId: userId);
  }

  @override
  void notifyApprovalPollingChanged() {
    _notifyListenersIfAlive();
  }

  @override
  ClientAgentAccessRequest? accessRequestForAgentId(String agentId) {
    final items = _accessRequests?.items;
    if (items == null) {
      return null;
    }
    for (final request in items) {
      if (request.agentId == agentId) {
        return request;
      }
    }
    return null;
  }

  // ----- Token draft host -----

  @override
  void notifyTokenDraftChanged() => _notifyListenersIfAlive();

  // ----- Sync host -----

  @override
  void setSyncingPending({required bool value}) => _isSyncingPending = value;

  @override
  void setMutating({required bool value}) => _isMutating = value;

  @override
  void notifySyncChanged() => _notifyListenersIfAlive();

  @override
  Future<T> runPendingMutationSerialized<T>(
    Future<T> Function() action, {
    bool resetBusyFlags = true,
  }) => _runPendingMutationSerialized(action, resetBusyFlags: resetBusyFlags);

  @override
  void startApprovalPolling({
    required String userId,
    required Set<String> agentIds,
  }) {
    _approvalPolling.startPolling(userId: userId, agentIds: agentIds);
  }

  @override
  void pushLocalTokensAfterApproval({
    required String userId,
    required Iterable<String> agentIds,
  }) {
    unawaited(
      _tokenDraft.pushLocalTokenToServerAfterApproval(
        userId: userId,
        agentIds: agentIds,
      ),
    );
  }

  @override
  void dispose() {
    if (_isDisposed) {
      // Idempotent: tests and the page layer occasionally double-tap
      // dispose during teardown. ChangeNotifier.dispose throws on a
      // second call, so we short-circuit here.
      return;
    }
    _approvalPolling.dispose();
    _presence.dispose();
    _sync.dispose();
    _requestAccessRetryAfterGate.removeListener(_notifyListenersIfAlive);
    if (_ownsRequestAccessRetryAfterGate) {
      _requestAccessRetryAfterGate.dispose();
    }
    _isDisposed = true;
    super.dispose();
  }

  void _maybeArmRequestAccessRetryGateFromResult(AppResult<Unit> result) {
    final retryAfter = _retryAfterFromResult(result);
    if (retryAfter != null) {
      _requestAccessRetryAfterGate.arm(retryAfter);
    }
  }

  Duration? _retryAfterFromResult<T extends Object>(AppResult<T> result) {
    final failure = result.exceptionOrNull();
    if (failure is NetworkFailure) {
      return failure.retryAfter;
    }
    return null;
  }
}

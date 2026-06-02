import 'dart:async';
import 'dart:math' show min;

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
import 'package:colmeia/features/client_agents/domain/entities/agent_access_request_status.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent_access_request.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent_token_constraints.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agents_list_page_size.dart';
import 'package:colmeia/features/client_agents/domain/entities/paginated_query.dart';
import 'package:colmeia/features/client_agents/domain/entities/paginated_result.dart';
import 'package:colmeia/features/client_agents/domain/entities/pending_agent_action.dart';
import 'package:colmeia/features/client_agents/domain/entities/sync_pending_agent_actions_result.dart';
import 'package:colmeia/features/client_agents/presentation/controllers/client_agents_presence_coordinator.dart';
import 'package:colmeia/features/client_agents/presentation/controllers/request_access_submission_snapshot.dart';
import 'package:colmeia/features/client_agents/presentation/models/client_agent_access_request_row_input.dart';
import 'package:colmeia/features/client_agents/presentation/models/client_agents_presentation_message.dart';
import 'package:colmeia/features/client_agents/presentation/utils/client_agent_id_format.dart';
import 'package:colmeia/shared/ports/agent_query_target_resolution_invalidator.dart';
import 'package:flutter/foundation.dart';
import 'package:result_dart/result_dart.dart' show Unit;

export 'package:colmeia/features/client_agents/presentation/controllers/request_access_submission_snapshot.dart';

class ClientAgentsController extends ChangeNotifier
    implements ClientAgentsPresenceHost {
  ClientAgentsController({
    required AuthController authController,
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
    AgentQueryTargetResolutionInvalidator? targetResolutionInvalidator,
    Duration hintConfirmDelay = const Duration(seconds: 5),
    RetryAfterGate? syncRetryAfterGate,
    RetryAfterGate? requestAccessRetryAfterGate,
  }) : _authController = authController,
       _clientTokenDraftStore = clientTokenDraftStore,
       _loadApprovedAgentsUseCase = loadApprovedAgentsUseCase,
       _loadAccessRequestsUseCase = loadAccessRequestsUseCase,
       _loadClientAccessStatusUseCase = loadClientAccessStatusUseCase,
       _loadClientAgentDetailUseCase = loadClientAgentDetailUseCase,
       _queueRequestAccessUseCase = queueRequestAccessUseCase,
       _queueRemoveAccessUseCase = queueRemoveAccessUseCase,
       _probeClientApprovedAgentUseCase = probeClientApprovedAgentUseCase,
       _discardQueuedClientAgentRequestAccessUseCase =
           discardQueuedClientAgentRequestAccessUseCase,
       _readPendingActionsUseCase = readPendingActionsUseCase,
       _syncPendingActionsUseCase = syncPendingActionsUseCase,
       _getClientAgentTokenUseCase = getClientAgentTokenUseCase,
       _saveClientAgentTokenUseCase = saveClientAgentTokenUseCase,
       _retryClientAccessRequestUseCase = retryClientAccessRequestUseCase,
       _targetResolutionInvalidator = targetResolutionInvalidator,
       _syncRetryAfterGate = syncRetryAfterGate ?? RetryAfterGate(),
       _ownsSyncRetryAfterGate = syncRetryAfterGate == null,
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
    // Re-broadcast gate ticks so consumer widgets that already listen to
    // the controller refresh the countdown label without subscribing to
    // each gate individually.
    _syncRetryAfterGate.addListener(_handleSyncRetryAfterGateChanged);
    _requestAccessRetryAfterGate.addListener(_notifyListenersIfAlive);
  }

  static const Duration _approvalPollingInterval = Duration(seconds: 10);
  static const Duration _approvalPollingTimeout = Duration(minutes: 3);
  static const PaginatedQuery _approvalPollingQuery = PaginatedQuery(
    pageSize: kClientAgentsListPageSize,
  );
  static const int _approvedAgentsProbeConcurrency = 4;

  final AuthController _authController;
  final ClientAgentTokenDraftStore _clientTokenDraftStore;
  final LoadClientApprovedAgentsUseCase _loadApprovedAgentsUseCase;
  final LoadClientAccessRequestsUseCase _loadAccessRequestsUseCase;
  final LoadClientAccessStatusUseCase _loadClientAccessStatusUseCase;
  final LoadClientAgentDetailUseCase _loadClientAgentDetailUseCase;
  final QueueClientAgentRequestAccessUseCase _queueRequestAccessUseCase;
  final QueueClientAgentRemoveAccessUseCase _queueRemoveAccessUseCase;
  final ProbeClientApprovedAgentUseCase _probeClientApprovedAgentUseCase;
  final DiscardQueuedClientAgentRequestAccessUseCase
  _discardQueuedClientAgentRequestAccessUseCase;
  final ReadPendingClientAgentActionsUseCase _readPendingActionsUseCase;
  final SyncPendingClientAgentActionsUseCase _syncPendingActionsUseCase;
  final GetClientAgentTokenUseCase _getClientAgentTokenUseCase;
  final SaveClientAgentTokenUseCase _saveClientAgentTokenUseCase;
  final RetryClientAccessRequestUseCase _retryClientAccessRequestUseCase;
  final AgentQueryTargetResolutionInvalidator? _targetResolutionInvalidator;

  /// Owns the realtime presence concern (socket subscription, hint timers,
  /// visibility-gated REST poller). All its dependencies are optional, so it
  /// is a no-op when the build does not opt into the socket transport.
  late final ClientAgentsPresenceCoordinator _presence;

  /// Cooldown for `syncPending`. Armed every time the underlying use
  /// case fails with a `Retry-After` hint; the UI uses
  /// [syncRetryAfter] / [isSyncOnCooldown] to gray the button out.
  final RetryAfterGate _syncRetryAfterGate;

  final bool _ownsSyncRetryAfterGate;

  /// Same idea for the request-access flow. The hub returns
  /// `Retry-After` for the dedicated `REST_CLIENT_ME_AGENTS_POST_RATE_LIMIT_*`
  /// quota, so a flurry of submissions does not bypass the throttle.
  final RetryAfterGate _requestAccessRetryAfterGate;

  final bool _ownsRequestAccessRetryAfterGate;

  bool _isDisposed = false;
  bool _isLoadingInitial = false;
  bool _isRefreshing = false;
  bool _isSyncing = false;
  bool _hasLoadedInitialData = false;
  bool _isPollingApprovals = false;
  ClientAgentsPresentationMessage? _actionError;
  ClientAgentsPresentationNotice? _actionNotice;
  ClientAgentsPresentationMessage? _approvedAgentsError;
  ClientAgentsPresentationMessage? _accessRequestsError;
  ClientAgentsPresentationMessage? _pendingActionsError;

  PaginatedResult<ClientAgent>? _approvedAgents;
  PaginatedResult<ClientAgentAccessRequest>? _accessRequests;
  List<PendingAgentAction> _pendingActions = const <PendingAgentAction>[];
  final Set<String> _trackedApprovalAgentIds = <String>{};
  final Set<String> _pendingLocalTokenServerFlushAgentIds = <String>{};
  final Map<String, DateTime> _approvalPollingStartedAtByAgentId =
      <String, DateTime>{};
  Timer? _approvalPollingTimer;
  int _refreshAllToken = 0;
  Future<void> _pendingMutationTail = Future.value();

  Future<T> _runPendingMutationSerialized<T>(Future<T> Function() action) {
    final completer = Completer<T>();
    _pendingMutationTail = _pendingMutationTail.then((_) async {
      try {
        completer.complete(await action());
      } on Object catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }

  bool get isLoading => _isLoadingInitial || _isRefreshing;
  bool get isLoadingInitial => _isLoadingInitial;
  bool get isRefreshing => _isRefreshing;
  bool get isSyncing => _isSyncing;
  ClientAgentsPresentationMessage? get actionError => _actionError;
  ClientAgentsPresentationNotice? get actionNotice => _actionNotice;
  ClientAgentsPresentationMessage? get approvedAgentsError =>
      _approvedAgentsError;
  ClientAgentsPresentationMessage? get accessRequestsError =>
      _accessRequestsError;
  ClientAgentsPresentationMessage? get pendingActionsError =>
      _pendingActionsError;
  PaginatedResult<ClientAgent>? get approvedAgents => _approvedAgents;
  PaginatedResult<ClientAgentAccessRequest>? get accessRequests =>
      _accessRequests;
  List<PendingAgentAction> get pendingActions => _pendingActions;

  /// Time left in the `Retry-After` cooldown for the sync action, or
  /// `null` when the action is allowed.
  Duration? get syncRetryAfter => _syncRetryAfterGate.remaining;
  bool get isSyncOnCooldown => !_syncRetryAfterGate.isOpen;

  /// Time left in the `Retry-After` cooldown for the request-access
  /// action, or `null` when the action is allowed.
  Duration? get requestAccessRetryAfter =>
      _requestAccessRetryAfterGate.remaining;
  bool get isRequestAccessOnCooldown => !_requestAccessRetryAfterGate.isOpen;

  Future<void> initialize() async {
    if (_hasLoadedInitialData || isLoading) {
      return;
    }
    await _refreshAll(keepContentVisible: false);
    // Subscribe to realtime presence after the initial load so the first
    // hints/catalog events have a populated `_approvedAgents` to upsert
    // into. Subscription is idempotent — re-running `initialize()` is a
    // no-op (early return above), and the presence use case may not be
    // registered when the build does not opt in.
    _presence.subscribe();
  }

  Future<void> refreshAll() async {
    await _refreshAll(keepContentVisible: hasContent);
  }

  bool get hasContent {
    return _approvedAgents != null ||
        _accessRequests != null ||
        _pendingActions.isNotEmpty;
  }

  Future<void> _refreshAll({
    required bool keepContentVisible,
  }) async {
    final userId = _authController.session?.userId;
    if (userId == null || userId.isEmpty) {
      _actionError =
          ClientAgentsPresentationMessage.clientAgentsSessionUnavailableLoad();
      _notifyListenersIfAlive();
      return;
    }

    final refreshToken = ++_refreshAllToken;
    if (keepContentVisible) {
      _isLoadingInitial = false;
      _isRefreshing = true;
    } else {
      _isRefreshing = false;
      _isLoadingInitial = true;
    }
    _clearSectionErrors();
    _notifyListenersIfAlive();

    const query = PaginatedQuery(pageSize: kClientAgentsListPageSize);
    try {
      late AppResult<PaginatedResult<ClientAgent>> approvedResult;
      late AppResult<PaginatedResult<ClientAgentAccessRequest>> requestsResult;
      late AppResult<List<PendingAgentAction>> pendingResult;

      await Future.wait<void>(<Future<void>>[
        _loadApprovedAgentsUseCase(
          userId: userId,
          query: query,
          refresh: keepContentVisible,
        ).then((value) => approvedResult = value),
        _loadAccessRequestsUseCase(
          userId: userId,
          query: query,
        ).then((value) => requestsResult = value),
        _readPendingActionsUseCase(userId: userId).then(
          (value) => pendingResult = value,
        ),
      ]);
      if (_isDisposed || refreshToken != _refreshAllToken) {
        return;
      }

      _approvedAgentsError = _consumeResult(
        result: approvedResult,
        onSuccess: (value) => _approvedAgents = value,
        operation: 'loadApprovedClientAgents',
      );
      _accessRequestsError = _consumeResult(
        result: requestsResult,
        onSuccess: (value) => _accessRequests = value,
        operation: 'loadClientAgentAccessRequests',
      );
      _pendingActionsError = _consumeResult(
        result: pendingResult,
        onSuccess: (value) => _pendingActions = value,
        operation: 'readPendingClientAgentActions',
      );
      _scheduleLocalTokenServerFlushForApprovedAgents(userId: userId);
    } finally {
      if (!_isDisposed && refreshToken == _refreshAllToken) {
        if (keepContentVisible) {
          _isRefreshing = false;
        } else {
          _isLoadingInitial = false;
        }
        _hasLoadedInitialData = true;
        _notifyListenersIfAlive();
        _scheduleAutoSyncIfNeeded();
      }
    }
  }

  /// Reads the token to prefill in the request-access form for [agentId].
  ///
  /// Server is the source of truth for already-approved agents — we hit the
  /// dedicated `GET /client/me/agents/{id}/client-token` endpoint when this
  /// id is in the in-memory approved list and falls back to the local cache
  /// on auth/network failure (so the form keeps working offline). For
  /// agents that are NOT yet approved, the server returns 403 by design and
  /// only the local draft is meaningful.
  Future<String?> readLocalClientToken(String agentId) async {
    final userId = _authController.session?.userId;
    if (userId == null || userId.isEmpty) {
      return null;
    }
    final trimmedAgentId = agentId.trim();
    if (trimmedAgentId.isEmpty) {
      return null;
    }
    if (_approvedAgentIds().contains(trimmedAgentId)) {
      final result = await _getClientAgentTokenUseCase(
        userId: userId,
        agentId: trimmedAgentId,
      );
      final snapshot = result.getOrNull();
      if (snapshot != null) {
        return snapshot.token;
      }
      // Server unreachable / forbidden: fall back to local cache below.
    }
    return _clientTokenDraftStore.read(
      userId: userId,
      agentId: trimmedAgentId,
    );
  }

  /// Persists or clears the local token for a draft row when the agent id is
  /// a valid UUID (used from the request-access form while editing).
  ///
  /// Tokens longer than [ClientAgentTokenConstraints.maxLength] are
  /// dropped before touching storage so a value the server would reject
  /// never lands on disk.
  Future<void> persistLocalClientTokenDraftLine({
    required String agentIdRaw,
    required String clientTokenRaw,
  }) async {
    final userId = _authController.session?.userId;
    if (userId == null || userId.isEmpty) {
      return;
    }
    final id = agentIdRaw.trim();
    if (!isValidClientAgentId(id)) {
      return;
    }
    final token = clientTokenRaw.trim();
    if (token.length > ClientAgentTokenConstraints.maxLength) {
      AppLogger.warning(
        'Client token draft exceeds server cap; not persisted',
        context: <String, Object?>{
          'operation': 'persistLocalClientTokenDraftLine',
          'agentId': id,
          'length': token.length,
          'cap': ClientAgentTokenConstraints.maxLength,
        },
      );
      return;
    }
    if (token.isEmpty) {
      await _clientTokenDraftStore.delete(userId: userId, agentId: id);
    } else {
      await _clientTokenDraftStore.write(
        userId: userId,
        agentId: id,
        clientToken: token,
      );
    }
  }

  /// Submits an access request transactionally w.r.t. the local token cache.
  ///
  /// 1. Snapshots existing local tokens for the rows we are about to touch
  ///    so we can roll back on failure.
  /// 2. Validates token length BEFORE touching storage.
  /// 3. Calls [requestAccess] (which probes / classifies / queues).
  /// 4. On success, applies the new token values:
  ///    - For ids the server reported as **already linked** (relink path),
  ///      pushes the token to the server via [SaveClientAgentTokenUseCase]
  ///      so the bridge can use it on the next SQL call. The use case
  ///      mirrors into the local cache on success.
  ///    - For ids that landed in the local pending queue (new request),
  ///      writes the token to the local cache. After approval polling
  ///      detects the link, [_pushLocalTokenToServerAfterApproval] flushes
  ///      it to the server.
  ///    - For blocked ids (already approved/pending/queued), the local
  ///      cache is left untouched — the user's draft cannot silently
  ///      overwrite a token they did not intend to change.
  /// 5. On failure of the underlying [requestAccess], the local cache for
  ///    the touched ids is restored to its pre-submit state.
  Future<bool> submitAccessRequestWithLocalTokens(
    List<ClientAgentAccessRequestRowInput> rows,
  ) async {
    final userId = _authController.session?.userId;
    if (userId == null || userId.isEmpty) {
      _actionError =
          ClientAgentsPresentationMessage.clientAgentsSessionUnavailableRequest();
      _notifyListenersIfAlive();
      return false;
    }

    final tokenByAgentId = <String, String>{};
    final tokensTooLongIds = <String>[];
    for (final row in rows) {
      final id = row.agentIdRaw.trim();
      if (!isValidClientAgentId(id)) {
        continue;
      }
      final token = row.clientTokenRaw.trim();
      if (token.length > ClientAgentTokenConstraints.maxLength) {
        tokensTooLongIds.add(id);
        continue;
      }
      tokenByAgentId[id] = token;
    }

    if (tokensTooLongIds.isNotEmpty) {
      _actionError =
          ClientAgentsPresentationMessage.clientAgentsValidationTokenTooLong(
            maxLength: ClientAgentTokenConstraints.maxLength,
            agentIds: tokensTooLongIds,
          );
      _notifyListenersIfAlive();
      return false;
    }

    final requestedIds = tokenByAgentId.keys.toSet();
    if (requestedIds.isEmpty) {
      return false;
    }

    // Snapshot existing local tokens for the ids we may touch, so we can
    // roll back on failure. `null` means "no token previously stored".
    final localSnapshotById = <String, String?>{};
    for (final id in requestedIds) {
      localSnapshotById[id] = await _clientTokenDraftStore.read(
        userId: userId,
        agentId: id,
      );
    }

    AppLogger.info(
      'Client agents request access submission starting',
      context: <String, Object?>{
        'operation': 'submitAccessRequestWithLocalTokens',
        'requestedCount': requestedIds.length,
        'withTokenCount': tokenByAgentId.values
            .where((t) => t.isNotEmpty)
            .length,
      },
    );

    final outcome = await requestAccess(
      agentIds: requestedIds,
      onResolved: (snapshot) async {
        await _applySubmittedTokensTransactionally(
          userId: userId,
          tokenByAgentId: tokenByAgentId,
          snapshot: snapshot,
        );
      },
    );

    if (!outcome) {
      // Best-effort rollback: requestAccess did not place anything in the
      // local pending queue (auth abort or all blocked). Leave the local
      // cache exactly as it was before this call so the form retry stays
      // idempotent. We did not write anything yet, so restoring is a no-op
      // unless `onResolved` ran (it does not when we abort early — the
      // closure runs AFTER queueing succeeds).
      // Defensive: re-write the snapshot in case any future change starts
      // mutating the cache earlier in `requestAccess`.
      await _restoreLocalTokenSnapshot(
        userId: userId,
        snapshotById: localSnapshotById,
      );
    }

    return outcome;
  }

  /// Server-applies the user-typed tokens for ids whose access was resolved
  /// by [requestAccess].
  ///
  /// - **Relinked ids** (server already had this client linked): tokens are
  ///   pushed to the server immediately via the dedicated PUT endpoint. The
  ///   underlying repository mirrors successful writes into the local cache.
  /// - **Queued ids** (new request placed in the local pending queue):
  ///   tokens land in the local secure-storage cache only. After approval
  ///   polling detects the link, [_pushLocalTokenToServerAfterApproval]
  ///   flushes them to the server.
  /// - Tokens NOT present in [tokenByAgentId] (or empty) trigger a server
  ///   clear for relinked ids and a local delete for queued ids.
  Future<void> _applySubmittedTokensTransactionally({
    required String userId,
    required Map<String, String> tokenByAgentId,
    required RequestAccessSubmissionSnapshot snapshot,
  }) async {
    for (final agentId in snapshot.relinkedAgentIds) {
      final token = tokenByAgentId[agentId] ?? '';
      final result = await _saveClientAgentTokenUseCase(
        userId: userId,
        agentId: agentId,
        clientToken: token,
      );
      if (result.isError()) {
        _pendingLocalTokenServerFlushAgentIds.add(agentId);
        final failure = result.exceptionOrNull()!;
        AppLogger.warning(
          'Server PUT of client-agent token after relink failed; falling '
          'back to local cache (will retry on next approval flush)',
          context: <String, Object?>{
            'operation': 'applySubmittedTokens',
            'agentId': agentId,
            'phase': 'relinked',
            'technicalMessage': failure.message,
          },
          error: failure.cause ?? failure,
          stackTrace: failure.stackTrace,
        );
        await _writeLocalTokenSafely(
          userId: userId,
          agentId: agentId,
          token: token,
        );
      } else {
        _pendingLocalTokenServerFlushAgentIds.remove(agentId);
      }
    }

    for (final agentId in snapshot.queuedAgentIds) {
      final token = tokenByAgentId[agentId] ?? '';
      await _writeLocalTokenSafely(
        userId: userId,
        agentId: agentId,
        token: token,
      );
    }
  }

  Future<void> _writeLocalTokenSafely({
    required String userId,
    required String agentId,
    required String token,
  }) async {
    if (token.isEmpty) {
      _pendingLocalTokenServerFlushAgentIds.remove(agentId);
      await _clientTokenDraftStore.delete(userId: userId, agentId: agentId);
      return;
    }
    await _clientTokenDraftStore.write(
      userId: userId,
      agentId: agentId,
      clientToken: token,
    );
  }

  Future<void> _restoreLocalTokenSnapshot({
    required String userId,
    required Map<String, String?> snapshotById,
  }) async {
    for (final entry in snapshotById.entries) {
      final previous = entry.value;
      if (previous == null || previous.isEmpty) {
        await _clientTokenDraftStore.delete(
          userId: userId,
          agentId: entry.key,
        );
      } else {
        await _clientTokenDraftStore.write(
          userId: userId,
          agentId: entry.key,
          clientToken: previous,
        );
      }
    }
  }

  /// After polling confirms an agent was approved, flush any local token we
  /// stashed during submission to the server.
  Future<void> _pushLocalTokenToServerAfterApproval({
    required String userId,
    required Iterable<String> agentIds,
  }) async {
    for (final agentId in agentIds) {
      final localToken = await _clientTokenDraftStore.read(
        userId: userId,
        agentId: agentId,
      );
      if (localToken == null) {
        continue;
      }
      final result = await _saveClientAgentTokenUseCase(
        userId: userId,
        agentId: agentId,
        clientToken: localToken,
      );
      if (result.isError()) {
        _pendingLocalTokenServerFlushAgentIds.add(agentId);
        final failure = result.exceptionOrNull()!;
        AppLogger.warning(
          'Server PUT of client-agent token after approval failed; local '
          'cache kept as fallback',
          context: <String, Object?>{
            'operation': 'pushLocalTokenAfterApproval',
            'agentId': agentId,
            'technicalMessage': failure.message,
          },
          error: failure.cause ?? failure,
          stackTrace: failure.stackTrace,
        );
      } else {
        _pendingLocalTokenServerFlushAgentIds.remove(agentId);
      }
    }
  }

  void _scheduleLocalTokenServerFlushForApprovedAgents({
    required String userId,
    Iterable<String> preferredAgentIds = const <String>[],
  }) {
    if (_isDisposed) {
      return;
    }
    final approvedItems = _approvedAgents?.items;
    if (approvedItems == null || approvedItems.isEmpty) {
      return;
    }
    final approvedIds = approvedItems.map((agent) => agent.agentId).toSet();
    final candidates = <String>{
      ..._pendingLocalTokenServerFlushAgentIds,
      ...preferredAgentIds,
      for (final agent in approvedItems)
        if (agent.hasServerClientToken != true) agent.agentId,
    }.intersection(approvedIds);
    if (candidates.isEmpty) {
      return;
    }
    unawaited(
      _pushLocalTokenToServerAfterApproval(
        userId: userId,
        agentIds: candidates,
      ),
    );
  }

  /// Optional callback fired by [requestAccess] right after the controller
  /// has resolved every id into either "relinked" (server already linked the
  /// client) or "queued" (POST will fire on the next sync). Lets callers
  /// (e.g. `submitAccessRequestWithLocalTokens`) apply side effects keyed by
  /// the resolved ids without re-reading the controller's internal state.
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
      // Preflight uses network truth (`GET /client/me/agents/{id}`). Transport
      // errors fall back to the normal queue path; 401/403 abort with an auth
      // message instead of enqueueing blindly.
      _isSyncing = true;
      _actionError = null;
      _clearActionFeedback();
      _notifyListenersIfAlive();

      final ids = agentIds.toList(growable: false);
      final relinkedById = <String, ClientAgent>{};
      final idsForClassification = <String>{};
      var probeFailureFallbackCount = 0;
      var authAborted = false;

      for (var i = 0; i < ids.length; i += _approvedAgentsProbeConcurrency) {
        final upper = min(i + _approvedAgentsProbeConcurrency, ids.length);
        final chunk = ids.sublist(i, upper);
        final chunkOutcomes = await Future.wait(
          chunk.map((agentId) async {
            final probeResult = await _probeClientApprovedAgentUseCase(
              userId: userId,
              agentId: agentId,
            );
            return (agentId, probeResult);
          }),
        );

        for (final record in chunkOutcomes) {
          record.$2.fold(
            (outcome) {
              final agent = outcome.agent;
              if (outcome.isLinked && agent != null) {
                relinkedById[agent.agentId] = agent;
              } else {
                idsForClassification.add(record.$1);
              }
            },
            (failure) {
              final authMessage = _probeAuthBlockingUserMessage(failure);
              if (authMessage != null) {
                _actionError = authMessage;
                authAborted = true;
                return;
              }
              probeFailureFallbackCount++;
              idsForClassification.add(record.$1);
            },
          );
          if (authAborted) {
            break;
          }
        }
        if (authAborted) {
          break;
        }
      }

      if (_actionError != null) {
        _isSyncing = false;
        _notifyListenersIfAlive();
        await _reloadPendingAfterEnqueue(userId: userId);
        return false;
      }

      final relinkedAgents = relinkedById.values.toList(growable: false);
      var pendingCleanupOk = true;
      if (relinkedAgents.isNotEmpty) {
        pendingCleanupOk = await _discardRelinkedPendingWithRetry(
          userId: userId,
          agentIds: relinkedById.keys.toSet(),
        );
        await _reloadApprovedAgentsCacheAfterRelink(
          userId: userId,
          fallbackAgents: relinkedAgents,
        );
        _invalidateTargetResolution(userId: userId);
        _scheduleLocalTokenServerFlushForApprovedAgents(
          userId: userId,
          preferredAgentIds: relinkedById.keys,
        );
      }

      AppLogger.info(
        'Client agents request access preflight completed',
        context: <String, Object?>{
          'relinkedCount': relinkedById.length,
          'classificationCount': idsForClassification.length,
          'probeFailureFallbackCount': probeFailureFallbackCount,
          'pendingCleanupOk': pendingCleanupOk,
        },
      );

      final classification = _classifyRequestAgentIds(idsForClassification);
      if (classification.allowed.isEmpty) {
        _isSyncing = false;
        if (relinkedAgents.isEmpty) {
          _actionError = _buildBlockedRequestMessage(classification);
        } else {
          _setActionFeedback(
            message:
                ClientAgentsPresentationMessage.clientAgentsRequestRelinkOnly(
                  relinkedCount: relinkedAgents.length,
                  pendingCleanupOk: pendingCleanupOk,
                ),
            kind: ClientAgentsActionFeedbackKind.success,
          );
          if (onResolved != null) {
            await onResolved(
              RequestAccessSubmissionSnapshot(
                relinkedAgentIds: relinkedById.keys.toSet(),
                queuedAgentIds: const <String>{},
              ),
            );
          }
        }
        _notifyListenersIfAlive();
        await _reloadPendingAfterEnqueue(userId: userId);
        return _actionError == null;
      }

      final queueResult = await _queueRequestAccessUseCase(
        userId: userId,
        agentIds: classification.allowed,
      );
      _actionError = _consumeResult(
        result: queueResult,
        operation: 'queueClientAgentRequestAccess',
      );
      _maybeArmRequestAccessRetryGateFromResult(queueResult);
      if (_actionError == null) {
        if (relinkedAgents.isEmpty) {
          _setActionFeedback(
            message: _buildQueuedRequestMessage(classification),
            kind: ClientAgentsActionFeedbackKind.info,
          );
        } else {
          _setActionFeedback(
            message:
                ClientAgentsPresentationMessage.clientAgentsRequestRelinkAndQueued(
                  relinkedCount: relinkedAgents.length,
                  queuedCount: classification.allowed.length,
                  ignoredCount:
                      classification.approved.length +
                      classification.remotePending.length +
                      classification.localPending.length,
                  pendingCleanupOk: pendingCleanupOk,
                ),
            kind: ClientAgentsActionFeedbackKind.info,
          );
        }
        if (onResolved != null) {
          await onResolved(
            RequestAccessSubmissionSnapshot(
              relinkedAgentIds: relinkedById.keys.toSet(),
              queuedAgentIds: classification.allowed,
            ),
          );
        }
      }
      await _reloadPendingAfterEnqueue(userId: userId);
      return _actionError == null;
    });
  }

  ClientAgentsPresentationMessage? _probeAuthBlockingUserMessage(
    AppFailure failure,
  ) {
    if (failure is SessionFailure) {
      return ClientAgentsPresentationMessage.clientAgentsSessionUnavailableRequest();
    }
    if (failure is AuthorizationFailure) {
      if (isBlockedAccountFailure(failure)) {
        return ClientAgentsPresentationMessage.failure(failure);
      }
      return ClientAgentsPresentationMessage.clientAgentsSessionUnavailableRequest();
    }
    return null;
  }

  Future<bool> _discardRelinkedPendingWithRetry({
    required String userId,
    required Set<String> agentIds,
  }) async {
    for (var attempt = 0; attempt < 2; attempt++) {
      final discardResult = await _discardQueuedClientAgentRequestAccessUseCase(
        userId: userId,
        agentIds: agentIds,
      );
      if (discardResult.isSuccess()) {
        return true;
      }
      discardResult.fold((_) {}, (failure) {
        AppLogger.warning(
          'discardQueuedClientAgentRequestAccess failed',
          context: <String, Object?>{
            'operation': 'discardQueuedClientAgentRequestAccess',
            'attempt': attempt + 1,
          },
          error: failure.cause ?? failure,
          stackTrace: failure.stackTrace,
        );
      });
    }
    return false;
  }

  Future<void> _reloadApprovedAgentsCacheAfterRelink({
    required String userId,
    required List<ClientAgent> fallbackAgents,
  }) async {
    const query = PaginatedQuery(pageSize: kClientAgentsListPageSize);
    final result = await _loadApprovedAgentsUseCase(
      userId: userId,
      query: query,
      refresh: true,
    );
    result.fold(
      (value) {
        _approvedAgents = value;
        _upsertApprovedAgentsInMemory(fallbackAgents);
      },
      (failure) {
        AppLogger.warning(
          'Approved agents refresh after relink failed; merged local list',
          context: <String, Object?>{
            'operation': 'reloadApprovedAgentsAfterRelink',
            'technicalMessage': failure.message,
          },
          error: failure.cause ?? failure,
          stackTrace: failure.stackTrace,
        );
        _upsertApprovedAgentsInMemory(fallbackAgents);
      },
    );
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
      _isSyncing = true;
      _actionError = null;
      _clearActionFeedback();
      _notifyListenersIfAlive();

      final classification = _classifyRemoveAgentIds(agentIds);
      if (classification.allowed.isEmpty) {
        _isSyncing = false;
        _actionError = _buildBlockedRemoveMessage(classification);
        _notifyListenersIfAlive();
        return;
      }

      final queueResult = await _queueRemoveAccessUseCase(
        userId: userId,
        agentIds: classification.allowed,
      );
      _actionError = _consumeResult(
        result: queueResult,
        operation: 'queueClientAgentRemoveAccess',
      );
      if (_actionError == null) {
        _setActionFeedback(
          message: _buildQueuedRemoveMessage(classification),
          kind: ClientAgentsActionFeedbackKind.info,
        );
      }
      await _reloadPendingAfterEnqueue(userId: userId);
    });
  }

  Future<void> retryAccessRequest({
    required ClientAgentAccessRequest request,
  }) async {
    final requestId = request.requestId?.trim();
    if (requestId == null || requestId.isEmpty) {
      _actionError =
          ClientAgentsPresentationMessage.clientAgentsRetryMissingRequestId();
      _notifyListenersIfAlive();
      return;
    }
    final userId = _authController.session?.userId;
    if (userId == null || userId.isEmpty) {
      _actionError =
          ClientAgentsPresentationMessage.clientAgentsSessionUnavailableRequest();
      _notifyListenersIfAlive();
      return;
    }

    await _runPendingMutationSerialized(() async {
      if (_isDisposed) {
        return;
      }
      _isSyncing = true;
      _actionError = null;
      _clearActionFeedback();
      _notifyListenersIfAlive();
      final retryResult = await _retryClientAccessRequestUseCase(
        userId: userId,
        requestId: requestId,
      );
      _actionError = _consumeResult(
        result: retryResult,
        operation: 'retryClientAccessRequest',
      );
      await _refreshAfterMutation(userId: userId);
      if (_actionError == null) {
        _setActionFeedback(
          message: ClientAgentsPresentationMessage.clientAgentsRetrySuccess(),
          kind: ClientAgentsActionFeedbackKind.info,
        );
        _startApprovalPolling(
          userId: userId,
          agentIds: <String>{request.agentId},
        );
      }
      _notifyListenersIfAlive();
    });
  }

  /// Drops a **local** `requestAccess` action that is still `queued` or
  /// `failed` (not yet successfully synced). Does not cancel a request that
  /// already exists on the server with status pending; that would require a
  /// dedicated hub route.
  Future<void> discardQueuedRequestAccess({
    required PendingAgentAction action,
  }) async {
    await _runPendingMutationSerialized(() async {
      if (_isDisposed) {
        return;
      }
      final userId = _authController.session?.userId;
      if (userId == null || userId.isEmpty) {
        _actionError =
            ClientAgentsPresentationMessage.clientAgentsSessionUnavailableRequest();
        _notifyListenersIfAlive();
        return;
      }
      final agentId = action.agentId.trim();
      if (!_matchesDiscardableLocalRequestAccess(action, agentId)) {
        _actionError =
            ClientAgentsPresentationMessage.clientAgentsDiscardQueuedRequestInvalidState();
        _notifyListenersIfAlive();
        return;
      }
      final beforeCount = _pendingActions
          .where((a) => _matchesDiscardableLocalRequestAccess(a, agentId))
          .length;
      if (beforeCount == 0) {
        _actionError =
            ClientAgentsPresentationMessage.clientAgentsDiscardQueuedRequestInvalidState();
        _notifyListenersIfAlive();
        return;
      }

      _isSyncing = true;
      _actionError = null;
      _clearActionFeedback();
      _notifyListenersIfAlive();

      final discardResult = await _discardQueuedClientAgentRequestAccessUseCase(
        userId: userId,
        agentIds: <String>{agentId},
      );
      _actionError = _consumeResult(
        result: discardResult,
        operation: 'discardQueuedClientAgentRequestAccess',
      );
      await _refreshAfterMutation(userId: userId);
      if (_actionError == null) {
        final afterCount = _pendingActions
            .where((a) => _matchesDiscardableLocalRequestAccess(a, agentId))
            .length;
        if (beforeCount > afterCount) {
          await persistLocalClientTokenDraftLine(
            agentIdRaw: agentId,
            clientTokenRaw: '',
          );
          _setActionFeedback(
            message:
                ClientAgentsPresentationMessage.clientAgentsDiscardQueuedRequestSuccess(),
            kind: ClientAgentsActionFeedbackKind.info,
          );
        }
      }
      _notifyListenersIfAlive();
    });
  }

  bool _matchesDiscardableLocalRequestAccess(
    PendingAgentAction action,
    String trimmedAgentId,
  ) {
    return action.agentId.trim() == trimmedAgentId &&
        action.type == PendingAgentActionType.requestAccess &&
        (action.state == PendingAgentActionState.queued ||
            action.state == PendingAgentActionState.failed);
  }

  Future<void> syncPending({
    bool autoTriggered = false,
  }) async {
    final userId = _authController.session?.userId;
    if (userId == null || userId.isEmpty) {
      _actionError =
          ClientAgentsPresentationMessage.clientAgentsSessionUnavailableSync();
      _notifyListenersIfAlive();
      return;
    }

    if (!_syncRetryAfterGate.isOpen) {
      // Honour the server's `Retry-After`: do not even attempt the call
      // until the cooldown elapses. Auto-triggered runs (post-enqueue
      // schedule) are silent so we do not spam the user with the same
      // banner across ticks; manual taps surface the wait window.
      if (!autoTriggered) {
        _actionError = ClientAgentsPresentationMessage.clientAgentsSyncCooldown(
          seconds: _remainingRetryAfterSeconds(_syncRetryAfterGate.remaining),
        );
        _notifyListenersIfAlive();
      }
      return;
    }

    await _runPendingMutationSerialized(() async {
      if (_isDisposed) {
        return;
      }

      final pendingCount = _pendingActions
          .where(
            (action) =>
                action.state == PendingAgentActionState.queued ||
                action.state == PendingAgentActionState.failed,
          )
          .length;
      if (pendingCount == 0) {
        if (!autoTriggered) {
          _setActionFeedback(
            message:
                ClientAgentsPresentationMessage.clientAgentsNoLocalPendingToSync(),
            kind: ClientAgentsActionFeedbackKind.info,
          );
          _notifyListenersIfAlive();
        }
        return;
      }

      _isSyncing = true;
      _actionError = null;
      if (!autoTriggered) {
        _clearActionFeedback();
      }
      _notifyListenersIfAlive();
      final syncResult = await _syncPendingActionsUseCase(userId: userId);
      syncResult.fold(
        (value) {
          AppLogger.info(
            'Client agents pending sync outcome',
            context: <String, Object?>{
              'operation': 'syncPendingClientAgentActions',
              'pollIds': value.requestAccessPollAgentIds.length,
              'alreadyApproved':
                  value.requestAccessAlreadyApprovedAgentIds.length,
              'debounced': value.requestAccessDebouncedAgentIds.length,
              'newRequests': value.requestAccessNewRequestsAgentIds.length,
            },
          );
        },
        (_) {},
      );
      final requestAccessPollAgentIds = syncResult.fold(
        (value) => value.requestAccessPollAgentIds,
        (_) => const <String>{},
      );
      final requestAccessAlreadyApprovedOnSync = syncResult.fold(
        (value) => value.requestAccessAlreadyApprovedAgentIds,
        (_) => const <String>{},
      );
      final requestAccessDebouncedOnSync = syncResult.fold(
        (value) => value.requestAccessDebouncedAgentIds,
        (_) => const <String>{},
      );
      _actionError = _consumeResult(
        result: syncResult,
        operation: 'syncPendingClientAgentActions',
      );
      _maybeArmSyncRetryGateFromResult(syncResult);
      await _refreshAfterMutation(userId: userId);
      if (_actionError == null &&
          requestAccessAlreadyApprovedOnSync.isNotEmpty) {
        await _hydrateApprovedAgentsInMemory(
          userId: userId,
          agentIds: requestAccessAlreadyApprovedOnSync,
        );
        _invalidateTargetResolution(userId: userId);
      }
      if (_actionError == null) {
        final outcome = syncResult.fold((v) => v, (_) => null);
        if (outcome != null) {
          _setActionFeedback(
            message: ClientAgentsPresentationMessage.clientAgentsSyncSuccess(
              syncedCount: outcome.successfulActionCount,
              failedCount: outcome.failedActionCount,
              attemptedPendingCount: pendingCount,
              autoTriggered: autoTriggered,
              watchingApproval: requestAccessPollAgentIds.isNotEmpty,
              alreadyApprovedCount: requestAccessAlreadyApprovedOnSync.length,
              debouncedCount: requestAccessDebouncedOnSync.length,
            ),
            kind: ClientAgentsActionFeedbackKind.success,
          );
          if (outcome.successfulRemoveAccessAgentIds.isNotEmpty) {
            _invalidateTargetResolution(userId: userId);
          }
        }
        // Sync may have discovered that some queued ids were already
        // approved server-side. Flush any local token we stashed for those
        // ids to the server right away so the user does not have to wait
        // for the polling loop to catch up.
        if (requestAccessAlreadyApprovedOnSync.isNotEmpty) {
          unawaited(
            _pushLocalTokenToServerAfterApproval(
              userId: userId,
              agentIds: requestAccessAlreadyApprovedOnSync,
            ),
          );
        }
        _startApprovalPolling(
          userId: userId,
          agentIds: requestAccessPollAgentIds,
        );
        _notifyListenersIfAlive();
      }
    });
  }

  Future<void> _reloadPendingAfterEnqueue({
    required String userId,
  }) async {
    final pendingResult = await _readPendingActionsUseCase(userId: userId);
    _pendingActionsError = _consumeResult(
      result: pendingResult,
      onSuccess: (value) => _pendingActions = value,
      operation: 'readPendingClientAgentActions',
    );
    _isSyncing = false;
    _notifyListenersIfAlive();
    _scheduleAutoSyncIfNeeded();
  }

  Future<void> _refreshAfterMutation({
    required String userId,
  }) async {
    const query = PaginatedQuery(pageSize: kClientAgentsListPageSize);
    late AppResult<PaginatedResult<ClientAgent>> approvedResult;
    late AppResult<PaginatedResult<ClientAgentAccessRequest>> requestsResult;
    late AppResult<List<PendingAgentAction>> pendingResult;

    await Future.wait<void>(<Future<void>>[
      _loadApprovedAgentsUseCase(
        userId: userId,
        query: query,
        refresh: true,
      ).then((value) => approvedResult = value),
      _loadAccessRequestsUseCase(
        userId: userId,
        query: query,
      ).then((value) => requestsResult = value),
      _readPendingActionsUseCase(userId: userId).then(
        (value) => pendingResult = value,
      ),
    ]);
    if (_isDisposed) {
      return;
    }

    _approvedAgentsError = _consumeResult(
      result: approvedResult,
      onSuccess: (value) => _approvedAgents = value,
      operation: 'loadApprovedClientAgents',
    );
    _accessRequestsError = _consumeResult(
      result: requestsResult,
      onSuccess: (value) => _accessRequests = value,
      operation: 'loadClientAgentAccessRequests',
    );
    _pendingActionsError = _consumeResult(
      result: pendingResult,
      onSuccess: (value) => _pendingActions = value,
      operation: 'readPendingClientAgentActions',
    );

    _isSyncing = false;
    _scheduleLocalTokenServerFlushForApprovedAgents(userId: userId);
    _notifyListenersIfAlive();
  }

  ClientAgentsPresentationMessage? _consumeResult<T extends Object>({
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

  void clearActionFeedback() {
    if (_actionNotice == null) {
      return;
    }
    _clearActionFeedback();
    _notifyListenersIfAlive();
  }

  void _clearSectionErrors() {
    _actionError = null;
    _approvedAgentsError = null;
    _accessRequestsError = null;
    _pendingActionsError = null;
  }

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

  void _scheduleAutoSyncIfNeeded() {
    if (_isSyncing || !_syncRetryAfterGate.isOpen) {
      return;
    }
    final hasPendingSync = _pendingActions.any(
      (action) =>
          action.state == PendingAgentActionState.queued ||
          action.state == PendingAgentActionState.failed,
    );
    if (!hasPendingSync) {
      return;
    }
    unawaited(syncPending(autoTriggered: true));
  }

  void _startApprovalPolling({
    required String userId,
    required Set<String> agentIds,
  }) {
    if (agentIds.isEmpty || _isDisposed) {
      return;
    }
    final now = DateTime.now();
    for (final agentId in agentIds) {
      _trackedApprovalAgentIds.add(agentId);
      _approvalPollingStartedAtByAgentId[agentId] = now;
    }
    _approvalPollingTimer ??= Timer.periodic(_approvalPollingInterval, (_) {
      unawaited(_pollApprovalStatus(userId: userId));
    });
    unawaited(_pollApprovalStatus(userId: userId));
  }

  void _stopApprovalPolling({bool clearTracked = false}) {
    _approvalPollingTimer?.cancel();
    _approvalPollingTimer = null;
    _isPollingApprovals = false;
    if (clearTracked) {
      _trackedApprovalAgentIds.clear();
      _approvalPollingStartedAtByAgentId.clear();
    }
  }

  Future<void> _pollApprovalStatus({
    required String userId,
  }) async {
    if (_isDisposed ||
        _isPollingApprovals ||
        _trackedApprovalAgentIds.isEmpty ||
        _isSyncing) {
      return;
    }
    final currentUserId = _authController.session?.userId;
    if (currentUserId == null || currentUserId != userId) {
      _stopApprovalPolling(clearTracked: true);
      return;
    }

    _isPollingApprovals = true;
    final requestsRefreshResult = await _loadAccessRequestsUseCase(
      userId: userId,
      query: _approvalPollingQuery,
    );
    _accessRequestsError = _consumeResult(
      result: requestsRefreshResult,
      onSuccess: (value) => _accessRequests = value,
      operation: 'pollRefreshClientAgentAccessRequests',
    );

    final approvedNow = <String, ClientAgent>{};
    final deniedNow = <String>{};
    final timedOutNow = <String>{};

    final idsToCheck = _trackedApprovalAgentIds.toList(growable: false);
    for (
      var i = 0;
      i < idsToCheck.length;
      i += _approvedAgentsProbeConcurrency
    ) {
      final upper = min(i + _approvedAgentsProbeConcurrency, idsToCheck.length);
      final chunk = idsToCheck.sublist(i, upper);
      final chunkResults = await Future.wait(
        chunk.map(
          (agentId) => _evaluateTrackedAgentForPoll(
            userId: userId,
            agentId: agentId,
          ),
        ),
      );
      for (final r in chunkResults) {
        if (r.timedOut) {
          timedOutNow.add(r.agentId);
        } else if (r.approved != null) {
          approvedNow[r.agentId] = r.approved!;
        } else if (r.denied) {
          deniedNow.add(r.agentId);
        }
      }
    }

    _trackedApprovalAgentIds
      ..removeAll(approvedNow.keys)
      ..removeAll(deniedNow)
      ..removeAll(timedOutNow);
    <String>{
      ...approvedNow.keys,
      ...deniedNow,
      ...timedOutNow,
    }.forEach(_approvalPollingStartedAtByAgentId.remove);

    if (approvedNow.isNotEmpty) {
      await _refreshApprovedAgentsSnapshot(userId: userId);
      _upsertApprovedAgentsInMemory(approvedNow.values.toList(growable: false));
      _invalidateTargetResolution(userId: userId);
      // Now that the server reports these agents as linked, flush any local
      // token the user typed during the request-access flow up to the server
      // so the SQL bridge sees it on the next call (and the detail page
      // shows the correct status chip without requiring a manual save).
      unawaited(
        _pushLocalTokenToServerAfterApproval(
          userId: userId,
          agentIds: approvedNow.keys,
        ),
      );
    }

    if (approvedNow.isNotEmpty ||
        deniedNow.isNotEmpty ||
        timedOutNow.isNotEmpty) {
      _setActionFeedback(
        message:
            ClientAgentsPresentationMessage.clientAgentsApprovalPollingProgress(
              approvedCount: approvedNow.length,
              deniedCount: deniedNow.length,
              timedOutCount: timedOutNow.length,
              remainingCount: _trackedApprovalAgentIds.length,
            ),
        kind: approvedNow.isNotEmpty && deniedNow.isEmpty && timedOutNow.isEmpty
            ? ClientAgentsActionFeedbackKind.success
            : ClientAgentsActionFeedbackKind.info,
      );
    }

    if (_trackedApprovalAgentIds.isEmpty) {
      _stopApprovalPolling();
    }
    _isPollingApprovals = false;
    _notifyListenersIfAlive();
  }

  void _handleSyncRetryAfterGateChanged() {
    if (_isDisposed) {
      return;
    }
    _notifyListenersIfAlive();
    if (_syncRetryAfterGate.isOpen) {
      _scheduleAutoSyncIfNeeded();
    }
  }

  int _remainingRetryAfterSeconds(Duration? remaining) {
    return (remaining?.inSeconds ?? 0).clamp(1, 86400);
  }

  Future<
    ({
      String agentId,
      bool timedOut,
      ClientAgent? approved,
      bool denied,
    })
  >
  _evaluateTrackedAgentForPoll({
    required String userId,
    required String agentId,
  }) async {
    final startedAt = _approvalPollingStartedAtByAgentId[agentId];
    if (startedAt != null &&
        DateTime.now().difference(startedAt) >= _approvalPollingTimeout) {
      return (
        agentId: agentId,
        timedOut: true,
        approved: null,
        denied: false,
      );
    }
    final approvedAgent = await _loadApprovedAgentForPolling(
      userId: userId,
      agentId: agentId,
    );
    if (approvedAgent != null) {
      return (
        agentId: agentId,
        timedOut: false,
        approved: approvedAgent,
        denied: false,
      );
    }
    final requestStatus = await _loadRequestStatusForPolling(
      userId: userId,
      agentId: agentId,
    );
    final denied =
        requestStatus == AgentAccessRequestStatus.rejected ||
        requestStatus == AgentAccessRequestStatus.expired;
    return (
      agentId: agentId,
      timedOut: false,
      approved: null,
      denied: denied,
    );
  }

  Future<ClientAgent?> _loadApprovedAgentForPolling({
    required String userId,
    required String agentId,
  }) async {
    final result = await _loadClientAgentDetailUseCase(
      userId: userId,
      agentId: agentId,
    );
    return result.fold((value) => value, (_) => null);
  }

  ClientAgentAccessRequest? _accessRequestForAgentId(String agentId) {
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

  Future<AgentAccessRequestStatus?> _loadRequestStatusForPolling({
    required String userId,
    required String agentId,
  }) async {
    final cached = _accessRequestForAgentId(agentId);
    if (cached != null) {
      final token = cached.statusPollToken?.trim();
      if (token != null && token.isNotEmpty) {
        final snapshot = await _loadClientAccessStatusUseCase(token: token);
        return snapshot.fold((value) => value.status, (_) => cached.status);
      }
      return cached.status;
    }

    final result = await _loadAccessRequestsUseCase(
      userId: userId,
      query: const PaginatedQuery(pageSize: kClientAgentsListPageSize),
      search: agentId,
    );
    return result.fold((value) {
      for (final request in value.items) {
        if (request.agentId == agentId) {
          return request.status;
        }
      }
      return null;
    }, (_) => null);
  }

  Future<void> _refreshApprovedAgentsSnapshot({
    required String userId,
  }) async {
    final approvedResult = await _loadApprovedAgentsUseCase(
      userId: userId,
      query: _approvalPollingQuery,
    );
    _approvedAgentsError = _consumeResult(
      result: approvedResult,
      onSuccess: (value) => _approvedAgents = value,
      operation: 'pollApprovedClientAgents',
    );
  }

  Future<void> _hydrateApprovedAgentsInMemory({
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

  ({
    Set<String> allowed,
    Set<String> approved,
    Set<String> remotePending,
    Set<String> localPending,
  })
  _classifyRequestAgentIds(
    Set<String> agentIds,
  ) {
    final approved = _approvedAgentIds().intersection(agentIds);
    final remotePending = _remotePendingRequestIds().intersection(agentIds);
    final localPending = _localPendingRequestIds().intersection(agentIds);
    final blocked = <String>{...approved, ...remotePending, ...localPending};
    final allowed = agentIds.difference(blocked);
    return (
      allowed: allowed,
      approved: approved,
      remotePending: remotePending,
      localPending: localPending,
    );
  }

  ({Set<String> allowed, Set<String> notApproved, Set<String> localPending})
  _classifyRemoveAgentIds(
    Set<String> agentIds,
  ) {
    final approved = _approvedAgentIds();
    final localPending = _localPendingRemoveIds().intersection(agentIds);
    final notApproved = agentIds.difference(approved);
    final blocked = <String>{...notApproved, ...localPending};
    final allowed = agentIds.difference(blocked);
    return (
      allowed: allowed,
      notApproved: notApproved,
      localPending: localPending,
    );
  }

  Set<String> _approvedAgentIds() {
    return _approvedAgents?.items.map((agent) => agent.agentId).toSet() ??
        const <String>{};
  }

  Set<String> _remotePendingRequestIds() {
    return _accessRequests?.items
            .where(
              (request) => request.status == AgentAccessRequestStatus.pending,
            )
            .map((request) => request.agentId)
            .toSet() ??
        const <String>{};
  }

  Set<String> _localPendingRequestIds() {
    return _pendingActions
        .where(
          (action) =>
              action.type == PendingAgentActionType.requestAccess &&
              action.state != PendingAgentActionState.synced,
        )
        .map((action) => action.agentId)
        .toSet();
  }

  Set<String> _localPendingRemoveIds() {
    return _pendingActions
        .where(
          (action) =>
              action.type == PendingAgentActionType.removeAccess &&
              action.state != PendingAgentActionState.synced,
        )
        .map((action) => action.agentId)
        .toSet();
  }

  ClientAgentsPresentationMessage _buildBlockedRequestMessage(
    ({
      Set<String> allowed,
      Set<String> approved,
      Set<String> remotePending,
      Set<String> localPending,
    })
    classification,
  ) {
    return ClientAgentsPresentationMessage.clientAgentsRequestBlocked(
      approved: classification.approved,
      remotePending: classification.remotePending,
      localPending: classification.localPending,
    );
  }

  ClientAgentsPresentationMessage _buildQueuedRequestMessage(
    ({
      Set<String> allowed,
      Set<String> approved,
      Set<String> remotePending,
      Set<String> localPending,
    })
    classification,
  ) {
    return ClientAgentsPresentationMessage.clientAgentsRequestQueued(
      queuedCount: classification.allowed.length,
      ignoredCount:
          classification.approved.length +
          classification.remotePending.length +
          classification.localPending.length,
    );
  }

  ClientAgentsPresentationMessage _buildBlockedRemoveMessage(
    ({Set<String> allowed, Set<String> notApproved, Set<String> localPending})
    classification,
  ) {
    return ClientAgentsPresentationMessage.clientAgentsRemoveBlocked(
      notApproved: classification.notApproved,
      localPending: classification.localPending,
    );
  }

  ClientAgentsPresentationMessage _buildQueuedRemoveMessage(
    ({Set<String> allowed, Set<String> notApproved, Set<String> localPending})
    classification,
  ) {
    return ClientAgentsPresentationMessage.clientAgentsRemoveQueued(
      queuedCount: classification.allowed.length,
      ignoredCount:
          classification.notApproved.length +
          classification.localPending.length,
    );
  }

  void _invalidateTargetResolution({required String userId}) {
    _targetResolutionInvalidator?.invalidate(userId: userId);
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

  @override
  void dispose() {
    if (_isDisposed) {
      // Idempotent: tests and the page layer occasionally double-tap
      // dispose during teardown. ChangeNotifier.dispose throws on a
      // second call, so we short-circuit here.
      return;
    }
    _stopApprovalPolling(clearTracked: true);
    _presence.dispose();
    _syncRetryAfterGate.removeListener(_handleSyncRetryAfterGateChanged);
    if (_ownsSyncRetryAfterGate) {
      _syncRetryAfterGate.dispose();
    }
    _requestAccessRetryAfterGate.removeListener(_notifyListenersIfAlive);
    if (_ownsRequestAccessRetryAfterGate) {
      _requestAccessRetryAfterGate.dispose();
    }
    _isDisposed = true;
    super.dispose();
  }

  /// Inspects [result] and arms [_syncRetryAfterGate] when the underlying
  /// failure carries a `Retry-After` hint propagated from the hub.
  void _maybeArmSyncRetryGateFromResult(
    AppResult<SyncPendingAgentActionsResult> result,
  ) {
    final retryAfter = _retryAfterFromResult(result);
    if (retryAfter != null) {
      _syncRetryAfterGate.arm(retryAfter);
    }
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

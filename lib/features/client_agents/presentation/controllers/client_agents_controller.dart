import 'dart:async';
import 'dart:math' show min;

import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/errors/retry_after_gate.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/core/socket/consumer_socket_connection.dart';
import 'package:colmeia/core/socket/consumer_socket_connection_state.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
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
import 'package:colmeia/features/client_agents/data/models/client_agent_token_request_dto.dart';
import 'package:colmeia/features/client_agents/data/storage/local_agent_client_token_store.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_access_request_status.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_connection_status.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent_access_request.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agents_list_page_size.dart';
import 'package:colmeia/features/client_agents/domain/entities/paginated_query.dart';
import 'package:colmeia/features/client_agents/domain/entities/paginated_result.dart';
import 'package:colmeia/features/client_agents/domain/entities/pending_agent_action.dart';
import 'package:colmeia/features/client_agents/domain/entities/sync_pending_agent_actions_result.dart';
import 'package:colmeia/features/client_agents/domain/events/agent_presence_event.dart';
import 'package:colmeia/features/client_agents/presentation/localization/client_agents_failure_l10n.dart';
import 'package:colmeia/features/client_agents/presentation/models/client_agent_access_request_row_input.dart';
import 'package:colmeia/features/client_agents/presentation/utils/client_agent_id_format.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/l10n/app_localizations_en.dart';
import 'package:flutter/foundation.dart';
import 'package:result_dart/result_dart.dart' show Unit;

enum ClientAgentsActionFeedbackKind { info, success }

class ClientAgentsController extends ChangeNotifier {
  ClientAgentsController({
    required AuthController authController,
    required LocalAgentClientTokenStore clientTokenStore,
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
    Duration hintConfirmDelay = const Duration(seconds: 5),
    RetryAfterGate? syncRetryAfterGate,
    RetryAfterGate? requestAccessRetryAfterGate,
  }) : _authController = authController,
       _clientTokenStore = clientTokenStore,
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
       _observeAgentPresenceUseCase = observeAgentPresenceUseCase,
       _agentPresencePoller = agentPresencePoller,
       _consumerSocketConnection = consumerSocketConnection,
       _hintConfirmDelay = hintConfirmDelay,
       _syncRetryAfterGate = syncRetryAfterGate ?? RetryAfterGate(),
       _requestAccessRetryAfterGate =
           requestAccessRetryAfterGate ?? RetryAfterGate() {
    // Re-broadcast gate ticks so consumer widgets that already listen to
    // the controller refresh the countdown label without subscribing to
    // each gate individually.
    _syncRetryAfterGate.addListener(_notifyListenersIfAlive);
    _requestAccessRetryAfterGate.addListener(_notifyListenersIfAlive);
  }

  static const Duration _approvalPollingInterval = Duration(seconds: 10);
  static const Duration _approvalPollingTimeout = Duration(minutes: 3);
  static const PaginatedQuery _approvalPollingQuery = PaginatedQuery(
    pageSize: kClientAgentsListPageSize,
  );
  static const int _approvedAgentsProbeConcurrency = 4;

  final AuthController _authController;
  final LocalAgentClientTokenStore _clientTokenStore;
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

  /// PR-M part 2: optional dependency. When the build does not enable
  /// `SOCKET_PRESENCE_LISTENER_ENABLED`, the use case is `null` and the
  /// controller behaves exactly as before — preserving every existing
  /// test and the legacy `Refresh`-only UX.
  final ObserveAgentPresenceUseCase? _observeAgentPresenceUseCase;

  /// PR-M part 3: optional REST fallback poller. Liga só quando o
  /// socket está fora de `connected` E a tela está visível
  /// (`onScreenVisible`). Mantém o badge `online`/`offline`
  /// vivo mesmo durante uma queda do socket.
  final AgentPresencePoller? _agentPresencePoller;

  /// PR-M part 3: optional handle to observe socket state transitions
  /// for the visibility-aware poller gating. `null` when the build
  /// does not enable the socket layer.
  final ConsumerSocketConnection? _consumerSocketConnection;

  /// Delay between an `AgentPresenceHint` landing in memory and the
  /// confirming REST refresh. Tests pass a small value to keep the
  /// suite fast.
  final Duration _hintConfirmDelay;

  /// Cooldown for `syncPending`. Armed every time the underlying use
  /// case fails with a `Retry-After` hint; the UI uses
  /// [syncRetryAfter] / [isSyncOnCooldown] to gray the button out.
  final RetryAfterGate _syncRetryAfterGate;

  /// Same idea for the request-access flow. The hub returns
  /// `Retry-After` for the dedicated `REST_CLIENT_ME_AGENTS_POST_RATE_LIMIT_*`
  /// quota, so a flurry of submissions does not bypass the throttle.
  final RetryAfterGate _requestAccessRetryAfterGate;

  AppLocalizations? _l10n;

  AppLocalizations? get activeLocalizations => _l10n;

  set activeLocalizations(AppLocalizations value) => _l10n = value;

  AppLocalizations get _s => _l10n ?? AppLocalizationsEn();

  bool _isDisposed = false;
  bool _isLoadingInitial = false;
  bool _isRefreshing = false;
  bool _isSyncing = false;
  bool _hasLoadedInitialData = false;
  bool _hasAttemptedAutoSync = false;
  bool _isPollingApprovals = false;
  String? _actionErrorMessage;
  String? _actionFeedbackMessage;
  ClientAgentsActionFeedbackKind? _actionFeedbackKind;
  String? _approvedAgentsErrorMessage;
  String? _accessRequestsErrorMessage;
  String? _pendingActionsErrorMessage;

  PaginatedResult<ClientAgent>? _approvedAgents;
  PaginatedResult<ClientAgentAccessRequest>? _accessRequests;
  List<PendingAgentAction> _pendingActions = const <PendingAgentAction>[];
  final Set<String> _trackedApprovalAgentIds = <String>{};
  final Map<String, DateTime> _approvalPollingStartedAtByAgentId =
      <String, DateTime>{};
  Timer? _approvalPollingTimer;
  int _refreshAllToken = 0;
  Future<void> _pendingMutationTail = Future.value();

  /// Realtime presence (PR-M part 2). Subscription is set up lazily on the
  /// first `initialize()` call when `_observeAgentPresenceUseCase != null`.
  StreamSubscription<AgentPresenceEvent>? _presenceSub;

  /// Tracks the most recent `observedAt` per agent so out-of-order events
  /// (catalog → hint → catalog with stale clock) do not flap the badge.
  final Map<String, DateTime> _lastPresenceObservedByAgentId =
      <String, DateTime>{};

  /// Per-agent debounce for confirming a hint via REST. Cancelled on
  /// subsequent hints for the same agent and on `dispose()`.
  final Map<String, Timer> _hintConfirmTimers = <String, Timer>{};

  /// PR-M part 3: subscription to `ConsumerSocketConnection.states()`.
  /// Drives the poller on/off in tandem with the visibility state.
  StreamSubscription<ConsumerSocketConnectionState>? _socketStateSub;

  /// PR-M part 3: latest socket state observed. The page tells us
  /// when it becomes visible/hidden via [onScreenVisible] /
  /// [onScreenHidden]; we combine the two signals to gate the poller.
  bool _isScreenVisible = false;
  bool _isSocketConnected = false;

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
  String? get actionErrorMessage => _actionErrorMessage;
  String? get actionFeedbackMessage => _actionFeedbackMessage;
  ClientAgentsActionFeedbackKind? get actionFeedbackKind => _actionFeedbackKind;
  String? get approvedAgentsErrorMessage => _approvedAgentsErrorMessage;
  String? get accessRequestsErrorMessage => _accessRequestsErrorMessage;
  String? get pendingActionsErrorMessage => _pendingActionsErrorMessage;
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
    _maybeSubscribeToPresence();
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
      _actionErrorMessage = _s.clientAgentsSessionUnavailableLoad;
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

      _approvedAgentsErrorMessage = _consumeResult(
        result: approvedResult,
        onSuccess: (value) => _approvedAgents = value,
        operation: 'loadApprovedClientAgents',
      );
      _accessRequestsErrorMessage = _consumeResult(
        result: requestsResult,
        onSuccess: (value) => _accessRequests = value,
        operation: 'loadClientAgentAccessRequests',
      );
      _pendingActionsErrorMessage = _consumeResult(
        result: pendingResult,
        onSuccess: (value) => _pendingActions = value,
        operation: 'readPendingClientAgentActions',
      );
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
    return _clientTokenStore.read(userId: userId, agentId: trimmedAgentId);
  }

  /// Persists or clears the local token for a draft row when the agent id is
  /// a valid UUID (used from the request-access form while editing).
  ///
  /// Tokens longer than [ClientAgentTokenRequestDto.maxTokenLength] are
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
    if (token.length > ClientAgentTokenRequestDto.maxTokenLength) {
      AppLogger.warning(
        'Client token draft exceeds server cap; not persisted',
        context: <String, Object?>{
          'operation': 'persistLocalClientTokenDraftLine',
          'agentId': id,
          'length': token.length,
          'cap': ClientAgentTokenRequestDto.maxTokenLength,
        },
      );
      return;
    }
    if (token.isEmpty) {
      await _clientTokenStore.delete(userId: userId, agentId: id);
    } else {
      await _clientTokenStore.write(
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
      _actionErrorMessage = _s.clientAgentsSessionUnavailableRequest;
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
      if (token.length > ClientAgentTokenRequestDto.maxTokenLength) {
        tokensTooLongIds.add(id);
        continue;
      }
      tokenByAgentId[id] = token;
    }

    if (tokensTooLongIds.isNotEmpty) {
      _actionErrorMessage = _s.clientAgentsValidationTokenTooLong(
        ClientAgentTokenRequestDto.maxTokenLength,
        tokensTooLongIds.join(', '),
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
      localSnapshotById[id] = await _clientTokenStore.read(
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
      await _clientTokenStore.delete(userId: userId, agentId: agentId);
      return;
    }
    await _clientTokenStore.write(
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
        await _clientTokenStore.delete(
          userId: userId,
          agentId: entry.key,
        );
      } else {
        await _clientTokenStore.write(
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
      final localToken = await _clientTokenStore.read(
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
      }
    }
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
      _actionErrorMessage = _s.clientAgentsSessionUnavailableRequest;
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
      _actionErrorMessage = null;
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
                _actionErrorMessage = authMessage;
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

      if (_actionErrorMessage != null) {
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
          _actionErrorMessage = _buildBlockedRequestMessage(classification);
        } else {
          _setActionFeedback(
            message: _withRelinkPendingCleanupNote(
              _relinkFeedbackMessage(relinkedAgents.length),
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
        return _actionErrorMessage == null;
      }

      final queueResult = await _queueRequestAccessUseCase(
        userId: userId,
        agentIds: classification.allowed,
      );
      _actionErrorMessage = _consumeResult(
        result: queueResult,
        operation: 'queueClientAgentRequestAccess',
      );
      _maybeArmRequestAccessRetryGateFromResult(queueResult);
      if (_actionErrorMessage == null) {
        final queueMessage = _buildQueuedRequestMessage(classification);
        if (relinkedAgents.isEmpty) {
          _setActionFeedback(
            message: queueMessage,
            kind: ClientAgentsActionFeedbackKind.info,
          );
        } else {
          _setActionFeedback(
            message: _withRelinkPendingCleanupNote(
              _s.clientAgentsRequestRelinkAndQueued(
                _relinkFeedbackMessage(relinkedAgents.length),
                queueMessage,
              ),
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
      return _actionErrorMessage == null;
    });
  }

  String? _probeAuthBlockingUserMessage(AppFailure failure) {
    if (failure is SessionFailure) {
      return _s.clientAgentsSessionUnavailableRequest;
    }
    if (failure is AuthorizationFailure) {
      if (isBlockedAccountFailure(failure)) {
        return clientAgentsFailureUserMessage(failure, _s);
      }
      return _s.clientAgentsSessionUnavailableRequest;
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

  String _withRelinkPendingCleanupNote(
    String message, {
    required bool pendingCleanupOk,
  }) {
    if (pendingCleanupOk) {
      return message;
    }
    return '$message ${_s.clientAgentsRelinkPendingNotCleared}';
  }

  String _relinkFeedbackMessage(int relinkedCount) {
    return relinkedCount == 1
        ? _s.clientAgentsRequestRelinkUpdatedSingle
        : _s.clientAgentsRequestRelinkUpdatedPlural(relinkedCount);
  }

  Future<void> removeAccess({
    required Set<String> agentIds,
  }) async {
    if (agentIds.isEmpty) {
      return;
    }
    final userId = _authController.session?.userId;
    if (userId == null || userId.isEmpty) {
      _actionErrorMessage = _s.clientAgentsSessionUnavailableRemove;
      _notifyListenersIfAlive();
      return;
    }

    await _runPendingMutationSerialized(() async {
      if (_isDisposed) {
        return;
      }
      _isSyncing = true;
      _actionErrorMessage = null;
      _clearActionFeedback();
      _notifyListenersIfAlive();

      final classification = _classifyRemoveAgentIds(agentIds);
      if (classification.allowed.isEmpty) {
        _isSyncing = false;
        _actionErrorMessage = _buildBlockedRemoveMessage(classification);
        _notifyListenersIfAlive();
        return;
      }

      final queueResult = await _queueRemoveAccessUseCase(
        userId: userId,
        agentIds: classification.allowed,
      );
      _actionErrorMessage = _consumeResult(
        result: queueResult,
        operation: 'queueClientAgentRemoveAccess',
      );
      if (_actionErrorMessage == null) {
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
      _actionErrorMessage = _s.clientAgentsRetryMissingRequestId;
      _notifyListenersIfAlive();
      return;
    }
    final userId = _authController.session?.userId;
    if (userId == null || userId.isEmpty) {
      _actionErrorMessage = _s.clientAgentsSessionUnavailableRequest;
      _notifyListenersIfAlive();
      return;
    }

    await _runPendingMutationSerialized(() async {
      if (_isDisposed) {
        return;
      }
      _isSyncing = true;
      _actionErrorMessage = null;
      _clearActionFeedback();
      _notifyListenersIfAlive();
      final retryResult = await _retryClientAccessRequestUseCase(
        userId: userId,
        requestId: requestId,
      );
      _actionErrorMessage = _consumeResult(
        result: retryResult,
        operation: 'retryClientAccessRequest',
      );
      await _refreshAfterMutation(userId: userId);
      if (_actionErrorMessage == null) {
        _setActionFeedback(
          message: _s.clientAgentsRetrySuccess,
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

  Future<void> syncPending({
    bool autoTriggered = false,
  }) async {
    final userId = _authController.session?.userId;
    if (userId == null || userId.isEmpty) {
      _actionErrorMessage = _s.clientAgentsSessionUnavailableSync;
      _notifyListenersIfAlive();
      return;
    }

    if (!_syncRetryAfterGate.isOpen) {
      // Honour the server's `Retry-After`: do not even attempt the call
      // until the cooldown elapses. Auto-triggered runs (post-enqueue
      // schedule) are silent so we do not spam the user with the same
      // banner across ticks; manual taps surface the wait window.
      if (!autoTriggered) {
        _actionErrorMessage = _buildSyncCooldownMessage(
          _syncRetryAfterGate.remaining,
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
            message: _s.clientAgentsNoLocalPendingToSync,
            kind: ClientAgentsActionFeedbackKind.info,
          );
          _notifyListenersIfAlive();
        }
        return;
      }

      _isSyncing = true;
      _actionErrorMessage = null;
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
      _actionErrorMessage = _consumeResult(
        result: syncResult,
        operation: 'syncPendingClientAgentActions',
      );
      _maybeArmSyncRetryGateFromResult(syncResult);
      await _refreshAfterMutation(userId: userId);
      if (_actionErrorMessage == null) {
        final outcome = syncResult.fold((v) => v, (_) => null);
        if (outcome != null) {
          _setActionFeedback(
            message: _buildSyncSuccessMessage(
              result: outcome,
              autoTriggered: autoTriggered,
              attemptedPendingCount: pendingCount,
              watchingApproval: requestAccessPollAgentIds.isNotEmpty,
              alreadyApprovedIds: requestAccessAlreadyApprovedOnSync,
              debouncedIds: requestAccessDebouncedOnSync,
            ),
            kind: ClientAgentsActionFeedbackKind.success,
          );
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
    _pendingActionsErrorMessage = _consumeResult(
      result: pendingResult,
      onSuccess: (value) => _pendingActions = value,
      operation: 'readPendingClientAgentActions',
    );
    _isSyncing = false;
    _notifyListenersIfAlive();
    _scheduleAutoSyncIfNeeded(force: true);
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

    _approvedAgentsErrorMessage = _consumeResult(
      result: approvedResult,
      onSuccess: (value) => _approvedAgents = value,
      operation: 'loadApprovedClientAgents',
    );
    _accessRequestsErrorMessage = _consumeResult(
      result: requestsResult,
      onSuccess: (value) => _accessRequests = value,
      operation: 'loadClientAgentAccessRequests',
    );
    _pendingActionsErrorMessage = _consumeResult(
      result: pendingResult,
      onSuccess: (value) => _pendingActions = value,
      operation: 'readPendingClientAgentActions',
    );

    _isSyncing = false;
    _notifyListenersIfAlive();
  }

  String? _consumeResult<T extends Object>({
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
        return clientAgentsFailureUserMessage(failure, _s);
      },
    );
  }

  void clearActionError() {
    if (_actionErrorMessage == null) {
      return;
    }
    _actionErrorMessage = null;
    _notifyListenersIfAlive();
  }

  void clearActionFeedback() {
    if (_actionFeedbackMessage == null) {
      return;
    }
    _clearActionFeedback();
    _notifyListenersIfAlive();
  }

  void _clearSectionErrors() {
    _actionErrorMessage = null;
    _approvedAgentsErrorMessage = null;
    _accessRequestsErrorMessage = null;
    _pendingActionsErrorMessage = null;
  }

  void _clearActionFeedback() {
    _actionFeedbackMessage = null;
    _actionFeedbackKind = null;
  }

  void _setActionFeedback({
    required String message,
    required ClientAgentsActionFeedbackKind kind,
  }) {
    _actionFeedbackMessage = message;
    _actionFeedbackKind = kind;
  }

  void _scheduleAutoSyncIfNeeded({
    bool force = false,
  }) {
    if (_isSyncing) {
      return;
    }
    if (!force && _hasAttemptedAutoSync) {
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
    _hasAttemptedAutoSync = true;
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
    _accessRequestsErrorMessage = _consumeResult(
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
        message: _buildApprovalPollingProgressMessage(
          approvedNow: approvedNow.keys.toSet(),
          deniedNow: deniedNow,
          timedOutNow: timedOutNow,
          remaining: _trackedApprovalAgentIds.length,
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
    _approvedAgentsErrorMessage = _consumeResult(
      result: approvedResult,
      onSuccess: (value) => _approvedAgents = value,
      operation: 'pollApprovedClientAgents',
    );
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

  String _buildBlockedRequestMessage(
    ({
      Set<String> allowed,
      Set<String> approved,
      Set<String> remotePending,
      Set<String> localPending,
    })
    classification,
  ) {
    final remotePendingMessage = classification.remotePending.join(', ');
    final localPendingMessage = classification.localPending.join(', ');
    final parts = <String>[
      if (classification.approved.isNotEmpty)
        _s.clientAgentsRequestBlockedAlreadyApproved(
          classification.approved.join(', '),
        ),
      if (classification.remotePending.isNotEmpty)
        _s.clientAgentsRequestBlockedAlreadyReview(remotePendingMessage),
      if (classification.localPending.isNotEmpty)
        _s.clientAgentsRequestBlockedAlreadyQueued(localPendingMessage),
    ];
    return parts.isEmpty
        ? _s.clientAgentsRequestBlockedFallback
        : _s.clientAgentsRequestBlockedIntro(parts.join(' '));
  }

  String _buildQueuedRequestMessage(
    ({
      Set<String> allowed,
      Set<String> approved,
      Set<String> remotePending,
      Set<String> localPending,
    })
    classification,
  ) {
    final queuedCount = classification.allowed.length;
    final ignoredCount =
        classification.approved.length +
        classification.remotePending.length +
        classification.localPending.length;
    final baseMessage = queuedCount == 1
        ? _s.clientAgentsRequestQueuedWatchingSingle
        : _s.clientAgentsRequestQueuedWatchingPlural(queuedCount);
    if (ignoredCount == 0) {
      return baseMessage;
    }
    return '$baseMessage '
        '${_s.clientAgentsRequestQueuedIgnoredSuffix(ignoredCount)}';
  }

  String _buildBlockedRemoveMessage(
    ({Set<String> allowed, Set<String> notApproved, Set<String> localPending})
    classification,
  ) {
    final localPendingMessage = classification.localPending.join(', ');
    final parts = <String>[
      if (classification.notApproved.isNotEmpty)
        _s.clientAgentsRemoveBlockedNotApproved(
          classification.notApproved.join(', '),
        ),
      if (classification.localPending.isNotEmpty)
        _s.clientAgentsRemoveBlockedAlreadyQueued(localPendingMessage),
    ];
    return parts.isEmpty
        ? _s.clientAgentsRemoveBlockedFallback
        : _s.clientAgentsRemoveBlockedIntro(parts.join(' '));
  }

  String _buildQueuedRemoveMessage(
    ({Set<String> allowed, Set<String> notApproved, Set<String> localPending})
    classification,
  ) {
    final queuedCount = classification.allowed.length;
    final ignoredCount =
        classification.notApproved.length + classification.localPending.length;
    final baseMessage = queuedCount == 1
        ? _s.clientAgentsRemoveQueuedSingle
        : _s.clientAgentsRemoveQueuedPlural(queuedCount);
    if (ignoredCount == 0) {
      return baseMessage;
    }
    return '$baseMessage '
        '${_s.clientAgentsRemoveQueuedIgnoredSuffix(ignoredCount)}';
  }

  String _buildSyncSuccessMessage({
    required SyncPendingAgentActionsResult result,
    required bool autoTriggered,
    required int attemptedPendingCount,
    required bool watchingApproval,
    Set<String> alreadyApprovedIds = const <String>{},
    Set<String> debouncedIds = const <String>{},
  }) {
    final synced = result.successfulActionCount;
    final failed = result.failedActionCount;
    final String prefix;
    if (synced == 0 && attemptedPendingCount > 0) {
      prefix = _s.clientAgentsSyncSuccessNoneCompleted;
    } else if (synced == 1) {
      prefix = _s.clientAgentsSyncSuccessSingle;
    } else {
      prefix = _s.clientAgentsSyncSuccessPlural(synced);
    }
    final suffix = autoTriggered
        ? _s.clientAgentsSyncSuccessAutoSuffix
        : _s.clientAgentsSyncSuccessManualSuffix;
    final polling = watchingApproval
        ? _s.clientAgentsSyncSuccessPollingSuffix
        : '';
    var message = '$prefix$suffix$polling';
    if (alreadyApprovedIds.isNotEmpty) {
      message += alreadyApprovedIds.length == 1
          ? _s.clientAgentsSyncSuccessAlreadyApprovedSingle
          : _s.clientAgentsSyncSuccessAlreadyApprovedPlural(
              alreadyApprovedIds.length,
            );
    }
    if (debouncedIds.isNotEmpty) {
      message += debouncedIds.length == 1
          ? _s.clientAgentsSyncSuccessDebouncedSingle
          : _s.clientAgentsSyncSuccessDebouncedPlural(debouncedIds.length);
    }
    if (failed > 0) {
      message += _s.clientAgentsSyncSuccessSomeFailedSuffix(failed);
    }
    return message;
  }

  String _buildApprovalPollingProgressMessage({
    required Set<String> approvedNow,
    required Set<String> deniedNow,
    required Set<String> timedOutNow,
    required int remaining,
  }) {
    final myAgentsTab = _s.clientAgentsTabMyAgents;
    final parts = <String>[
      if (approvedNow.isNotEmpty)
        approvedNow.length == 1
            ? _s.clientAgentsPollApprovedSingle(myAgentsTab)
            : _s.clientAgentsPollApprovedPlural(
                approvedNow.length,
                myAgentsTab,
              ),
      if (deniedNow.isNotEmpty)
        deniedNow.length == 1
            ? _s.clientAgentsPollDeniedSingle
            : _s.clientAgentsPollDeniedPlural(deniedNow.length),
      if (timedOutNow.isNotEmpty)
        timedOutNow.length == 1
            ? _s.clientAgentsPollTimeoutSingle
            : _s.clientAgentsPollTimeoutPlural(timedOutNow.length),
      if (remaining > 0)
        remaining == 1
            ? _s.clientAgentsPollRemainingSingle
            : _s.clientAgentsPollRemainingPlural(remaining),
    ];
    return parts.join(' ');
  }

  void _notifyListenersIfAlive() {
    if (_isDisposed) {
      return;
    }
    notifyListeners();
  }

  // ----- Realtime presence (PR-M part 2) -----

  void _maybeSubscribeToPresence() {
    final useCase = _observeAgentPresenceUseCase;
    if (useCase == null) {
      return;
    }
    if (_presenceSub != null) {
      return;
    }
    _presenceSub = useCase().listen(
      _onPresence,
      onError: (Object error, StackTrace stackTrace) {
        AppLogger.warning(
          'Agent presence stream error',
          context: const <String, Object?>{
            'component': 'ClientAgentsController',
            'operation': 'presence_stream',
          },
          error: error,
          stackTrace: stackTrace,
        );
      },
    );
    _maybeSubscribeToSocketState();
  }

  void _maybeSubscribeToSocketState() {
    final connection = _consumerSocketConnection;
    if (connection == null) {
      return;
    }
    if (_socketStateSub != null) {
      return;
    }
    // Seed with the current state so the first visibility transition
    // does not race against the first state event.
    _isSocketConnected = connection.isConnected;
    _socketStateSub = connection.states().listen((state) {
      if (_isDisposed) {
        return;
      }
      _isSocketConnected = state is ConsumerSocketConnected;
      _reconcilePollerGate();
    });
  }

  /// Reconciles the REST poller (Camada 3) with the current socket
  /// state and screen visibility. The contract is: poll **only** when
  /// the screen is visible AND the socket is NOT connected. As soon
  /// as the socket comes back, push events take over and the poller
  /// stops to avoid double-counting.
  void _reconcilePollerGate() {
    final poller = _agentPresencePoller;
    if (poller == null) {
      return;
    }
    final userId = _authController.session?.userId;
    if (userId == null || userId.isEmpty) {
      poller.stop();
      return;
    }
    final shouldPoll = _isScreenVisible && !_isSocketConnected;
    if (shouldPoll) {
      poller.start(userId: userId);
    } else {
      poller.stop();
    }
  }

  /// Page-level hook (RouteAware): the `client_agents` screen became
  /// the visible route. Only effective when PR-M part 3 dependencies
  /// (`AgentPresencePoller` + `ConsumerSocketConnection`) were wired —
  /// no-op otherwise so the legacy build behaves identically.
  void onScreenVisible() {
    _isScreenVisible = true;
    _reconcilePollerGate();
  }

  /// Page-level hook (RouteAware): the `client_agents` screen left the
  /// foreground (push to detail, tab switch, deep route). Stops the
  /// REST polling so we do not waste battery on hidden views.
  void onScreenHidden() {
    _isScreenVisible = false;
    _reconcilePollerGate();
  }

  void _onPresence(AgentPresenceEvent event) {
    if (_isDisposed) {
      return;
    }
    // Drop events older than the latest observation we already applied
    // for the same agent. Both sources (catalog push + command hints)
    // can race, so anchoring on `observedAt` keeps the badge stable.
    final last = _lastPresenceObservedByAgentId[event.agentId];
    if (last != null && !event.observedAt.isAfter(last)) {
      AppLogger.debug(
        'Discarded stale presence event',
        context: <String, Object?>{
          'component': 'ClientAgentsController',
          'operation': 'presence_dedup',
          'agentId': event.agentId,
        },
      );
      return;
    }
    _lastPresenceObservedByAgentId[event.agentId] = event.observedAt;

    final userId = _authController.session?.userId;
    if (userId == null || userId.isEmpty) {
      return;
    }

    switch (event) {
      case AgentPresenceCatalogUpdated():
        unawaited(
          _refreshAgentDetailFromPresence(
            userId: userId,
            agentId: event.agentId,
          ),
        );
      case AgentPresenceHint():
        _applyHintInMemory(
          agentId: event.agentId,
          online: event.online,
        );
        _scheduleHintConfirm(userId: userId, agentId: event.agentId);
    }
  }

  Future<void> _refreshAgentDetailFromPresence({
    required String userId,
    required String agentId,
  }) async {
    final result = await _loadClientAgentDetailUseCase(
      userId: userId,
      agentId: agentId,
    );
    if (_isDisposed) {
      return;
    }
    result.fold(
      (agent) {
        _upsertApprovedAgentsInMemory(<ClientAgent>[agent]);
        _notifyListenersIfAlive();
      },
      (failure) {
        AppLogger.warning(
          'Refresh after presence event failed',
          context: <String, Object?>{
            'component': 'ClientAgentsController',
            'operation': 'refreshAfterPresence',
            'agentId': agentId,
            'technicalMessage': failure.message,
          },
          error: failure.cause ?? failure,
          stackTrace: failure.stackTrace,
        );
      },
    );
  }

  void _applyHintInMemory({
    required String agentId,
    required bool online,
  }) {
    final current = _approvedAgents;
    if (current == null) {
      // No approved list yet — the next refresh will reconcile presence
      // with the server. Hints are a UI optimisation, not the truth.
      return;
    }
    var changed = false;
    final updatedItems = current.items
        .map((agent) {
          if (agent.agentId != agentId) {
            return agent;
          }
          final desired = online
              ? AgentConnectionStatus.online
              : AgentConnectionStatus.offline;
          if (agent.connectionStatus == desired) {
            return agent;
          }
          changed = true;
          return agent.copyWith(connectionStatus: desired);
        })
        .toList(growable: false);
    if (!changed) {
      return;
    }
    _approvedAgents = PaginatedResult<ClientAgent>(
      items: updatedItems,
      count: current.count,
      total: current.total,
      page: current.page,
      pageSize: current.pageSize,
    );
    _notifyListenersIfAlive();
  }

  void _scheduleHintConfirm({
    required String userId,
    required String agentId,
  }) {
    _hintConfirmTimers[agentId]?.cancel();
    _hintConfirmTimers[agentId] = Timer(_hintConfirmDelay, () {
      _hintConfirmTimers.remove(agentId);
      if (_isDisposed) {
        return;
      }
      unawaited(
        _refreshAgentDetailFromPresence(
          userId: userId,
          agentId: agentId,
        ),
      );
    });
  }

  void _cancelAllHintConfirmTimers() {
    for (final timer in _hintConfirmTimers.values) {
      timer.cancel();
    }
    _hintConfirmTimers.clear();
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
    _cancelAllHintConfirmTimers();
    unawaited(_presenceSub?.cancel());
    _presenceSub = null;
    unawaited(_socketStateSub?.cancel());
    _socketStateSub = null;
    _agentPresencePoller?.stop();
    _lastPresenceObservedByAgentId.clear();
    _syncRetryAfterGate
      ..removeListener(_notifyListenersIfAlive)
      ..dispose();
    _requestAccessRetryAfterGate
      ..removeListener(_notifyListenersIfAlive)
      ..dispose();
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

  String _buildSyncCooldownMessage(Duration? remaining) {
    final seconds = (remaining?.inSeconds ?? 0).clamp(1, 86400);
    return _s.clientAgentsSyncRetryAfterCountdown(seconds);
  }
}

/// Snapshot passed from [ClientAgentsController.requestAccess] to its
/// optional `onResolved` callback so the caller knows which ids ended up
/// where after preflight + classification + queueing.
class RequestAccessSubmissionSnapshot {
  const RequestAccessSubmissionSnapshot({
    required this.relinkedAgentIds,
    required this.queuedAgentIds,
  });

  /// Ids the server already had linked for this client. Tokens for these
  /// can be PUT to the server immediately.
  final Set<String> relinkedAgentIds;

  /// Ids the controller placed in the local pending queue (POST will fire
  /// on the next sync). Tokens for these are stashed locally and PUT to the
  /// server later, after approval polling sees the link.
  final Set<String> queuedAgentIds;
}

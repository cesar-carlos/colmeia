import 'dart:async';

import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/client_agents/application/usecases/load_client_access_requests_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/load_client_agent_detail_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/load_client_approved_agents_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/queue_client_agent_remove_access_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/queue_client_agent_request_access_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/read_pending_client_agent_actions_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/sync_pending_client_agent_actions_use_case.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_access_request_status.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent_access_request.dart';
import 'package:colmeia/features/client_agents/domain/entities/paginated_query.dart';
import 'package:colmeia/features/client_agents/domain/entities/paginated_result.dart';
import 'package:colmeia/features/client_agents/domain/entities/pending_agent_action.dart';
import 'package:colmeia/features/client_agents/presentation/localization/client_agents_failure_l10n.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/l10n/app_localizations_en.dart';
import 'package:flutter/foundation.dart';

enum ClientAgentsActionFeedbackKind { info, success }

class ClientAgentsController extends ChangeNotifier {
  ClientAgentsController({
    required AuthController authController,
    required LoadClientApprovedAgentsUseCase loadApprovedAgentsUseCase,
    required LoadClientAccessRequestsUseCase loadAccessRequestsUseCase,
    required LoadClientAgentDetailUseCase loadClientAgentDetailUseCase,
    required QueueClientAgentRequestAccessUseCase queueRequestAccessUseCase,
    required QueueClientAgentRemoveAccessUseCase queueRemoveAccessUseCase,
    required ReadPendingClientAgentActionsUseCase readPendingActionsUseCase,
    required SyncPendingClientAgentActionsUseCase syncPendingActionsUseCase,
  }) : _authController = authController,
       _loadApprovedAgentsUseCase = loadApprovedAgentsUseCase,
       _loadAccessRequestsUseCase = loadAccessRequestsUseCase,
       _loadClientAgentDetailUseCase = loadClientAgentDetailUseCase,
       _queueRequestAccessUseCase = queueRequestAccessUseCase,
       _queueRemoveAccessUseCase = queueRemoveAccessUseCase,
       _readPendingActionsUseCase = readPendingActionsUseCase,
       _syncPendingActionsUseCase = syncPendingActionsUseCase;

  static const Duration _approvalPollingInterval = Duration(seconds: 10);
  static const Duration _approvalPollingTimeout = Duration(minutes: 3);
  static const PaginatedQuery _approvalPollingQuery = PaginatedQuery(
    pageSize: 50,
  );

  final AuthController _authController;
  final LoadClientApprovedAgentsUseCase _loadApprovedAgentsUseCase;
  final LoadClientAccessRequestsUseCase _loadAccessRequestsUseCase;
  final LoadClientAgentDetailUseCase _loadClientAgentDetailUseCase;
  final QueueClientAgentRequestAccessUseCase _queueRequestAccessUseCase;
  final QueueClientAgentRemoveAccessUseCase _queueRemoveAccessUseCase;
  final ReadPendingClientAgentActionsUseCase _readPendingActionsUseCase;
  final SyncPendingClientAgentActionsUseCase _syncPendingActionsUseCase;

  AppLocalizations? _l10n;

  AppLocalizations? get activeLocalizations => _l10n;

  set activeLocalizations(AppLocalizations value) => _l10n = value;

  AppLocalizations get _s => _l10n ?? AppLocalizationsEn();

  bool _isDisposed = false;
  bool _isLoading = false;
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

  bool get isLoading => _isLoading;
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

  Future<void> initialize() async {
    if (_hasLoadedInitialData || _isLoading) {
      return;
    }
    await refreshAll();
  }

  Future<void> refreshAll() async {
    final userId = _authController.session?.userId;
    if (userId == null || userId.isEmpty) {
      _actionErrorMessage = _s.clientAgentsSessionUnavailableLoad;
      _notifyListenersIfAlive();
      return;
    }

    _isLoading = true;
    _clearSectionErrors();
    _notifyListenersIfAlive();

    const query = PaginatedQuery(pageSize: 50);
    final approvedResult = await _loadApprovedAgentsUseCase(
      userId: userId,
      query: query,
    );
    final requestsResult = await _loadAccessRequestsUseCase(
      userId: userId,
      query: query,
    );
    final pendingResult = await _readPendingActionsUseCase(userId: userId);

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

    _isLoading = false;
    _hasLoadedInitialData = true;
    _notifyListenersIfAlive();
    _scheduleAutoSyncIfNeeded();
  }

  Future<bool> requestAccess({
    required Set<String> agentIds,
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
    _isSyncing = true;
    _actionErrorMessage = null;
    _clearActionFeedback();
    _notifyListenersIfAlive();

    final classification = _classifyRequestAgentIds(agentIds);
    if (classification.allowed.isEmpty) {
      _isSyncing = false;
      _actionErrorMessage = _buildBlockedRequestMessage(classification);
      _notifyListenersIfAlive();
      return false;
    }

    final queueResult = await _queueRequestAccessUseCase(
      userId: userId,
      agentIds: classification.allowed,
    );
    _actionErrorMessage = _consumeResult(
      result: queueResult,
      operation: 'queueClientAgentRequestAccess',
    );
    if (_actionErrorMessage == null) {
      _setActionFeedback(
        message: _buildQueuedRequestMessage(classification),
        kind: ClientAgentsActionFeedbackKind.info,
      );
    }
    await _reloadPendingAfterEnqueue(userId: userId);
    return _actionErrorMessage == null;
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
    if (_isSyncing) {
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
    final syncedRequestAccessAgentIds = syncResult.fold(
      (value) => value.successfulRequestAccessAgentIds,
      (_) => const <String>{},
    );
    _actionErrorMessage = _consumeResult(
      result: syncResult,
      operation: 'syncPendingClientAgentActions',
    );
    await _refreshAfterMutation(userId: userId);
    if (_actionErrorMessage == null) {
      _setActionFeedback(
        message: _buildSyncSuccessMessage(
          pendingCount: pendingCount,
          autoTriggered: autoTriggered,
          watchingApproval: syncedRequestAccessAgentIds.isNotEmpty,
        ),
        kind: ClientAgentsActionFeedbackKind.success,
      );
      _startApprovalPolling(
        userId: userId,
        agentIds: syncedRequestAccessAgentIds,
      );
      _notifyListenersIfAlive();
    }
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
    const query = PaginatedQuery(pageSize: 50);
    final approvedResult = await _loadApprovedAgentsUseCase(
      userId: userId,
      query: query,
    );
    final requestsResult = await _loadAccessRequestsUseCase(
      userId: userId,
      query: query,
    );
    final pendingResult = await _readPendingActionsUseCase(userId: userId);

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
    if (_isSyncing || _pendingActionsErrorMessage != null) {
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
    final approvedNow = <String, ClientAgent>{};
    final deniedNow = <String>{};
    final timedOutNow = <String>{};

    for (final agentId in _trackedApprovalAgentIds.toList(growable: false)) {
      final startedAt = _approvalPollingStartedAtByAgentId[agentId];
      if (startedAt != null &&
          DateTime.now().difference(startedAt) >= _approvalPollingTimeout) {
        timedOutNow.add(agentId);
        continue;
      }

      final approvedAgent = await _loadApprovedAgentForPolling(
        userId: userId,
        agentId: agentId,
      );
      if (approvedAgent != null) {
        approvedNow[agentId] = approvedAgent;
        continue;
      }

      final requestStatus = await _loadRequestStatusForPolling(
        userId: userId,
        agentId: agentId,
      );
      if (requestStatus == AgentAccessRequestStatus.rejected ||
          requestStatus == AgentAccessRequestStatus.expired) {
        deniedNow.add(agentId);
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

  Future<AgentAccessRequestStatus?> _loadRequestStatusForPolling({
    required String userId,
    required String agentId,
  }) async {
    final result = await _loadAccessRequestsUseCase(
      userId: userId,
      query: const PaginatedQuery(),
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
    required int pendingCount,
    required bool autoTriggered,
    required bool watchingApproval,
  }) {
    final prefix = pendingCount == 1
        ? _s.clientAgentsSyncSuccessSingle
        : _s.clientAgentsSyncSuccessPlural(pendingCount);
    final suffix = autoTriggered
        ? _s.clientAgentsSyncSuccessAutoSuffix
        : _s.clientAgentsSyncSuccessManualSuffix;
    final polling = watchingApproval
        ? _s.clientAgentsSyncSuccessPollingSuffix
        : '';
    return '$prefix$suffix$polling';
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

  @override
  void dispose() {
    _stopApprovalPolling(clearTracked: true);
    _isDisposed = true;
    super.dispose();
  }
}

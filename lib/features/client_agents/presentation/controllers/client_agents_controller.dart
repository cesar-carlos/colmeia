import 'dart:async';
import 'dart:math' show min;

import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/client_agents/application/usecases/discard_queued_client_agent_request_access_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/load_client_access_requests_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/load_client_access_status_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/load_client_agent_detail_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/load_client_approved_agents_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/probe_client_approved_agent_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/queue_client_agent_remove_access_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/queue_client_agent_request_access_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/read_pending_client_agent_actions_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/sync_pending_client_agent_actions_use_case.dart';
import 'package:colmeia/features/client_agents/data/storage/local_agent_client_token_store.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_access_request_status.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent_access_request.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agents_list_page_size.dart';
import 'package:colmeia/features/client_agents/domain/entities/paginated_query.dart';
import 'package:colmeia/features/client_agents/domain/entities/paginated_result.dart';
import 'package:colmeia/features/client_agents/domain/entities/pending_agent_action.dart';
import 'package:colmeia/features/client_agents/domain/entities/sync_pending_agent_actions_result.dart';
import 'package:colmeia/features/client_agents/presentation/localization/client_agents_failure_l10n.dart';
import 'package:colmeia/features/client_agents/presentation/models/client_agent_access_request_row_input.dart';
import 'package:colmeia/features/client_agents/presentation/utils/client_agent_id_format.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/l10n/app_localizations_en.dart';
import 'package:flutter/foundation.dart';

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
       _syncPendingActionsUseCase = syncPendingActionsUseCase;

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

  Future<void> initialize() async {
    if (_hasLoadedInitialData || isLoading) {
      return;
    }
    await _refreshAll(keepContentVisible: false);
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

  Future<String?> readLocalClientToken(String agentId) async {
    final userId = _authController.session?.userId;
    if (userId == null || userId.isEmpty) {
      return null;
    }
    return _clientTokenStore.read(userId: userId, agentId: agentId);
  }

  /// Persists or clears the local token for a draft row when the agent id is
  /// a valid UUID (used from the request-access form while editing).
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

  /// Writes tokens for each row, then enqueues access for valid agent ids.
  Future<bool> submitAccessRequestWithLocalTokens(
    List<ClientAgentAccessRequestRowInput> rows,
  ) async {
    final userId = _authController.session?.userId;
    if (userId == null || userId.isEmpty) {
      _actionErrorMessage = _s.clientAgentsSessionUnavailableRequest;
      _notifyListenersIfAlive();
      return false;
    }

    for (final row in rows) {
      final id = row.agentIdRaw.trim();
      if (!isValidClientAgentId(id)) {
        continue;
      }
      final token = row.clientTokenRaw.trim();
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

    final requestedIds = <String>{};
    for (final row in rows) {
      final id = row.agentIdRaw.trim();
      if (isValidClientAgentId(id)) {
        requestedIds.add(id);
      }
    }

    if (requestedIds.isEmpty) {
      return false;
    }

    return requestAccess(agentIds: requestedIds);
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
      final discardResult =
          await _discardQueuedClientAgentRequestAccessUseCase(
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

  Future<void> syncPending({
    bool autoTriggered = false,
  }) async {
    final userId = _authController.session?.userId;
    if (userId == null || userId.isEmpty) {
      _actionErrorMessage = _s.clientAgentsSessionUnavailableSync;
      _notifyListenersIfAlive();
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
    for (var i = 0; i < idsToCheck.length; i += _approvedAgentsProbeConcurrency) {
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
      })> _evaluateTrackedAgentForPoll({
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
    final denied = requestStatus == AgentAccessRequestStatus.rejected ||
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

  @override
  void dispose() {
    _stopApprovalPolling(clearTracked: true);
    _isDisposed = true;
    super.dispose();
  }
}

import 'dart:async';

import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/client_agents/application/usecases/load_client_access_requests_use_case.dart';
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
import 'package:flutter/foundation.dart';

enum ClientAgentsActionFeedbackKind { info, success }

class ClientAgentsController extends ChangeNotifier {
  ClientAgentsController({
    required AuthController authController,
    required LoadClientApprovedAgentsUseCase loadApprovedAgentsUseCase,
    required LoadClientAccessRequestsUseCase loadAccessRequestsUseCase,
    required QueueClientAgentRequestAccessUseCase queueRequestAccessUseCase,
    required QueueClientAgentRemoveAccessUseCase queueRemoveAccessUseCase,
    required ReadPendingClientAgentActionsUseCase readPendingActionsUseCase,
    required SyncPendingClientAgentActionsUseCase syncPendingActionsUseCase,
  }) : _authController = authController,
       _loadApprovedAgentsUseCase = loadApprovedAgentsUseCase,
       _loadAccessRequestsUseCase = loadAccessRequestsUseCase,
       _queueRequestAccessUseCase = queueRequestAccessUseCase,
       _queueRemoveAccessUseCase = queueRemoveAccessUseCase,
       _readPendingActionsUseCase = readPendingActionsUseCase,
       _syncPendingActionsUseCase = syncPendingActionsUseCase;

  final AuthController _authController;
  final LoadClientApprovedAgentsUseCase _loadApprovedAgentsUseCase;
  final LoadClientAccessRequestsUseCase _loadAccessRequestsUseCase;
  final QueueClientAgentRequestAccessUseCase _queueRequestAccessUseCase;
  final QueueClientAgentRemoveAccessUseCase _queueRemoveAccessUseCase;
  final ReadPendingClientAgentActionsUseCase _readPendingActionsUseCase;
  final SyncPendingClientAgentActionsUseCase _syncPendingActionsUseCase;

  bool _isDisposed = false;
  bool _isLoading = false;
  bool _isSyncing = false;
  bool _hasLoadedInitialData = false;
  bool _hasAttemptedAutoSync = false;
  String? _actionErrorMessage;
  String? _actionFeedbackMessage;
  ClientAgentsActionFeedbackKind? _actionFeedbackKind;
  String? _approvedAgentsErrorMessage;
  String? _accessRequestsErrorMessage;
  String? _pendingActionsErrorMessage;

  PaginatedResult<ClientAgent>? _approvedAgents;
  PaginatedResult<ClientAgentAccessRequest>? _accessRequests;
  List<PendingAgentAction> _pendingActions = const <PendingAgentAction>[];

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
      _actionErrorMessage = 'Sessao indisponivel para carregar agentes.';
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

  Future<void> requestAccess({
    required Set<String> agentIds,
  }) async {
    if (agentIds.isEmpty) {
      return;
    }
    final userId = _authController.session?.userId;
    if (userId == null || userId.isEmpty) {
      _actionErrorMessage = 'Sessao indisponivel para solicitar acesso.';
      _notifyListenersIfAlive();
      return;
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
      return;
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
  }

  Future<void> removeAccess({
    required Set<String> agentIds,
  }) async {
    if (agentIds.isEmpty) {
      return;
    }
    final userId = _authController.session?.userId;
    if (userId == null || userId.isEmpty) {
      _actionErrorMessage = 'Sessao indisponivel para remover acesso.';
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
      _actionErrorMessage = 'Sessao indisponivel para sincronizar pendencias.';
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
          message: 'Nao ha pendencias locais para sincronizar.',
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
        ),
        kind: ClientAgentsActionFeedbackKind.success,
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
        return failure.displayMessage;
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
        'Ja aprovados: ${classification.approved.join(', ')}.',
      if (classification.remotePending.isNotEmpty)
        'Ja enviados para aprovacao: $remotePendingMessage.',
      if (classification.localPending.isNotEmpty)
        'Ja registrados localmente: $localPendingMessage.',
    ];
    return parts.isEmpty
        ? 'Nao foi possivel registrar a solicitacao informada.'
        : 'Nenhum agentId novo pode ser solicitado. ${parts.join(' ')}';
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
        ? '1 solicitacao foi registrada localmente e sera sincronizada '
              'automaticamente.'
        : '$queuedCount solicitacoes foram registradas localmente e serao '
              'sincronizadas automaticamente.';
    if (ignoredCount == 0) {
      return baseMessage;
    }
    return '$baseMessage $ignoredCount agentIds foram ignorados porque '
        'ja estavam aprovados ou pendentes.';
  }

  String _buildBlockedRemoveMessage(
    ({Set<String> allowed, Set<String> notApproved, Set<String> localPending})
    classification,
  ) {
    final localPendingMessage = classification.localPending.join(', ');
    final parts = <String>[
      if (classification.notApproved.isNotEmpty)
        'Sem acesso aprovado: ${classification.notApproved.join(', ')}.',
      if (classification.localPending.isNotEmpty)
        'Remocao ja pendente localmente: $localPendingMessage.',
    ];
    return parts.isEmpty
        ? 'Nao foi possivel registrar a remocao informada.'
        : 'Nenhum agentId novo pode ser removido. ${parts.join(' ')}';
  }

  String _buildQueuedRemoveMessage(
    ({Set<String> allowed, Set<String> notApproved, Set<String> localPending})
    classification,
  ) {
    final queuedCount = classification.allowed.length;
    final ignoredCount =
        classification.notApproved.length + classification.localPending.length;
    final baseMessage = queuedCount == 1
        ? '1 remocao foi registrada localmente e sera sincronizada '
              'automaticamente.'
        : '$queuedCount remocoes foram registradas localmente e serao '
              'sincronizadas automaticamente.';
    if (ignoredCount == 0) {
      return baseMessage;
    }
    return '$baseMessage $ignoredCount agentIds foram ignorados.';
  }

  String _buildSyncSuccessMessage({
    required int pendingCount,
    required bool autoTriggered,
  }) {
    final prefix = pendingCount == 1
        ? '1 pendencia local foi enviada para a API.'
        : '$pendingCount pendencias locais foram enviadas para a API.';
    final suffix = autoTriggered
        ? ' A sincronizacao aconteceu automaticamente.'
        : ' A tela ja foi atualizada com o retorno mais recente.';
    return '$prefix$suffix';
  }

  void _notifyListenersIfAlive() {
    if (_isDisposed) {
      return;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}

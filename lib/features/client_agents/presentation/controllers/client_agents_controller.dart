import 'dart:async';

import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/client_agents/application/usecases/load_client_access_requests_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/load_client_agent_catalog_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/load_client_approved_agents_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/queue_client_agent_remove_access_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/queue_client_agent_request_access_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/read_pending_client_agent_actions_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/sync_pending_client_agent_actions_use_case.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent_access_request.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent_catalog_item.dart';
import 'package:colmeia/features/client_agents/domain/entities/paginated_query.dart';
import 'package:colmeia/features/client_agents/domain/entities/paginated_result.dart';
import 'package:colmeia/features/client_agents/domain/entities/pending_agent_action.dart';
import 'package:flutter/foundation.dart';

class ClientAgentsController extends ChangeNotifier {
  ClientAgentsController({
    required AuthController authController,
    required LoadClientAgentCatalogUseCase loadCatalogUseCase,
    required LoadClientApprovedAgentsUseCase loadApprovedAgentsUseCase,
    required LoadClientAccessRequestsUseCase loadAccessRequestsUseCase,
    required QueueClientAgentRequestAccessUseCase queueRequestAccessUseCase,
    required QueueClientAgentRemoveAccessUseCase queueRemoveAccessUseCase,
    required ReadPendingClientAgentActionsUseCase readPendingActionsUseCase,
    required SyncPendingClientAgentActionsUseCase syncPendingActionsUseCase,
  }) : _authController = authController,
       _loadCatalogUseCase = loadCatalogUseCase,
       _loadApprovedAgentsUseCase = loadApprovedAgentsUseCase,
       _loadAccessRequestsUseCase = loadAccessRequestsUseCase,
       _queueRequestAccessUseCase = queueRequestAccessUseCase,
       _queueRemoveAccessUseCase = queueRemoveAccessUseCase,
       _readPendingActionsUseCase = readPendingActionsUseCase,
       _syncPendingActionsUseCase = syncPendingActionsUseCase;

  final AuthController _authController;
  final LoadClientAgentCatalogUseCase _loadCatalogUseCase;
  final LoadClientApprovedAgentsUseCase _loadApprovedAgentsUseCase;
  final LoadClientAccessRequestsUseCase _loadAccessRequestsUseCase;
  final QueueClientAgentRequestAccessUseCase _queueRequestAccessUseCase;
  final QueueClientAgentRemoveAccessUseCase _queueRemoveAccessUseCase;
  final ReadPendingClientAgentActionsUseCase _readPendingActionsUseCase;
  final SyncPendingClientAgentActionsUseCase _syncPendingActionsUseCase;

  bool _isDisposed = false;
  bool _isLoading = false;
  bool _isSyncing = false;
  String? _errorMessage;

  PaginatedResult<ClientAgentCatalogItem>? _catalog;
  PaginatedResult<ClientAgent>? _approvedAgents;
  PaginatedResult<ClientAgentAccessRequest>? _accessRequests;
  List<PendingAgentAction> _pendingActions = const <PendingAgentAction>[];

  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  String? get errorMessage => _errorMessage;
  PaginatedResult<ClientAgentCatalogItem>? get catalog => _catalog;
  PaginatedResult<ClientAgent>? get approvedAgents => _approvedAgents;
  PaginatedResult<ClientAgentAccessRequest>? get accessRequests =>
      _accessRequests;
  List<PendingAgentAction> get pendingActions => _pendingActions;

  Future<void> initialize() async {
    if (_catalog != null || _isLoading) {
      return;
    }
    await refreshAll();
  }

  Future<void> refreshAll() async {
    final userId = _authController.session?.userId;
    if (userId == null || userId.isEmpty) {
      _errorMessage = 'Sessao indisponivel para carregar agentes.';
      _notifyListenersIfAlive();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    _notifyListenersIfAlive();

    const query = PaginatedQuery(pageSize: 50);
    final catalogResult = await _loadCatalogUseCase(
      userId: userId,
      query: query,
    );
    final approvedResult = await _loadApprovedAgentsUseCase(
      userId: userId,
      query: query,
    );
    final requestsResult = await _loadAccessRequestsUseCase(
      userId: userId,
      query: query,
    );
    final pendingResult = await _readPendingActionsUseCase(userId: userId);

    _consumeResult(
      result: catalogResult,
      onSuccess: (value) => _catalog = value,
    );
    _consumeResult(
      result: approvedResult,
      onSuccess: (value) => _approvedAgents = value,
    );
    _consumeResult(
      result: requestsResult,
      onSuccess: (value) => _accessRequests = value,
    );
    _consumeResult(
      result: pendingResult,
      onSuccess: (value) => _pendingActions = value,
    );

    _isLoading = false;
    _notifyListenersIfAlive();
  }

  Future<void> requestAccess({
    required Set<String> agentIds,
  }) async {
    if (agentIds.isEmpty) {
      return;
    }
    final userId = _authController.session?.userId;
    if (userId == null || userId.isEmpty) {
      _errorMessage = 'Sessao indisponivel para solicitar acesso.';
      _notifyListenersIfAlive();
      return;
    }
    _isSyncing = true;
    _errorMessage = null;
    _notifyListenersIfAlive();

    final queueResult = await _queueRequestAccessUseCase(
      userId: userId,
      agentIds: agentIds,
    );
    _consumeResult(result: queueResult);
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
      _errorMessage = 'Sessao indisponivel para remover acesso.';
      _notifyListenersIfAlive();
      return;
    }

    _isSyncing = true;
    _errorMessage = null;
    _notifyListenersIfAlive();

    final queueResult = await _queueRemoveAccessUseCase(
      userId: userId,
      agentIds: agentIds,
    );
    _consumeResult(result: queueResult);
    await _reloadPendingAfterEnqueue(userId: userId);
  }

  Future<void> syncPending() async {
    final userId = _authController.session?.userId;
    if (userId == null || userId.isEmpty) {
      _errorMessage = 'Sessao indisponivel para sincronizar pendencias.';
      _notifyListenersIfAlive();
      return;
    }
    _isSyncing = true;
    _errorMessage = null;
    _notifyListenersIfAlive();
    final syncResult = await _syncPendingActionsUseCase(userId: userId);
    _consumeResult(result: syncResult);
    await _refreshAfterMutation(userId: userId);
  }

  Future<void> _reloadPendingAfterEnqueue({
    required String userId,
  }) async {
    final pendingResult = await _readPendingActionsUseCase(userId: userId);
    _consumeResult(
      result: pendingResult,
      onSuccess: (value) => _pendingActions = value,
    );
    _isSyncing = false;
    _notifyListenersIfAlive();
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

    _consumeResult(
      result: approvedResult,
      onSuccess: (value) => _approvedAgents = value,
    );
    _consumeResult(
      result: requestsResult,
      onSuccess: (value) => _accessRequests = value,
    );
    _consumeResult(
      result: pendingResult,
      onSuccess: (value) => _pendingActions = value,
    );

    _isSyncing = false;
    _notifyListenersIfAlive();
  }

  void _consumeResult<T extends Object>({
    required AppResult<T> result,
    ValueChanged<T>? onSuccess,
  }) {
    result.fold(
      (value) {
        onSuccess?.call(value);
      },
      (failure) {
        _errorMessage = failure.displayMessage;
        AppLogger.warning(
          'Client agents operation failed',
          context: <String, Object?>{
            'operation': 'clientAgentsController',
            'technicalMessage': failure.message,
          },
          error: failure.cause ?? failure,
          stackTrace: failure.stackTrace,
        );
      },
    );
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

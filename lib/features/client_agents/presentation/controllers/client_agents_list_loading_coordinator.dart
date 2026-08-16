import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/client_agents/application/usecases/load_client_access_requests_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/load_client_approved_agents_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/read_pending_client_agent_actions_use_case.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent_access_request.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agents_list_page_size.dart';
import 'package:colmeia/features/client_agents/domain/entities/paginated_query.dart';
import 'package:colmeia/features/client_agents/domain/entities/paginated_result.dart';
import 'package:colmeia/features/client_agents/domain/entities/pending_agent_action.dart';
import 'package:colmeia/features/client_agents/presentation/models/client_agents_presentation_message.dart';
import 'package:flutter/foundation.dart';

/// Surface the list-loading coordinator needs from its owner controller.
abstract interface class ClientAgentsListLoadingHost {
  bool get isDisposed;

  String? get currentUserId;

  bool get isLoadingInitial;

  bool get isRefreshing;

  bool get hasLoadedInitialData;

  set isLoadingInitial(bool value);

  set isRefreshing(bool value);

  set hasLoadedInitialData(bool value);

  int get refreshAllToken;

  set refreshAllToken(int value);

  PaginatedResult<ClientAgent>? get approvedAgentsSnapshot;

  PaginatedResult<ClientAgentAccessRequest>? get accessRequestsSnapshot;

  List<PendingAgentAction> get pendingActionsSnapshot;

  void replaceApprovedAgents(PaginatedResult<ClientAgent> value);

  void replaceAccessRequests(PaginatedResult<ClientAgentAccessRequest> value);

  void replacePendingActions(List<PendingAgentAction> actions);

  void setApprovedAgentsError(ClientAgentsPresentationMessage? error);

  void setAccessRequestsError(ClientAgentsPresentationMessage? error);

  void setPendingActionsError(ClientAgentsPresentationMessage? error);

  void setActionError(ClientAgentsPresentationMessage? error);

  void clearSectionErrors();

  bool hasListContent();

  void notifyListChanged();

  void scheduleLocalTokenServerFlushForApprovedAgents({required String userId});

  void scheduleAutoSyncIfNeeded();

  ClientAgentsPresentationMessage? consumeResult<T extends Object>({
    required AppResult<T> result,
    required String operation,
    ValueChanged<T>? onSuccess,
  });
}

/// Owns parallel list loads (approved agents, access requests, pending
/// actions) and the refresh-token guard that drops stale responses.
class ClientAgentsListLoadingCoordinator {
  ClientAgentsListLoadingCoordinator({
    required this._host,
    required this._loadApprovedAgentsUseCase,
    required this._loadAccessRequestsUseCase,
    required this._readPendingActionsUseCase,
  });

  final ClientAgentsListLoadingHost _host;
  final LoadClientApprovedAgentsUseCase _loadApprovedAgentsUseCase;
  final LoadClientAccessRequestsUseCase _loadAccessRequestsUseCase;
  final ReadPendingClientAgentActionsUseCase _readPendingActionsUseCase;

  Future<void> refreshAll({required bool keepContentVisible}) async {
    final userId = _host.currentUserId;
    if (userId == null || userId.isEmpty) {
      _host
        ..setActionError(
          ClientAgentsPresentationMessage.clientAgentsSessionUnavailableLoad(),
        )
        ..notifyListChanged();
      return;
    }

    final refreshToken = _host.refreshAllToken + 1;
    _host.refreshAllToken = refreshToken;
    if (keepContentVisible) {
      _host.isLoadingInitial = false;
      _host.isRefreshing = true;
    } else {
      _host.isRefreshing = false;
      _host.isLoadingInitial = true;
    }
    _host
      ..clearSectionErrors()
      ..notifyListChanged();

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
      if (_host.isDisposed || refreshToken != _host.refreshAllToken) {
        return;
      }

      _host
        ..setApprovedAgentsError(
          _host.consumeResult(
            result: approvedResult,
            onSuccess: _host.replaceApprovedAgents,
            operation: 'loadApprovedClientAgents',
          ),
        )
        ..setAccessRequestsError(
          _host.consumeResult(
            result: requestsResult,
            onSuccess: _host.replaceAccessRequests,
            operation: 'loadClientAgentAccessRequests',
          ),
        )
        ..setPendingActionsError(
          _host.consumeResult(
            result: pendingResult,
            onSuccess: _host.replacePendingActions,
            operation: 'readPendingClientAgentActions',
          ),
        )
        ..scheduleLocalTokenServerFlushForApprovedAgents(userId: userId);
    } finally {
      if (!_host.isDisposed && refreshToken == _host.refreshAllToken) {
        if (keepContentVisible) {
          _host.isRefreshing = false;
        } else {
          _host.isLoadingInitial = false;
        }
        _host.hasLoadedInitialData = true;
        _host
          ..notifyListChanged()
          ..scheduleAutoSyncIfNeeded();
      }
    }
  }

  Future<void> refreshAfterMutation({required String userId}) async {
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
    if (_host.isDisposed) {
      return;
    }

    _host
      ..setApprovedAgentsError(
        _host.consumeResult(
          result: approvedResult,
          onSuccess: _host.replaceApprovedAgents,
          operation: 'loadApprovedClientAgents',
        ),
      )
      ..setAccessRequestsError(
        _host.consumeResult(
          result: requestsResult,
          onSuccess: _host.replaceAccessRequests,
          operation: 'loadClientAgentAccessRequests',
        ),
      )
      ..setPendingActionsError(
        _host.consumeResult(
          result: pendingResult,
          onSuccess: _host.replacePendingActions,
          operation: 'readPendingClientAgentActions',
        ),
      )
      ..scheduleLocalTokenServerFlushForApprovedAgents(userId: userId)
      ..notifyListChanged();
  }
}

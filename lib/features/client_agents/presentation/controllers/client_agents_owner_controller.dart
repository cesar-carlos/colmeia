import 'dart:async';

import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/client_agents/application/usecases/approve_owner_access_request_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/load_managed_agents_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/load_owner_access_requests_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/load_owner_approved_clients_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/reject_owner_access_request_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/revoke_owner_client_access_use_case.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent.dart';
import 'package:colmeia/features/client_agents/domain/entities/owner_approved_client.dart';
import 'package:colmeia/features/client_agents/domain/entities/owner_client_access_request.dart';
import 'package:colmeia/features/client_agents/presentation/localization/client_agents_failure_l10n.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/l10n/app_localizations_en.dart';
import 'package:flutter/foundation.dart';
import 'package:result_dart/result_dart.dart' show Unit;

class ClientAgentsOwnerController extends ChangeNotifier {
  ClientAgentsOwnerController({
    required AuthController authController,
    required LoadManagedAgentsUseCase loadManagedAgentsUseCase,
    required LoadOwnerAccessRequestsUseCase loadOwnerAccessRequestsUseCase,
    required ApproveOwnerAccessRequestUseCase approveOwnerAccessRequestUseCase,
    required RejectOwnerAccessRequestUseCase rejectOwnerAccessRequestUseCase,
    required LoadOwnerApprovedClientsUseCase loadOwnerApprovedClientsUseCase,
    required RevokeOwnerClientAccessUseCase revokeOwnerClientAccessUseCase,
  }) : _authController = authController,
       _loadManagedAgentsUseCase = loadManagedAgentsUseCase,
       _loadOwnerAccessRequestsUseCase = loadOwnerAccessRequestsUseCase,
       _approveOwnerAccessRequestUseCase = approveOwnerAccessRequestUseCase,
       _rejectOwnerAccessRequestUseCase = rejectOwnerAccessRequestUseCase,
       _loadOwnerApprovedClientsUseCase = loadOwnerApprovedClientsUseCase,
       _revokeOwnerClientAccessUseCase = revokeOwnerClientAccessUseCase;

  final AuthController _authController;
  final LoadManagedAgentsUseCase _loadManagedAgentsUseCase;
  final LoadOwnerAccessRequestsUseCase _loadOwnerAccessRequestsUseCase;
  final ApproveOwnerAccessRequestUseCase _approveOwnerAccessRequestUseCase;
  final RejectOwnerAccessRequestUseCase _rejectOwnerAccessRequestUseCase;
  final LoadOwnerApprovedClientsUseCase _loadOwnerApprovedClientsUseCase;
  final RevokeOwnerClientAccessUseCase _revokeOwnerClientAccessUseCase;

  AppLocalizations? _l10n;
  bool _isDisposed = false;
  bool _isLoadingInitial = false;
  bool _isRefreshing = false;
  bool _isMutating = false;
  bool _hasLoadedInitialData = false;
  String? _managedAgentsErrorMessage;
  String? _ownerRequestsErrorMessage;
  String? _approvedClientsErrorMessage;
  String? _actionErrorMessage;
  String? _actionFeedbackMessage;
  List<ClientAgent> _managedAgents = const <ClientAgent>[];
  List<OwnerClientAccessRequest> _ownerRequests =
      const <OwnerClientAccessRequest>[];
  List<OwnerApprovedClient> _approvedClients = const <OwnerApprovedClient>[];
  String? _selectedManagedAgentId;

  AppLocalizations get _s => _l10n ?? AppLocalizationsEn();

  AppLocalizations? get activeLocalizations => _l10n;

  set activeLocalizations(AppLocalizations value) => _l10n = value;

  bool get isLoading => _isLoadingInitial || _isRefreshing;
  bool get isLoadingInitial => _isLoadingInitial;
  bool get isRefreshing => _isRefreshing;
  bool get isMutating => _isMutating;
  String? get managedAgentsErrorMessage => _managedAgentsErrorMessage;
  String? get ownerRequestsErrorMessage => _ownerRequestsErrorMessage;
  String? get approvedClientsErrorMessage => _approvedClientsErrorMessage;
  String? get actionErrorMessage => _actionErrorMessage;
  String? get actionFeedbackMessage => _actionFeedbackMessage;
  List<ClientAgent> get managedAgents => _managedAgents;
  List<OwnerClientAccessRequest> get ownerRequests => _ownerRequests;
  List<OwnerApprovedClient> get approvedClients => _approvedClients;
  String? get selectedManagedAgentId => _selectedManagedAgentId;

  Future<void> initialize() async {
    if (_hasLoadedInitialData || isLoading) {
      return;
    }
    await _refreshAll(keepContentVisible: false);
  }

  Future<void> refreshAll() async {
    await _refreshAll(keepContentVisible: _hasLoadedInitialData);
  }

  Future<void> selectManagedAgent(String? agentId) async {
    final normalized = agentId?.trim();
    if (normalized == _selectedManagedAgentId) {
      return;
    }
    _selectedManagedAgentId = normalized;
    _approvedClients = const <OwnerApprovedClient>[];
    _approvedClientsErrorMessage = null;
    _notifyListenersIfAlive();
    await _loadApprovedClients();
  }

  Future<void> approveRequest({
    required String requestId,
    required String agentId,
  }) {
    return _mutateRequest(
      operation: 'approveOwnerAccessRequest',
      fallbackFeedback: _s.clientAgentsOwnerApproveSuccess,
      action: (userId) => _approveOwnerAccessRequestUseCase(
        userId: userId,
        requestId: requestId,
      ),
      refreshAgentId: agentId,
    );
  }

  Future<void> rejectRequest({
    required String requestId,
    required String agentId,
  }) {
    return _mutateRequest(
      operation: 'rejectOwnerAccessRequest',
      fallbackFeedback: _s.clientAgentsOwnerRejectSuccess,
      action: (userId) => _rejectOwnerAccessRequestUseCase(
        userId: userId,
        requestId: requestId,
      ),
      refreshAgentId: agentId,
    );
  }

  Future<void> revokeClientAccess({
    required String agentId,
    required String clientId,
  }) {
    return _mutateRequest(
      operation: 'revokeOwnerClientAccess',
      fallbackFeedback: _s.clientAgentsOwnerRevokeSuccess,
      action: (userId) => _revokeOwnerClientAccessUseCase(
        userId: userId,
        agentId: agentId,
        clientId: clientId,
      ),
      refreshAgentId: agentId,
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
    _actionFeedbackMessage = null;
    _notifyListenersIfAlive();
  }

  Future<void> _refreshAll({required bool keepContentVisible}) async {
    final userId = _authController.session?.userId;
    if (userId == null || userId.isEmpty) {
      _actionErrorMessage = _s.clientAgentsSessionUnavailableLoad;
      _notifyListenersIfAlive();
      return;
    }

    _managedAgentsErrorMessage = null;
    _ownerRequestsErrorMessage = null;
    _approvedClientsErrorMessage = null;
    _actionErrorMessage = null;
    if (keepContentVisible) {
      _isRefreshing = true;
      _isLoadingInitial = false;
    } else {
      _isLoadingInitial = true;
      _isRefreshing = false;
    }
    _notifyListenersIfAlive();

    try {
      late AppResult<List<ClientAgent>> managedResult;
      late AppResult<List<OwnerClientAccessRequest>> requestsResult;
      await Future.wait<void>(<Future<void>>[
        _loadManagedAgentsUseCase(
          userId: userId,
        ).then((value) => managedResult = value),
        _loadOwnerAccessRequestsUseCase(
          userId: userId,
        ).then((value) => requestsResult = value),
      ]);
      _managedAgentsErrorMessage = _consumeResult(
        result: managedResult,
        operation: 'loadManagedAgents',
        onSuccess: (value) => _managedAgents = value,
      );
      _ownerRequestsErrorMessage = _consumeResult(
        result: requestsResult,
        operation: 'loadOwnerAccessRequests',
        onSuccess: (value) => _ownerRequests = value,
      );
      _selectedManagedAgentId = _resolveSelectedManagedAgentId();
      await _loadApprovedClients(userId: userId);
    } finally {
      _isLoadingInitial = false;
      _isRefreshing = false;
      _hasLoadedInitialData = true;
      _notifyListenersIfAlive();
    }
  }

  Future<void> _loadApprovedClients({String? userId}) async {
    final resolvedUserId = userId ?? _authController.session?.userId;
    final agentId = _selectedManagedAgentId;
    if (resolvedUserId == null || resolvedUserId.isEmpty || agentId == null) {
      _approvedClients = const <OwnerApprovedClient>[];
      _approvedClientsErrorMessage = null;
      _notifyListenersIfAlive();
      return;
    }
    final result = await _loadOwnerApprovedClientsUseCase(
      userId: resolvedUserId,
      agentId: agentId,
    );
    _approvedClientsErrorMessage = _consumeResult(
      result: result,
      operation: 'loadOwnerApprovedClients',
      onSuccess: (value) => _approvedClients = value,
    );
    _notifyListenersIfAlive();
  }

  String? _resolveSelectedManagedAgentId() {
    if (_managedAgents.isEmpty) {
      return null;
    }
    final current = _selectedManagedAgentId;
    if (current != null &&
        _managedAgents.any((agent) => agent.agentId == current)) {
      return current;
    }
    return _managedAgents.first.agentId;
  }

  Future<void> _mutateRequest({
    required String operation,
    required String fallbackFeedback,
    required Future<AppResult<Unit>> Function(String userId) action,
    required String refreshAgentId,
  }) async {
    final userId = _authController.session?.userId;
    if (userId == null || userId.isEmpty) {
      _actionErrorMessage = _s.clientAgentsSessionUnavailableLoad;
      _notifyListenersIfAlive();
      return;
    }
    _isMutating = true;
    _actionErrorMessage = null;
    _actionFeedbackMessage = null;
    _notifyListenersIfAlive();
    final result = await action(userId);
    _actionErrorMessage = _consumeResult(result: result, operation: operation);
    if (_actionErrorMessage == null) {
      _actionFeedbackMessage = fallbackFeedback;
      if (_selectedManagedAgentId != refreshAgentId) {
        _selectedManagedAgentId = refreshAgentId;
      }
      await _refreshAll(keepContentVisible: true);
    }
    _isMutating = false;
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
          'Client agents owner operation failed',
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

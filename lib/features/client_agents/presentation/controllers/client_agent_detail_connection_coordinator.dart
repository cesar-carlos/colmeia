import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/agent_meta/application/usecases/load_client_token_policy_use_case.dart';
import 'package:colmeia/features/agent_meta/application/usecases/refresh_agent_profile_use_case.dart';
import 'package:colmeia/features/agent_meta/domain/entities/agent_profile_snapshot.dart';
import 'package:colmeia/features/agent_meta/domain/entities/client_token_policy.dart';
import 'package:colmeia/features/client_agents/application/usecases/get_client_agent_token_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/persist_client_agent_profile_snapshot_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/remove_client_agent_token_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/save_client_agent_token_use_case.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent.dart';
import 'package:colmeia/features/client_agents/presentation/controllers/client_agent_token_status.dart';
import 'package:colmeia/features/client_agents/presentation/models/client_agents_presentation_message.dart';

abstract interface class ClientAgentDetailConnectionHost {
  bool get isDisposed;

  ClientAgent? get agent;

  void setAgent(ClientAgent agent);

  String? get currentUserId;

  String? get persistedClientToken;

  ClientAgentsPresentationMessage consumeFailure(AppFailure failure);

  bool agentSupportsRpcMethod(String method);

  void invalidateTargetResolution({required String userId});

  void notifyConnectionChanged();
}

class ClientAgentDetailConnectionCoordinator {
  ClientAgentDetailConnectionCoordinator({
    required this._host,
    required this._getClientAgentTokenUseCase,
    required this._saveClientAgentTokenUseCase,
    required this._removeClientAgentTokenUseCase,
    required this._refreshAgentProfileUseCase,
    required this._persistClientAgentProfileSnapshotUseCase,
    required this._loadClientTokenPolicyUseCase,
  });

  final ClientAgentDetailConnectionHost _host;
  final GetClientAgentTokenUseCase _getClientAgentTokenUseCase;
  final SaveClientAgentTokenUseCase _saveClientAgentTokenUseCase;
  final RemoveClientAgentTokenUseCase _removeClientAgentTokenUseCase;
  final RefreshAgentProfileUseCase _refreshAgentProfileUseCase;
  final PersistClientAgentProfileSnapshotUseCase
  _persistClientAgentProfileSnapshotUseCase;
  final LoadClientTokenPolicyUseCase _loadClientTokenPolicyUseCase;

  int _clientTokenRevision = 0;
  int _clientTokenLoadGeneration = 0;
  String? _persistedClientToken;
  ClientAgentTokenStatus _clientTokenStatus = ClientAgentTokenStatus.unknown;
  bool _isLoadingClientToken = false;
  bool _isSavingClientToken = false;
  ClientAgentsPresentationMessage? _clientTokenFeedback;
  ClientAgentsPresentationMessage? _clientTokenError;

  ClientTokenPolicy? _clientTokenPolicy;
  bool _clientTokenPolicyUnsupported = false;
  bool _isLoadingClientTokenPolicy = false;
  ClientAgentsPresentationMessage? _clientTokenPolicyError;
  int _clientTokenPolicyGeneration = 0;

  bool _isRefreshingFromAgent = false;
  ClientAgentsPresentationMessage? _refreshFromAgentFeedback;
  ClientAgentsPresentationMessage? _refreshFromAgentError;

  int get clientTokenRevision => _clientTokenRevision;
  String get persistedClientTokenForField => _persistedClientToken ?? '';
  bool get isLoadingClientToken => _isLoadingClientToken;
  bool get isSavingClientToken => _isSavingClientToken;
  ClientAgentsPresentationMessage? get clientTokenFeedback =>
      _clientTokenFeedback;
  ClientAgentsPresentationMessage? get clientTokenError => _clientTokenError;
  ClientAgentTokenStatus get clientTokenStatus => _clientTokenStatus;
  ClientTokenPolicy? get clientTokenPolicy => _clientTokenPolicy;
  bool get clientTokenPolicyUnsupported => _clientTokenPolicyUnsupported;
  bool get isLoadingClientTokenPolicy => _isLoadingClientTokenPolicy;
  ClientAgentsPresentationMessage? get clientTokenPolicyError =>
      _clientTokenPolicyError;
  bool get isRefreshingFromAgent => _isRefreshingFromAgent;
  ClientAgentsPresentationMessage? get refreshFromAgentFeedback =>
      _refreshFromAgentFeedback;
  ClientAgentsPresentationMessage? get refreshFromAgentError =>
      _refreshFromAgentError;

  void seedTokenStatusFromAgent(ClientAgent agent) {
    _clientTokenStatus = _statusFromAgent(agent);
  }

  void resetTokenState() {
    _persistedClientToken = null;
    _clientTokenStatus = ClientAgentTokenStatus.unknown;
    _clientTokenError = null;
    _clientTokenRevision++;
    resetPolicyState();
  }

  void resetPolicyState() {
    _clientTokenPolicy = null;
    _clientTokenPolicyUnsupported = false;
    _clientTokenPolicyError = null;
  }

  Future<void> refreshPersistedClientTokenFromServer({
    required String agentId,
  }) async {
    final userId = _host.currentUserId;
    if (userId == null || userId.isEmpty) {
      return;
    }

    final generation = ++_clientTokenLoadGeneration;
    _isLoadingClientToken = true;
    _clientTokenError = null;
    _host.notifyConnectionChanged();

    try {
      final result = await _getClientAgentTokenUseCase(
        userId: userId,
        agentId: agentId,
      );
      if (_host.isDisposed || generation != _clientTokenLoadGeneration) {
        return;
      }
      final snapshot = result.getOrNull();
      if (snapshot != null) {
        _persistedClientToken = snapshot.token ?? '';
        _clientTokenStatus = snapshot.hasToken
            ? ClientAgentTokenStatus.configured
            : ClientAgentTokenStatus.missing;
      } else {
        final failure = result.exceptionOrNull()!;
        _clientTokenError = _host.consumeFailure(failure);
        AppLogger.warning(
          'Client agent token load failed',
          context: <String, Object?>{
            'operation': 'getClientAgentToken',
            'agentId': agentId,
            'technicalMessage': failure.message,
          },
          error: failure.cause ?? failure,
          stackTrace: failure.stackTrace,
        );
      }
      _clientTokenRevision++;
    } finally {
      if (!_host.isDisposed && generation == _clientTokenLoadGeneration) {
        _isLoadingClientToken = false;
        _host.notifyConnectionChanged();
      }
    }
  }

  Future<void> saveClientAgentToken({
    required String agentId,
    required String rawToken,
  }) async {
    final userId = _host.currentUserId;
    if (userId == null || userId.isEmpty) {
      _clientTokenError =
          ClientAgentsPresentationMessage.clientAgentDetailSessionUnavailable();
      _host.notifyConnectionChanged();
      return;
    }

    _isSavingClientToken = true;
    _clientTokenFeedback = null;
    _clientTokenError = null;
    resetPolicyState();
    _host.notifyConnectionChanged();

    try {
      final result = await _saveClientAgentTokenUseCase(
        userId: userId,
        agentId: agentId,
        clientToken: rawToken,
      );
      if (_host.isDisposed) {
        return;
      }
      final snapshot = result.getOrNull();
      if (snapshot != null) {
        _persistedClientToken = snapshot.token ?? '';
        _clientTokenStatus = snapshot.hasToken
            ? ClientAgentTokenStatus.configured
            : ClientAgentTokenStatus.missing;
        _clientTokenRevision++;
        _clientTokenFeedback = snapshot.hasToken
            ? ClientAgentsPresentationMessage.clientAgentDetailServerTokenSaved()
            : ClientAgentsPresentationMessage.clientAgentDetailServerTokenRemoved();
        _refreshLoadedAgentTokenFlag(hasToken: snapshot.hasToken);
        _host.invalidateTargetResolution(userId: userId);
      } else {
        final failure = result.exceptionOrNull()!;
        _clientTokenError = _host.consumeFailure(failure);
        AppLogger.warning(
          'Client agent token save failed',
          context: <String, Object?>{
            'operation': 'saveClientAgentToken',
            'agentId': agentId,
            'technicalMessage': failure.message,
          },
          error: failure.cause ?? failure,
          stackTrace: failure.stackTrace,
        );
      }
    } finally {
      if (!_host.isDisposed) {
        _isSavingClientToken = false;
        _host.notifyConnectionChanged();
      }
    }
  }

  Future<void> removeClientAgentToken({required String agentId}) async {
    final userId = _host.currentUserId;
    if (userId == null || userId.isEmpty) {
      _clientTokenError =
          ClientAgentsPresentationMessage.clientAgentDetailSessionUnavailable();
      _host.notifyConnectionChanged();
      return;
    }

    _isSavingClientToken = true;
    _clientTokenFeedback = null;
    _clientTokenError = null;
    resetPolicyState();
    _host.notifyConnectionChanged();

    try {
      final result = await _removeClientAgentTokenUseCase(
        userId: userId,
        agentId: agentId,
      );
      if (_host.isDisposed) {
        return;
      }
      if (result.isSuccess()) {
        _persistedClientToken = '';
        _clientTokenStatus = ClientAgentTokenStatus.missing;
        _clientTokenRevision++;
        _clientTokenFeedback =
            ClientAgentsPresentationMessage.clientAgentDetailServerTokenRemoved();
        _refreshLoadedAgentTokenFlag(hasToken: false);
        _host.invalidateTargetResolution(userId: userId);
      } else {
        final failure = result.exceptionOrNull()!;
        _clientTokenError = _host.consumeFailure(failure);
        AppLogger.warning(
          'Client agent token remove failed',
          context: <String, Object?>{
            'operation': 'removeClientAgentToken',
            'agentId': agentId,
            'technicalMessage': failure.message,
          },
          error: failure.cause ?? failure,
          stackTrace: failure.stackTrace,
        );
      }
    } finally {
      if (!_host.isDisposed) {
        _isSavingClientToken = false;
        _host.notifyConnectionChanged();
      }
    }
  }

  void clearClientTokenFeedback() {
    if (_clientTokenFeedback == null && _clientTokenError == null) {
      return;
    }
    _clientTokenFeedback = null;
    _clientTokenError = null;
    _host.notifyConnectionChanged();
  }

  Future<void> refreshFromAgent({required String agentId}) async {
    if (!_host.agentSupportsRpcMethod('agent.getProfile')) {
      _refreshFromAgentError =
          ClientAgentsPresentationMessage.clientAgentDetailRefreshFromAgentUnsupported();
      _host.notifyConnectionChanged();
      return;
    }
    final userId = _host.currentUserId;
    if (userId == null || userId.isEmpty) {
      _refreshFromAgentError =
          ClientAgentsPresentationMessage.clientAgentDetailSessionUnavailable();
      _host.notifyConnectionChanged();
      return;
    }

    _isRefreshingFromAgent = true;
    _refreshFromAgentError = null;
    _refreshFromAgentFeedback = null;
    _host.notifyConnectionChanged();

    try {
      final clientToken = (_persistedClientToken ?? '').trim();
      final result = await _refreshAgentProfileUseCase(
        agentId: agentId,
        clientToken: clientToken.isEmpty ? null : clientToken,
      );
      if (_host.isDisposed) {
        return;
      }
      final snapshot = result.getOrNull();
      if (snapshot != null) {
        _applyAgentProfileSnapshot(snapshot);
        final persistResult = await _persistClientAgentProfileSnapshotUseCase(
          userId: userId,
          agentId: agentId,
          snapshot: snapshot,
        );
        if (_host.isDisposed) {
          return;
        }
        if (persistResult.isError()) {
          final failure = persistResult.exceptionOrNull()!;
          _refreshFromAgentError = _host.consumeFailure(failure);
          AppLogger.warning(
            'Persisting refreshed agent snapshot locally failed',
            context: <String, Object?>{
              'operation': 'persistRefreshAgentProfileSnapshotLocally',
              'agentId': agentId,
              'technicalMessage': failure.message,
            },
            error: failure.cause ?? failure,
            stackTrace: failure.stackTrace,
          );
          return;
        }
        _refreshFromAgentFeedback =
            ClientAgentsPresentationMessage.clientAgentDetailRefreshFromAgentSuccess();
      } else {
        final failure = result.exceptionOrNull()!;
        _refreshFromAgentError = _host.consumeFailure(failure);
        AppLogger.warning(
          'agent.getProfile refresh failed',
          context: <String, Object?>{
            'operation': 'refreshAgentProfileFromAgent',
            'agentId': agentId,
            'technicalMessage': failure.message,
          },
          error: failure.cause ?? failure,
          stackTrace: failure.stackTrace,
        );
      }
    } finally {
      if (!_host.isDisposed) {
        _isRefreshingFromAgent = false;
        _host.notifyConnectionChanged();
      }
    }
  }

  Future<void> loadClientTokenPolicy({required String agentId}) async {
    final token = (_persistedClientToken ?? '').trim();
    if (token.isEmpty) {
      resetPolicyState();
      _host.notifyConnectionChanged();
      return;
    }
    if (!_host.agentSupportsRpcMethod('client_token.getPolicy')) {
      _clientTokenPolicy = null;
      _clientTokenPolicyUnsupported = true;
      _clientTokenPolicyError = null;
      _host.notifyConnectionChanged();
      return;
    }
    final generation = ++_clientTokenPolicyGeneration;
    _isLoadingClientTokenPolicy = true;
    _clientTokenPolicyError = null;
    _host.notifyConnectionChanged();
    try {
      final result = await _loadClientTokenPolicyUseCase(
        agentId: agentId,
        clientToken: token,
      );
      if (_host.isDisposed || generation != _clientTokenPolicyGeneration) {
        return;
      }
      final policySnapshot = result.getOrNull();
      if (policySnapshot != null) {
        _clientTokenPolicy = policySnapshot.policy;
        _clientTokenPolicyUnsupported = !policySnapshot.supported;
      } else {
        final failure = result.exceptionOrNull()!;
        _clientTokenPolicyError = _host.consumeFailure(failure);
        AppLogger.warning(
          'client_token.getPolicy failed',
          context: <String, Object?>{
            'operation': 'loadClientTokenPolicy',
            'agentId': agentId,
            'technicalMessage': failure.message,
          },
          error: failure.cause ?? failure,
          stackTrace: failure.stackTrace,
        );
      }
    } finally {
      if (!_host.isDisposed && generation == _clientTokenPolicyGeneration) {
        _isLoadingClientTokenPolicy = false;
        _host.notifyConnectionChanged();
      }
    }
  }

  void clearRefreshFromAgentFeedback() {
    if (_refreshFromAgentFeedback == null && _refreshFromAgentError == null) {
      return;
    }
    _refreshFromAgentFeedback = null;
    _refreshFromAgentError = null;
    _host.notifyConnectionChanged();
  }

  void _refreshLoadedAgentTokenFlag({required bool hasToken}) {
    final current = _host.agent;
    if (current == null || current.hasServerClientToken == hasToken) {
      return;
    }
    _host.setAgent(current.copyWith(hasServerClientToken: hasToken));
  }

  ClientAgentTokenStatus _statusFromAgent(ClientAgent agent) {
    final flag = agent.hasServerClientToken;
    if (flag == null) {
      return ClientAgentTokenStatus.unknown;
    }
    return flag
        ? ClientAgentTokenStatus.configured
        : ClientAgentTokenStatus.missing;
  }

  void _applyAgentProfileSnapshot(AgentProfileSnapshot snapshot) {
    final current = _host.agent;
    if (current == null) {
      return;
    }
    final normalizedDocument = snapshot.document?.trim();
    final updated = ClientAgent(
      agentId: current.agentId,
      name: snapshot.name,
      tradeName: snapshot.tradeName ?? current.tradeName,
      document: normalizedDocument ?? current.document,
      cnpjCpf: normalizedDocument ?? current.cnpjCpf,
      registrationDocument: normalizedDocument ?? current.registrationDocument,
      documentType: snapshot.documentType ?? current.documentType,
      phone: snapshot.phone ?? current.phone,
      mobile: snapshot.mobile ?? current.mobile,
      email: snapshot.email ?? current.email,
      address: current.address,
      notes: snapshot.notes ?? current.notes,
      observation: snapshot.observation ?? current.observation,
      profileUpdatedAt: snapshot.profileUpdatedAt ?? current.profileUpdatedAt,
      profileVersion: snapshot.profileVersion ?? current.profileVersion,
      catalogStatus: current.catalogStatus,
      connectionStatus: current.connectionStatus,
      createdAt: current.createdAt,
      updatedAt: current.updatedAt,
      hasServerClientToken: current.hasServerClientToken,
    );
    _host.setAgent(updated);
  }
}

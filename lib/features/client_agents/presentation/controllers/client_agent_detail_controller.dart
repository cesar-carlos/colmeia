import 'dart:async';

import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/retry_after_gate.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/agent_meta/application/agent_rpc_capabilities_registry.dart';
import 'package:colmeia/features/agent_meta/application/usecases/discover_agent_rpc_methods_use_case.dart';
import 'package:colmeia/features/agent_meta/application/usecases/load_client_token_policy_use_case.dart';
import 'package:colmeia/features/agent_meta/application/usecases/refresh_agent_profile_use_case.dart';
import 'package:colmeia/features/agent_meta/domain/entities/agent_rpc_descriptor.dart';
import 'package:colmeia/features/agent_meta/domain/entities/client_token_policy.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/client_agents/application/usecases/get_client_agent_token_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/load_client_agent_detail_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/persist_client_agent_profile_snapshot_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/remove_client_agent_token_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/save_client_agent_token_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/update_client_agent_profile_use_case.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent.dart';
import 'package:colmeia/features/client_agents/presentation/controllers/client_agent_detail_agent_meta_coordinator.dart';
import 'package:colmeia/features/client_agents/presentation/controllers/client_agent_detail_connection_coordinator.dart';
import 'package:colmeia/features/client_agents/presentation/controllers/client_agent_detail_profile_coordinator.dart';
import 'package:colmeia/features/client_agents/presentation/controllers/client_agent_token_status.dart';
import 'package:colmeia/features/client_agents/presentation/models/client_agents_presentation_message.dart';
import 'package:colmeia/shared/ports/agent_query_target_resolution_invalidator.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

export 'package:colmeia/features/client_agents/presentation/controllers/client_agent_token_status.dart';

const Uuid _defaultUuid = Uuid();
String _defaultIdempotencyKeyGenerator() => _defaultUuid.v4();

class ClientAgentDetailController extends ChangeNotifier
    implements
        ClientAgentDetailAgentMetaHost,
        ClientAgentDetailProfileHost,
        ClientAgentDetailConnectionHost {
  ClientAgentDetailController({
    required AuthController authController,
    required LoadClientAgentDetailUseCase loadClientAgentDetailUseCase,
    required UpdateClientAgentProfileUseCase updateClientAgentProfileUseCase,
    required GetClientAgentTokenUseCase getClientAgentTokenUseCase,
    required SaveClientAgentTokenUseCase saveClientAgentTokenUseCase,
    required RemoveClientAgentTokenUseCase removeClientAgentTokenUseCase,
    required PersistClientAgentProfileSnapshotUseCase
    persistClientAgentProfileSnapshotUseCase,
    required RefreshAgentProfileUseCase refreshAgentProfileUseCase,
    required LoadClientTokenPolicyUseCase loadClientTokenPolicyUseCase,
    required DiscoverAgentRpcMethodsUseCase discoverAgentRpcMethodsUseCase,
    AgentRpcCapabilitiesRegistry? agentRpcCapabilitiesRegistry,
    AgentQueryTargetResolutionInvalidator? targetResolutionInvalidator,
    String Function()? idempotencyKeyGenerator,
    RetryAfterGate? retryAfterGate,
  }) : _authController = authController,
       _loadClientAgentDetailUseCase = loadClientAgentDetailUseCase,
       _targetResolutionInvalidator = targetResolutionInvalidator,
       _retryAfterGate = retryAfterGate ?? RetryAfterGate(),
       _ownsRetryAfterGate = retryAfterGate == null {
    _agentMeta = ClientAgentDetailAgentMetaCoordinator(
      host: this,
      discoverAgentRpcMethodsUseCase: discoverAgentRpcMethodsUseCase,
      agentRpcCapabilitiesRegistry: agentRpcCapabilitiesRegistry,
    );
    _profile = ClientAgentDetailProfileCoordinator(
      host: this,
      updateClientAgentProfileUseCase: updateClientAgentProfileUseCase,
      idempotencyKeyGenerator:
          idempotencyKeyGenerator ?? _defaultIdempotencyKeyGenerator,
    );
    _connection = ClientAgentDetailConnectionCoordinator(
      host: this,
      getClientAgentTokenUseCase: getClientAgentTokenUseCase,
      saveClientAgentTokenUseCase: saveClientAgentTokenUseCase,
      removeClientAgentTokenUseCase: removeClientAgentTokenUseCase,
      refreshAgentProfileUseCase: refreshAgentProfileUseCase,
      persistClientAgentProfileSnapshotUseCase:
          persistClientAgentProfileSnapshotUseCase,
      loadClientTokenPolicyUseCase: loadClientTokenPolicyUseCase,
    );
    _retryAfterGate.addListener(_notifyListenersIfAlive);
  }

  final AuthController _authController;
  final LoadClientAgentDetailUseCase _loadClientAgentDetailUseCase;
  final AgentQueryTargetResolutionInvalidator? _targetResolutionInvalidator;
  final RetryAfterGate _retryAfterGate;
  final bool _ownsRetryAfterGate;

  late final ClientAgentDetailAgentMetaCoordinator _agentMeta;
  late final ClientAgentDetailProfileCoordinator _profile;
  late final ClientAgentDetailConnectionCoordinator _connection;

  ClientAgent? _agent;
  ClientAgentsPresentationMessage? _errorMessage;
  bool _isLoading = false;
  bool _isRefreshing = false;
  bool _disposed = false;
  String? _loadedAgentId;
  int _loadGeneration = 0;
  bool _isDiscoveringRpc = false;

  @override
  ClientAgent? get agent => _agent;
  ClientAgentsPresentationMessage? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;

  int get clientTokenRevision => _connection.clientTokenRevision;
  String get persistedClientTokenForField =>
      _connection.persistedClientTokenForField;
  bool get isLoadingClientToken => _connection.isLoadingClientToken;
  bool get isSavingClientToken => _connection.isSavingClientToken;
  ClientAgentsPresentationMessage? get clientTokenFeedback =>
      _connection.clientTokenFeedback;
  ClientAgentsPresentationMessage? get clientTokenError =>
      _connection.clientTokenError;
  ClientAgentTokenStatus get clientTokenStatus => _connection.clientTokenStatus;

  bool get isSavingProfile => _profile.isSavingProfile;
  ClientAgentsPresentationMessage? get profileSaveError =>
      _profile.profileSaveError;
  ClientAgentsPresentationMessage? get profileSaveSuccess =>
      _profile.profileSaveSuccess;

  AgentRpcDescriptor? get agentRpcDescriptor => _agentMeta.agentRpcDescriptor;
  bool get isDiscoveringRpc => _isDiscoveringRpc;
  ClientTokenPolicy? get clientTokenPolicy => _connection.clientTokenPolicy;
  bool get clientTokenPolicyUnsupported =>
      _connection.clientTokenPolicyUnsupported;
  bool get isLoadingClientTokenPolicy => _connection.isLoadingClientTokenPolicy;
  ClientAgentsPresentationMessage? get clientTokenPolicyError =>
      _connection.clientTokenPolicyError;
  bool get isRefreshingFromAgent => _connection.isRefreshingFromAgent;
  ClientAgentsPresentationMessage? get refreshFromAgentFeedback =>
      _connection.refreshFromAgentFeedback;
  ClientAgentsPresentationMessage? get refreshFromAgentError =>
      _connection.refreshFromAgentError;

  @override
  bool agentSupportsRpcMethod(String method) =>
      _agentMeta.agentSupportsRpcMethod(method);

  void clearProfileFeedback() => _profile.clearProfileFeedback();

  Future<void> load(String agentId, {bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _loadedAgentId == agentId &&
        (_agent != null || _isLoading)) {
      return;
    }

    final userId = currentUserId;
    if (userId == null || userId.isEmpty) {
      _errorMessage =
          ClientAgentsPresentationMessage.clientAgentDetailSessionUnavailable();
      _notifyListenersIfAlive();
      return;
    }

    _loadedAgentId = agentId;
    final keepContentVisible = forceRefresh && _agent != null;
    final generation = ++_loadGeneration;

    if (keepContentVisible) {
      _isRefreshing = true;
    } else {
      _isLoading = true;
    }
    _errorMessage = null;
    _notifyListenersIfAlive();

    try {
      final result = await _loadClientAgentDetailUseCase(
        userId: userId,
        agentId: agentId,
      );
      if (_disposed || generation != _loadGeneration) {
        return;
      }

      final loadedAgent = result.getOrNull();
      if (loadedAgent != null) {
        _agent = loadedAgent;
        _errorMessage = null;
        _connection.seedTokenStatusFromAgent(loadedAgent);
        unawaited(_connection.refreshPersistedClientTokenFromServer(
          agentId: agentId,
        ));
        unawaited(_agentMeta.discoverAgentRpcMethods(agentId: agentId));
      } else {
        final failure = result.exceptionOrNull()!;
        if (!keepContentVisible) {
          _agent = null;
          _connection.resetTokenState();
          _agentMeta.reset();
        }
        _errorMessage = consumeFailure(failure);
        AppLogger.warning(
          'Client agent detail load failed',
          context: <String, Object?>{
            'operation': 'loadClientAgentDetail',
            'agentId': agentId,
            'forceRefresh': forceRefresh,
            'technicalMessage': failure.message,
          },
          error: failure.cause ?? failure,
          stackTrace: failure.stackTrace,
        );
      }
    } finally {
      if (!_disposed && generation == _loadGeneration) {
        if (keepContentVisible) {
          _isRefreshing = false;
        } else {
          _isLoading = false;
        }
        _notifyListenersIfAlive();
      }
    }
  }

  Future<void> reload() async {
    final agentId = _loadedAgentId;
    if (agentId == null) {
      return;
    }
    _loadedAgentId = null;
    await load(agentId);
  }

  Future<void> refresh(String agentId) async {
    await load(agentId, forceRefresh: true);
  }

  Future<void> saveClientAgentToken({
    required String agentId,
    required String rawToken,
  }) => _connection.saveClientAgentToken(agentId: agentId, rawToken: rawToken);

  Future<void> removeClientAgentToken({required String agentId}) =>
      _connection.removeClientAgentToken(agentId: agentId);

  void clearClientTokenFeedback() => _connection.clearClientTokenFeedback();

  Future<void> saveAgentProfile({
    required String agentId,
    required String name,
    required String tradeName,
    required String cnpjCpf,
    required String phone,
    required String mobile,
    required String email,
    required String street,
    required String number,
    required String district,
    required String postalCode,
    required String city,
    required String state,
    required String notes,
    required String observation,
  }) => _profile.saveAgentProfile(
    agentId: agentId,
    name: name,
    tradeName: tradeName,
    cnpjCpf: cnpjCpf,
    phone: phone,
    mobile: mobile,
    email: email,
    street: street,
    number: number,
    district: district,
    postalCode: postalCode,
    city: city,
    state: state,
    notes: notes,
    observation: observation,
  );

  Future<void> refreshFromAgent({required String agentId}) =>
      _connection.refreshFromAgent(agentId: agentId);

  Future<void> loadClientTokenPolicy({required String agentId}) =>
      _connection.loadClientTokenPolicy(agentId: agentId);

  void clearRefreshFromAgentFeedback() =>
      _connection.clearRefreshFromAgentFeedback();

  RetryAfterGate get retryAfterGate => _retryAfterGate;
  bool get isOnRetryCooldown => !_retryAfterGate.isOpen;

  @override
  ClientAgentsPresentationMessage consumeFailure(AppFailure failure) {
    final retryAfter = appFailureRetryAfter(failure);
    if (retryAfter != null) {
      _retryAfterGate.arm(retryAfter);
    }
    return ClientAgentsPresentationMessage.failure(failure);
  }

  void _notifyListenersIfAlive() {
    if (_disposed) {
      return;
    }
    notifyListeners();
  }

  @override
  bool get isDisposed => _disposed;

  @override
  String? get currentUserId => _authController.session?.userId;

  @override
  String? get persistedClientToken => _connection.persistedClientTokenForField;

  @override
  void setAgent(ClientAgent agent) {
    _agent = agent;
  }

  @override
  void notifyProfileChanged() => _notifyListenersIfAlive();

  @override
  Future<void> reloadAgentDetail({
    required String agentId,
    required bool forceRefresh,
  }) => load(agentId, forceRefresh: forceRefresh);

  @override
  void invalidateTargetResolution({required String userId}) {
    _targetResolutionInvalidator?.invalidate(userId: userId);
  }

  @override
  void notifyConnectionChanged() => _notifyListenersIfAlive();

  @override
  void setAgentRpcDescriptor(AgentRpcDescriptor? descriptor) {}

  @override
  void setDiscoveringRpc({required bool value}) => _isDiscoveringRpc = value;

  @override
  void notifyAgentMetaChanged() => _notifyListenersIfAlive();

  @override
  void dispose() {
    _disposed = true;
    _retryAfterGate.removeListener(_notifyListenersIfAlive);
    if (_ownsRetryAfterGate) {
      _retryAfterGate.dispose();
    }
    super.dispose();
  }
}

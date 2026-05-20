import 'dart:async';

import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/retry_after_gate.dart';
import 'package:colmeia/core/formatters/agent_document_digits.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/agent_meta/application/agent_rpc_capabilities_registry.dart';
import 'package:colmeia/features/agent_meta/application/usecases/discover_agent_rpc_methods_use_case.dart';
import 'package:colmeia/features/agent_meta/application/usecases/load_client_token_policy_use_case.dart';
import 'package:colmeia/features/agent_meta/application/usecases/refresh_agent_profile_use_case.dart';
import 'package:colmeia/features/agent_meta/domain/entities/agent_profile_snapshot.dart';
import 'package:colmeia/features/agent_meta/domain/entities/agent_rpc_descriptor.dart';
import 'package:colmeia/features/agent_meta/domain/entities/client_token_policy.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/client_agents/application/usecases/get_client_agent_token_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/load_client_agent_detail_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/remove_client_agent_token_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/save_client_agent_token_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/update_client_agent_profile_use_case.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_profile_address.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_profile_update_request.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent.dart';
import 'package:colmeia/features/client_agents/presentation/models/client_agents_presentation_message.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

/// Process-wide UUID generator used as the default `Idempotency-Key`
/// source for profile saves. The constructor allows tests to inject a
/// deterministic generator instead.
const Uuid _defaultUuid = Uuid();
String _defaultIdempotencyKeyGenerator() => _defaultUuid.v4();

/// Visible state of the per-(client, agent) bearer token stored on the
/// server. The detail page renders different copy/chips for each branch.
enum ClientAgentTokenStatus {
  /// Server snapshot has not been fetched yet (initial load or refresh in
  /// flight). Treat the field value as the local cache fallback.
  unknown,

  /// Server confirmed there is no token stored for this `(client, agent)`.
  missing,

  /// Server confirmed a non-empty token is stored.
  configured,
}

class ClientAgentDetailController extends ChangeNotifier {
  ClientAgentDetailController({
    required AuthController authController,
    required LoadClientAgentDetailUseCase loadClientAgentDetailUseCase,
    required UpdateClientAgentProfileUseCase updateClientAgentProfileUseCase,
    required GetClientAgentTokenUseCase getClientAgentTokenUseCase,
    required SaveClientAgentTokenUseCase saveClientAgentTokenUseCase,
    required RemoveClientAgentTokenUseCase removeClientAgentTokenUseCase,
    required RefreshAgentProfileUseCase refreshAgentProfileUseCase,
    required LoadClientTokenPolicyUseCase loadClientTokenPolicyUseCase,
    required DiscoverAgentRpcMethodsUseCase discoverAgentRpcMethodsUseCase,
    AgentRpcCapabilitiesRegistry? agentRpcCapabilitiesRegistry,
    String Function()? idempotencyKeyGenerator,
    RetryAfterGate? retryAfterGate,
  }) : _authController = authController,
       _loadClientAgentDetailUseCase = loadClientAgentDetailUseCase,
       _updateClientAgentProfileUseCase = updateClientAgentProfileUseCase,
       _getClientAgentTokenUseCase = getClientAgentTokenUseCase,
       _saveClientAgentTokenUseCase = saveClientAgentTokenUseCase,
       _removeClientAgentTokenUseCase = removeClientAgentTokenUseCase,
       _refreshAgentProfileUseCase = refreshAgentProfileUseCase,
       _loadClientTokenPolicyUseCase = loadClientTokenPolicyUseCase,
       _discoverAgentRpcMethodsUseCase = discoverAgentRpcMethodsUseCase,
       _agentRpcCapabilitiesRegistry = agentRpcCapabilitiesRegistry,
       _idempotencyKeyGenerator =
           idempotencyKeyGenerator ?? _defaultIdempotencyKeyGenerator,
       _retryAfterGate = retryAfterGate ?? RetryAfterGate() {
    // Re-publish gate ticks (countdown updates + window expired) so any
    // listener of this controller — typically the detail page — reacts
    // to the cooldown without subscribing to the gate directly.
    _retryAfterGate.addListener(_notifyListenersIfAlive);
  }

  final AuthController _authController;
  final LoadClientAgentDetailUseCase _loadClientAgentDetailUseCase;
  final UpdateClientAgentProfileUseCase _updateClientAgentProfileUseCase;
  final GetClientAgentTokenUseCase _getClientAgentTokenUseCase;
  final SaveClientAgentTokenUseCase _saveClientAgentTokenUseCase;
  final RemoveClientAgentTokenUseCase _removeClientAgentTokenUseCase;
  final RefreshAgentProfileUseCase _refreshAgentProfileUseCase;
  final LoadClientTokenPolicyUseCase _loadClientTokenPolicyUseCase;
  final DiscoverAgentRpcMethodsUseCase _discoverAgentRpcMethodsUseCase;

  /// Optional shared cache of `rpc.discover` results. When supplied we
  /// hydrate from it synchronously on [load] to avoid an extra round
  /// trip when the overview already prefetched the descriptor, and we
  /// publish back into it so other surfaces (queries, banners) see the
  /// fresh capabilities without re-discovering.
  final AgentRpcCapabilitiesRegistry? _agentRpcCapabilitiesRegistry;

  /// Source of the per-save UUID forwarded as `Idempotency-Key`. Tests
  /// inject a deterministic generator so the header value can be asserted
  /// against an expected map.
  final String Function() _idempotencyKeyGenerator;

  /// Cool-down gate fed by `Retry-After` hints surfaced by the bridge
  /// (HTTP header, JSON-RPC `error.data.retry_after_ms`, socket
  /// `app:error` overload payloads). Shared across every operation in
  /// this controller because hub quotas are per-user / per-socket — a
  /// rate-limit on save token throttles refresh-from-agent too.
  final RetryAfterGate _retryAfterGate;

  ClientAgent? _agent;
  ClientAgentsPresentationMessage? _errorMessage;
  bool _isLoading = false;
  bool _isRefreshing = false;
  bool _disposed = false;
  String? _loadedAgentId;
  int _loadGeneration = 0;
  int _clientTokenRevision = 0;
  int _clientTokenLoadGeneration = 0;
  String? _persistedClientToken;
  ClientAgentTokenStatus _clientTokenStatus = ClientAgentTokenStatus.unknown;
  bool _isLoadingClientToken = false;
  bool _isSavingClientToken = false;
  ClientAgentsPresentationMessage? _clientTokenFeedback;
  ClientAgentsPresentationMessage? _clientTokenError;
  bool _isSavingProfile = false;
  ClientAgentsPresentationMessage? _profileSaveError;
  ClientAgentsPresentationMessage? _profileSaveSuccess;

  // -- agent_meta state --

  /// Catalogue of RPC methods the connected agent advertises via
  /// `rpc.discover`. `null` while the discovery call is in flight or has
  /// not been attempted; `AgentRpcDescriptor.empty()` when the call
  /// failed gracefully (e.g. older agents without `rpc.discover`).
  AgentRpcDescriptor? _agentRpcDescriptor;
  bool _isDiscoveringRpc = false;
  int _rpcDiscoveryGeneration = 0;

  /// Result of the most recent `client_token.getPolicy` call. `null`
  /// while the call is in flight or has not been attempted.
  ClientTokenPolicy? _clientTokenPolicy;

  /// Differentiates "not loaded yet" from "agent does not support the
  /// method" (the second case keeps `_clientTokenPolicy = null` but flips
  /// this flag to `true`).
  bool _clientTokenPolicyUnsupported = false;
  bool _isLoadingClientTokenPolicy = false;
  ClientAgentsPresentationMessage? _clientTokenPolicyError;
  int _clientTokenPolicyGeneration = 0;

  bool _isRefreshingFromAgent = false;
  ClientAgentsPresentationMessage? _refreshFromAgentFeedback;
  ClientAgentsPresentationMessage? _refreshFromAgentError;

  ClientAgent? get agent => _agent;
  ClientAgentsPresentationMessage? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;

  /// Bumped every time [persistedClientTokenForField] changes so the text
  /// field can re-sync its content even though the value is a `String`.
  int get clientTokenRevision => _clientTokenRevision;

  /// Most recent token resolved from the server (or local cache fallback)
  /// for the current agent. Empty when no token is stored or when the field
  /// has not been loaded yet.
  String get persistedClientTokenForField => _persistedClientToken ?? '';

  bool get isLoadingClientToken => _isLoadingClientToken;

  bool get isSavingClientToken => _isSavingClientToken;

  /// One-shot success message after a save/remove operation. The page should
  /// clear it once shown via [clearClientTokenFeedback].
  ClientAgentsPresentationMessage? get clientTokenFeedback =>
      _clientTokenFeedback;

  /// One-shot error message after a save/remove operation. Cleared the same
  /// way as [clientTokenFeedback].
  ClientAgentsPresentationMessage? get clientTokenError => _clientTokenError;

  /// Server-confirmed token presence for the loaded agent. Defaults to
  /// [ClientAgentTokenStatus.unknown] until the GET endpoint succeeds.
  ClientAgentTokenStatus get clientTokenStatus => _clientTokenStatus;

  bool get isSavingProfile => _isSavingProfile;

  ClientAgentsPresentationMessage? get profileSaveError => _profileSaveError;

  ClientAgentsPresentationMessage? get profileSaveSuccess =>
      _profileSaveSuccess;

  // -- agent_meta getters --

  /// RPC catalogue the agent advertises (or `null` while discovery has
  /// not completed). UI uses [agentSupportsRpcMethod] to gate features.
  AgentRpcDescriptor? get agentRpcDescriptor => _agentRpcDescriptor;

  bool get isDiscoveringRpc => _isDiscoveringRpc;

  /// Latest snapshot of `client_token.getPolicy`. `null` when the agent
  /// did not implement the method (see [clientTokenPolicyUnsupported])
  /// or when the call has not run yet.
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

  /// `true` when the connected agent advertised [method] in its
  /// `rpc.discover` catalogue. Returns `true` when the catalogue is
  /// missing (older hub / discovery failed gracefully) so the UI does
  /// not hide features that the agent might still support.
  bool agentSupportsRpcMethod(String method) {
    final descriptor = _agentRpcDescriptor;
    if (descriptor == null || descriptor.isEmpty) {
      return true;
    }
    return descriptor.supportsMethod(method);
  }

  void clearProfileFeedback() {
    if (_profileSaveError == null && _profileSaveSuccess == null) {
      return;
    }
    _profileSaveError = null;
    _profileSaveSuccess = null;
    _notifyListenersIfAlive();
  }

  Future<void> load(String agentId, {bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _loadedAgentId == agentId &&
        (_agent != null || _isLoading)) {
      return;
    }

    final userId = _authController.session?.userId;
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
        // Seed the token status from the freshly loaded agent: list/detail
        // endpoints expose `hasClientToken` so we can render the chip
        // immediately while the dedicated GET resolves the actual value.
        _clientTokenStatus = _statusFromAgent(loadedAgent);
        unawaited(_refreshPersistedClientTokenFromServer(agentId: agentId));
        // Side channel: ask the agent which RPC methods it supports so
        // the UI can gate optional actions (Refresh from agent, Load
        // policy, ...). Failure is silent — `agentSupportsRpcMethod`
        // returns true when the catalogue is missing, so the UI keeps
        // the feature visible.
        unawaited(_discoverAgentRpcMethods(agentId: agentId));
      } else {
        final failure = result.exceptionOrNull()!;
        if (!keepContentVisible) {
          _agent = null;
          _persistedClientToken = null;
          _clientTokenStatus = ClientAgentTokenStatus.unknown;
          _clientTokenError = null;
          _clientTokenRevision++;
          _agentRpcDescriptor = null;
          _clientTokenPolicy = null;
          _clientTokenPolicyUnsupported = false;
          _clientTokenPolicyError = null;
        }
        _errorMessage = _consumeFailure(failure);
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

  Future<void> _refreshPersistedClientTokenFromServer({
    required String agentId,
  }) async {
    final userId = _authController.session?.userId;
    if (userId == null || userId.isEmpty) {
      return;
    }

    final generation = ++_clientTokenLoadGeneration;
    _isLoadingClientToken = true;
    _clientTokenError = null;
    _notifyListenersIfAlive();

    try {
      final result = await _getClientAgentTokenUseCase(
        userId: userId,
        agentId: agentId,
      );
      if (_disposed || generation != _clientTokenLoadGeneration) {
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
        _clientTokenError = _consumeFailure(failure);
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
      if (!_disposed && generation == _clientTokenLoadGeneration) {
        _isLoadingClientToken = false;
        _notifyListenersIfAlive();
      }
    }
  }

  Future<void> saveClientAgentToken({
    required String agentId,
    required String rawToken,
  }) async {
    final userId = _authController.session?.userId;
    if (userId == null || userId.isEmpty) {
      _clientTokenError =
          ClientAgentsPresentationMessage.clientAgentDetailSessionUnavailable();
      _notifyListenersIfAlive();
      return;
    }

    _isSavingClientToken = true;
    _clientTokenFeedback = null;
    _clientTokenError = null;
    _notifyListenersIfAlive();

    try {
      final result = await _saveClientAgentTokenUseCase(
        userId: userId,
        agentId: agentId,
        clientToken: rawToken,
      );
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
      } else {
        final failure = result.exceptionOrNull()!;
        _clientTokenError = _consumeFailure(failure);
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
      _isSavingClientToken = false;
      _notifyListenersIfAlive();
    }
  }

  Future<void> removeClientAgentToken({required String agentId}) async {
    final userId = _authController.session?.userId;
    if (userId == null || userId.isEmpty) {
      _clientTokenError =
          ClientAgentsPresentationMessage.clientAgentDetailSessionUnavailable();
      _notifyListenersIfAlive();
      return;
    }

    _isSavingClientToken = true;
    _clientTokenFeedback = null;
    _clientTokenError = null;
    _notifyListenersIfAlive();

    try {
      final result = await _removeClientAgentTokenUseCase(
        userId: userId,
        agentId: agentId,
      );
      if (result.isSuccess()) {
        _persistedClientToken = '';
        _clientTokenStatus = ClientAgentTokenStatus.missing;
        _clientTokenRevision++;
        _clientTokenFeedback =
            ClientAgentsPresentationMessage.clientAgentDetailServerTokenRemoved();
        _refreshLoadedAgentTokenFlag(hasToken: false);
      } else {
        final failure = result.exceptionOrNull()!;
        _clientTokenError = _consumeFailure(failure);
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
      _isSavingClientToken = false;
      _notifyListenersIfAlive();
    }
  }

  void clearClientTokenFeedback() {
    if (_clientTokenFeedback == null && _clientTokenError == null) {
      return;
    }
    _clientTokenFeedback = null;
    _clientTokenError = null;
    _notifyListenersIfAlive();
  }

  void _refreshLoadedAgentTokenFlag({required bool hasToken}) {
    final current = _agent;
    if (current == null || current.hasServerClientToken == hasToken) {
      return;
    }
    _agent = current.copyWith(hasServerClientToken: hasToken);
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
  }) async {
    final userId = _authController.session?.userId;
    if (userId == null || userId.isEmpty) {
      _profileSaveSuccess = null;
      _profileSaveError =
          ClientAgentsPresentationMessage.clientAgentDetailSessionUnavailable();
      _notifyListenersIfAlive();
      return;
    }

    _isSavingProfile = true;
    _profileSaveError = null;
    _profileSaveSuccess = null;
    _notifyListenersIfAlive();

    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      _profileSaveError =
          ClientAgentsPresentationMessage.clientAgentDetailProfileNameRequired();
      _isSavingProfile = false;
      _notifyListenersIfAlive();
      return;
    }

    final current = _agent;
    // CAS token (`expectedProfileVersion`) is the **monotonic integer**
    // counter served by the hub on `profileVersion`. We send it only when
    // the entity carries a known value — older hub builds may omit the
    // field, in which case we let the PATCH proceed without a version
    // guard rather than send `0` (which would behave as "match a fresh
    // profile" and silently overwrite genuine concurrent edits).
    //
    // `idempotencyKey` is a per-save UUID that the datasource turns into
    // the `Idempotency-Key` HTTP header; the same key is used across
    // automatic retries of the same logical save so the hub returns the
    // original write outcome instead of duplicating the revision.
    final request = AgentProfileUpdateRequest(
      name: trimmedName,
      tradeName: tradeName.trim().isEmpty ? null : tradeName.trim(),
      cnpjCpf: digitsOnlyDocument(cnpjCpf),
      phone: phone.trim().isEmpty ? null : phone.trim(),
      mobile: mobile.trim().isEmpty ? null : mobile.trim(),
      email: email.trim().isEmpty ? null : email.trim(),
      address: _optionalAgentProfileAddress(
        street: street,
        number: number,
        district: district,
        postalCode: postalCode,
        city: city,
        state: state,
      ),
      notes: notes.trim().isEmpty ? null : notes.trim(),
      observation: observation.trim().isEmpty ? null : observation.trim(),
      expectedProfileVersion: current?.profileVersion,
      idempotencyKey: _idempotencyKeyGenerator(),
    );

    try {
      final result = await _updateClientAgentProfileUseCase(
        userId: userId,
        agentId: agentId,
        request: request,
      );
      final updated = result.getOrNull();
      if (updated != null) {
        await load(agentId, forceRefresh: true);
        _profileSaveSuccess =
            ClientAgentsPresentationMessage.clientAgentDetailProfileSaved();
      } else {
        final failure = result.exceptionOrNull()!;
        _profileSaveError = _consumeFailure(failure);
        AppLogger.warning(
          'Client agent profile update failed',
          context: <String, Object?>{
            'operation': 'saveAgentProfile',
            'agentId': agentId,
            'technicalMessage': failure.message,
          },
          error: failure.cause ?? failure,
          stackTrace: failure.stackTrace,
        );
      }
    } finally {
      _isSavingProfile = false;
      _notifyListenersIfAlive();
    }
  }

  // ---------------------------------------------------------------------------
  // agent_meta wiring (rpc.discover, agent.getProfile, client_token.getPolicy)
  // ---------------------------------------------------------------------------

  Future<void> _discoverAgentRpcMethods({required String agentId}) async {
    final generation = ++_rpcDiscoveryGeneration;
    final registry = _agentRpcCapabilitiesRegistry;
    // Optimistic hydrate from the shared registry so UI can already
    // gate features on the first frame even before the network call
    // settles. We still kick the discover below — the descriptor in
    // cache may be stale (older session, agent restarted, etc.).
    if (registry != null) {
      final cached = registry.descriptorFor(agentId);
      if (cached != null) {
        _agentRpcDescriptor = cached;
      }
    }
    _isDiscoveringRpc = true;
    _notifyListenersIfAlive();
    try {
      final result = await _discoverAgentRpcMethodsUseCase(agentId: agentId);
      if (_disposed || generation != _rpcDiscoveryGeneration) {
        return;
      }
      result.fold(
        (descriptor) {
          _agentRpcDescriptor = descriptor;
          // Share the fresh descriptor so the next surface that needs
          // the capabilities does not pay another round-trip.
          registry?.put(agentId, descriptor);
        },
        (failure) {
          // Failure is silent — older agents do not implement
          // rpc.discover, but their other capabilities still work.
          AppLogger.info(
            'rpc.discover failed; treating agent as feature-permissive',
            context: <String, Object?>{
              'operation': 'discoverAgentRpcMethods',
              'agentId': agentId,
              'technicalMessage': failure.message,
            },
          );
        },
      );
    } finally {
      if (!_disposed && generation == _rpcDiscoveryGeneration) {
        _isDiscoveringRpc = false;
        _notifyListenersIfAlive();
      }
    }
  }

  /// Forces a `agent.getProfile` against the connected agent and applies
  /// the returned snapshot on top of the local [agent]. Useful when the
  /// catalog read shows stale data and the user wants to reconcile
  /// without waiting for the realtime push.
  ///
  /// No-op when the agent's `rpc.discover` catalogue does not advertise
  /// `agent.getProfile` — UI should hide the action in that case.
  Future<void> refreshFromAgent({required String agentId}) async {
    if (!agentSupportsRpcMethod('agent.getProfile')) {
      _refreshFromAgentError =
          ClientAgentsPresentationMessage.clientAgentDetailRefreshFromAgentUnsupported();
      _notifyListenersIfAlive();
      return;
    }
    final userId = _authController.session?.userId;
    if (userId == null || userId.isEmpty) {
      _refreshFromAgentError =
          ClientAgentsPresentationMessage.clientAgentDetailSessionUnavailable();
      _notifyListenersIfAlive();
      return;
    }

    _isRefreshingFromAgent = true;
    _refreshFromAgentError = null;
    _refreshFromAgentFeedback = null;
    _notifyListenersIfAlive();

    try {
      final clientToken = (_persistedClientToken ?? '').trim();
      final result = await _refreshAgentProfileUseCase(
        agentId: agentId,
        clientToken: clientToken.isEmpty ? null : clientToken,
      );
      final snapshot = result.getOrNull();
      if (snapshot != null) {
        _applyAgentProfileSnapshot(snapshot);
        _refreshFromAgentFeedback =
            ClientAgentsPresentationMessage.clientAgentDetailRefreshFromAgentSuccess();
      } else {
        final failure = result.exceptionOrNull()!;
        _refreshFromAgentError = _consumeFailure(failure);
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
      _isRefreshingFromAgent = false;
      _notifyListenersIfAlive();
    }
  }

  void _applyAgentProfileSnapshot(AgentProfileSnapshot snapshot) {
    final current = _agent;
    if (current == null) {
      return;
    }
    final newVersion = snapshot.profileVersion;
    final updated = current.copyWith(
      profileVersion: newVersion,
    );
    if (newVersion != null) {
      _agent = updated;
    } else {
      _agent = updated;
    }
  }

  /// Asks the connected agent for the policy resolved for the currently
  /// stored token. Skips the call when there is no token to inspect or
  /// when `client_token.getPolicy` is not in the agent's catalogue (sets
  /// [clientTokenPolicyUnsupported] in that case).
  Future<void> loadClientTokenPolicy({required String agentId}) async {
    final token = (_persistedClientToken ?? '').trim();
    if (token.isEmpty) {
      _clientTokenPolicy = null;
      _clientTokenPolicyUnsupported = false;
      _clientTokenPolicyError = null;
      _notifyListenersIfAlive();
      return;
    }
    if (!agentSupportsRpcMethod('client_token.getPolicy')) {
      _clientTokenPolicy = null;
      _clientTokenPolicyUnsupported = true;
      _clientTokenPolicyError = null;
      _notifyListenersIfAlive();
      return;
    }
    final generation = ++_clientTokenPolicyGeneration;
    _isLoadingClientTokenPolicy = true;
    _clientTokenPolicyError = null;
    _notifyListenersIfAlive();
    try {
      final result = await _loadClientTokenPolicyUseCase(
        agentId: agentId,
        clientToken: token,
      );
      if (_disposed || generation != _clientTokenPolicyGeneration) {
        return;
      }
      final snapshot = result.getOrNull();
      if (snapshot != null) {
        _clientTokenPolicy = snapshot.policy;
        _clientTokenPolicyUnsupported = !snapshot.supported;
      } else {
        final failure = result.exceptionOrNull()!;
        _clientTokenPolicyError = _consumeFailure(failure);
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
      if (!_disposed && generation == _clientTokenPolicyGeneration) {
        _isLoadingClientTokenPolicy = false;
        _notifyListenersIfAlive();
      }
    }
  }

  void clearRefreshFromAgentFeedback() {
    if (_refreshFromAgentFeedback == null && _refreshFromAgentError == null) {
      return;
    }
    _refreshFromAgentFeedback = null;
    _refreshFromAgentError = null;
    _notifyListenersIfAlive();
  }

  /// Cool-down gate exposed read-only so the page can render a
  /// countdown label and disable buttons while the window is closed.
  RetryAfterGate get retryAfterGate => _retryAfterGate;

  /// Convenience for "is the controller currently in a server-asked
  /// cool-down?". Pages typically combine this with operation-specific
  /// flags (e.g. `isSavingClientToken`).
  bool get isOnRetryCooldown => !_retryAfterGate.isOpen;

  /// Centralised failure handler for this controller.
  ///
  /// 1. Returns the localized message the UI should display.
  /// 2. Arms the retry-after gate when the failure carries a
  ///    `Retry-After` hint, so subsequent button taps are throttled
  ///    automatically without each call site repeating the wiring.
  ClientAgentsPresentationMessage _consumeFailure(AppFailure failure) {
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
  void dispose() {
    _disposed = true;
    _retryAfterGate
      ..removeListener(_notifyListenersIfAlive)
      ..dispose();
    super.dispose();
  }
}

AgentProfileAddress? _optionalAgentProfileAddress({
  required String street,
  required String number,
  required String district,
  required String postalCode,
  required String city,
  required String state,
}) {
  String? nz(String raw) {
    final t = raw.trim();
    return t.isEmpty ? null : t;
  }

  final st = nz(street);
  final numStr = nz(number);
  final dist = nz(district);
  final pc = nz(postalCode);
  final ct = nz(city);
  final stCode = nz(state);
  if (st == null &&
      numStr == null &&
      dist == null &&
      pc == null &&
      ct == null &&
      stCode == null) {
    return null;
  }
  return AgentProfileAddress(
    street: st,
    number: numStr,
    district: dist,
    postalCode: pc,
    city: ct,
    state: stCode,
  );
}

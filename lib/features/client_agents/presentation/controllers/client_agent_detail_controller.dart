import 'dart:async';

import 'package:colmeia/core/formatters/agent_document_digits.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/client_agents/application/usecases/get_client_agent_token_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/load_client_agent_detail_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/remove_client_agent_token_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/save_client_agent_token_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/update_client_agent_profile_use_case.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_profile_address.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_profile_update_request.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent.dart';
import 'package:colmeia/features/client_agents/presentation/localization/client_agents_failure_l10n.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/l10n/app_localizations_en.dart';
import 'package:flutter/foundation.dart';

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
  }) : _authController = authController,
       _loadClientAgentDetailUseCase = loadClientAgentDetailUseCase,
       _updateClientAgentProfileUseCase = updateClientAgentProfileUseCase,
       _getClientAgentTokenUseCase = getClientAgentTokenUseCase,
       _saveClientAgentTokenUseCase = saveClientAgentTokenUseCase,
       _removeClientAgentTokenUseCase = removeClientAgentTokenUseCase;

  final AuthController _authController;
  final LoadClientAgentDetailUseCase _loadClientAgentDetailUseCase;
  final UpdateClientAgentProfileUseCase _updateClientAgentProfileUseCase;
  final GetClientAgentTokenUseCase _getClientAgentTokenUseCase;
  final SaveClientAgentTokenUseCase _saveClientAgentTokenUseCase;
  final RemoveClientAgentTokenUseCase _removeClientAgentTokenUseCase;

  AppLocalizations? _l10n;

  AppLocalizations? get activeLocalizations => _l10n;

  set activeLocalizations(AppLocalizations value) => _l10n = value;

  AppLocalizations get _s => _l10n ?? AppLocalizationsEn();

  ClientAgent? _agent;
  String? _errorMessage;
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
  String? _clientTokenFeedback;
  String? _clientTokenError;
  bool _isSavingProfile = false;
  String? _profileSaveError;
  String? _profileSaveSuccess;

  ClientAgent? get agent => _agent;
  String? get errorMessage => _errorMessage;
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
  String? get clientTokenFeedback => _clientTokenFeedback;

  /// One-shot error message after a save/remove operation. Cleared the same
  /// way as [clientTokenFeedback].
  String? get clientTokenError => _clientTokenError;

  /// Server-confirmed token presence for the loaded agent. Defaults to
  /// [ClientAgentTokenStatus.unknown] until the GET endpoint succeeds.
  ClientAgentTokenStatus get clientTokenStatus => _clientTokenStatus;

  bool get isSavingProfile => _isSavingProfile;

  String? get profileSaveError => _profileSaveError;

  String? get profileSaveSuccess => _profileSaveSuccess;

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
      _errorMessage = _s.clientAgentDetailSessionUnavailable;
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
      } else {
        final failure = result.exceptionOrNull()!;
        if (!keepContentVisible) {
          _agent = null;
          _persistedClientToken = null;
          _clientTokenStatus = ClientAgentTokenStatus.unknown;
          _clientTokenError = null;
          _clientTokenRevision++;
        }
        _errorMessage = clientAgentsFailureUserMessage(failure, _s);
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
        _clientTokenError = clientAgentsFailureUserMessage(failure, _s);
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
      _clientTokenError = _s.clientAgentDetailSessionUnavailable;
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
            ? _s.clientAgentDetailServerTokenSaved
            : _s.clientAgentDetailServerTokenRemoved;
        _refreshLoadedAgentTokenFlag(hasToken: snapshot.hasToken);
      } else {
        final failure = result.exceptionOrNull()!;
        _clientTokenError = clientAgentsFailureUserMessage(failure, _s);
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
      _clientTokenError = _s.clientAgentDetailSessionUnavailable;
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
        _clientTokenFeedback = _s.clientAgentDetailServerTokenRemoved;
        _refreshLoadedAgentTokenFlag(hasToken: false);
      } else {
        final failure = result.exceptionOrNull()!;
        _clientTokenError = clientAgentsFailureUserMessage(failure, _s);
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
      _profileSaveError = _s.clientAgentDetailSessionUnavailable;
      _notifyListenersIfAlive();
      return;
    }

    _isSavingProfile = true;
    _profileSaveError = null;
    _profileSaveSuccess = null;
    _notifyListenersIfAlive();

    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      _profileSaveError = _s.clientAgentDetailProfileNameRequired;
      _isSavingProfile = false;
      _notifyListenersIfAlive();
      return;
    }

    final current = _agent;
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
      expectedProfileVersion: current?.profileUpdatedAt,
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
        _profileSaveSuccess = _s.clientAgentDetailProfileSaved;
      } else {
        final failure = result.exceptionOrNull()!;
        _profileSaveError = clientAgentsFailureUserMessage(failure, _s);
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

  void _notifyListenersIfAlive() {
    if (_disposed) {
      return;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
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

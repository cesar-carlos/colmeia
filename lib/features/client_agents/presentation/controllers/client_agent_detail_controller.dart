import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/client_agents/application/usecases/load_client_agent_detail_use_case.dart';
import 'package:colmeia/features/client_agents/data/storage/local_agent_client_token_store.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent.dart';
import 'package:colmeia/features/client_agents/presentation/localization/client_agents_failure_l10n.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/l10n/app_localizations_en.dart';
import 'package:flutter/foundation.dart';

class ClientAgentDetailController extends ChangeNotifier {
  ClientAgentDetailController({
    required AuthController authController,
    required LocalAgentClientTokenStore clientTokenStore,
    required LoadClientAgentDetailUseCase loadClientAgentDetailUseCase,
  }) : _authController = authController,
       _clientTokenStore = clientTokenStore,
       _loadClientAgentDetailUseCase = loadClientAgentDetailUseCase;

  final AuthController _authController;
  final LocalAgentClientTokenStore _clientTokenStore;
  final LoadClientAgentDetailUseCase _loadClientAgentDetailUseCase;

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
  int _localTokenRevision = 0;
  String? _persistedLocalClientToken;
  bool _isSavingLocalClientToken = false;
  String? _localClientTokenFeedback;

  ClientAgent? get agent => _agent;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;

  int get localClientTokenRevision => _localTokenRevision;

  String get persistedLocalClientTokenForField =>
      _persistedLocalClientToken ?? '';

  bool get isSavingLocalClientToken => _isSavingLocalClientToken;

  String? get localClientTokenFeedback => _localClientTokenFeedback;

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
        await _refreshPersistedLocalClientToken(agentId: agentId);
      } else {
        final failure = result.exceptionOrNull()!;
        if (!keepContentVisible) {
          _agent = null;
          _persistedLocalClientToken = null;
          _localTokenRevision++;
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

  Future<void> _refreshPersistedLocalClientToken({
    required String agentId,
  }) async {
    final userId = _authController.session?.userId;
    if (userId == null || userId.isEmpty) {
      return;
    }
    final token = await _clientTokenStore.read(
      userId: userId,
      agentId: agentId,
    );
    if (_disposed) {
      return;
    }
    _persistedLocalClientToken = token ?? '';
    _localTokenRevision++;
    _notifyListenersIfAlive();
  }

  Future<void> saveLocalClientToken({
    required String agentId,
    required String rawToken,
  }) async {
    final userId = _authController.session?.userId;
    if (userId == null || userId.isEmpty) {
      _localClientTokenFeedback = _s.clientAgentDetailSessionUnavailable;
      _notifyListenersIfAlive();
      return;
    }

    _isSavingLocalClientToken = true;
    _localClientTokenFeedback = null;
    _notifyListenersIfAlive();

    try {
      final trimmed = rawToken.trim();
      if (trimmed.isEmpty) {
        await _clientTokenStore.delete(userId: userId, agentId: agentId);
        _persistedLocalClientToken = '';
      } else {
        await _clientTokenStore.write(
          userId: userId,
          agentId: agentId,
          clientToken: trimmed,
        );
        _persistedLocalClientToken = trimmed;
      }
      _localTokenRevision++;
      _localClientTokenFeedback = _s.clientAgentDetailLocalTokenSaved;
    } finally {
      _isSavingLocalClientToken = false;
      _notifyListenersIfAlive();
    }
  }

  Future<void> removeLocalClientToken({required String agentId}) async {
    final userId = _authController.session?.userId;
    if (userId == null || userId.isEmpty) {
      _localClientTokenFeedback = _s.clientAgentDetailSessionUnavailable;
      _notifyListenersIfAlive();
      return;
    }

    _isSavingLocalClientToken = true;
    _localClientTokenFeedback = null;
    _notifyListenersIfAlive();

    try {
      await _clientTokenStore.delete(userId: userId, agentId: agentId);
      _persistedLocalClientToken = '';
      _localTokenRevision++;
      _localClientTokenFeedback = _s.clientAgentDetailLocalTokenRemoved;
    } finally {
      _isSavingLocalClientToken = false;
      _notifyListenersIfAlive();
    }
  }

  void clearLocalClientTokenFeedback() {
    if (_localClientTokenFeedback == null) {
      return;
    }
    _localClientTokenFeedback = null;
    _notifyListenersIfAlive();
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

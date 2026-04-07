import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/client_agents/application/usecases/load_client_agent_detail_use_case.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent.dart';
import 'package:colmeia/features/client_agents/presentation/localization/client_agents_failure_l10n.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/l10n/app_localizations_en.dart';
import 'package:flutter/foundation.dart';

class ClientAgentDetailController extends ChangeNotifier {
  ClientAgentDetailController({
    required AuthController authController,
    required LoadClientAgentDetailUseCase loadClientAgentDetailUseCase,
  }) : _authController = authController,
       _loadClientAgentDetailUseCase = loadClientAgentDetailUseCase;

  final AuthController _authController;
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

  ClientAgent? get agent => _agent;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;

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

    if (keepContentVisible) {
      _isRefreshing = true;
    } else {
      _isLoading = true;
    }
    _errorMessage = null;
    _notifyListenersIfAlive();

    final result = await _loadClientAgentDetailUseCase(
      userId: userId,
      agentId: agentId,
    );
    if (_disposed) {
      return;
    }

    result.fold(
      (loadedAgent) {
        _agent = loadedAgent;
        _errorMessage = null;
      },
      (failure) {
        if (!keepContentVisible) {
          _agent = null;
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
      },
    );

    if (keepContentVisible) {
      _isRefreshing = false;
    } else {
      _isLoading = false;
    }
    _notifyListenersIfAlive();
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

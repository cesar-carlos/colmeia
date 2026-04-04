import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/client_agents/application/usecases/load_client_agent_detail_use_case.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent.dart';
import 'package:flutter/foundation.dart';

class ClientAgentDetailController extends ChangeNotifier {
  ClientAgentDetailController({
    required AuthController authController,
    required LoadClientAgentDetailUseCase loadClientAgentDetailUseCase,
  }) : _authController = authController,
       _loadClientAgentDetailUseCase = loadClientAgentDetailUseCase;

  final AuthController _authController;
  final LoadClientAgentDetailUseCase _loadClientAgentDetailUseCase;

  ClientAgent? _agent;
  String? _errorMessage;
  bool _isLoading = false;
  bool _disposed = false;
  String? _loadedAgentId;

  ClientAgent? get agent => _agent;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;

  Future<void> load(String agentId) async {
    if (_loadedAgentId == agentId && (_agent != null || _isLoading)) {
      return;
    }

    final userId = _authController.session?.userId;
    if (userId == null || userId.isEmpty) {
      _errorMessage = 'Sessao indisponivel para carregar o agente.';
      _notifyListenersIfAlive();
      return;
    }

    _loadedAgentId = agentId;
    _isLoading = true;
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
        _agent = null;
        _errorMessage = failure.displayMessage;
        AppLogger.warning(
          'Client agent detail load failed',
          context: <String, Object?>{
            'operation': 'loadClientAgentDetail',
            'agentId': agentId,
            'technicalMessage': failure.message,
          },
          error: failure.cause ?? failure,
          stackTrace: failure.stackTrace,
        );
      },
    );

    _isLoading = false;
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

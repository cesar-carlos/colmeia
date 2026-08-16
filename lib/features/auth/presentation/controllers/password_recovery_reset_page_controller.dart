import 'package:colmeia/features/auth/application/usecases/read_password_recovery_status_use_case.dart';
import 'package:colmeia/features/auth/application/usecases/reset_password_use_case.dart';
import 'package:colmeia/features/auth/domain/entities/client_password_recovery_status.dart';
import 'package:flutter/foundation.dart';

class PasswordRecoveryResetPageController extends ChangeNotifier {
  PasswordRecoveryResetPageController({
    required this._readPasswordRecoveryStatusUseCase,
    required this._resetPasswordUseCase,
    String? initialToken,
  }) : _token = initialToken?.trim() ?? '';

  final ReadPasswordRecoveryStatusUseCase _readPasswordRecoveryStatusUseCase;
  final ResetPasswordUseCase _resetPasswordUseCase;

  String _token;
  ClientPasswordRecoveryStatus? _status;
  String? _errorMessage;
  String? _successMessage;
  bool _isLoading = false;

  String get token => _token;
  ClientPasswordRecoveryStatus? get status => _status;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  bool get isLoading => _isLoading;
  bool get canReset =>
      _status == ClientPasswordRecoveryStatus.pending && !_isLoading;

  void setToken(String value) {
    _token = value.trim();
    _status = null;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  Future<void> resolveToken(String value) async {
    setToken(value);
    await loadStatus();
  }

  Future<bool> ensurePendingToken(String value) async {
    setToken(value);
    if (_status == ClientPasswordRecoveryStatus.pending) {
      return true;
    }

    await loadStatus();
    return _status == ClientPasswordRecoveryStatus.pending;
  }

  Future<void> loadStatus() async {
    if (_token.isEmpty) {
      _status = null;
      _errorMessage = 'Informe o token para continuar.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    final result = await _readPasswordRecoveryStatusUseCase(token: _token);
    result.fold(
      (resolvedStatus) {
        _status = resolvedStatus;
        _errorMessage = null;
      },
      (failure) {
        _status = null;
        _errorMessage = failure.displayMessage;
      },
    );

    _isLoading = false;
    notifyListeners();
  }

  Future<void> resetPassword({
    required String newPassword,
  }) async {
    if (_token.isEmpty) {
      _errorMessage = 'Informe o token para continuar.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    final result = await _resetPasswordUseCase(
      token: _token,
      newPassword: newPassword,
    );
    result.fold(
      (_) {
        _status = null;
        _successMessage =
            'Senha redefinida com sucesso. Voce ja pode entrar na conta.';
      },
      (failure) {
        _errorMessage = failure.displayMessage;
      },
    );

    _isLoading = false;
    notifyListeners();
  }
}

import 'package:colmeia/features/auth/application/usecases/request_password_recovery_use_case.dart';
import 'package:flutter/foundation.dart';

class PasswordRecoveryRequestPageController extends ChangeNotifier {
  PasswordRecoveryRequestPageController({
    required this._requestPasswordRecoveryUseCase,
  });

  final RequestPasswordRecoveryUseCase _requestPasswordRecoveryUseCase;

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  Future<void> submit({
    required String email,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    final result = await _requestPasswordRecoveryUseCase(email: email.trim());
    result.fold(
      (message) {
        _successMessage = message;
        _errorMessage = null;
      },
      (failure) {
        _successMessage = null;
        _errorMessage = failure.displayMessage;
      },
    );

    _isLoading = false;
    notifyListeners();
  }
}

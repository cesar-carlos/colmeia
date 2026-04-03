import 'package:colmeia/features/auth/application/usecases/read_registration_status_use_case.dart';
import 'package:colmeia/features/auth/domain/entities/client_registration_status.dart';
import 'package:flutter/foundation.dart';

class RegistrationStatusPageController extends ChangeNotifier {
  RegistrationStatusPageController({
    required ReadRegistrationStatusUseCase readRegistrationStatusUseCase,
    String? initialToken,
  }) : _readRegistrationStatusUseCase = readRegistrationStatusUseCase,
       _token = initialToken?.trim() ?? '';

  final ReadRegistrationStatusUseCase _readRegistrationStatusUseCase;

  String _token;
  ClientRegistrationStatus? _status;
  String? _errorMessage;
  bool _isLoading = false;

  String get token => _token;
  ClientRegistrationStatus? get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get hasResolvedStatus => _status != null;

  void setToken(String value) {
    _token = value.trim();
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> loadStatus() async {
    if (_token.isEmpty) {
      _status = null;
      _errorMessage = 'Informe o token para consultar o cadastro.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _readRegistrationStatusUseCase(token: _token);
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
}

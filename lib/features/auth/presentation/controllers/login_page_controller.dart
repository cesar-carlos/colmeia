import 'dart:async';

import 'package:colmeia/features/auth/application/auth_login_preferences_service.dart';
import 'package:flutter/foundation.dart';

class LoginPageController extends ChangeNotifier {
  LoginPageController(this._preferencesService);

  final AuthLoginPreferencesService _preferencesService;
  bool _obscurePassword = true;
  bool _rememberMe = false;

  bool get obscurePassword => _obscurePassword;
  bool get rememberMe => _rememberMe;

  void toggleObscurePassword() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  Future<void> loadRememberMePreference() async {
    final stored = _preferencesService.readRememberMe();
    if (_rememberMe != stored) {
      _rememberMe = stored;
      notifyListeners();
    }
  }

  void setRememberMe({required bool value}) {
    if (_rememberMe == value) {
      return;
    }
    _rememberMe = value;
    notifyListeners();
    unawaited(_persistRememberMe(value));
  }

  Future<void> _persistRememberMe(bool value) async {
    await _preferencesService.persistRememberMe(value: value);
  }
}

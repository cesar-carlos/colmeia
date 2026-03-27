import 'dart:async';

import 'package:colmeia/features/auth/presentation/preferences/auth_login_preference_keys.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPageController extends ChangeNotifier {
  bool _obscurePassword = true;
  bool _rememberMe = false;

  bool get obscurePassword => _obscurePassword;
  bool get rememberMe => _rememberMe;

  void toggleObscurePassword() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  Future<void> loadRememberMePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getBool(AuthLoginPreferenceKeys.rememberMe) ?? false;
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AuthLoginPreferenceKeys.rememberMe, value);
  }
}

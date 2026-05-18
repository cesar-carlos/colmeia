import 'package:colmeia/features/auth/presentation/preferences/auth_login_preference_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthLoginPreferencesService {
  AuthLoginPreferencesService(this._prefs);

  final SharedPreferences _prefs;

  bool readRememberMe() {
    return _prefs.getBool(AuthLoginPreferenceKeys.rememberMe) ?? false;
  }

  Future<void> persistRememberMe({required bool value}) {
    return _prefs.setBool(AuthLoginPreferenceKeys.rememberMe, value);
  }
}

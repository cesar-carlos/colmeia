import 'package:colmeia/features/auth/presentation/preferences/auth_registration_preference_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthRegistrationPreferencesService {
  AuthRegistrationPreferencesService(this._prefs);

  final SharedPreferences _prefs;

  String? readPollToken() {
    final value = _prefs.getString(AuthRegistrationPreferenceKeys.pollToken);
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return value.trim();
  }

  Future<void> persistPollToken(String token) {
    return _prefs.setString(
      AuthRegistrationPreferenceKeys.pollToken,
      token.trim(),
    );
  }

  Future<void> clearPollToken() {
    return _prefs.remove(AuthRegistrationPreferenceKeys.pollToken);
  }
}

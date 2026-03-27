import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight user-facing preferences persisted on device.
class AppUserPreferencesStore {
  AppUserPreferencesStore(this._prefs);

  final SharedPreferences _prefs;

  static const String _pushNotificationsKey = 'colmeia_push_notifications_v1';
  static const String _themeModeKey = 'colmeia_theme_mode_v1';

  static const String themeModeSystem = 'system';
  static const String themeModeLight = 'light';
  static const String themeModeDark = 'dark';

  bool get pushNotificationsEnabled =>
      _prefs.getBool(_pushNotificationsKey) ?? true;

  Future<void> setPushNotificationsEnabled({required bool enabled}) async {
    await _prefs.setBool(_pushNotificationsKey, enabled);
  }

  String? get themeModePreference => _prefs.getString(_themeModeKey);

  Future<void> setThemeModePreference(String value) async {
    await _prefs.setString(_themeModeKey, value);
  }
}

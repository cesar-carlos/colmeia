import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight user-facing preferences persisted on device.
class AppUserPreferencesStore {
  AppUserPreferencesStore(this._prefs);

  final SharedPreferences _prefs;

  static const String _pushNotificationsKey = 'colmeia_push_notifications_v1';

  bool get pushNotificationsEnabled =>
      _prefs.getBool(_pushNotificationsKey) ?? true;

  Future<void> setPushNotificationsEnabled({required bool enabled}) async {
    await _prefs.setBool(_pushNotificationsKey, enabled);
  }
}

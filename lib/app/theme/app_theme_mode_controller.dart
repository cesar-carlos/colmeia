import 'package:colmeia/core/preferences/app_user_preferences_store.dart';
import 'package:flutter/material.dart';

class AppThemeModeController extends ChangeNotifier {
  AppThemeModeController(AppUserPreferencesStore store)
    : _store = store,
      _themeMode = _fromStored(store.themeModePreference);

  final AppUserPreferencesStore _store;
  ThemeMode _themeMode;

  ThemeMode get themeMode => _themeMode;

  static ThemeMode _fromStored(String? value) {
    return switch (value) {
      AppUserPreferencesStore.themeModeLight => ThemeMode.light,
      AppUserPreferencesStore.themeModeDark => ThemeMode.dark,
      AppUserPreferencesStore.themeModeSystem => ThemeMode.system,
      null => ThemeMode.system,
      _ => ThemeMode.system,
    };
  }

  static String _toStored(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.light => AppUserPreferencesStore.themeModeLight,
      ThemeMode.dark => AppUserPreferencesStore.themeModeDark,
      ThemeMode.system => AppUserPreferencesStore.themeModeSystem,
    };
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) {
      return;
    }
    _themeMode = mode;
    notifyListeners();
    await _store.setThemeModePreference(_toStored(mode));
  }
}

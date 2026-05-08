import 'package:colmeia/core/preferences/app_user_preferences_store.dart';
import 'package:flutter/foundation.dart';

class AppUserExperiencePreferencesController extends ChangeNotifier {
  AppUserExperiencePreferencesController(AppUserPreferencesStore store)
    : _store = store,
      _overviewLoadingMode = store.overviewLoadingMode;

  final AppUserPreferencesStore _store;

  OverviewLoadingMode _overviewLoadingMode;
  OverviewLoadingMode get overviewLoadingMode => _overviewLoadingMode;

  Future<void> setOverviewLoadingMode(OverviewLoadingMode mode) async {
    if (_overviewLoadingMode == mode) {
      return;
    }
    _overviewLoadingMode = mode;
    notifyListeners();
    await _store.setOverviewLoadingMode(mode);
  }
}

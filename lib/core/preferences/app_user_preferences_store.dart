import 'package:colmeia/core/update/windows_auto_update_diagnostic.dart';
import 'package:colmeia/core/update/windows_auto_update_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum OverviewLoadingMode {
  progressive,
  complete,
}

/// Lightweight user-facing preferences persisted on device.
class AppUserPreferencesStore {
  AppUserPreferencesStore(this._prefs);

  final SharedPreferences _prefs;

  static const String _pushNotificationsKey = 'colmeia_push_notifications_v1';
  static const String _themeModeKey = 'colmeia_theme_mode_v1';
  static const String _overviewLoadingModeKey =
      'colmeia_overview_loading_mode_v1';
  static const String _windowsAutoUpdateStatusKey =
      'colmeia_windows_auto_update_status_v1';
  static const String _windowsAutoUpdateHeadlineKey =
      'colmeia_windows_auto_update_headline_v1';
  static const String _windowsAutoUpdateDetailsKey =
      'colmeia_windows_auto_update_details_v1';
  static const String _windowsAutoUpdateFeedUrlKey =
      'colmeia_windows_auto_update_feed_url_v1';
  static const String _windowsAutoUpdateCheckedAtMsKey =
      'colmeia_windows_auto_update_checked_at_ms_v1';

  static const String themeModeSystem = 'system';
  static const String themeModeLight = 'light';
  static const String themeModeDark = 'dark';
  static const String overviewLoadingModeProgressive = 'progressive';
  static const String overviewLoadingModeComplete = 'complete';

  bool get pushNotificationsEnabled =>
      _prefs.getBool(_pushNotificationsKey) ?? true;

  Future<void> setPushNotificationsEnabled({required bool enabled}) async {
    await _prefs.setBool(_pushNotificationsKey, enabled);
  }

  String? get themeModePreference => _prefs.getString(_themeModeKey);

  Future<void> setThemeModePreference(String value) async {
    await _prefs.setString(_themeModeKey, value);
  }

  OverviewLoadingMode get overviewLoadingMode {
    return switch (_prefs.getString(_overviewLoadingModeKey)) {
      overviewLoadingModeComplete => OverviewLoadingMode.complete,
      overviewLoadingModeProgressive => OverviewLoadingMode.progressive,
      null => OverviewLoadingMode.progressive,
      _ => OverviewLoadingMode.progressive,
    };
  }

  Future<void> setOverviewLoadingMode(OverviewLoadingMode mode) async {
    await _prefs.setString(
      _overviewLoadingModeKey,
      switch (mode) {
        OverviewLoadingMode.progressive => overviewLoadingModeProgressive,
        OverviewLoadingMode.complete => overviewLoadingModeComplete,
      },
    );
  }

  WindowsAutoUpdateDiagnostic? get windowsAutoUpdateDiagnostic {
    final statusName = _prefs.getString(_windowsAutoUpdateStatusKey);
    final headline = _prefs.getString(_windowsAutoUpdateHeadlineKey);
    if (statusName == null || headline == null || headline.isEmpty) {
      return null;
    }

    WindowsAutoUpdateStatus? status;
    for (final value in WindowsAutoUpdateStatus.values) {
      if (value.name == statusName) {
        status = value;
        break;
      }
    }
    if (status == null) {
      return null;
    }

    final checkedAtMs = _prefs.getInt(_windowsAutoUpdateCheckedAtMsKey);
    return WindowsAutoUpdateDiagnostic(
      status: status,
      headline: headline,
      details: _prefs.getString(_windowsAutoUpdateDetailsKey),
      feedUrl: _prefs.getString(_windowsAutoUpdateFeedUrlKey) ?? '',
      lastCheckedAt: checkedAtMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(checkedAtMs),
    );
  }

  Future<void> persistWindowsAutoUpdateDiagnostic(
    WindowsAutoUpdateDiagnostic diagnostic,
  ) async {
    await _prefs.setString(
      _windowsAutoUpdateStatusKey,
      diagnostic.status.name,
    );
    await _prefs.setString(
      _windowsAutoUpdateHeadlineKey,
      diagnostic.headline,
    );
    if (diagnostic.details == null || diagnostic.details!.isEmpty) {
      await _prefs.remove(_windowsAutoUpdateDetailsKey);
    } else {
      await _prefs.setString(
        _windowsAutoUpdateDetailsKey,
        diagnostic.details!,
      );
    }
    await _prefs.setString(_windowsAutoUpdateFeedUrlKey, diagnostic.feedUrl);
    if (diagnostic.lastCheckedAt == null) {
      await _prefs.remove(_windowsAutoUpdateCheckedAtMsKey);
    } else {
      await _prefs.setInt(
        _windowsAutoUpdateCheckedAtMsKey,
        diagnostic.lastCheckedAt!.millisecondsSinceEpoch,
      );
    }
  }
}

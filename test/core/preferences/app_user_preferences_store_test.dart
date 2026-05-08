import 'package:checks/checks.dart';
import 'package:colmeia/core/preferences/app_user_preferences_store.dart';
import 'package:colmeia/core/update/windows_auto_update_diagnostic.dart';
import 'package:colmeia/core/update/windows_auto_update_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('AppUserPreferencesStore', () {
    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    test('should persist and restore windows auto-update diagnostic', () async {
      final prefs = await SharedPreferences.getInstance();
      final store = AppUserPreferencesStore(prefs);
      final checkedAt = DateTime(2026, 5, 5, 12, 30);

      await store.persistWindowsAutoUpdateDiagnostic(
        WindowsAutoUpdateDiagnostic(
          status: WindowsAutoUpdateStatus.failed,
          headline: 'Feed indisponivel.',
          details: 'HTTP 503 ao consultar o appcast.',
          feedUrl: 'https://example.com/appcast.xml',
          lastCheckedAt: checkedAt,
        ),
      );

      final diagnostic = store.windowsAutoUpdateDiagnostic;
      check(diagnostic).isNotNull();
      check(diagnostic!.status).equals(WindowsAutoUpdateStatus.failed);
      check(diagnostic.headline).equals('Feed indisponivel.');
      check(diagnostic.details).equals('HTTP 503 ao consultar o appcast.');
      check(diagnostic.feedUrl).equals('https://example.com/appcast.xml');
      check(diagnostic.lastCheckedAt).equals(checkedAt);
    });

    test('should default overview loading mode to progressive', () async {
      final prefs = await SharedPreferences.getInstance();
      final store = AppUserPreferencesStore(prefs);

      check(store.overviewLoadingMode).equals(OverviewLoadingMode.progressive);
    });

    test('should persist overview loading mode', () async {
      final prefs = await SharedPreferences.getInstance();
      final store = AppUserPreferencesStore(prefs);

      await store.setOverviewLoadingMode(OverviewLoadingMode.complete);

      check(store.overviewLoadingMode).equals(OverviewLoadingMode.complete);
    });
  });
}

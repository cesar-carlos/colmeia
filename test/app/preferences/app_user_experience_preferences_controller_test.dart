import 'package:checks/checks.dart';
import 'package:colmeia/app/preferences/app_user_experience_preferences_controller.dart';
import 'package:colmeia/core/preferences/app_user_preferences_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('AppUserExperiencePreferencesController', () {
    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    test('notifies listeners when overview loading mode changes', () async {
      final prefs = await SharedPreferences.getInstance();
      final store = AppUserPreferencesStore(prefs);
      final controller = AppUserExperiencePreferencesController(store);
      var notifications = 0;
      controller.addListener(() => notifications++);

      await controller.setOverviewLoadingMode(OverviewLoadingMode.complete);

      check(
        controller.overviewLoadingMode,
      ).equals(OverviewLoadingMode.complete);
      check(store.overviewLoadingMode).equals(OverviewLoadingMode.complete);
      check(notifications).equals(1);
    });

    test(
      'does not notify listeners when overview loading mode is unchanged',
      () async {
        final prefs = await SharedPreferences.getInstance();
        final store = AppUserPreferencesStore(prefs);
        final controller = AppUserExperiencePreferencesController(store);
        var notifications = 0;
        controller.addListener(() => notifications++);

        await controller.setOverviewLoadingMode(
          OverviewLoadingMode.progressive,
        );

        check(notifications).equals(0);
      },
    );
  });
}

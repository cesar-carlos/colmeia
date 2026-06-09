import 'package:auto_updater/auto_updater.dart';
import 'package:colmeia/app/theme/app_theme.dart';
import 'package:colmeia/core/preferences/app_user_preferences_store.dart';
import 'package:colmeia/core/update/appcast_probe_client.dart';
import 'package:colmeia/core/update/auto_updater_client.dart';
import 'package:colmeia/core/update/windows_auto_update_controller.dart';
import 'package:colmeia/core/update/windows_auto_update_messages.dart';
import 'package:colmeia/core/update/windows_auto_update_state.dart';
import 'package:colmeia/features/settings/presentation/widgets/windows_auto_update_settings_tile.dart';
import 'package:colmeia/shared/widgets/actions/app_flat_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AppUserPreferencesStore preferencesStore;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    preferencesStore = AppUserPreferencesStore(prefs);
  });

  group('WindowsAutoUpdateSettingsTile', () {
    testWidgets('should show full unavailable instructions without ellipsis', (
      tester,
    ) async {
      final controller = WindowsAutoUpdateController(
        autoUpdaterClient: _FakeAutoUpdaterClient(),
        appcastProbeClient: _immediateProbe,
        feedUrlResolver: () => '',
        preferencesStore: preferencesStore,
        supportsNativeUpdates: () => true,
      );
      await controller.initialize();

      await tester.pumpWidget(
        _TestApp(
          child: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: WindowsAutoUpdateSettingsTile(controller: controller),
          ),
        ),
      );
      await tester.pump();

      expect(
        find.text(WindowsAutoUpdateMessages.feedUrlMissingDetails),
        findsOneWidget,
      );

      final detailsWidget = tester.widget<Text>(
        find.text(WindowsAutoUpdateMessages.feedUrlMissingDetails),
      );
      expect(detailsWidget.maxLines, isNull);
      expect(detailsWidget.overflow, isNull);
      expect(
        find.widgetWithText(
          AppFlatButton,
          WindowsAutoUpdateMessages.checkButtonLabel,
        ),
        findsOneWidget,
      );
      final button = tester.widget<AppFlatButton>(
        find.widgetWithText(
          AppFlatButton,
          WindowsAutoUpdateMessages.checkButtonLabel,
        ),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('should show checking state with loading button', (
      tester,
    ) async {
      final controller = WindowsAutoUpdateController(
        autoUpdaterClient: _FakeAutoUpdaterClient(),
        appcastProbeClient: _immediateProbe,
        feedUrlResolver: () => 'https://example.com/appcast.xml',
        preferencesStore: preferencesStore,
        supportsNativeUpdates: () => true,
      );
      await controller.initialize();
      await Future<void>.delayed(Duration.zero);

      expect(controller.state.isChecking, isTrue);

      await tester.pumpWidget(
        _TestApp(
          child: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: WindowsAutoUpdateSettingsTile(controller: controller),
          ),
        ),
      );
      await tester.pump();

      expect(
        find.text(WindowsAutoUpdateMessages.checkingButtonLabel),
        findsOneWidget,
      );
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('should show failed state with error styling', (
      tester,
    ) async {
      final controller = WindowsAutoUpdateController(
        autoUpdaterClient: _FakeAutoUpdaterClient(),
        appcastProbeClient: _immediateProbe,
        feedUrlResolver: () => 'https://example.com/appcast.xml',
        preferencesStore: preferencesStore,
        supportsNativeUpdates: () => true,
      );
      await controller.initialize();
      controller.onUpdaterError(UpdaterError('network error'));

      await tester.pumpWidget(
        _TestApp(
          child: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: WindowsAutoUpdateSettingsTile(controller: controller),
          ),
        ),
      );
      await tester.pump();

      expect(
        find.text(WindowsAutoUpdateMessages.updaterErrorHeadline),
        findsOneWidget,
      );
      expect(
        find.text(
          WindowsAutoUpdateMessages.settingsStatusLabel(
            WindowsAutoUpdateStatus.failed,
          ),
        ),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    });
  });
}

Future<AppcastProbeResult> _immediateProbe({required String feedUrl}) async {
  return const AppcastProbeResult.success();
}

final class _FakeAutoUpdaterClient implements AutoUpdaterClient {
  @override
  void addListener(UpdaterListener listener) {}

  @override
  Future<void> checkForUpdates({required bool inBackground}) async {}

  @override
  void removeListener(UpdaterListener listener) {}

  @override
  Future<void> setFeedUrl(String feedUrl) async {}

  @override
  Future<void> setScheduledCheckInterval(int intervalInSeconds) async {}
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: child),
    );
  }
}

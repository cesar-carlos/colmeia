import 'package:checks/checks.dart';
import 'package:colmeia/core/preferences/persisted_page_session_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PersistedPageSessionStore', () {
    late SharedPreferences prefs;
    late PersistedPageSessionStore store;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      prefs = await SharedPreferences.getInstance();
      store = PersistedPageSessionStore(
        prefs: prefs,
        namespace: 'client_agents',
      );
    });

    test(
      'should restore fallback tab index when saved value is out of range',
      () async {
        await prefs.setInt('client_agents.selected_tab', 99);

        final restored = store.restoreTabIndex(
          suffix: 'selected_tab',
          fallbackIndex: 1,
          maxTabIndex: 2,
        );

        check(restored).equals(1);
      },
    );

    test('should persist and remove json maps when empty', () async {
      await store.persistJsonMap(
        suffix: 'filters',
        value: <String, Object?>{
          'search': 'alpha',
          'enabled': true,
        },
      );

      check(store.restoreJsonMap(suffix: 'filters')).deepEquals(
        <String, Object?>{
          'search': 'alpha',
          'enabled': true,
        },
      );

      await store.persistJsonMap(
        suffix: 'filters',
        value: const <String, Object?>{},
      );

      check(store.restoreJsonMap(suffix: 'filters')).isEmpty();
    });

    test('should remove persisted text when blank', () async {
      await store.persistText(
        suffix: 'draft',
        value: '  abc  ',
      );
      check(store.restoreText(suffix: 'draft')).equals('  abc  ');

      await store.persistText(
        suffix: 'draft',
        value: '   ',
      );

      check(store.restoreText(suffix: 'draft')).isEmpty();
    });
  });
}

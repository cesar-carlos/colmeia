import 'package:colmeia/app/router/shell_section_navigation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('shellSectionDrawerSuppressedForLocation', () {
    test('is false on shell section roots', () {
      expect(shellSectionDrawerSuppressedForLocation('/sales'), isFalse);
      expect(shellSectionDrawerSuppressedForLocation('/dashboard'), isFalse);
      expect(shellSectionDrawerSuppressedForLocation('/agents'), isFalse);
      expect(shellSectionDrawerSuppressedForLocation('/settings'), isFalse);
    });

    test('is true below shell section roots', () {
      expect(
        shellSectionDrawerSuppressedForLocation('/sales/daily_totals'),
        isTrue,
      );
      expect(
        shellSectionDrawerSuppressedForLocation('/agents/agent-1'),
        isTrue,
      );
      expect(
        shellSectionDrawerSuppressedForLocation('/dashboard/store/42'),
        isTrue,
      );
    });
  });

  group('shellSectionBackVisibleForLocation', () {
    test('is true when canPop regardless of location', () {
      expect(
        shellSectionBackVisibleForLocation('/sales', canPop: true),
        isTrue,
      );
    });

    test('is false on roots without canPop', () {
      expect(
        shellSectionBackVisibleForLocation('/sales', canPop: false),
        isFalse,
      );
    });

    test('is true below shell section roots without canPop', () {
      expect(
        shellSectionBackVisibleForLocation(
          '/sales/daily_totals',
          canPop: false,
        ),
        isTrue,
      );
    });
  });
}

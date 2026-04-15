import 'package:colmeia/features/overview/presentation/widgets/overview_agent_names_list_sheet.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalizeOverviewAgentNames', () {
    test('returns empty for empty or only blanks', () {
      expect(normalizeOverviewAgentNames([]), isEmpty);
      expect(normalizeOverviewAgentNames(['', '  ', '\t']), isEmpty);
    });

    test('trims and sorts case-insensitively', () {
      expect(
        normalizeOverviewAgentNames([' b ', 'a']),
        <String>['a', 'b'],
      );
    });

    test('removes case-insensitive duplicates', () {
      final merged = normalizeOverviewAgentNames(['Acme', 'acme', 'ACME']);
      expect(merged.length, 1);
      expect(merged.single.toLowerCase(), 'acme');
    });

    test('removes exact duplicates and sorts', () {
      expect(
        normalizeOverviewAgentNames(['Foo', 'Bar', 'Foo']),
        <String>['Bar', 'Foo'],
      );
    });
  });
}

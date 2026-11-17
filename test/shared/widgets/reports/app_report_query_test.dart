import 'package:checks/checks.dart';
import 'package:colmeia/shared/widgets/reports/app_report_query.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppReportQuery.resolveVisibleColumnKeys', () {
    test('uses defaults when a restored query has no explicit selection', () {
      const customized = AppReportQuery(visibleColumnKeys: {'name'});
      const restored = AppReportQuery();
      const defaults = ['name', 'total'];
      expect(customized.resolveVisibleColumnKeys(defaults), {'name'});
      expect(restored.resolveVisibleColumnKeys(defaults), {'name', 'total'});
    });

    test('isolates resolved visibility from query and default sets', () {
      final selected = {'name'};
      final query = AppReportQuery(visibleColumnKeys: selected);
      final resolved = query.resolveVisibleColumnKeys({'total'})..add('total');
      expect(selected, {'name'});
      selected.add('date');
      expect(resolved, {'name', 'total'});

      final defaults = {'name'};
      const AppReportQuery().resolveVisibleColumnKeys(defaults).clear();
      expect(defaults, {'name'});
    });

    test('preserves an explicitly empty selection', () {
      const query = AppReportQuery(visibleColumnKeys: {});
      expect(query.resolveVisibleColumnKeys(['name']), isEmpty);
    });
  });

  group('AppReportQuery.withSearchTerm', () {
    test('clears whitespace-only searches and resets pagination', () {
      const query = AppReportQuery(searchTerm: 'Mel', page: 4);
      final updated = query.withSearchTerm(' \t ');
      expect(updated.searchTerm, isNull);
      expect(updated.page, 1);
      expect(query.searchTerm, 'Mel');
    });

    test('trims surrounding whitespace while preserving internal spaces', () {
      const query = AppReportQuery(page: 3, pageSize: 50);
      final updated = query.withSearchTerm('  Casa do Mel  ');
      expect(updated.searchTerm, 'Casa do Mel');
      expect(updated.page, 1);
      expect(updated.pageSize, 50);
    });
  });

  group('AppReportQuery.isSameSearchTerm', () {
    test(
      'treats null, blank, and padded whitespace as the same empty term',
      () {
        const query = AppReportQuery();

        check(query.isSameSearchTerm(null)).isTrue();
        check(query.isSameSearchTerm('')).isTrue();
        check(query.isSameSearchTerm('   ')).isTrue();
        check(query.isSameSearchTerm('Mel')).isFalse();
      },
    );

    test('ignores surrounding whitespace on an existing term', () {
      const query = AppReportQuery(searchTerm: 'Mel');

      check(query.isSameSearchTerm('Mel')).isTrue();
      check(query.isSameSearchTerm('  Mel  ')).isTrue();
      check(query.isSameSearchTerm('Mel ')).isTrue();
      check(query.isSameSearchTerm('Mela')).isFalse();
      check(query.isSameSearchTerm(null)).isFalse();
    });
  });
}

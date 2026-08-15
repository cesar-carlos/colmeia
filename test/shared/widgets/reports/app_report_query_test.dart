import 'package:checks/checks.dart';
import 'package:colmeia/shared/widgets/reports/app_report_query.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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

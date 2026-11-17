import 'package:colmeia/shared/widgets/reports/app_report_filter_values_equality.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('compares selections by values and preserves list ordering', () {
    final values = {
      'tags': <String>['a', 'b'],
      'enabled': false,
    };
    expect(
      reportFilterValuesEqual(values, {
        'enabled': false,
        'tags': ['a', 'b'],
      }),
      isTrue,
    );
    expect(
      reportFilterValuesEqual(values, {
        'enabled': false,
        'tags': ['b', 'a'],
      }),
      isFalse,
    );
  });

  test(
    'distinguishes missing keys, explicit null and changed scalar values',
    () {
      expect(reportFilterValuesEqual({'a': null}, {'b': null}), isFalse);
      expect(reportFilterValuesEqual({'a': null}, {}), isFalse);
      expect(reportFilterValuesEqual({'a': null}, {'a': null}), isTrue);
      expect(
        reportFilterValuesEqual({'enabled': true}, {'enabled': false}),
        isFalse,
      );
      expect(
        reportFilterValuesEqual(
          {
            'tags': ['a'],
          },
          {'tags': 'a'},
        ),
        isFalse,
      );
    },
  );
}

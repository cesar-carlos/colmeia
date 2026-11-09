import 'package:colmeia/shared/widgets/reports/app_report_filter_form_values.dart';
import 'package:colmeia/shared/widgets/reports/app_report_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const filters = [
    AppReportFilterDescriptor(
      name: 'name',
      label: 'Name',
      type: AppReportFilterType.text,
      initialValue: 'default',
    ),
    AppReportFilterDescriptor(
      name: 'price',
      label: 'Price',
      type: AppReportFilterType.numericRange,
    ),
    AppReportFilterDescriptor(
      name: 'enabled',
      label: 'Enabled',
      type: AppReportFilterType.toggle,
      initialValue: true,
    ),
    AppReportFilterDescriptor(
      name: 'tags',
      label: 'Tags',
      type: AppReportFilterType.multiSelect,
    ),
    AppReportFilterDescriptor(
      name: 'date',
      label: 'Date',
      type: AppReportFilterType.date,
    ),
  ];

  test('clear removes defaults and every bound of numeric ranges', () {
    final values = reportFilterFormValues(filters, {
      'name': 'Ana',
      'price_min': 10,
    }, clear: true);
    expect(values, {
      'name': null,
      'price_min': null,
      'price_max': null,
      'enabled': false,
      'tags': <String>[],
      'date': null,
    });
    expect(filters.any((filter) => filter.hasActiveValue(values)), isFalse);
  });

  test('numeric updates match text field types and missing bounds clear', () {
    final values = reportFilterFormValues(filters, {'price_min': 12.5});
    expect(values['price_min'], '12.5');
    expect(values['price_max'], isNull);
  });

  test('explicit null overrides a default while absent values use it', () {
    expect(reportFilterFormValues(filters, {})['name'], 'default');
    expect(reportFilterFormValues(filters, {'name': null})['name'], isNull);
  });

  test('patch excludes removed fields and isolates multiselect lists', () {
    final tags = <String>['one'];
    final values = reportFilterFormValues(filters, {
      'removed': 'old',
      'tags': tags,
    });
    tags.add('two');
    expect(values.containsKey('removed'), isFalse);
    expect(values['tags'], ['one']);
  });
}

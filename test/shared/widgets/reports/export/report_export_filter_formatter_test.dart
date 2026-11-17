import 'package:colmeia/shared/widgets/reports/app_report_models.dart';
import 'package:colmeia/shared/widgets/reports/export/report_export_filter_formatter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));

  const amount = AppReportFilterDescriptor(
    name: 'amount',
    label: 'Valor',
    type: AppReportFilterType.numericRange,
  );
  const period = AppReportFilterDescriptor(
    name: 'period',
    label: 'Período',
    type: AppReportFilterType.dateRange,
  );

  test('exports the actual inclusive period without technical date text', () {
    final result = ReportExportFilterFormatter.resolve(
      [period],
      {
        'period': DateTimeRange(
          start: DateTime(2026, 11),
          end: DateTime(2026, 11, 17),
        ),
      },
    );
    expect(result, [(label: 'Período', value: '01/11/2026 – 17/11/2026')]);
  });

  test('exports both numeric bounds using their form field keys', () {
    expect(
      ReportExportFilterFormatter.resolve(
        [amount],
        {
          'amount_min': 0,
          'amount_max': 1234.5,
        },
      ),
      [(label: 'Valor', value: '0 – 1.234,5')],
    );
  });

  test('distinguishes minimum-only from maximum-only restrictions', () {
    expect(ReportExportFilterFormatter.resolve([amount], {'amount_min': 0}), [
      (label: 'Valor', value: '≥ 0'),
    ]);
    expect(ReportExportFilterFormatter.resolve([amount], {'amount_max': 0}), [
      (label: 'Valor', value: '≤ 0'),
    ]);
  });

  test(
    'preserves numeric strings supplied by the form without guessing locale',
    () {
      expect(
        ReportExportFilterFormatter.resolve(
          [amount],
          {
            'amount_min': ' 1.234,50 ',
            'amount_max': ' 2.000,00 ',
          },
        ),
        [(label: 'Valor', value: '1.234,50 – 2.000,00')],
      );
    },
  );

  test('omits absent and cleared range values', () {
    expect(
      ReportExportFilterFormatter.resolve(
        [amount, period],
        {
          'amount_min': ' ',
          'amount_max': null,
          'period': null,
        },
      ),
      isEmpty,
    );
    expect(ReportExportFilterFormatter.resolve([amount], null), isEmpty);
  });

  test('retains scalar date and boolean formatting', () {
    const date = AppReportFilterDescriptor(
      name: 'date',
      label: 'Data',
      type: AppReportFilterType.date,
    );
    const enabled = AppReportFilterDescriptor(
      name: 'enabled',
      label: 'Ativo',
      type: AppReportFilterType.toggle,
    );
    expect(
      ReportExportFilterFormatter.resolve(
        [date, enabled],
        {
          'date': DateTime(2026, 11, 17),
          'enabled': false,
        },
      ),
      [(label: 'Data', value: '17/11/2026'), (label: 'Ativo', value: 'Não')],
    );
  });
}

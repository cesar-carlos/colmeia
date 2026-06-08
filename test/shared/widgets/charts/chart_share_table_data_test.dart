import 'package:colmeia/shared/widgets/charts/app_category_donut_card_models.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_table_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fromDonutSegments builds label value percent rows', () {
    final table = ChartShareTableData.fromDonutSegments(
      segments: const <AppCategoryDonutSegment>[
        AppCategoryDonutSegment(label: 'Pix', value: 60),
        AppCategoryDonutSegment(label: 'Card', value: 40),
      ],
      labelHeader: 'Label',
      valueHeader: 'Value',
      percentHeader: 'Share',
    );

    expect(table.headers, <String>['Label', 'Value', 'Share']);
    expect(table.rows.length, 2);
    expect(table.rows.first.first, 'Pix');
    expect(table.rows.last.last, '40%');
  });

  test('fromRanking includes optional sales count column', () {
    final table = ChartShareTableData.fromRanking(
      rankHeader: 'Rank',
      nameHeader: 'Name',
      amountHeader: 'Amount',
      salesCountHeader: 'Sales',
      salesCounts: <String>['12', '8'],
      items: const <({String name, String amount})>[
        (name: 'Agent A', amount: r'R$ 100'),
        (name: 'Agent B', amount: r'R$ 80'),
      ],
    );

    expect(table.headers, <String>['Rank', 'Name', 'Sales', 'Amount']);
    expect(table.rows.first, <String>['1', 'Agent A', '12', r'R$ 100']);
  });

  test('fromLabelValueRows supports secondary column', () {
    final table = ChartShareTableData.fromLabelValueRows(
      labelHeader: 'Month',
      valueHeader: 'Sales',
      secondaryHeader: 'Amount',
      rows: const <({String label, String value})>[
        (label: '2026/01', value: '10'),
      ],
      secondaryValues: <String>[r'R$ 100'],
    );

    expect(table.headers, <String>['Month', 'Sales', 'Amount']);
    expect(table.rows.single, <String>['2026/01', '10', r'R$ 100']);
  });
}

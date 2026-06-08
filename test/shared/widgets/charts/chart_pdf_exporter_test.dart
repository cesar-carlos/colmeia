import 'package:colmeia/shared/widgets/charts/chart_pdf_exporter.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_table_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('build returns a non-empty PDF with table data', () async {
    final bytes = await ChartPdfExporter.build(
      title: 'Daily sales',
      subtitle: 'Selected period',
      tableData: const ChartShareTableData(
        headers: <String>['Date', 'Sales'],
        rows: <List<String>>[
          <String>['2026-06-01', '12'],
          <String>['2026-06-02', '8'],
        ],
      ),
    );

    expect(bytes, isNotEmpty);
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });

  test('build returns a non-empty PDF with only title', () async {
    final bytes = await ChartPdfExporter.build(
      title: 'Chart export',
    );

    expect(bytes, isNotEmpty);
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });
}

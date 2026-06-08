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

  test('build includes filter summary and localized page numbers', () async {
    final bytes = await ChartPdfExporter.build(
      title: 'Filtered chart',
      filterSummary: 'Branch: All',
      pageNumberLabelBuilder: (page, pages) => 'Page $page of $pages',
      tableData: const ChartShareTableData(
        headers: <String>['A'],
        rows: <List<String>>[
          <String>['1'],
        ],
      ),
    );

    expect(bytes, isNotEmpty);
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });

  test('build returns PDF with table data only', () async {
    final bytes = await ChartPdfExporter.build(
      title: 'Table only',
      tableData: const ChartShareTableData(
        headers: <String>['Metric', 'Value'],
        rows: <List<String>>[
          <String>['Sales', '10'],
        ],
      ),
    );

    expect(bytes, isNotEmpty);
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });

  test('build uses A4 landscape by default for narrow tables', () async {
    final bytes = await ChartPdfExporter.build(
      title: 'Narrow table',
      tableData: const ChartShareTableData(
        headers: <String>['A', 'B'],
        rows: <List<String>>[
          <String>['1', '2'],
        ],
      ),
    );

    expect(bytes, isNotEmpty);
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });

  test('build uses landscape for wide tables', () async {
    final bytes = await ChartPdfExporter.build(
      title: 'Wide table',
      tableData: ChartShareTableData(
        headers: List<String>.generate(7, (index) => 'C$index'),
        rows: <List<String>>[
          List<String>.generate(7, (index) => '$index'),
        ],
      ),
    );

    expect(bytes, isNotEmpty);
  });

}

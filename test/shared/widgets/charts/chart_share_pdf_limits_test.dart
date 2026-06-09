import 'package:colmeia/shared/widgets/charts/chart_share_pdf_limits.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_table_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('applyChartShareTableRowLimit keeps data when under cap', () {
    const tableData = ChartShareTableData(
      headers: <String>['A'],
      rows: <List<String>>[
        <String>['1'],
        <String>['2'],
      ],
    );

    final result = applyChartShareTableRowLimit(
      tableData: tableData,
      truncationNoticeBuilder: (shownRows, totalRows) =>
          'shown $shownRows of $totalRows',
    );

    expect(result.wasTruncated, isFalse);
    expect(result.tableData.rows, tableData.rows);
    expect(result.truncationNotice, isNull);
  });

  test('applyChartShareTableRowLimit truncates rows and builds notice', () {
    final tableData = ChartShareTableData(
      headers: const <String>['A'],
      rows: List<List<String>>.generate(
        3,
        (index) => <String>['$index'],
        growable: false,
      ),
    );

    final result = applyChartShareTableRowLimit(
      tableData: tableData,
      maxRows: 2,
      truncationNoticeBuilder: (shownRows, totalRows) =>
          'shown $shownRows of $totalRows',
    );

    expect(result.wasTruncated, isTrue);
    expect(result.tableData.rows, hasLength(2));
    expect(result.truncationNotice, 'shown 2 of 3');
  });

  test(
    'paginateChartShareTableRows returns single chunk when under page size',
    () {
      final rows = List<List<String>>.generate(
        3,
        (index) => <String>['$index'],
        growable: false,
      );

      final chunks = paginateChartShareTableRows(rows);

      expect(chunks, hasLength(1));
      expect(chunks.first, rows);
    },
  );

  test('paginateChartShareTableRows splits rows across chunks', () {
    final rows = List<List<String>>.generate(
      501,
      (index) => <String>['$index'],
      growable: false,
    );

    final chunks = paginateChartShareTableRows(rows);

    expect(chunks, hasLength(2));
    expect(chunks.first, hasLength(500));
    expect(chunks.last, hasLength(1));
  });

  test('joinChartShareFilterSummary merges filter and truncation notice', () {
    expect(
      joinChartShareFilterSummary(
        filterSummary: 'Branch A',
        truncationNotice: 'Truncated',
      ),
      'Branch A\nTruncated',
    );
  });
}

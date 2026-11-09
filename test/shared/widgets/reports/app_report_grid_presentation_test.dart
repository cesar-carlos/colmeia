import 'package:colmeia/shared/widgets/reports/app_report_column.dart';
import 'package:colmeia/shared/widgets/reports/app_report_grid_source.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

class _MockBuildContext extends Mock implements BuildContext {}

void main() {
  test(
    'presentation updates preserve rows and sort without reading cells again',
    () {
      var reads = 0;
      var notifications = 0;
      final source = AppReportGridSource<int>(
        rows: List.generate(1000, (index) => index),
        visibleColumns: [
          AppReportColumn<int>(
            key: 'value',
            label: 'Value',
            valueGetter: (row) {
              reads++;
              return row;
            },
          ),
        ],
        context: _MockBuildContext(),
      );
      addTearDown(source.dispose);
      final originalRows = source.rows;
      source.sortedColumns.add(
        const SortColumnDetails(
          name: 'value',
          sortDirection: DataGridSortDirection.descending,
        ),
      );
      source.addListener(() => notifications++);
      const color = Color(0xff112233);
      const style = TextStyle(fontSize: 16);
      source.updatePresentation(alternateRowColor: color, dataTextStyle: style);
      expect(identical(source.rows, originalRows), isTrue);
      expect(reads, 1000);
      expect(source.sortedColumns.single.name, 'value');
      expect(source.alternateRowColor, color);
      expect(source.dataTextStyle, style);
      expect(notifications, 1);
      source.updatePresentation(alternateRowColor: color, dataTextStyle: style);
      expect(notifications, 1);
      source.updatePresentation();
      expect(source.alternateRowColor, isNull);
      expect(source.dataTextStyle, isNull);
      expect(reads, 1000);
      expect(notifications, 2);
    },
  );
}

import 'package:colmeia/shared/widgets/reports/app_report_column.dart';
import 'package:colmeia/shared/widgets/reports/app_report_grid_source.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Object? _rowValue(int row) => row;

void main() {
  testWidgets(
    'buildSummaryValue should sum numeric column values',
    (tester) async {
      late BuildContext context;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (ctx) {
              context = ctx;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      const col = AppReportColumn<int>(
        key: 'n',
        label: 'N',
        valueGetter: _rowValue,
        numeric: true,
      );

      final source = AppReportGridSource<int>(
        rows: const <int>[1, 2, 3],
        visibleColumns: const <AppReportColumn<int>>[col],
        context: context,
      );

      expect(
        source.buildSummaryValue(col, AppReportAggregation.sum),
        '6',
      );
    },
  );

  testWidgets(
    'buildSummaryValue should return empty string when no numeric values',
    (tester) async {
      late BuildContext context;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (ctx) {
              context = ctx;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      const col = AppReportColumn<String>(
        key: 's',
        label: 'S',
        valueGetter: _stringRow,
        numeric: true,
      );

      final source = AppReportGridSource<String>(
        rows: const <String>['a', 'b'],
        visibleColumns: const <AppReportColumn<String>>[col],
        context: context,
      );

      expect(
        source.buildSummaryValue(col, AppReportAggregation.sum),
        '',
      );
      expect(
        source.buildSummaryValue(col, AppReportAggregation.count),
        '2',
      );
    },
  );

  testWidgets(
    'buildSummaryValue count uses non-null cells for any value type',
    (tester) async {
      late BuildContext context;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (ctx) {
              context = ctx;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      const col = AppReportColumn<String>(
        key: 's',
        label: 'S',
        valueGetter: _stringOrNull,
        numeric: true,
        aggregations: <AppReportAggregation>[AppReportAggregation.count],
      );

      final source = AppReportGridSource<String>(
        rows: const <String>['a', 'b', 'c'],
        visibleColumns: const <AppReportColumn<String>>[col],
        context: context,
      );

      expect(
        source.buildSummaryValue(col, AppReportAggregation.count),
        '2',
      );
    },
  );
}

Object? _stringRow(String row) => row;

Object? _stringOrNull(String row) => row == 'b' ? null : row;

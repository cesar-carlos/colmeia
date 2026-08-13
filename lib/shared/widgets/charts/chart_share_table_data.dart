import 'package:colmeia/shared/widgets/charts/app_category_donut_card_models.dart';
import 'package:colmeia/shared/widgets/reports/app_report_column.dart';

/// Tabular chart values included in a shared PDF export.
class ChartShareTableData {
  const ChartShareTableData({
    required this.headers,
    required this.rows,
  });

  factory ChartShareTableData.fromDonutSegments({
    required List<AppCategoryDonutSegment> segments,
    required String labelHeader,
    required String valueHeader,
    required String percentHeader,
  }) {
    final total = segments.donutWeightTotal;
    return ChartShareTableData(
      headers: <String>[labelHeader, valueHeader, percentHeader],
      rows: <List<String>>[
        for (final segment in segments)
          <String>[
            segment.label,
            segment.resolveValueLabel(),
            segment.resolvePercentLabel(total),
          ],
      ],
    );
  }

  factory ChartShareTableData.fromRanking({
    required String rankHeader,
    required String nameHeader,
    required String amountHeader,
    required List<({String name, String amount})> items,
    String? salesCountHeader,
    List<String>? salesCounts,
  }) {
    final hasSalesCount =
        salesCountHeader != null &&
        salesCounts != null &&
        salesCounts.length == items.length;
    final headers = hasSalesCount
        ? <String>[rankHeader, nameHeader, salesCountHeader, amountHeader]
        : <String>[rankHeader, nameHeader, amountHeader];
    return ChartShareTableData(
      headers: headers,
      rows: <List<String>>[
        for (var index = 0; index < items.length; index++)
          if (hasSalesCount)
            <String>[
              '${index + 1}',
              items[index].name,
              salesCounts[index],
              items[index].amount,
            ]
          else
            <String>[
              '${index + 1}',
              items[index].name,
              items[index].amount,
            ],
      ],
    );
  }

  factory ChartShareTableData.fromLabelValueRows({
    required String labelHeader,
    required String valueHeader,
    required Iterable<({String label, String value})> rows,
    String? secondaryHeader,
    Iterable<String>? secondaryValues,
  }) {
    final secondaryList = secondaryValues?.toList(growable: false);
    final rowList = rows.toList(growable: false);
    final hasSecondary =
        secondaryHeader != null &&
        secondaryList != null &&
        secondaryList.length == rowList.length;
    return ChartShareTableData(
      headers: hasSecondary
          ? <String>[labelHeader, valueHeader, secondaryHeader]
          : <String>[labelHeader, valueHeader],
      rows: <List<String>>[
        for (var index = 0; index < rowList.length; index++)
          if (hasSecondary)
            <String>[
              rowList[index].label,
              rowList[index].value,
              secondaryList[index],
            ]
          else
            <String>[rowList[index].label, rowList[index].value],
      ],
    );
  }

  static ChartShareTableData fromReportColumns<T>({
    required List<AppReportColumn<T>> columns,
    required List<T> rows,
  }) {
    if (columns.isEmpty) {
      return const ChartShareTableData(
        headers: <String>[],
        rows: <List<String>>[],
      );
    }
    return ChartShareTableData(
      headers: columns.map((column) => column.label).toList(growable: false),
      rows: <List<String>>[
        for (final row in rows)
          <String>[
            for (final column in columns)
              column.formatValue(column.valueGetter(row)),
          ],
      ],
    );
  }

  final List<String> headers;
  final List<List<String>> rows;

  bool get isEmpty => headers.isEmpty || rows.isEmpty;
}

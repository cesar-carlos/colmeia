import 'package:colmeia/shared/widgets/charts/chart_share_table_data.dart';

/// Shared limits for chart PDF table exports.
abstract final class ChartSharePdfLimits {
  static const int maxTableRows = 500;
}

/// Result of applying a row cap to chart share table data.
class ChartShareTableLimitResult {
  const ChartShareTableLimitResult({
    required this.tableData,
    this.truncationNotice,
  });

  final ChartShareTableData tableData;
  final String? truncationNotice;

  bool get wasTruncated => truncationNotice != null;
}

/// Truncates [tableData] when it exceeds [maxRows] and builds an optional notice.
ChartShareTableLimitResult applyChartShareTableRowLimit({
  required ChartShareTableData tableData,
  required String Function(int shownRows, int totalRows) truncationNoticeBuilder,
  int maxRows = ChartSharePdfLimits.maxTableRows,
}) {
  if (tableData.rows.length <= maxRows) {
    return ChartShareTableLimitResult(tableData: tableData);
  }

  return ChartShareTableLimitResult(
    tableData: ChartShareTableData(
      headers: tableData.headers,
      rows: tableData.rows
          .take(maxRows)
          .map((row) => List<String>.of(row, growable: false))
          .toList(growable: false),
    ),
    truncationNotice: truncationNoticeBuilder(maxRows, tableData.rows.length),
  );
}

String? joinChartShareFilterSummary({
  String? filterSummary,
  String? truncationNotice,
}) {
  final parts = <String>[
    if (filterSummary != null && filterSummary.trim().isNotEmpty)
      filterSummary.trim(),
    if (truncationNotice != null && truncationNotice.trim().isNotEmpty)
      truncationNotice.trim(),
  ];
  if (parts.isEmpty) {
    return null;
  }
  return parts.join('\n');
}

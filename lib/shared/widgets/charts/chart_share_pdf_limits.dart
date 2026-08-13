import 'package:colmeia/shared/widgets/charts/chart_share_table_data.dart';

/// Shared limits for chart PDF table exports.
abstract final class ChartSharePdfLimits {
  /// Hard safety cap applied before PDF generation to avoid OOM.
  static const int maxTableRows = 2000;

  /// Target row count per PDF table chunk; larger tables paginate across pages.
  static const int tableRowsPerPage = 500;

  /// Upper bound for PDF MultiPage generation. The pdf package defaults to 20,
  /// which debug-mode asserts when a wrapping landscape table spans more
  /// pages — below [maxTableRows] at typical row heights.
  static const int maxPdfPages = 300;
}

/// Splits [rows] into chunks of at most [rowsPerPage] for PDF pagination.
List<List<List<String>>> paginateChartShareTableRows(
  List<List<String>> rows, {
  int rowsPerPage = ChartSharePdfLimits.tableRowsPerPage,
}) {
  if (rows.isEmpty || rowsPerPage <= 0) {
    return const <List<List<String>>>[];
  }

  final chunks = <List<List<String>>>[];
  for (var start = 0; start < rows.length; start += rowsPerPage) {
    final end = start + rowsPerPage;
    chunks.add(
      rows.sublist(start, end > rows.length ? rows.length : end),
    );
  }
  return chunks;
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
  required String Function(int shownRows, int totalRows)
  truncationNoticeBuilder,
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

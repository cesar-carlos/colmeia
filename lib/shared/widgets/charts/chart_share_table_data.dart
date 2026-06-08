/// Tabular chart values included in a shared PDF export.
class ChartShareTableData {
  const ChartShareTableData({
    required this.headers,
    required this.rows,
  });

  final List<String> headers;
  final List<List<String>> rows;

  bool get isEmpty => headers.isEmpty || rows.isEmpty;
}
